function laserAblationWithAdjustableRectangle()
% Load the post-MALDI optical image and the previously transformed mROI
% coordinates. 
% We define the laser-ablation area using an adjustable rectangle and apply a 
% projective transformation to crop the selected region, and
% retain only the mROI coordinates in the cropped analysis area. 
    clear; close all; clc;

    % Step 1: Load the post-MALDI optical image
    [laserFile, laserPath] = uigetfile({'*.png;*.jpg;*.tif;*.tiff'}, 'Upload post-MALDI-optical image.');
    if isequal(laserFile, 0)
        disp('Image selection has been canceled.');
        return;
    end
    laserImage = imread(fullfile(laserPath, laserFile));

    % Step 2: Load the mROI coordinates generated from the previous steps
    [coordFile, coordPath] = uigetfile('*.csv', 'mROI coordinates file upload.');
    if isequal(coordFile, 0)
        disp('CSV file selection has been canceled.');
        return;
    end
    roiData = readtable(fullfile(coordPath, coordFile));
    regions = roiData.Region;
    coords  = [roiData.X, roiData.Y];

    % Step 3: Laser ablation and mROI showing
    figure('Name', 'Laser Ablation and mROI');
    imshow(laserImage, 'InitialMagnification', 'fit');
    hold on;
    plotRegions(coords, regions); % plotting mROI on the post-MALDI-image

    % Step 4: Manually define the laser-ablation area by drawing an rectangular region (adjustable)
    % on the displayed post-MALDI optical image. We adjusted the position of the rectangle and resize it to match the visible
    % laser-ablation boundaries, and finalize the selection after adjustment.
    % The four corner points of the finalized rectangle are then used as the
    % reference coordinates for projective transformation of the image and mROI data.
    disp('Draw a rectangular region over the laser-ablation area.');
    rect = drawrectangle('Label', 'Adjust Me', 'Color', 'r');
    wait(rect); % wait until adjustment is done

    % Extract the four corner of the finalized rectangle in the
    % order of left upper, right upper, right bottom, and left bottom.
    rectPosition = rect.Position; % [x y w h]
    clickedPoints = [
        rectPosition(1),                 rectPosition(2);                  % left up
        rectPosition(1)+rectPosition(3), rectPosition(2);                  % right up
        rectPosition(1)+rectPosition(3), rectPosition(2)+rectPosition(4);  % right bottom
        rectPosition(1),                 rectPosition(2)+rectPosition(4)   % left bottom
    ];

    % % Define a fixed target coordinate system of 500 × 500 pixels to standardize
    targetWidth  = 500;
    targetHeight = 500;
    targetPoints = [0, 0; targetWidth, 0; targetWidth, targetHeight; 0, targetHeight];

    % Perspective transformation
    tform = fitgeotrans(clickedPoints, targetPoints, 'projective');

    % Step 5: Apply the projective transformation to the post-MALDI optical image
    % and the imported mROI coordinates.
    % The defined laser-ablation region is mapped onto the fixed target
    % coordinate system (500 × 500).

    transformedImage  = imwarp(laserImage, tform, 'OutputView', imref2d([targetHeight, targetWidth]));
    transformedCoords = transformPointsForward(tform, coords);

    % We can decide whether ROI coordinates located on the rectangle boundary are
    % included or excluded when filtering points the laser-ablation area.
    includeBorder = true;  % true: boundary include, false: exclude boundary
    tol = 1e-6;
    x = transformedCoords(:,1);
    y = transformedCoords(:,2);
    if includeBorder
        inRectIdx = (x >= 0 & x <= targetWidth  & y >= 0 & y <= targetHeight);
    else
        inRectIdx = (x >  0+tol & x <  targetWidth-tol & y >  0+tol & y <  targetHeight-tol);
    end

    % % Filter the transformed mROI coordinates and retain only the points
    % located within the user-defined laser-ablation region.
    filteredCoords  = transformedCoords(inRectIdx, :);
    filteredRegions = regions(inRectIdx);

    % Step 6: Display the transformed image together with the filtered mROI
    % coordinates - For visual inspection. 
    figure('Name', 'Transformed Image and mROI'); % Loading the image
    imshow(transformedImage, 'InitialMagnification', 'fit');
    hold on;
    plotRegions(filteredCoords, filteredRegions); % transformed mROI visualize
    hold off;

    % Step 7: Save the transformed image and the filtered mROI coordinates
    % generated from the selected laser-ablation region. The saved image serves
    % as the aligned reference image for the next step.
    uicontrol('Style', 'pushbutton', 'String', 'Save mROI and Images', ...
              'Position', [350, 20, 160, 40], 'Callback', @(~, ~) ...
              saveTransformedData(transformedImage, filteredCoords, filteredRegions, targetHeight, targetWidth));

    disp('conversion is completed');
end

% Visualize the mROI coordinates as cyan polygon shapes.
% Connect the coordinates of each segmented trichome in sequence
function plotRegions(coords, regions)
    cyan = [0 1 1];
    uR = unique(regions, 'stable');
    hold on;
    for i = 1:numel(uR)
        idx = regions == uR(i);
        pts = coords(idx, :);
        if isempty(pts), continue; end

        if size(pts,1) >= 3
            pts = [pts; pts(1,:)];   % 
        end
        plot(pts(:,1), pts(:,2), '-', 'Color', cyan, 'LineWidth', 2);
        plot(pts(:,1), pts(:,2), '.', 'Color', cyan, 'MarkerSize', 6);
    end
    axis image off;
end

% saving image and coordinates for the next step. 
function saveTransformedData(image, coords, regions, imgHeight, imgWidth)
    [filename, pathname] = uiputfile('*.csv', 'Save Transformed mROI Coordinates');
    if isequal(filename, 0)
        disp('CSV file save has been canceled.');
        return;
    end

    coordsTable = table(regions, coords(:, 1), coords(:, 2), ...
                        repmat(imgHeight, size(coords, 1), 1), ...
                        repmat(imgWidth,  size(coords, 1), 1), ...
                        'VariableNames', {'Region', 'X', 'Y', 'ImageHeight', 'ImageWidth'});

    writetable(coordsTable, fullfile(pathname, filename));
    disp(['CSV file has been saved: ', fullfile(pathname, filename)]);

    [imgFile, imgPath] = uiputfile({'*.png;*.jpg;*.tif'}, 'Save Transformed Image');
    if isequal(imgFile, 0)
        disp('Saving image has been canceled.');
        return;
    end
    imwrite(image, fullfile(imgPath, imgFile));
    disp(['Image has been saved: ', fullfile(imgPath, imgFile)]);
end
