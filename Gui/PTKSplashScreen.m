classdef PTKSplashScreen < PTKProgressInterface
    % PTKSplashScreen. A splash screen dialog which also reports progress informaton
    %
    %     PTKSplashScreen creates a dialog with the application logo and version
    %     information. It also displays progress information, for use during the
    %     application startup for reporting progress before the user interface
    %     is visible.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Dependent = true)
        Title
    end

    properties (Access = private)
        FigureHandle
        Image
        TitleText
        BodyText
        PanelHandle
        Disabled = false
        
        ProgressBarHandle
        Text
        ProgressTitle
        Cancel
        Quit
        UserClickedCancel = false

        Parent
        IncrementThreshold = 5
        HandleToWaitDialog
        DialogText
        DialogTitle = ''
        ProgressValue = 0
        
        Hold = false;
        ShowProgressBar = false
        
        TimerRef
        MaxTimeBetweenUpdates = 0.25
        
        PanelIsShown = false
        LastText
        LastTitle
    end
        
    methods
        function obj = PTKSplashScreen
            set(0, 'Units', 'pixels');
            screen_size = get(0, 'ScreenSize');
            obj.FigureHandle = figure('Color', [1 1 1], 'Units', 'Pixels', 'ToolBar', 'none', 'Visible', 'off', 'Resize', 'off', 'MenuBar', 'none');
            position = get(obj.FigureHandle, 'Position');
            position(3) = 926; position(4) = 474;
            position(1) = max(1, round((screen_size(3) - position(3))/2));
            position(2) = max(1, round((screen_size(4) - position(4))/2));
            set(obj.FigureHandle, 'Position', position);
            set(obj.FigureHandle, 'NumberTitle', 'off');
            obj.Image = axes('Units', 'Pixels', 'Position', [30, 100, 333, 314]);
            logo = imread(PTKSoftwareInfo.SplashScreenImageFile);
            image(logo, 'Parent', obj.Image);
            axis(obj.Image, 'off');
            obj.TitleText = uicontrol('Style', 'text', 'Units', 'Pixels', 'Position', [420, 350, 460, 75], 'String', PTKSoftwareInfo.Name, 'FontName', PTKSoftwareInfo.GuiFont, 'FontUnits', 'pixels', 'FontSize', 40, 'FontWeight', 'bold', 'ForegroundColor', [0, 0.129, 0.278], 'BackgroundColor', [1 1 1]);
            obj.BodyText = uicontrol('Style', 'text', 'Units', 'Pixels', 'Position', [420, 240, 460, 110], 'FontName', PTKSoftwareInfo.GuiFont, 'FontUnits', 'pixels', 'FontSize', 16, 'FontWeight', 'bold', 'ForegroundColor', [0, 0.129, 0.278], 'BackgroundColor', [1 1 1]);
            set(obj.BodyText, 'String', sprintf(['Version ' PTKSoftwareInfo.Version ' \n\n' PTKSoftwareInfo.WebsiteUrl]));
            
            

            % Create the progress reporting
            panel_background_colour = [1 1 1];
            text_color = [0.0 0.129 0.278];
            
            title_position = [450, 140, 400, 30];
            text_position = [450, 90, 400, 40];
            cancel_position = [580, 20, 140, 30];
            quit_position = [750, 20, 70, 30];
            progress_bar_position = [450, 80, 400, 18];
            
            
            obj.ProgressTitle = uicontrol('parent', obj.FigureHandle, 'style', 'text', 'units', 'pixel', 'Position', title_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 24, 'FontWeight', 'bold', 'Fore', text_color, 'Back', panel_background_colour);
            obj.Text = uicontrol('parent', obj.FigureHandle, 'style', 'text', 'units', 'pixel', 'Position', text_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 16, 'Fore', text_color, 'Back', panel_background_colour);
            obj.Cancel = uicontrol('parent', obj.FigureHandle, 'string', 'Cancel', ...
                'FontUnits', 'pixels', 'Position', cancel_position, 'Callback', @obj.CancelButton);
            obj.Quit = uicontrol('parent', obj.FigureHandle, 'string', 'Force Quit', ...
                'FontUnits', 'pixels', 'Position', quit_position, 'Callback', @obj.QuitButton);
            
            [obj.ProgressBarHandle, ~] = javacomponent('javax.swing.JProgressBar', ...
                progress_bar_position, obj.FigureHandle);
            obj.ProgressBarHandle.setValue(0);

            set(obj.FigureHandle, 'Visible', 'on');
            obj.TimerRef = tic;

            obj.Hide;
            
        end
        
        function Delete(obj)
            delete(obj.FigureHandle);
        end
        
        function title = get.Title(obj)
            title = get(obj.FigureHandle, 'Name');
        end
        
        function set.Title(obj, title)
            set(obj.FigureHandle, 'Name', title);
        end
               
        function ShowAndHold(obj, text)
            if nargin < 2
                text = 'Please wait';
            end
            obj.Hide;
            obj.DialogTitle = PTKTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.Update;
            obj.ShowPanel;
            obj.UserClickedCancel = false;
        end
        
        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.ShowProgressBar = false;

            obj.HidePanel;
            obj.Hold = false;
        end
        
        % Call to complete a progress operaton, which will also hide the dialog
        % unless the dialog is being held
        function Complete(obj)
            obj.ShowProgressBar = false;
            obj.ProgressValue = 100;
            if ~obj.Hold
                obj.Hide;
            else
                obj.DialogText = '';
                obj.Update;
            end
        end
        
        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end            
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.Update;
            obj.ShowPanel;            
        end
        
        function SetProgressValue(obj, progress_value)
            obj.ProgressValue = progress_value;
            obj.ShowProgressBar = true;
            obj.Update;
            obj.ShowPanel;
        end
        
        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.Update;
            obj.ShowPanel;            
        end
        
        function cancelled = CancelClicked(obj)
            cancelled = obj.UserClickedCancel;
            obj.UserClickedCancel = false;
        end
        
        function Resize(~, ~)
        end
        
    end
    
    methods (Access = private)
        function Update(obj)
            if isempty(obj.LastTitle) || ~strcmp(obj.DialogTitle, obj.LastTitle)
                set(obj.ProgressTitle, 'String', obj.DialogTitle);
                obj.LastTitle = obj.DialogTitle;
            end
            
            if isempty(obj.LastText) || ~strcmp(obj.DialogText, obj.LastText)
                set(obj.Text, 'String', obj.DialogText);
                obj.LastText = obj.DialogText;
            end
            
            obj.ProgressBarHandle.setValue(obj.ProgressValue);
            
            if isempty(obj.TimerRef) || toc(obj.TimerRef) > obj.MaxTimeBetweenUpdates
                obj.TimerRef = tic;
                drawnow;
            end
        end
        
        function ShowPanel(obj)
            if obj.Disabled || obj.PanelIsShown
                return;
            end            
            set(obj.Text, 'Visible', 'on');
            set(obj.ProgressTitle, 'Visible', 'on');

            if PTKSoftwareInfo.DebugMode
                set(obj.Quit, 'Visible', 'on');
            end

            set(obj.Cancel, 'Visible', 'on');
            set(obj.ProgressBarHandle, 'visible', 1);
            
            obj.PanelIsShown = true;            
        end
        
        function HidePanel(obj)
            
            if obj.Disabled || ~obj.PanelIsShown
                return;
            end
            
            set(obj.Text, 'Visible', 'off');
            set(obj.ProgressTitle, 'Visible', 'off');
            set(obj.Quit, 'Visible', 'off');
            set(obj.Cancel, 'Visible', 'off');
            set(obj.ProgressBarHandle, 'visible', 0);
            obj.PanelIsShown = false;
        end
        
        function CancelButton(obj, ~, ~)
            obj.UserClickedCancel = true;
        end
        
        function QuitButton(obj, ~, ~)
            obj.Hide;
            throw(MException('PTKCustomProgressDialog:UserForceQuit', 'User forced plugin to terminate'));
        end
    end
    
end
