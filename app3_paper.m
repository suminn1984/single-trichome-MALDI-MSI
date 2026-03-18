function runAlignmentWithOverlay()
    clear; close all; clc;  % initialize the session

    % Step 1: Load the pre-MALDI optical image and the corresponding
    % post-MALDI optical image.
    % They are used as the reference images for landmark selection, affine transformation,
    % and subsequent spatial registration of the mROI coordinates.It uses
    % png, jpg, tif files. 
    [opticalFile, opticalPath] = uigetfile({'*.png;*.jpg;*.tif;*.tiff'}, ...
        'Optical selection.');
    if isequal(opticalFile, 0)
        disp('Optical image selection canceled');
        return;
    end
    opticalImage = imread(fullfile(opticalPath, opticalFile));
    [opticalHeight, opticalWidth, ~] = size(opticalImage);  % Optical image resolution settings

    [postOptiFile, postOptiPath] = uigetfile({'*.png;*.jpg;*.tif;*.tiff'}, ...
        'post-MALDI optical image selection.');
    if isequal(postOptiFile, 0)
        disp('post-MALDI optical image selection canceled.');
        return;
    end
    postOptiImage = imread(fullfile(postOptiPath, postOptiFile));
    [postOptiHeight, postOptiWidth, ~] = size(postOptiImage);  % post-optical image resolution

    % Step 2: Resize the post-MALDI optical image to match the area of the
    % pre-MALDI optical image so that both images share the same resolution,
    % enabling consistent landmark selection and affine registration.
    postOptiImage = imresize(postOptiImage, [opticalHeight, opticalWidth]);

    % Step 3: Manually select five corresponding landmarks on the pre-MALDI and
    % post-MALDI optical images to define the point pairs required for affine
    % transformation and spatial registration of the trichome ROIs.
    opticalPoints = selectLandmarks(opticalImage, 'Optical');
    postOptiPoints = selectLandmarks(postOptiImage, 'postOptical');

    % Step 4: Calculate the affine transformation from the corresponding
    % landmark pairs, the spatial relationship between the pre-MALDI and
    % post-MALDI optical images are stored.
    tform = fitgeotrans(postOptiPoints, opticalPoints, 'affine');
    disp('Affine matrix applied:');
    disp(tform.T);

    % Step 5: Load the mROI coordinate file exported from the previous ROI selection
    % step, which contains the region, X, Y coordinates to be
    % transformed and registered onto the post-MALDI optical image.
    [coordFile, coordPath] = uigetfile('*.csv', 'mROI upload from STEP1.');
    if isequal(coordFile, 0)
        disp('mROI upload canceled');
        return;
    end

    roiData = readtable(fullfile(coordPath, coordFile));
    regions = roiData.Region;
    roiCoords = [roiData.X, roiData.Y];

    % Step 6: Apply the calculated affine transformation to the imported mROI
    % coordinates.
    % The trichome ROI positions are projected onto the post-MALDI optical image.
    transformedCoords = transformPointsInverse(tform, roiCoords);

    % printing transformed mROI coordinates
    disp('transformed mROI coordinates:');
    disp(table(regions, transformedCoords(:, 1), transformedCoords(:, 2), ...
        'VariableNames', {'Region', 'X', 'Y'}));

    % Step 7: image with transformed mROI
    fig = figure('Name', 'post-optical image and mROI', 'Position', [100, 100, 800, 600]);

    ax = axes('Parent', fig, 'Position', [0.1, 0.2, 0.8, 0.7]);
    imshow(postOptiImage, 'Parent', ax, 'InitialMagnification', 'fit');
    hold on;
    plotRegions(transformedCoords, regions);
    hold off;

    % Step 8: CSV save
    uicontrol('Style', 'pushbutton', 'String', 'Save mROI to CSV', ...
        'Position', [350, 20, 120, 40], ...
        'Callback', @(~, ~) saveTransformedCoordsToCSV(transformedCoords, regions, opticalHeight, opticalWidth));
end

    % Selection of Landmarks: Display the input optical image and allow the user
    % to manually select five corresponding landmark points by clicking them in "sequential order".
  

function points = selectLandmarks(image, imageType)
    figure, imshow(image);
    title([imageType, ' selection: click 5 landmarks on image.']);
    hold on;

    points = zeros(5, 2);  
    for i = 1:5
        [x, y] = ginput(1);  
        points(i, :) = [x, y];
        plot(x, y, 'ro', 'MarkerSize', 6, 'LineWidth', 1.0);
        text(x, y, sprintf('%d', i), 'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold');
    end
    hold off;
    close;
end

% mROI coordinates saved with detailed information
function saveTransformedCoordsToCSV(transformedCoords, regions, height, width)
    [filename, pathname] = uiputfile('*.csv', 'Save Transformed mROI Coordinates');
    if isequal(filename, 0)
        disp('CSV file save canceled.');
        return;
    end

    % table with coordinates and resolution information
    coordsTable = table(regions, transformedCoords(:, 1), transformedCoords(:, 2), ...
        repmat(height, size(transformedCoords, 1), 1), ...
        repmat(width, size(transformedCoords, 1), 1), ...
        'VariableNames', {'Region', 'X', 'Y', 'ImageHeight', 'ImageWidth'});

    % CSV file saves
    filePath = fullfile(pathname, filename);
    writetable(coordsTable, filePath);

    disp(['CSV saved: ', filePath]);
end
% Plot the transformed mROI coordinates assigning a unique color to each region (you can change the color), and drawing
% each group as a closed polygon overlay for visual inspection of the registration result
function plotRegions(coords, regions) % setting for drawing polygon
    uniqueRegions = unique(regions);  % unique region
    numRegions = min(length(uniqueRegions), 200);  % max 200 region
    colors = lines(numRegions);  % color

    hold on;  % 
    for i = 1:numRegions
        regionIdx = regions == uniqueRegions(i);  % selecting coordinates in a certain region
        regionCoords = coords(regionIdx, :);  % coordinates filtering

        
        closedCoords = [regionCoords; regionCoords(1, :)];

        
        plot(closedCoords(:, 1), closedCoords(:, 2), '-', 'Color', colors(i, :), ...
            'LineWidth', 1.0, 'DisplayName', ['Region ', num2str(uniqueRegions(i))]);

        
        plot(regionCoords(:, 1), regionCoords(:, 2), 'o', 'Color', colors(i, :), ...
            'MarkerSize', 1, 'LineWidth', 1.0);
    end
    hold off;

    legend show;  
    axis equal;  
end