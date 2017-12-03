function doReport(datFileName1, datFileName2, currentData1, currentData2, outputFormat)
% make a report on regression test for UniAir system

% datFileName1 --- INACA/Turbolab data of last release 
% datFileName2 --- INACA/Turbolab data of present release
% currentData1 --- Turbolab SV current data of last release
% currentData2 --- Turbolab SV current data of present release
% outputFormat --- test report format, e.g., 'doc', 'html', 'pdf', ...


% by Weigang (02.06.2013)
% wangwig@schaeffler.com

% add a path where many m-scripts reside
addpath('.\reportBib','-end')

% deal with default file names
if nargin < 1,
    datFileName1 = 'SVT_EVC_11p02build1.dat';
    datFileName2 = 'SVT_EVC_11p21build1.dat';
    currentData1 = 'AET9174000_10_500_xxx_580_mdf.dat';
    currentData2 = 'AET9174000_10_500_xxx_580_mdf.dat'; 
    outputFormat = 'doc';
elseif nargin < 3,
    currentData1 = '';
    currentData2 = '';
    outputFormat = 'doc';
elseif nargin < 4,
    currentData2 = currentData1;
    outputFormat = 'doc';
else
    fprintf('\nError: No file names specified and Ctrl+c to stop the session');
    pause;
end

assignin('base', 'fileNameDrivingSequence', 'datFileNameDrivingSequence.dat');

% send file names to base
assignin('base', 'fileNameLastRelease',    datFileName1);
assignin('base', 'fileNameCurrentRelease', datFileName2);
assignin('base', 'currentLastRelease',     currentData1);
assignin('base', 'currentCurrentRelease',  currentData2);
 
% build names and send to base
lastBuild    = datFileName1(max(myStrfind(datFileName1, '\'))+1:end-4);
currentBuild = datFileName2(max(myStrfind(datFileName2, '\'))+1:end-4);
assignin('base', 'lastBuild',    lastBuild);
assignin('base', 'currentBuild', currentBuild);

% make language to english
java.util.Locale.setDefault(java.util.Locale.ENGLISH)

% Generate report
report('ReportRegressionHIL', ['-f',outputFormat]);



