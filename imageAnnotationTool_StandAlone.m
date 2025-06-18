function imageAnnotationTool_StandAlone()
    % MATLAB Image Annotation Tool
    % Interactive tool for drawing polylines and adding text annotations to images
    
    % Initialize variables - using more specific variable names to avoid conflicts
    imageData = [];
    currentColor = [1 0 0]; % Default red color
    currentThickness = 2;
    fontSize = 12;
    textColor = [1 0 0];
    isDrawing = false;
    currentPolyline = [];
    polylineHandles = {};
    textHandles = {};
    dynamicLineHandle = [];
    currentMode = 'polyline';
    
    % Create main figure
    mainFig = figure('Name', 'Image Annotation Tool', ...
                     'NumberTitle', 'off', ...
                     'Position', [100 100 1200 800], ...
                     'Resize', 'on', ...
                     'CloseRequestFcn', @closeFigure);
    
    % Create image axes
    imgAxes = axes('Parent', mainFig, ...
                   'Position', [0.25 0.1 0.7 0.8], ...
                   'Box', 'on');
    
    % Create control panel
    controlPanel = uipanel('Parent', mainFig, ...
                          'Title', 'Controls', ...
                          'Position', [0.02 0.1 0.2 0.8], ...
                          'BackgroundColor', [0.94 0.94 0.94]);
    
    % Load Image Button
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Load Image', ...
              'Position', [10 550 120 30], ...
              'Callback', @loadImage, ...
              'FontSize', 10, ...
              'FontWeight', 'bold');
    
    % Color Selection
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Color:', ...
              'Position', [10 500 60 20], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'FontWeight', 'bold');
    
    colorButtons = [];
    colors = {[1 0 0], [0 1 0], [0 0 1], [1 1 0], [1 0 1], [0 1 1], [0 0 0], [1 1 1]};
    colorNames = {'Red', 'Green', 'Blue', 'Yellow', 'Magenta', 'Cyan', 'Black', 'White'};
    
    for i = 1:length(colors)
        row = floor((i-1)/4);
        col = mod(i-1, 4);
        colorButtons(i) = uicontrol('Parent', controlPanel, ...
                                   'Style', 'pushbutton', ...
                                   'String', '', ...
                                   'Position', [10 + col*25, 470 - row*25, 20, 20], ...
                                   'BackgroundColor', colors{i}, ...
                                   'Callback', {@selectColor, colors{i}}, ...
                                   'TooltipString', colorNames{i});
    end
    
    % Line Thickness
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Line Thickness:', ...
              'Position', [10 410 100 20], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'FontWeight', 'bold');
    
    thicknessSlider = uicontrol('Parent', controlPanel, ...
                               'Style', 'slider', ...
                               'Position', [10 380 100 20], ...
                               'Min', 1, 'Max', 10, ...
                               'Value', currentThickness, ...
                               'SliderStep', [0.1 0.2], ...
                               'Callback', @thicknessChanged);
    
    thicknessLabel = uicontrol('Parent', controlPanel, ...
                              'Style', 'text', ...
                              'String', sprintf('%.1f px', currentThickness), ...
                              'Position', [115 380 30 20], ...
                              'BackgroundColor', [0.94 0.94 0.94]);
    
    % Font Size (for text)
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Font Size:', ...
              'Position', [10 350 100 20], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'FontWeight', 'bold');
    
    fontSlider = uicontrol('Parent', controlPanel, ...
                          'Style', 'slider', ...
                          'Position', [10 320 100 20], ...
                          'Min', 8, 'Max', 24, ...
                          'Value', fontSize, ...
                          'SliderStep', [0.1 0.2], ...
                          'Callback', @fontSizeChanged);
    
    fontLabel = uicontrol('Parent', controlPanel, ...
                         'Style', 'text', ...
                         'String', sprintf('%d pt', fontSize), ...
                         'Position', [115 320 30 20], ...
                         'BackgroundColor', [0.94 0.94 0.94]);
    
    % Mode Toggle Button
    modeButton = uicontrol('Parent', controlPanel, ...
                          'Style', 'togglebutton', ...
                          'String', 'Polyline Mode', ...
                          'Position', [10 270 120 30], ...
                          'Callback', @toggleMode, ...
                          'FontSize', 10, ...
                          'Value', 1);
    
    % Action Buttons
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Clear All', ...
              'Position', [10 90 120 30], ...
              'Callback', @clearAll, ...
              'FontSize', 10);
    
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Save Annotated Image', ...
              'Position', [10 50 120 30], ...
              'Callback', @saveImage, ...
              'FontSize', 10, ...
              'FontWeight', 'bold');
    
    % Instructions
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Instructions: Load image, toggle mode, then click on image. For polylines: click points, double-click or right-click to finish.', ...
              'Position', [10 5 120 40], ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'FontSize', 8, ...
              'HorizontalAlignment', 'left');
    
    % Set initial button states and highlight first color
    % Highlight the first color button (red) by changing its appearance
    set(colorButtons(1), 'String', '●', 'FontSize', 12, 'ForegroundColor', [1 1 1]);
    
    % Display initial message
    axes(imgAxes);
    text(0.5, 0.5, 'Load an image to start annotating', ...
         'Units', 'normalized', ...
         'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', ...
         'FontSize', 14, ...
         'Color', [0.5 0.5 0.5]);
    
    % Callback Functions
    function loadImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tiff;*.tif', ...
                                         'Image Files (*.jpg,*.jpeg,*.png,*.bmp,*.tiff,*.tif)'}, ...
                                        'Select an image file');
        if filename ~= 0
            try
                imageData = imread(fullfile(pathname, filename));
                axes(imgAxes);
                imshow(imageData);
                title('Click to annotate - Right-click to finish polyline');
                
                % Set up mouse callbacks
                set(mainFig, 'WindowButtonDownFcn', @mouseClick);
                set(mainFig, 'WindowButtonUpFcn', @mouseRelease);
                set(mainFig, 'WindowButtonMotionFcn', @mouseMove);
                
                % Set cursor for drawing
                setCursor();
                
                % Clear previous annotations
                clearAll();
                
            catch ME
                errordlg(['Error loading image: ' ME.message], 'Load Error');
            end
        end
    end
    
    function toggleMode(src, ~)
        if get(src, 'Value') == 1
            currentMode = 'polyline';
            set(src, 'String', 'Polyline Mode');
            if ~isempty(imageData)
                title(imgAxes, 'Polyline Mode - Click to draw, double-click or right-click to finish');
            end
        else
            currentMode = 'text';
            set(src, 'String', 'Text Mode');
            if ~isempty(imageData)
                title(imgAxes, 'Text Mode - Click to add text');
            end
        end
        % Reset any ongoing drawing
        isDrawing = false;
        currentPolyline = [];
        clearDynamicLine();
        setCursor();
    end
    
    function setCursor()
        if strcmp(currentMode, 'polyline')
            set(mainFig, 'Pointer', 'crosshair');
        else
            set(mainFig, 'Pointer', 'ibeam');
        end
    end
    
    function clearDynamicLine()
        if ~isempty(dynamicLineHandle) && ishandle(dynamicLineHandle)
            delete(dynamicLineHandle);
            dynamicLineHandle = [];
        end
    end
    
    function selectColor(~, ~, color)
        currentColor = color;
        textColor = color;
        % Highlight selected color button by adding a symbol and clearing others
        for i = 1:length(colorButtons)
            if isequal(get(colorButtons(i), 'BackgroundColor'), color)
                set(colorButtons(i), 'String', '●', 'FontSize', 12, 'ForegroundColor', [1 1 1]);
            else
                set(colorButtons(i), 'String', '', 'FontSize', 10);
            end
        end
    end
    
    function thicknessChanged(src, ~)
        currentThickness = get(src, 'Value');
        set(thicknessLabel, 'String', sprintf('%.1f px', currentThickness));
    end
    
    function fontSizeChanged(src, ~)
        fontSize = round(get(src, 'Value'));
        set(fontLabel, 'String', sprintf('%d pt', fontSize));
    end
    
    function mouseClick(~, ~)
        if isempty(imageData)
            return;
        end
        
        % Get click position
        pos = get(imgAxes, 'CurrentPoint');
        x = pos(1,1);
        y = pos(1,2);
        
        % Check if click is within image bounds
        xlim = get(imgAxes, 'XLim');
        ylim = get(imgAxes, 'YLim');
        if x < xlim(1) || x > xlim(2) || y < ylim(1) || y > ylim(2)
            return;
        end
        
        % Get click type
        clickType = get(mainFig, 'SelectionType');
        
        if strcmp(currentMode, 'polyline')
            handlePolylineClick(x, y, clickType);
        elseif strcmp(currentMode, 'text')
            handleTextClick(x, y);
        end
    end
    
    function mouseMove(~, ~)
        if ~isDrawing || isempty(currentPolyline) || isempty(imageData)
            return;
        end
        
        % Get current mouse position
        pos = get(imgAxes, 'CurrentPoint');
        x = pos(1,1);
        y = pos(1,2);
        
        % Check if mouse is within image bounds
        xlim = get(imgAxes, 'XLim');
        ylim = get(imgAxes, 'YLim');
        if x < xlim(1) || x > xlim(2) || y < ylim(1) || y > ylim(2)
            clearDynamicLine();
            return;
        end
        
        % Draw dynamic line from last point to current mouse position
        lastPoint = currentPolyline(end, :);
        
        % Clear previous dynamic line
        clearDynamicLine();
        
        % Draw new dynamic line
        axes(imgAxes);
        hold on;
        dynamicLineHandle = plot([lastPoint(1), x], [lastPoint(2), y], ...
                                '--', 'Color', currentColor, ...
                                'LineWidth', currentThickness, ...
                                'Tag', 'dynamic_line');
    end
    
    function handlePolylineClick(x, y, clickType)
        if strcmp(clickType, 'alt') || strcmp(clickType, 'open') % Right click or double click - finish polyline
            if isDrawing && length(currentPolyline) >= 2
                finishPolyline();
            end
            return;
        end
        
        % Left click - add point
        if ~isDrawing
            % Start new polyline
            isDrawing = true;
            currentPolyline = [x, y];
        else
            % Add point to current polyline
            currentPolyline = [currentPolyline; x, y];
        end
        
        % Clear dynamic line
        clearDynamicLine();
        
        % Draw current polyline
        axes(imgAxes);
        hold on;
        
        if size(currentPolyline, 1) >= 2
            % Remove previous temporary line if exists
            temp_lines = findobj(imgAxes, 'Tag', 'temp_polyline');
            delete(temp_lines);
            
            % Draw current polyline
            plot(currentPolyline(:,1), currentPolyline(:,2), ...
                 'Color', currentColor, 'LineWidth', currentThickness, ...
                 'Tag', 'temp_polyline');
        end
        
        % Draw current point
        plot(x, y, 'o', 'Color', currentColor, 'MarkerSize', 4, ...
             'MarkerFaceColor', currentColor, 'Tag', 'temp_polyline');
    end
    
    function finishPolyline()
        if length(currentPolyline) < 2
            return;
        end
        
        axes(imgAxes);
        hold on;
        
        % Remove temporary lines
        temp_lines = findobj(imgAxes, 'Tag', 'temp_polyline');
        delete(temp_lines);
        
        % Clear dynamic line
        clearDynamicLine();
        
        % Create final polyline
        polyline_points = currentPolyline;
        
        % Draw final polyline
        h = plot(polyline_points(:,1), polyline_points(:,2), ...
                 'Color', currentColor, 'LineWidth', currentThickness, ...
                 'Tag', 'final_polyline');
        
        % Store handle
        polylineHandles{end+1} = h;
        
        % Reset drawing state
        isDrawing = false;
        currentPolyline = [];
    end
    
    function handleTextClick(x, y)
        % Prompt for text input
        text_input = inputdlg('Enter text annotation:', 'Text Input', 1, {''});
        
        if ~isempty(text_input) && ~isempty(text_input{1})
            axes(imgAxes);
            hold on;
            
            % Add text annotation
            h = text(x, y, text_input{1}, ...
                     'Color', textColor, ...
                     'FontSize', fontSize, ...
                     'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'VerticalAlignment', 'middle', ...
                     'BackgroundColor', 'white', ...
                     'EdgeColor', 'black', ...
                     'Tag', 'text_annotation');
            
            % Store handle
            textHandles{end+1} = h;
        end
    end
    
    function mouseRelease(~, ~)
        % Handle mouse release events if needed
    end
    
    function clearAll(~, ~)
        if isempty(imageData)
            return;
        end
        
        % Clear all annotations
        axes(imgAxes);
        
        % Delete all polylines
        for i = 1:length(polylineHandles)
            if ishandle(polylineHandles{i})
                delete(polylineHandles{i});
            end
        end
        polylineHandles = {};
        
        % Delete all text annotations
        for i = 1:length(textHandles)
            if ishandle(textHandles{i})
                delete(textHandles{i});
            end
        end
        textHandles = {};
        
        % Delete temporary elements
        temp_elements = findobj(imgAxes, 'Tag', 'temp_polyline');
        delete(temp_elements);
        
        % Clear dynamic line
        clearDynamicLine();
        
        % Reset drawing state
        isDrawing = false;
        currentPolyline = [];
        
        % Refresh display
        imshow(imageData);
        title('Annotations cleared - Ready to annotate');
    end
    
    function saveImage(~, ~)
        if isempty(imageData)
            errordlg('No image loaded!', 'Save Error');
            return;
        end
        
        try
            % Get current axes frame
            axes(imgAxes);
            frame = getframe(imgAxes);
            annotated_img = frame.cdata;
            
            % Save dialog
            [filename, pathname] = uiputfile({'*.png', 'PNG Image (*.png)'; ...
                                             '*.jpg', 'JPEG Image (*.jpg)'; ...
                                             '*.bmp', 'Bitmap Image (*.bmp)'; ...
                                             '*.tiff', 'TIFF Image (*.tiff)'}, ...
                                            'Save Annotated Image', ...
                                            'annotated_image.png');
            
            if filename ~= 0
                imwrite(annotated_img, fullfile(pathname, filename));
                msgbox(['Image saved successfully to: ' fullfile(pathname, filename)], ...
                       'Save Complete');
            end
            
        catch ME
            errordlg(['Error saving image: ' ME.message], 'Save Error');
        end
    end
    
    function closeFigure(~, ~)
        % Clean up and close
        delete(mainFig);
    end
    
end