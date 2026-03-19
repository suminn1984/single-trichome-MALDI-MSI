% Step 1: Set the path to the folder containing the Java library files
% required for reading imzML data in MATLAB through jimzML.

libPath = 'C:\Users\nasum\Downloads\jimzMLConverter-2.1.1\lib';

% Step 2: Find all JAR files in the lib folder -> Java
% libraries needed for imzML parsing can be loaded into MATLAB.
jarFiles = dir(fullfile(libPath, '*.jar'));

% Step 3: Add each JAR file in the lib folder to the MATLAB Java path.
% These library files are required for initializing the jimzML-based
% parser and related Java classes.
for k = 1:length(jarFiles)
    javaaddpath(fullfile(libPath, jarFiles(k).name));
end

% Step 4: Add the main jimzMLConverter JAR file to the MATLAB Java path.

javaaddpath('C:\Users\nasum\Downloads\jimzMLConverter-2.1.1\jimzMLConverter-2.1.1.jar');

disp('All required JAR files have been loaded.');
