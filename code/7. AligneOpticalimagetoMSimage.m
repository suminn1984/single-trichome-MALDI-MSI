% Align the post-MALDI optical image to the MS image 
% a resizable semi-transparent optical image overlay
% The aligned rectangle is then used to transform the mROI coordinates into the MS image

% % Define a larger background canvas for displaying the ion image during
% manual optical-to-MS image alignment.
backgroundScale = 1.5; 
backgroundHeight = ceil(maxY * backgroundScale);
backgroundWidth = ceil(maxX * backgroundScale);

background = zeros(backgroundHeight, backgroundWidth);

% Place the ion image onto the background canvas using the specified X and Y offsets
ionOffsetX = 30;
ionOffsetY = 30;
background(ionOffsetY + (1:maxY), ionOffsetX + (1:maxX)) = ionImage;

% 2. Load the cropped optical image (post-MALDI optical image)
[opticalFile, opticalPath] = uigetfile({'*.png;*.jpg;*.tif;*.tiff'}, 'Select an Optical Image');
if isequal(opticalFile, 0)
    disp('Optical selection canceled.');
    return;
end
opticalImage = imread(fullfile(opticalPath, opticalFile));  
disp('Optical uploaded.');

% Resize the optical image to the MS image dimensions
% images share the same scale for manual alignment.
resizedOpticalImage = imresize(opticalImage, [maxY, maxX]);  
% % Display the background MS image for manual alignment
figure;
imshow(background, []);
hold on;

% Overlay the resized optical image (transparent) on the background MS image
% We controlled the degree of transparency of the optical image
hOptical = imshow(resizedOpticalImage);
set(hOptical, 'AlphaData', 0.3); 

% Create an adjustable rectangle whose aspect ratio is fixed 
% The optical image can be resized without distortion during manual alignment 
aspectRatio = size(resizedOpticalImage, 2) / size(resizedOpticalImage, 1);  
initWidth = 100;  
initHeight = initWidth / aspectRatio;  

hRect = imrect(gca, [50, 50, initWidth, initHeight]);  
setPositionConstraintFcn(hRect, @(pos) fixedAspectRatio(pos, aspectRatio)); 

% Update the optical image overlay whenever the alignment rectangle is moved
% or resized while preserving the original aspect ratio
addNewPositionCallback(hRect, @(pos) updateOpticalImageInRect(hOptical, resizedOpticalImage, pos, aspectRatio));


% Complete button added
uicontrol('Style', 'pushbutton', 'String', 'Complete', ...
          'Position', [20, 100, 200, 30], ...
          'Callback', @(~, ~) loadMROIToRect(hRect, maxX, maxY, ionOffsetX, ionOffsetY));

disp('resize the rectengle and push "Complete" button, then load the mROI file.');

% Local function: update the optical image overlay during manual alignment
% resize and reposition the optical image overlay
% according to the changing alignment rectangle while preserving the aspect ratio
function updateOpticalImageInRect(hImage, originalImage, pos, aspectRatio)
    width = pos(3);
    height = width / aspectRatio;
    resizedImage = imresize(originalImage, [round(height), round(width)]);
    
    
    set(hImage, 'CData', resizedImage, ...
                'XData', [pos(1), pos(1) + width], ...
                'YData', [pos(2), pos(2) + height]);
end

% Local function: constrain the alignment rectangle to preserve the original aspect ratio of the optical image during manual resizing
function constrainedPos = fixedAspectRatio(pos, aspectRatio)
    width = pos(3);
    height = width / aspectRatio;
    constrainedPos = [pos(1), pos(2), width, height];
end

% It loads the transformed mROI coordinate file, rescale the
% coordinates from the standardized 500 × 500 size to the
% current MS image area, and map them into the manually aligned
% rectangle on the MS image. 
% The transformed coordinates are visualized
function loadMROIToRect(hRect, maxX, maxY, ionOffsetX, ionOffsetY)
    [csvFile, csvPath] = uigetfile('*.csv', 'Select an mROI CSV file');
    if isequal(csvFile, 0)
        disp('CSV file selection canceled.');
        return;
    end

    
    mroiData = readtable(fullfile(csvPath, csvFile));
    xCoords = mroiData.X;  
    yCoords = mroiData.Y;  
    regions = mroiData.Region;  

    
    scaledX = (xCoords / 500) * maxX;  
    scaledY = (yCoords / 500) * maxY;  

   
    %
    pos = getPosition(hRect);  
    rectX = pos(1);  
    rectY = pos(2);  
    rectWidth = pos(3);  
    rectHeight = pos(4);  

    
    normalizedX = (scaledX / maxX) * rectWidth; 
    normalizedY = (scaledY / maxY) * rectHeight; 
    transformedX = normalizedX + rectX;  
    transformedY = normalizedY + rectY;

    
    transformedCoords = [transformedX, transformedY];

    
    hold on;
    uniqueRegions = unique(regions);  
    for i = 1:length(uniqueRegions)
        regionIdx = regions == uniqueRegions(i);  
        regionCoords = transformedCoords(regionIdx, :);  

        
        closedRegionCoords = [regionCoords; regionCoords(1, :)];

        
        plot(closedRegionCoords(:, 1), closedRegionCoords(:, 2), '-', ...
             'Color', [0 1 1], ...   % Cyan
             'LineWidth', 0.7);      
    end
    legend show;  

    disp('mROI is visualized in the selected region.');

    
    saveCoordinatesAll(transformedX, transformedY, regions, mroiData, rectWidth, rectHeight, ionOffsetX, ionOffsetY);
end
% 1. Rescale the imported mROI coordinates from the 500 × 500 area
% 2. to the current MS image dimensions, plot them into the aligned rectangle,
% 3. visualize the transformed ROIs.

    


% Save the final aligned mROI coordinates to CSV file. 
% Correct the transformed coordinates by subtracting the ion-image offset,
% update the original mROI table with the final X and Y values, add the
% aligned image width and height information, and export the resulting
% coordinate table as a CSV file for downstream analysis.
function saveCoordinatesAll(transformedX, transformedY, regions, mroiData, rectWidth, rectHeight, ionOffsetX, ionOffsetY)
    % Ion Image coordinates are corrected
    transformedX = transformedX - ionOffsetX;
    transformedY = transformedY - ionOffsetY;
    % mroiData is updated
    mroiData.X = transformedX;
    mroiData.Y = transformedY;

    mroiData.Image_Width = repmat(rectWidth, height(mroiData), 1); 
    mroiData.Image_Height = repmat(rectHeight, height(mroiData), 1);  

   
    [file, path] = uiputfile('*.csv', 'Save Aligned Coordinates');
    if isequal(file, 0)
        disp('Saving mROI has been canceled.');
        return;
    end

    % save the mroiData
    writetable(mroiData, fullfile(path, file));
    disp(['Aligned mROI data saved: ', fullfile(path, file)]);
end
