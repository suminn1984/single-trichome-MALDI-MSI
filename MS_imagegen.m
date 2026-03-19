%% Simple imzML Ion Image Viewer (sum intensities within tolerance)
% Generate an ion image from an imzML file by selecting a target m/z value
% and tolerance (mass window), summing all peak intensities within the tolerance window
% for each pixel, and displaying the resulting MS image.
clear; clc;

% Import the jimzML parser for imzML loading. 
import com.alanmrace.jimzmlparser.parser.ImzMLHandler;

%% Step 1: Select imzML file
[filename, pathname] = uigetfile({'*.imzML','imzML Files (*.imzML)'}, 'Select an imzML file');
if isequal(filename, 0)
    disp('imzML file selection cancelled.');
    return;
end
imzPath = fullfile(pathname, filename);

%% 2) Step 2: Load the selected imzML file using the jimzML parser
% it initialize the imzML object for extracting image dimensions
% and pixel-wise mass spectra in the following steps.
try
    imzML = ImzMLHandler.parseimzML(char(imzPath));
catch ME
    fprintf(2, 'Failed to load imzML: %s\n', ME.message);
    return;
end
disp('imzML loaded successfully.');

maxX = imzML.getWidth();
maxY = imzML.getHeight();
fprintf('Image size: %d (X) x %d (Y)\n', maxX, maxY);

%% 3) Input information for m/z + tolerance + (optional) clipping
% 1. specify the target m/z value to visualize, 
% 2. the tolerance window in absolute m/z units, and an optional maximum intensity for display clipping. 
% If a ppm-based tolerance is needed, it should be converted to an absolute m/z tolerance before input.
prompt = {
    'Enter target m/z (e.g., 585.4888):'
    'Enter tolerance in m/z units (e.g., 0.002):'
    'Clip max intensity? (e.g., 1000). Leave blank for no clip:'
};
dlgtitle = 'Ion Image Settings';
definput = {'585.4888','0.002','2000'};
answ = inputdlg(prompt, dlgtitle, [1 60], definput);

if isempty(answ)
    disp('Input cancelled.');
    return;
end

targetMz  = str2double(answ{1});
tolerance = str2double(answ{2});
clipMax   = str2double(answ{3});
if isnan(targetMz) || isnan(tolerance) || tolerance <= 0
    error('Invalid m/z or tolerance input.');
end
if isnan(clipMax)
    clipMax = []; % no clipping
end

%% 4) Generate the MS image 
% it scans each pixel spectrum in the imzML
% it identifies all peaks within the specified tolerance window
% around the target m/z, and summing their intensities to assign a single
% ion intensity value to each pixel. In this step, a relatively broad tolerance window is acceptable 
% because the ion image is used primarily as a visual background for
% alignment.


ionImage = zeros(maxY, maxX, 'double');
% Loop through all pixel in the imzML dataset (X, Y positions), sum the intensities
% of all peaks within the  tolerance.

for x = 1:maxX
    for y = 1:maxY
        spectrum = imzML.getSpectrum(x, y);
        if isempty(spectrum)
            continue;
        end

        mzArray  = spectrum.getmzArray();
        intArray = spectrum.getIntensityArray();

        % Sum all peaks within tolerance window
        idx = abs(mzArray - targetMz) <= tolerance;
        if any(idx)
            ionImage(y, x) = sum(double(intArray(idx)));
        end
    end
end

% Optional clipping (IF needed) 
if ~isempty(clipMax)
    ionImage(ionImage > clipMax) = clipMax;
end

%% 5) Display the generated ion image for visual inspection
% it show the summed MS image.
figure('Color','w');
imagesc([0.5, maxX+0.5], [0.5, maxY+0.5], ionImage);
axis image;
set(gca, 'YDir', 'reverse');
colormap('parula');
colorbar;

title(sprintf('Ion Image: m/z %.4f (± %.4f), summed', targetMz, tolerance), 'Interpreter','none');
xlabel('X (pixel)');
ylabel('Y (pixel)');