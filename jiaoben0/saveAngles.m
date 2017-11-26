function numOfEventSaved3 = saveAngles(folderNo, caseNo, filePathInput, angleFileName)
% save statistic results from seeCurrent in xls file

% if ~exist('numOfEventSaved1', 'var') || isempty(numOfEventSaved1),
%     numOfEventSaved1 = 13;
% end
% if ~exist('numOfEventSaved2', 'var') || isempty(numOfEventSaved2),
%     numOfEventSaved2 = 13;
% end

% get mean and std
% nCol: results of various methods; nRow: events

load([filePathInput, '\', angleFileName]);

% correct caseNo by extract the number from angleFileName

[nRow0, nCol0] = size(saveAFewVar);
[nRow,  nCol]  = size(saveAFewVar{nCol0});

numOfEventSaved3 = 0;

aNumber = '';
for i = 1:length(angleFileName)
    strTmp = str2num(angleFileName(i));
    if isreal(strTmp),
        aNumber = [aNumber, num2str(strTmp)];
    end
end
if ~isempty(str2num(aNumber))
    caseNo = str2num(aNumber);
end

numOfEventSaved3 = (caseNo-1)*4 + 1;

% [cylNo, eventCounter, nTmp] = size(angleFileName{4});

% for V-Shape
% for i = 1:cylNo
%     for j = 1:eventCounter
%         landmark{i,j,1} = angleFileName{4}{i,j,1};
%         landmark{i,j,2} = angleFileName{4}{i,j,2};
%     end
% end

dataFileName = saveAFewVar{1}{1,2};
rpm          = str2num(saveAFewVar{1}{7,2});
temp         = str2num(strrep(saveAFewVar{1}{1,1}, 'deg', ''));
modei        = saveAFewVar{1}{3,2};
SVSet        = {saveAFewVar{1}{2,1}, saveAFewVar{1}{3,1} saveAFewVar{1}{4,1} saveAFewVar{1}{5,1} };
voltage      = str2num(strrep(strrep(saveAFewVar{1}{4,2}, 'k','.'), 'V', ''));
peakCurrent  = str2num(strrep(strrep(saveAFewVar{1}{5,2}, 'k','.'), 'A', ''));
Phi1         = str2num(strrep(strrep(saveAFewVar{1}{4,2}, 'k','.'), 'V', ''));
Phi2         = str2num(strrep(strrep(saveAFewVar{1}{5,2}, 'k','.'), 'V', ''));
peakCurrent  = str2num(strrep(strrep(saveAFewVar{1}{6,2}, 'k','.'), 'A', ''));
 
% saveAFewVar{2}
%  1 [current(jPeakStart,i)
%  2 angleSVClose
%  3 angleMVOpen1
%  4 angleMVOpen2
%  5 angleMVClose1
%  6 angleMVClose2
%  7 mean(angleLiftMVMax)
%  8 AngleMax1stDeriv
%  9 angleSVBiasStart
% 10 angleSVPushStart
% 11 angleVShapeValley

% ttHL   = angleFileName{3}{3,2};
% angle1 = angleFileName{3}{4,2};
% angle2 = angleFileName{3}{5,2};
% ttHL   = 0;

var4Landmark = cell(1,1);
var4Case     = cell(1,1);

timei        = clock;

xlsFileName  = 'angleEvaluation';
countCatch   = 0;
item2Save    = cell(4,1);
try
    % ------------------ save V-Shape ------------------   
    item2Save = {};
    for i = 1:4
        item2Save = [item2Save; {numOfEventSaved3+i-1, caseNo, dataFileName, rpm, modei, temp, voltage, i, peakCurrent, ...
            saveAFewVar{2}{i,4}(2)-saveAFewVar{2}{i,4}(10), saveAFewVar{2}{i,4}(11)-saveAFewVar{2}{i,4}(10), saveAFewVar{2}{i,4}(3)-saveAFewVar{2}{i,4}(10), saveAFewVar{2}{i,4}(8)-saveAFewVar{2}{i,4}(10)}];
        %   closeAngle by accel                             closeAngle by V-Shape                            MV openAngle                                    tipAngle 1st Derivative 
    end
    
    xlswrite([xlsFileName, '.xls'], item2Save, 'angleTime',    ['B',num2str(numOfEventSaved3+4)]);
 
    fprintf('-- Angle info saved in %s.xls for case %i --\n', xlsFileName, caseNo);
catch ME1
    fprintf('-- Error: Angle info not saved and caused by file access error in %s.xls for case %i --\n', xlsFileName, caseNo);
end

end

