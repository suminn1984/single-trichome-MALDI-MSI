function plotTransformedCoordinatesOnImage()
    clear; close all; clc;

    % Step 1: Load the post-MALDI optical image onto which the affine-transformed mROI coordinates
    % will be overlaid. 
    [imageFile, imagePath] = uigetfile({'*.png;*.jpg;*.tif;*.tiff'}, 'select the post-MALDI-optical image.');
    if isequal(imageFile, 0)
        disp('image selection has been canceled.');
        return;
    end
    originalImage = imread(fullfile(imagePath, imageFile));
    [imgHeight, imgWidth, ~] = size(originalImage); 

    % Step 2: Load the CSV file containing the previously affine-transformed mROI
    % coordinates and region.  
    [coordFile, coordPath] = uigetfile('*.csv', 'upload mROI coordinates files');
    if isequal(coordFile, 0)
        disp('CSV selection has been canceled');
        return;
    end
    roiData = readtable(fullfile(coordPath, coordFile));

    % Step 3: Read the image height and width stored in the CSV file so that
    % the original coordinate reference resolution can be identified before
    % rescaling the mROI coordinates to the current image size.
    origHeight = roiData.ImageHeight(1);  
    origWidth = roiData.ImageWidth(1);    

    % Step 4: Calculate the scaling factors and apply them tㅐ the imported mROI coordinates
    % for projecting mROI on the post-MALDI optical image.
    scaleY = imgHeight / origHeight;
    scaleX = imgWidth / origWidth;
    transformedCoords = [roiData.X * scaleX, roiData.Y * scaleY];

    % Step 5: Create a figure of the post-MALDI optical image for visualizing the
    % resolution-adjusted mROI coordinates 
    fig = figure('Name', '원본 이미지와 mROI', 'Position', [100, 100, 800, 600]);
    ax = axes('Parent', fig, 'Position', [0.1, 0.2, 0.8, 0.7]);
    imshow(originalImage, 'Parent', ax, 'InitialMagnification', 'fit');
    hold on;

    % Step 6: projecting mROI onto the post-MALDI optical image
    regions = roiData.Region;
    plotRegions(transformedCoords, regions);  
    hold off;

    % Creating a button to save the transformed mROI coordinates
    uicontrol('Style', 'pushbutton', 'String', 'Save mROI to CSV', ...
              'Position', [350, 20, 120, 40], ...
              'Callback', @(~, ~) saveTransformedCoordsToCSV(transformedCoords, regions));
end

function plotRegions(coords, regions)
    uniqueRegions = unique(regions);  % 
    numRegions = min(length(uniqueRegions), 200);  % 
    colors = lines(numRegions);  % 

    hold on;  
    for i = 1:numRegions
        regionIdx = regions == uniqueRegions(i);  
        regionCoords = coords(regionIdx, :);  

        
        closedCoords = [regionCoords; regionCoords(1, :)];

        %
        plot(closedCoords(:, 1), closedCoords(:, 2), '-', 'Color', colors(i, :), ...
            'LineWidth', 1.0, 'DisplayName', ['Region ', num2str(uniqueRegions(i))]);

        % 
        plot(regionCoords(:, 1), regionCoords(:, 2), 'o', 'Color', colors(i, :), ...
            'MarkerSize', 1, 'LineWidth', 1.0);
    end
    hold off;

    legend show;  %
    axis equal;  % 
end


% mROI coordinates are stored in CSV files
function saveTransformedCoordsToCSV(transformedCoords, regions)
    [filename, pathname] = uiputfile('*.csv', 'Save Transformed mROI Coordinates');
    if isequal(filename, 0)
        disp('CSV save has been canceled.');
        return;
    end

    coordsTable = table(regions, transformedCoords(:, 1), transformedCoords(:, 2), ...
        'VariableNames', {'Region', 'X', 'Y'});

    writetable(coordsTable, fullfile(pathname, filename));
    disp(['CSV is saved: ', fullfile(pathname, filename)]);
end
