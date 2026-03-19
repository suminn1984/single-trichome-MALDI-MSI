classdef mROI_paper < handle  % Use handle to work with standard figures

    properties (Access = public)
        MainFigure
        LoadButton % Button for loading optical image
        DetectButton % Button for automatic detection
        PointSelectButton  % Button for point selection
        GetCoordsButton % Button for displaying ROI coordinates in MATLAB
        ExportButton % Button for saving the coordinates
        Axes
        AllRegions = []  % Store all detected or manually defined regions
        ContourHandles = []  % Store plotted region handles used for visibility-based selection
        PointBuffer = []  % Store points for manual selection
        MinPixels = 1000;
        MaxPixels = 9000;
    end

    methods
        % initializes the main GUI window and connects each button
        function app = mROI_paper
            % Create the main figure window for the ROI selection workflow
            app.MainFigure = figure('Name', 'MATLAB Shape Detection and Export', ...
                'NumberTitle', 'off', 'Toolbar', 'figure', 'Menubar', 'none');

            % Create the axes used to display the optical image and ROI overlays
            app.Axes = axes(app.MainFigure);
            app.Axes.Position = [0.1 0.2 0.8 0.7];

            % Create the button for loading an optical image
            app.LoadButton = uicontrol('Style', 'pushbutton', 'String', 'Load Image', ...
                'Position', [50, 50, 100, 30], 'Callback', @(~, ~) app.loadImage());
            % Create the button for automatic ROI detection
            app.DetectButton = uicontrol('Style', 'pushbutton', 'String', 'Detect Shapes', ...
                'Position', [180, 50, 100, 30], 'Callback', @(~, ~) app.detectShapes());
            % Create the button for manual point-by-point ROI selection
            app.PointSelectButton = uicontrol('Style', 'pushbutton', 'String', 'Point Select Shape', ...
                'Position', [310, 50, 100, 30], 'Callback', @(~, ~) app.addPointSelectionShape());
            % Create the button for displaying the coordinates of visible ROIs
            app.GetCoordsButton = uicontrol('Style', 'pushbutton', 'String', 'Get Coordinates', ...
                'Position', [440, 50, 100, 30], 'Callback', @(~, ~) app.getCoordinates());
             % Create the button for exporting visible ROI coordinates to a CSV file
            app.ExportButton = uicontrol('Style', 'pushbutton', 'String', 'Export to CSV', ...
                'Position', [570, 50, 100, 30], 'Callback', @(~, ~) app.exportToCSV());
        end

        % Load an optical image and display it in the main axes
        function loadImage(app)
            [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.tif;*.tiff', 'Image Files (*.jpg, *.jpeg, *.png, *.tif, *.tiff)'}, 'Select an Image');
            if isequal(file, 0)
                disp('Image load canceled.');
            else
                img = imread(fullfile(path, file));
                imshow(img, 'Parent', app.Axes);
                title(app.Axes, 'Loaded Image');
                disp('Image successfully loaded.');
            end
        end

        % Add point selection shape: Click points to define the ROI boundary, then double-click to finish the shape
        function addPointSelectionShape(app)
            disp('Click points to define a shape. Double-click to finish.');
            app.PointBuffer = [];  % Reset the point buffer

            % Set mouse click listener
            app.MainFigure.WindowButtonDownFcn = @(~, ~) app.handleClick();
        end

        % Process mouse clicks during manual ROI selection
        function handleClick(app)
            % Check if the click is a double click
            if strcmp(app.MainFigure.SelectionType, 'open')  % Double-click
                app.finalizePointSelectionShape();
            else
                app.addPoint();  % Single click to add a point
            end
        end

        % Add a clicked point to the manual ROI boundary
        function addPoint(app)
            currPoint = get(app.Axes, 'CurrentPoint');
            x = currPoint(1, 1);
            y = currPoint(1, 2);

            % Add the selected point to the buffer
            app.PointBuffer = [app.PointBuffer; x, y];

            % Display the shape with point and lines
            hold(app.Axes, 'on');
            plot(app.Axes, x, y, 'ro', 'MarkerSize', 5);  
            if size(app.PointBuffer, 1) > 1
               plot(app.Axes, app.PointBuffer(end-1:end, 1), app.PointBuffer(end-1:end, 2), 'r-');
            end
            hold(app.Axes, 'off');
        end

        % Finalize the manual ROI selection by converting the collected boundary points
        % into a polyshape object, displaying it on the image, and saving it 
        function finalizePointSelectionShape(app)
            if size(app.PointBuffer, 1) < 3
                disp('At least 3 points are required to create a shape.');
                return;
            end

            % Create the polyshape from the buffer points
            newRegion = polyshape(app.PointBuffer(:, 1), app.PointBuffer(:, 2), 'Simplify', true);

            % Display the shape
            hold(app.Axes, 'on');
            h = plot(app.Axes, newRegion, 'FaceColor', 'none', 'EdgeColor', 'b', 'LineWidth', 0.1);
            h.ButtonDownFcn = @(src, ~) app.toggleVisibility(src);  % Enable click selection
            hold(app.Axes, 'off');

            % Save the shape and handle
            app.AllRegions = [app.AllRegions, newRegion];
            app.ContourHandles = [app.ContourHandles, h];

            % Reset listeners
            app.MainFigure.WindowButtonDownFcn = [];
            app.PointBuffer = [];  % Clear buffer
            disp('Shape created and added.');
        end

        % Get coordinates of shapes
        function getCoordinates(app)
            if isempty(app.AllRegions) || isempty(app.ContourHandles)
                disp('No regions to display.');
                return;
            end

            % Display coordinates of only visible regions
            foundVisible = false;
            for i = 1:length(app.AllRegions)
                if isvalid(app.ContourHandles(i)) && strcmp(app.ContourHandles(i).Visible, 'on')
                    region = app.AllRegions(i);
                    coords = region.Vertices;
                    disp(['Region ', num2str(i), ' coordinates:']);
                    disp(coords);
                    foundVisible = true;
                end
            end

            if ~foundVisible
                disp('No visible regions to display.');
            end
        end

        % Export coordinates of valid and visible ROI contours to a CSV file by
        % retrieving polygon vertices from AllRegions and assigning the region index to each vertex
        function exportToCSV(app)
            if isempty(app.AllRegions) || isempty(app.ContourHandles)
                disp('No regions to export.');
                return;
            end

            data = [];
            % Loop through all stored regions
            % Keep only regions whose plotted contours are valid and currently visible
            % Get the polygon vertex coordinates for each selected region
            % Repeat the region number for each vertex and append the result to the export array
            for i = 1:length(app.AllRegions)
                if isvalid(app.ContourHandles(i)) && strcmp(app.ContourHandles(i).Visible, 'on')
                    coords = app.AllRegions(i).Vertices;
                    regionIndex = repmat(i, size(coords, 1), 1);
                    data = [data; regionIndex, coords];
                end
            end

            if isempty(data)
                disp('No visible regions to export.');
                return;
            end

            T = array2table(data, 'VariableNames', {'Region', 'X', 'Y'});
            [file, path] = uiputfile('regions.csv', 'Save Coordinates as');
            if isequal(file, 0)
                disp('Export canceled.');
            else
                writetable(T, fullfile(path, file));
                disp('Coordinates exported to CSV.');
            end
        end

        % Detect trichome candidate shapes from the loaded image - converting the image to grayscale,
        % identifying edges under optimized detection conditions, and processing each detected trichome
        % as an individual polygonal ROI for visualization and export
        % of the coordinates
        function detectShapes(app)
            imgHandle = findobj(app.Axes, 'Type', 'Image');
            if isempty(imgHandle)
                disp('No image found.');
                return;
            end

            img = imgHandle.CData;
            if size(img, 3) == 3
                img = rgb2gray(img);
            end
            img = imgaussfilt(img, 2);
            edges = edge(img, 'Canny', [0.01, 0.4]);
            edges = imdilate(edges, strel('disk', 3));
            edges = imfill(edges, 'holes');
            edges = bwareaopen(edges, app.MinPixels);
            [labeledImage, numObjects] = bwlabel(edges);

                        if ~isempty(app.ContourHandles)
                delete([app.ContourHandles{:}]);
            end
            app.ContourHandles = [];
            app.AllRegions = [];
            
            hold(app.Axes, 'on');
            for i = 1:numObjects
                componentMask = (labeledImage == i);
                areaPx = nnz(componentMask);
                if areaPx < app.MinPixels || areaPx > app.MaxPixels
                    continue;
                end

                boundary = bwboundaries(componentMask, 'noholes');
                boundary = boundary{1};
                newRegion = polyshape(boundary(:, 2), boundary(:, 1), 'Simplify', true);

                % Store the detected region and plot its handle
                app.AllRegions = [app.AllRegions, newRegion];
                h = plot(app.Axes, newRegion, 'FaceColor', 'none', 'EdgeColor', [0 0.8 1], 'LineWidth', 1);
                h.ButtonDownFcn = @(src, ~) app.toggleVisibility(src);  % Enable click selection
                app.ContourHandles = [app.ContourHandles, h];
            end
            hold(app.Axes, 'off');
            disp('Shape detection completed.');
        end

        % Toggle visibility of a shape
        function toggleVisibility(app, src)
            if strcmp(src.Visible, 'on')
                src.Visible = 'off';
                disp('Shape hidden.');
            else
                src.Visible = 'on';
                disp('Shape displayed.');
            end
        end
    end  % End of methods
end  % End of class

