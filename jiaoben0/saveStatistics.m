function [numOfEventSaved3 numOfEventSaved4] = saveStatistics(folderNo, caseNo, filePathInput, statistcFileName, numOfEventSaved1, numOfEventSaved2)
% save statistic results from seeCurrent in xls file

% if ~exist('numOfEventSaved1', 'var') || isempty(numOfEventSaved1),
%     numOfEventSaved1 = 13;
% end
% if ~exist('numOfEventSaved2', 'var') || isempty(numOfEventSaved2),
%     numOfEventSaved2 = 13;
% end

% get mean and std
% nCol: results of various methods; nRow: events

load([filePathInput, '\', statistcFileName]);

% correct caseNo by extract the number from statistcFileName

[nRow, nCol] = size(statisticResult);
aNumber = '';
for i = 1:length(statistcFileName)
    strTmp = str2num(statistcFileName(i));
    if isreal(strTmp),
        aNumber = [aNumber, num2str(strTmp)];
    end
end
if ~isempty(str2num(aNumber))
    caseNo = str2num(aNumber);
end

[cylNo, eventCounter, nTmp] = size(statisticResult{4});

landmark = cell(1,1);

% for V-Shape
for i = 1:cylNo
    for j = 1:eventCounter
        landmark{i,j,1} = statisticResult{4}{i,j,1};
        landmark{i,j,2} = statisticResult{4}{i,j,2};
    end
end

rpm         = NaN;
temp        = NaN;
ttHL        = NaN;
valveMode   = NaN;
angle1      = NaN;
angle2      = NaN;
peakCurrent = NaN;
voltage     = NaN;

[numOfRow numOfCol] = size(statisticResult{3});
temp              = statisticResult{3}{1,1};
peakCurrent       = theParIsA('current', statisticResult{3}(3:end,2), peakCurrent);
voltage           = theParIsA('voltage', statisticResult{3}(3:end,2), voltage);
rpm               = theParIsA('rpm',     statisticResult{3}(3:end,2), rpm);
[ttHL posCell0]   = theParIsA('ttHL',    statisticResult{3}(3:end,2), ttHL);
if isnan(ttHL),
    valveMode = theParIsA('mode',    statisticResult{3}(3:end,2), valveMode);
    ttHL      = valveMode;
end
[angle1 posCell1] = theParIsA('angle',    statisticResult{3}(3:end,2), angle1, [posCell0]);
[angle2 posCell2] = theParIsA('angle',    statisticResult{3}(3:end,2), angle2, [posCell0 posCell1]);

if ~isnan(voltage),
    angle2 = voltage;
end

% if numOfRow == 7,   % AET9021000_10_LVO_370_620_09k0A
%     [angle1 posCell2] = theParIsA('angle',    statisticResult{3}(3:end,2), angle1, [posCell1]);
% 
%     %     % peakCurrent = getANumberFrom(statisticResult{3}{6,2}, 'k', 'A');
% %     if peakCurrent > 20,
% %         peakCurrent = getANumberFrom(statisticResult{3}{5,2}, 'k', 'A');
% %     end
% %     temp   = statisticResult{3}{1,1};
% %     ttHL   = statisticResult{3}{3,2};  % mode or ttHL
% %     angle1 = statisticResult{3}{4,2};  % phi1 or voltage
% %     if ~isnumeric(angle1),
% %         angle2 = getANumberFrom(statisticResult{3}{5,2}, 'k', 'V');
% %     end
% %     angle2 = statisticResult{3}{5,2};  % phi2
% %     if ~isnumeric(angle2),
% %         angle2 = getANumberFrom(statisticResult{3}{5,2}, 'k', 'V');
% %     rpm    = statisticResult{3}{7,2};
% %    
% %     if isempty(rpm),
% %         rpm = statisticResult{3}{6,2};
% %     end
%     aaa=0;
%     % AET8621000_10_LVO_11k0V_09k0A_mdf_Current
%     % voltage     = statisticResult{3}{4,2};
%     % peakCurrent = statisticResult{3}{5,2};
%     % rpm         = statisticResult{3}{6,2};   
% elseif numOfRow == 6, 
%     % AET9270700_10_500_314_LVO
%     % AET8731000_10_LVO_11k0V_09k0A
%     temp   = statisticResult{3}{1,1};
%     ttHL   = statisticResult{3}{3,2};
%     voltage = statisticResult{3}{4,2};
%     peakCurrent = getANumberFrom(statisticResult{3}{5,2}, 'k', 'A');
%     rpm    = statisticResult{3}{6,2};
%     angle1 = voltage;
%     angle2 = '0';
%     aaa=0;
% elseif numOfRow == 9,
%     temp   = statisticResult{3}{1,1};
%     ttHL   = statisticResult{3}{3,2};
%     angle1 = statisticResult{3}{4,2};
%     angle2 = statisticResult{3}{5,2};
%     peakCurrent = 0;
%     voltage     = 0;
%     rpm         = statisticResult{3}{9,2};
%     aaa=0;    
% end

[numOfCyl, numOfEvent] = size(statisticResult{5});

% ttHL   = 0;

var4Landmark = cell(1,1);
var4Case     = cell(1,1);

timei        = clock;


xlsFileNameMat  = '';
caseDescription = cell(4,1);
caseDescription(1,1:3) = [num2str(folderNo), 'Case Description for ', statisticResult{3}(1,2)];
caseDescription(2,1:2) = [statisticResult{3}(1,1), statisticResult{3}(6,1)];
caseDescription(3,1:numOfRow-1) = statisticResult{3}(2:numOfRow,2)';
caseDescription(4,1:4) = statisticResult{3}(2:5,1);
% caseDescription(5,1) = [statisticResult{3}(5,1)]; in for here is really event by event

xlsFileName  = 'evaluation';
txtFileName  = 'evaluation';
countCatch   = 0;
item2Save    = cell(1,1);

saveXSLfile = 0;
if saveXSLfile == 0,
    fidV    = fopen([txtFileName,'_landmarkV',       '.txt'], 'a');
    fidVSTD = fopen([txtFileName,'_landmarkVSTD',    '.txt'], 'a');
%     fidTail    = fopen([txtFileName,'_landmarkTail',    '.txt'], 'wt');
%     fidTailSTD = fopen([txtFileName,'_landmarkTailSTD', '.txt'], 'wt');
end
try
    if saveXSLfile,
        % ------------------ save V-Shape ------------------
        % collect landmark and save their mean
        xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkV',    ['AT',num2str(numOfEventSaved1+1)]);
        xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkV', ['B',num2str(numOfEventSaved1+1)]);
        item2Save = [[1 myMean4Cell(landmark,1,1,1,2)]; [2 myMean4Cell(landmark,2,1,1,2)]; [3 myMean4Cell(landmark,3,1,1,2)]; [4 myMean4Cell(landmark,4,1,1,2)]];
        xlswrite([xlsFileName, '.xls'], item2Save, 'landmarkV',    ['I',num2str(numOfEventSaved1+1)]);
        
        
        xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkVSTD', ['AT',num2str(numOfEventSaved1+1)]);
        xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkVSTD', ['B',num2str(numOfEventSaved1+1)]);
        item2Save = [[1 myStd4Cell(landmark,1,1,1,2)]; [2 myStd4Cell(landmark,2,1,1,2)]; [3 myStd4Cell(landmark,3,1,1,2)]; [4 myStd4Cell(landmark,4,1,1,2)]];
        xlswrite([xlsFileName, '.xls'], item2Save,  'landmarkVSTD', ['I',num2str(numOfEventSaved1+1)]);
        
        % ----------------- save angle info ------------------
        % collect angles ans save
        xlswrite([xlsFileName, '.xls'], caseDescription,          'angleInfo',    ['AE',num2str(numOfEventSaved2+1)]);
        
        [numOfCyl, numOfEvent] = size(statisticResult{5});
        aaa=0;
        
        item2Save = {}; % {caseNo, rpm, temp, modei, angle1, angle2, ttHL, 1, flatIt({statisticResult{5}{:,1}})};
        for i = 1:numOfEvent
            item2Save{i} = flatIt({statisticResult{5}{:,i}});
        end
        
        item2Save1 = cell(numOfEvent, 28);
        item2Save  = [item2Save{:}];
        if length(item2Save) == 20*numOfEvent,
            item2Save             = reshape(item2Save, 20, numOfEvent)';  % 20 (=5*4)columns
            item2Save1(:,9:28)    = item2Save;
        elseif length(item2Save) == 15*numOfEvent,
            item2Save             = reshape(item2Save, 15, numOfEvent)';
            item2Save1(:,9:28-5)  = item2Save;
        elseif length(item2Save) == 10*numOfEvent,
            item2Save             = reshape(item2Save, 10, numOfEvent)';
            item2Save1(:,9:28-10) = item2Save;
        elseif length(item2Save) == 5*numOfEvent,
            item2Save             = reshape(item2Save, 5, numOfEvent)';
            item2Save1(:,9:28-15) = item2Save;
        else
            disp('Warning: pause for wrong data');
            aaa=0;
        end
        
    else % save in txt file
        % ------------------ save V-Shape ------------------
        % collect landmark and save their mean
        % rrr = myCell2Mat((caseDescription(1,:)));
        if caseNo == 34,
            aaa = 0;
        end
        % row for cylinder 1
        fprintf(fidV, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '1'};
        fprintf(fidV, '%s; ', item2Save{1,:});
        item2Save = myMean4Cell(landmark,1,1,1,2); 
        fprintf(fidV, '%d; ', item2Save);
        fprintf(fidV, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{1,:});
        fprintf(fidV, '\n');
        % row for cylinder 2
        fprintf(fidV, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '2'};
        fprintf(fidV, '%s; ', item2Save{1,:});
        item2Save = myMean4Cell(landmark,2,1,1,2); 
        fprintf(fidV, '%d; ', item2Save);
        fprintf(fidV, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{2,:});
        fprintf(fidV, '\n');
        % row for cylinder 3
        fprintf(fidV, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '3'};
        fprintf(fidV, '%s; ', item2Save{1,:});
        item2Save = myMean4Cell(landmark,3,1,1,2); 
        fprintf(fidV, '%d; ', item2Save);
        fprintf(fidV, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{3,:});
        fprintf(fidV, '\n');
        % row for cylinder 4
        fprintf(fidV, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '4'};
        fprintf(fidV, '%s; ', item2Save{1,:});
        item2Save = myMean4Cell(landmark,4,1,1,2); 
        fprintf(fidV, '%d; ', item2Save);
        fprintf(fidV, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{4,:});
        fprintf(fidV, '\n');
        
        % fprintf(fidV, '%s; ', {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent});
        
        % xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkV',    ['AT',num2str(numOfEventSaved1+1)]);
%         xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkV', ['B',num2str(numOfEventSaved1+1)]);
%         item2Save = [[1 myMean4Cell(landmark,1,1,1,2)]; [2 myMean4Cell(landmark,2,1,1,2)]; [3 myMean4Cell(landmark,3,1,1,2)]; [4 myMean4Cell(landmark,4,1,1,2)]];
%         xlswrite([xlsFileName, '.xls'], item2Save, 'landmarkV',    ['I',num2str(numOfEventSaved1+1)]);
        
        % for std info
        % row for cylinder 1
        fprintf(fidVSTD, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '1'};
        fprintf(fidVSTD, '%s; ', item2Save{1,:});
        item2Save = myStd4Cell(landmark,1,1,1,2); 
        fprintf(fidVSTD, '%d; ', item2Save);
        fprintf(fidVSTD, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{1,:});
        fprintf(fidVSTD, '\n');
        % row for cylinder 2
        fprintf(fidVSTD, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '2'};
        fprintf(fidVSTD, '%s; ', item2Save{1,:});
        item2Save = myStd4Cell(landmark,2,1,1,2); 
        fprintf(fidVSTD, '%d; ', item2Save);
        fprintf(fidVSTD, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{2,:});
        fprintf(fidVSTD, '\n');
        % row for cylinder 3
        fprintf(fidVSTD, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '3'};
        fprintf(fidVSTD, '%s; ', item2Save{1,:});
        item2Save = myStd4Cell(landmark,3,1,1,2); 
        fprintf(fidVSTD, '%d; ', item2Save);
        fprintf(fidVSTD, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{3,:});
        fprintf(fidVSTD, '\n');
        % row for cylinder 4
        fprintf(fidVSTD, ' ;');
        item2Save = {num2str(caseNo), num2str(rpm), num2str(temp), num2str(ttHL), num2str(angle1), num2str(angle2), num2str(peakCurrent), '4'};
        fprintf(fidVSTD, '%s; ', item2Save{1,:});
        item2Save = myStd4Cell(landmark,4,1,1,2); 
        fprintf(fidVSTD, '%d; ', item2Save);
        fprintf(fidVSTD, ' ; %s; %s; %s; %s; %s; %s; %s; %s;',caseDescription{4,:});
        fprintf(fidVSTD, '\n');

%         xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkVSTD', ['AT',num2str(numOfEventSaved1+1)]);
%         xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkVSTD', ['B',num2str(numOfEventSaved1+1)]);
%         item2Save = [[1 myStd4Cell(landmark,1,1,1,2)]; [2 myStd4Cell(landmark,2,1,1,2)]; [3 myStd4Cell(landmark,3,1,1,2)]; [4 myStd4Cell(landmark,4,1,1,2)]];
%         xlswrite([xlsFileName, '.xls'], item2Save,  'landmarkVSTD', ['I',num2str(numOfEventSaved1+1)]);
        
        % ----------------- save angle info ------------------
        % collect angles ans save
        if 0,
            xlswrite([xlsFileName, '.xls'], caseDescription,          'angleInfo',    ['AE',num2str(numOfEventSaved2+1)]);
            
            [numOfCyl, numOfEvent] = size(statisticResult{5});
            aaa=0;
            
            item2Save = {}; % {caseNo, rpm, temp, modei, angle1, angle2, ttHL, 1, flatIt({statisticResult{5}{:,1}})};
            for i = 1:numOfEvent
                item2Save{i} = flatIt({statisticResult{5}{:,i}});
            end
            
            item2Save1 = cell(numOfEvent, 28);
            item2Save  = [item2Save{:}];
            if length(item2Save) == 20*numOfEvent,
                item2Save             = reshape(item2Save, 20, numOfEvent)';  % 20 (=5*4)columns
                item2Save1(:,9:28)    = item2Save;
            elseif length(item2Save) == 15*numOfEvent,
                item2Save             = reshape(item2Save, 15, numOfEvent)';
                item2Save1(:,9:28-5)  = item2Save;
            elseif length(item2Save) == 10*numOfEvent,
                item2Save             = reshape(item2Save, 10, numOfEvent)';
                item2Save1(:,9:28-10) = item2Save;
            elseif length(item2Save) == 5*numOfEvent,
                item2Save             = reshape(item2Save, 5, numOfEvent)';
                item2Save1(:,9:28-15) = item2Save;
            else
                disp('Warning: pause for wrong data');
                aaa=0;
            end
        end
    end
    
     if 0,
         for i = 1:numOfEvent
             item2Save1(i,1:8) = {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent, 1};
             %         for j = 9:28
             %             item2Save{i,j} = item2Save{i,j-8};
             %         end
             %         item2Save{i,1} = caseNo;
             %         item2Save{i,2} = rpm;
             %         item2Save{i,3} = temp;
             %         item2Save{i,4} = ttHL;
             %         item2Save{i,5} = angle1;
             %         item2Save{i,6} = angle2;
             %         item2Save{i,7} = peakCurrent;
             %         item2Save{i,8} = i;
         end
         
         
         xlswrite([xlsFileName, '.xls'], item2Save1,  'angleInfo', ['B',num2str(numOfEventSaved2+1)]);
        
        % ------------------ save Tail info ------------------
        % collect landmark and save their mean
        xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkTail',    ['AT',num2str(numOfEventSaved1+1)]);
        xlswrite([xlsFileName, '.xls'], {filePathInput},          'landmarkTail',    ['AY',num2str(numOfEventSaved1+1)]);
        xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkTail', ['B',num2str(numOfEventSaved1+1)]);
        item2Save = [[1 myMean4Cell(landmark,1,1,2,2)]; [2 myMean4Cell(landmark,2,1,2,2)]; [3 myMean4Cell(landmark,3,1,2,2)]; [4 myMean4Cell(landmark,4,1,2,2)]];
        xlswrite([xlsFileName, '.xls'], item2Save, 'landmarkTail',    ['I',num2str(numOfEventSaved1+1)]);
        
        xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkTailSTD', ['AT',num2str(numOfEventSaved1+1)]);
        xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkTailSTD', ['B',num2str(numOfEventSaved1+1)]);
        item2Save = [[1 myStd4Cell(landmark,1,1,2,2)]; [2 myStd4Cell(landmark,2,1,2,2)]; [3 myStd4Cell(landmark,3,1,2,2)]; [4 myStd4Cell(landmark,4,1,2,2)]];
        xlswrite([xlsFileName, '.xls'], item2Save,  'landmarkTailSTD', ['I',num2str(numOfEventSaved1+1)]);
        
        fprintf('-- Statistics saved in %s.xls for case %i --\n', xlsFileName, caseNo);
    end
catch ME1
    % Get last segment of the error message identifier.
    idSegLast = regexp(ME1.identifier, '(?<=:)\w+$', 'match');
    countCatch = countCatch + 1;
    if  strcmp(idSegLast, 'LockedFile') && countCatch < 5,
        xlsFileName = [xlsFileName, num2str(countCatch)];
        
        % ------------------------ same as first try ------------------------
        try
            % ------------------ save V-Shape ------------------
            % collect landmark and save their mean
            xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkV',    ['AT',num2str(numOfEventSaved1+1)]);
            xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkV', ['B',num2str(numOfEventSaved1+1)]);
            item2Save = [[1 myMean4Cell(landmark,1,1,1,2)]; [2 myMean4Cell(landmark,2,1,1,2)]; [3 myMean4Cell(landmark,3,1,1,2)]; [4 myMean4Cell(landmark,4,1,1,2)]];
            xlswrite([xlsFileName, '.xls'], item2Save, 'landmarkV',    ['I',num2str(numOfEventSaved1+1)]);
            
            xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkVSTD', ['AT',num2str(numOfEventSaved1+1)]);
            xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkVSTD', ['B',num2str(numOfEventSaved1+1)]);
            item2Save = [[1 myStd4Cell(landmark,1,1,1,2)]; [2 myStd4Cell(landmark,2,1,1,2)]; [3 myStd4Cell(landmark,3,1,1,2)]; [4 myStd4Cell(landmark,4,1,1,2)]];
            xlswrite([xlsFileName, '.xls'], item2Save,  'landmarkVSTD', ['I',num2str(numOfEventSaved1+1)]);
            
            % ----------------- save angle info ------------------
            % collect angles ans save
            xlswrite([xlsFileName, '.xls'], caseDescription,          'angleInfo',    ['AE',num2str(numOfEventSaved2+1)]);
            
            [numOfCyl, numOfEvent] = size(statisticResult{5});
            aaa=0;
            
            item2Save = {}; % {caseNo, rpm, temp, modei, angle1, angle2, ttHL, 1, flatIt({statisticResult{5}{:,1}})};
            for i = 1:numOfEvent
                item2Save{i} = flatIt({statisticResult{5}{:,i}});
            end
            
            item2Save1 = cell(numOfEvent, 28);
            item2Save  = [item2Save{:}];
            if length(item2Save) == 20*numOfEvent,
                item2Save             = reshape(item2Save, 20, numOfEvent)';  % 20 (=5*4)columns
                item2Save1(:,9:28)    = item2Save;
            elseif length(item2Save) == 15*numOfEvent,
                item2Save             = reshape(item2Save, 15, numOfEvent)';
                item2Save1(:,9:28-5)  = item2Save;
            elseif length(item2Save) == 10*numOfEvent,
                item2Save             = reshape(item2Save, 10, numOfEvent)';
                item2Save1(:,9:28-10) = item2Save;
            elseif length(item2Save) == 5*numOfEvent,
                item2Save             = reshape(item2Save, 5, numOfEvent)';
                item2Save1(:,9:28-15) = item2Save;
            else
                disp('Warning: pause for wrong data');
                aaa=0;
            end
            
            % item2Save = cell(numOfEvent,28);
            % item2Save  = reshape(item2Save, 20, numOfEvent)';  % 20 (=5*4)columns
            % item2Save1 = cell(numOfEvent, 28);
            
            % item2Save1(:,9:28) = item2Save;
            
            for i = 1:numOfEvent
                item2Save1(i,1:8) = {caseNo, rpm, temp, ttHL, angle1, angle2, 0, 1};
                %         for j = 9:28
                %             item2Save{i,j} = item2Save{i,j-8};
                %         end
                %         item2Save{i,1} = caseNo;
                %         item2Save{i,2} = rpm;
                %         item2Save{i,3} = temp;
                %         item2Save{i,4} = ttHL;
                %         item2Save{i,5} = angle1;
                %         item2Save{i,6} = angle2;
                %         item2Save{i,7} = 0;
                %         item2Save{i,8} = i;
            end
            
            
            xlswrite([xlsFileName, '.xls'], item2Save1,  'angleInfo', ['B',num2str(numOfEventSaved2+1)]);
            
            % ------------------ save Tail info ------------------
            % collect landmark and save their mean
            xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkTail',    ['AT',num2str(numOfEventSaved1+1)]);
            xlswrite([xlsFileName, '.xls'], {filePathInput},          'landmarkTail',    ['AY',num2str(numOfEventSaved1+1)]);
            xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkTail', ['B',num2str(numOfEventSaved1+1)]);
            item2Save = [[1 myMean4Cell(landmark,1,1,2,2)]; [2 myMean4Cell(landmark,2,1,2,2)]; [3 myMean4Cell(landmark,3,1,2,2)]; [4 myMean4Cell(landmark,4,1,2,2)]];
            xlswrite([xlsFileName, '.xls'], item2Save, 'landmarkTail',    ['I',num2str(numOfEventSaved1+1)]);
            
            xlswrite([xlsFileName, '.xls'], caseDescription,          'landmarkTailSTD', ['AT',num2str(numOfEventSaved1+1)]);
            xlswrite([xlsFileName, '.xls'], {caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent; caseNo, rpm, temp, ttHL, angle1, angle2, peakCurrent},  'landmarkTailSTD', ['B',num2str(numOfEventSaved1+1)]);
            item2Save = [[1 myStd4Cell(landmark,1,1,2,2)]; [2 myStd4Cell(landmark,2,1,2,2)]; [3 myStd4Cell(landmark,3,1,2,2)]; [4 myStd4Cell(landmark,4,1,2,2)]];
            xlswrite([xlsFileName, '.xls'], item2Save,  'landmarkTailSTD', ['I',num2str(numOfEventSaved1+1)]);
            
            % ------------------------ end of same try as the first one ------------------------
            fprintf('-- Statistics retried and saved in %s.xls for case %i --\n', xlsFileName, caseNo);
        catch ME2
            rethrow(ME1);
        end
    else
        rethrow(ME1);
    end
end
numOfEventSaved3 = numOfEventSaved1 + 4;
numOfEventSaved4 = numOfEventSaved2 + numOfEvent;

if saveXSLfile == 0,
    fclose(fidV);
    fclose(fidVSTD);
end
aaa=0;
end

function flatedMat = myCell2Mat(y)
% convert a row of cell of mixed to a string mat
numOfCol = length(y);
flatedMat = '';
for i = 1:numOfCol
    flatedMat = [flatedMat, y{i}];
end
aaa=0;
end

function [theVal posCelli] = theParIsA(indicator, aStringCell, theVal, posCell)
% get a parameter from

if nargin < 4,
    posCell = 111111;
end
posCelli = 0;
if isnan(theVal) || isempty(theVal),
    [numOfRow numOfCol] = size(aStringCell);
    if strcmpi(indicator, 'current'),
        for i = 1:numOfRow
            aString = aStringCell{i};
            kPos    = regexpi(aString, '[0-9]k[0-9]'); % '(?<=[0-9])k(?=[0-9])');
            APos    = regexpi(aString, 'A$');
            
            if ~isempty(kPos) && ~isempty(APos),
                theVal  = str2double([aString(1:kPos), '.', aString(kPos+2:end-1)]);
                posCelli = i;
                break;
            end
        end
    elseif strcmpi(indicator, 'voltage'),
        for i = 1:numOfRow
            aString = aStringCell{i};
            kPos    = regexpi(aString, '[0-9]k[0-9]'); % '(?<=[0-9])k(?=[0-9])');
            VPos    = regexpi(aString, 'V$');
            
            if ~isempty(kPos) && ~isempty(VPos),
                theVal  = str2double([aString(1:kPos), '.', aString(kPos+2:end-1)]);
                posCelli = i;
                break;
            end
        end
    elseif strcmpi(indicator, 'mode'),
        for i = 1:numOfRow
            aString = aStringCell{i};
            mPos    = regexpi(aString, '(LVO|EVC|ML|HB|MLHB|FL|FLRC)');
            if ~isempty(mPos),
                theVal   = aString;
                posCelli = i;
                break;
            end
        end
    elseif strcmpi(indicator, 'numeric'), % get the first nemric
        for i = 1:numOfRow
            aString = aStringCell{i};
            aNumber = str2double(aString);
            if ~isnan(aNumber),
                theVal   = aNumber;
                posCelli = i;
                break;
            end
        end
    elseif strcmpi(indicator, 'ttHL'),
        for i = 1:numOfRow
            aString = aStringCell{i};
            aNumber = str2double(aString);
            if ~isnan(aNumber),
                if length(aString)==3 && mod(aNumber,100)==0,  % ttHL 500, 600, ... only 3 digitals and 100 step size
                    theVal   = aNumber;
                    posCelli = i;
                    break;
                end
            end
        end
    elseif strcmpi(indicator, 'angle'),
        iSkip = 0;
        for i = 1:numOfRow
            for j = 1:length(posCell)
                if i == posCell(j), % || posCell(j) == 0,
                    iSkip = 1;
                end
            end
            
            if iSkip == 1,
                iSkip = 0;
                continue;
            end
            
            aString = aStringCell{i};
            aNumber = str2double(aString);
            if ~isnan(aNumber),
                if length(aString) == 3,  % angle 314, 610, ... only 3 digitals
                    theVal   = aNumber;
                    posCelli = i;
                    break;
                end
            end
        end
      
    elseif strcmpi(indicator, 'rpm'),
        for i = 1:numOfRow
            aString = aStringCell{i};
            aNumber = str2double(aString);
            if ~isnan(aNumber),
                if length(aString) == 4,  % rpm: 0700, 1000, 1600, ... only 4 digitals
                    theVal   = aNumber;
                    posCelli = i;
                    break;
                end
            end
        end
    end
end
end


function flatedCell = flatIt(y)
% fill all elements in a cell to be fit to xls row
% y{cylinder, event} = {1 2 3 4 5}

flatedCell   = cell(1,1);
[nRow nCol]  = size(y);
numOfElement = -1e33;
for i = 1:nRow
    for j = 1:nCol
        numOfElement = max(numOfElement, length(y{i,j}));
    end
end

if numOfElement ~= 5,
    fprintf('\nWarning: numOfElement is not 5 (instead %i)', numOfElement);
    aaa= 0;
end

for i = 1:nRow
    for j = 1:nCol
        for k = 1:numOfElement
            if numOfElement>length(y{i,j}) || isempty(y{i,j}(k)),
                flatedCell{(i-1)*nCol*numOfElement + (j-1)*numOfElement + k} = 1e33;
            else
                flatedCell{(i-1)*nCol*numOfElement + (j-1)*numOfElement + k} = y{i,j}(k);
            end
        end
    end
    aaa=0;
end
end

% % push phase time
% k= 4; m1=1; landmark{eventCounter,i,1}(m1)  = (time1(jPeakStart) - time1(jPushStart))*1000;  % [ms]
% %  3: delta-t of 1st fall
% k= 2; m3=3; landmark{eventCounter,i,1}(m3)  = (time1(jVShapeValley) - time1(jPeakStart))*1000;    % [ms]
% %  4: delta-I of 1st fall
% k= 1; m4=4; landmark{eventCounter,i,1}(m4)  = current(jPeakStart,i) - currentAtValley;
% %  5: 1st peak delta-I/delta-t
% k= 31; m5=5; landmark{eventCounter,i,1}(m5)  = landmark{eventCounter,i,1}(m4)/landmark{eventCounter,i,1}(m3);
% %  6: area 1
% k= 3; m6=6; landmark{eventCounter,i,1}(m6)  = integrateIt(samplingTime, -currentAtValley, current(:,i), jPeakStart, jVShapeValley)*1000; %[A x ms]
% %  7: area 2
% k= 8; m7=7; landmark{eventCounter,i,1}(m7)  = integrateIt(samplingTime, -currentAtValley, current(:,i), jVShapeValley, jPeakEnd)*1000;   %[A x ms]
% % TpHL
% k=18; m9=9; landmark{eventCounter,i,1}(m9)  = 1000*(time1(jTpHLEnd)-time1(jPeakEnd));
% % 11: fullness of area 2
% k=28; m11=11; landmark{eventCounter,i,1}(m11)  = abs(landmark{eventCounter,i,1}(m7) ...
% % 12: fullness of area 1 + 2
% k=33; m12=12; landmark{eventCounter,i,1}(m12)  = (landmark{eventCounter,i,1}(m6)+landmark{eventCounter,i,1}(m7)) ...
% % 13: GC(t) of areal 1
% k= 7; m13=13; landmark{eventCounter,i,1}(m13)  = (time1(getCoG4t(samplingTime, current(:,i)-currentAtValley, ...
% % 14: GC(t) of areal 2
% k=17; m14=14; landmark{eventCounter,i,1}(m14)  = (time1(getCoG4t(samplingTime*1000, current(:,i)-currentAtValley, ...
% % 15: GC(t) of areal 3
% k=22; m15=15; landmark{eventCounter,i,1}(m15)  = (time1(getCoG4t(samplingTime*1000, currentMax-current(:,i), ...
% % 16: cross point of min I and 2/3 first fall with fitted slope                               previously: GC(t) of areal 4
% k=27; m16=16; landmark{eventCounter,i,1}(m16)  = 1000*(time1(getFallInterceptTime(current(:,i), jPushStart, jPeakStart, jPeakEnd, samplingTime, i, plotInForeground)) -time1(jPeakStart));
% % 17: GC(I) of areal 1
% k= 6; m17=17; landmark{eventCounter,i,1}(m17)  = current(getCoG4I(samplingTime*1000, current(:,i)-currentAtValley, ...
% % 18: GC(I) of areal 2
% k=11; m18=18; landmark{eventCounter,i,1}(m18)  = current(getCoG4I(samplingTime*1000, current(:,i), ...
% % position for max dI/samplingTime from right at push phase
% k=32; m19=19; landmark{eventCounter,i,1}(m19)  = -1000*time1(jPeakStart)+1000*time1(get1stDerivativeAtPushRight(current(jPeakStart-55:jPeakStart,i), samplingTime, jPeakStart-55, jPeakStart));
% % 20: gradient of upper push phase with liniear regression [A/ms]
% k=34; m20=20; landmark{eventCounter,i,1}(m20)  =  0.001*linearRegression(current(jPeakStart-numOfBackwardCount4PushPhase:jPeakStart,i), samplingTime);
% % deviation time and index
% k=14; m28=28; [landmark{eventCounter,i,1}(m28), jDeviate]  = getDeviationStart(time1, current(:,i), jPushStart, jPeakStart, jPeakEnd, delayDeviate, threshold4DeviateDetect);
% % area 1 at push after deviation
% k=19; m21=21; landmark{eventCounter,i,1}(m21)  = getArea1(samplingTime, current(:,i), jDeviate, jDeviate+numOfSample4Area1AtPush, jDeviate+numOfSample4Area1AtPush, jPeakStart, 1, 2, 0.33); %[A x ms];
% % 22: push-phase slope
% k= 9; m22=22; landmark{eventCounter,i,1}(m22)  = (current(jPeakStart,i)-current(jPushStart,i)) / landmark{eventCounter,i,1}(m1);
% % 23: slope of CoG of area 1 (1) shifted -- GC(I)/GC(t)(s)
% k=16; m23=23; landmark{eventCounter,i,1}(m23)  = (3.5+landmark{eventCounter,i,1}(m17)) / landmark{eventCounter,i,1}(m13) ;
% % 24: slope of CoG of area 1 (2) no shift
% k=21; m24=24; landmark{eventCounter,i,1}(m24)  = landmark{eventCounter,i,1}(m17) / landmark{eventCounter,i,1}(m13) ;
% % 25: slope of 1st fall based on CoG1: delta-I/CoG1(t)
% k=26; m25=25; landmark{eventCounter,i,1}(m25)  = landmark{eventCounter,i,1}(m4) / landmark{eventCounter,i,1}(m13) ;
% % 26: last slope of push phase
% k=29; m26=26; landmark{eventCounter,i,1}(m26)  = gradBefore/1000;
% % 27: GC(t) of areal 1 after smoothing
% k=12; m27=27; landmark{eventCounter,i,1}(m27)  =(time1(getCoG4t(samplingTime, current(:,i)-currentAtValley, ...
% % Area1(u) at push phase
% k= 5; m29=29; landmark{eventCounter,i,1}(m29)  = 1000*samplingTime*upSegment*(current(jPeakStart,i)-current(jPeakStart-upSegment,i)) - ...
% % Area1(l) at push phase from ´push start with xxx points: make the start
% k=10; m30=30; landmark{eventCounter,i,1}(m30)  = 1000*samplingTime*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1,i)) - ...
% % ratio of areax u/l
% k=15; m31=31; landmark{eventCounter,i,1}(m31)  = landmark{eventCounter,i,1}(m29) / landmark{eventCounter,i,1}(m30);
% % ratio of area1/area2 (u)
% k=20; m32=32; landmark{eventCounter,i,1}(m32)  = ccc/(1-ccc);
% % ratio of area1/area2 (l)
% k=25; m33=33; landmark{eventCounter,i,1}(m33)  = ccc/(1-ccc);
% % Area1(u) at push phase, same dela-A
% k=30; m34=34; landmark{eventCounter,i,1}(m34)  = 1000*samplingTime*upSegment*(current(jPeakStart,i)-current(max(1,jPeakStart-upSegment),i)) - ...
% % 2: 1st peak angle/or its tangent
% k= 35; m2=2; landmark{eventCounter,i,1}(m2)  = 1000*samplingTime*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1,i)) - ...
% % area 2 from deviation point 
% k=24; m35=35; [tmp landmark{eventCounter,i,1}(m35)] = getArea1(samplingTime, current(:,i), jDeviate, jDeviate+numOfSample4Area1AtPush, jDeviate+numOfSample4Area1AtPush, jPeakStart, 1, 2, 0.33);
% % deviation time x Area2 (push)
% k=23; m10=10; landmark{eventCounter,i,1}(m10)  = landmark{eventCounter,i,1}(m35)*landmark{eventCounter,i,1}(m28);
% % dt^2+dI^2 between push start to deviation point
% k=13; m8=8; landmark{eventCounter,i,1}(m8)  = 1e8*(time1(jDeviate)-time1(jPushStart))^2 + (current(jDeviate,i)-current(jPushStart,i))^2; % [(0.1*ms x I)^2]


% % landmarks for current tail
% %  1: tmax
% k= 2; m1=1; landmark{eventCounter,i,2}(m1)  = (time1(jTailMax)-time1(jTailStart))*1000;
% %  2: Imax
% k= 1; m2=2; landmark{eventCounter,i,2}(m2)  = current(jTailMax,i);
% % Area 1
% k= 3; m3=3; landmark{eventCounter,i,2}(m3)  = integrateIt(dt, currentMax-current(:,i), jTailStart, jTailMax)*1000; %[A x ms];
% % Area 2
% k= 7; m4=4; landmark{eventCounter,i,2}(m4)  = integrateIt(dt, currentMax-current(:,i), jTailMax, jTailEnd)*1000; %[A x ms];
% % Area 1+2
% k=19; m5=5; landmark{eventCounter,i,2}(m5)  = landmark{eventCounter,i,2}(m3) + landmark{eventCounter,i,2}(m4);
% % Area 1/2
% k=20; m6=6; landmark{eventCounter,i,2}(m6)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m4);
% % Area 1/1+2
% k=24; m7=7; landmark{eventCounter,i,2}(m7)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m5);
% % fullness1
% k= 5; m8=8; landmark{eventCounter,i,2}(m8)  = landmark{eventCounter,i,2}(m3)/((currentMax-currentStart)*(jTailMax-jTailStart)*dt*1000);
% % fullness2
% k= 9; m9=9; landmark{eventCounter,i,2}(m9)  = landmark{eventCounter,i,2}(m4)/((currentMax-currentEnd)*(jTailEnd-jTailMax)*dt*1000);
% % fullness 1+2
% k=21; m10=10; landmark{eventCounter,i,2}(m10)  = (landmark{eventCounter,i,2}(m3)+landmark{eventCounter,i,2}(m4))/((currentMax-currentEnd)*(jTailEnd-jTailStart)*dt*1000);
% % Area 3
% k=11; m11=11; landmark{eventCounter,i,2}(m11)  = integrateIt(dt, current(:,i), jTailStart, jTailMid)*1000; %[A x ms];
% % Area 4
% k=15; m12=12; landmark{eventCounter,i,2}(m12)  = integrateIt(dt, current(:,i), jTailMid, jTailEnd)*1000; %[A x ms];
% % Area 3+4
% k=23; m13=13; landmark{eventCounter,i,2}(m13)  = landmark{eventCounter,i,2}(m11) + landmark{eventCounter,i,2}(m12);
% % Area 3/4
% k=27; m14=14; landmark{eventCounter,i,2}(m14)  = landmark{eventCounter,i,2}(m11)/landmark{eventCounter,i,2}(m12);
% % Area 3/3+4
% k=28; m15=15; landmark{eventCounter,i,2}(m15)  = landmark{eventCounter,i,2}(m11)/(landmark{eventCounter,i,2}(m11)+landmark{eventCounter,i,2}(m12));
% % fullness3
% k=13; m16=16; landmark{eventCounter,i,2}(m16)  = landmark{eventCounter,i,2}(m11)/((currentMax-currentStart)*(jTailMid-jTailStart)*dt*1000);
% % fullness4
% k=17; m17=17; landmark{eventCounter,i,2}(m17)  = landmark{eventCounter,i,2}(m11)/((currentMax-currentEnd)*(jTailEnd-jTailMid)*dt*1000);
% % fullness3+4
% k=25; m18=18; landmark{eventCounter,i,2}(m18)  = (landmark{eventCounter,i,2}(m11)+landmark{eventCounter,i,2}(m12))/((currentMax-currentEnd)*(jTailEnd-jTailStart)*dt*1000);
% % Area 1/3
% k=22; m19=19; landmark{eventCounter,i,2}(m19)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m11);
% % GC1_t
% k= 6; m20=20; landmark{eventCounter,i,2}(m20)  = (time1(getCoG4t(dt, currentMax-current(:,i), 0.5*0.001*landmark{eventCounter,i,2}(m3), jTailStart, jTailMax)) - time1(jTailStart))*1e6;
% % GC2_t
% k=10; m21=21; landmark{eventCounter,i,2}(m21)  = (time1(getCoG4t(dt, currentMax-current(:,i), 0.5*0.001*landmark{eventCounter,i,2}(m4), jTailMax, jTailEnd)) - time1(jTailStart))*1000;
% % GC3_t
% k=14; m22=22; landmark{eventCounter,i,2}(m22)  = (time1(getCoG4t(dt, current(:,i), 0.5*0.001*landmark{eventCounter,i,2}(m11), jTailStart, jTailMid)) - time1(jTailStart))*1e6;
% % GC4_t
% k=18; m23=23; landmark{eventCounter,i,2}(m23)  = (time1(getCoG4t(dt, current(:,i), 0.5*0.001*landmark{eventCounter,i,2}(m12), jTailMid, jTailEnd)) - time1(jTailStart))*1000;
% % curveLength of 150 sampling points
% k= 4; m24=24; landmark{eventCounter,i,2}(m24)  = lengthOfCurve(dt*1000, current(:,i), jTailStart, jTailStart+249)*1000;
% % Area1/3/fullness3
% k=12; m25=25; landmark{eventCounter,i,2}(m25)  = landmark{eventCounter,i,2}(m20)/landmark{eventCounter,i,2}(m16);
% % Area1/2*fullness1
% k= 8; m26=26; landmark{eventCounter,i,2}(m26)  = landmark{eventCounter,i,2}(m6)/landmark{eventCounter,i,2}(m8);
% % fullness1/3
% k=26; m27=27; landmark{eventCounter,i,2}(m27)  = landmark{eventCounter,i,2}(m8)/landmark{eventCounter,i,2}(m10);
% % Area1/2/Fullness3
% k=16; m28=28; landmark{eventCounter,i,2}(m28)  = landmark{eventCounter,i,2}(m6)/landmark{eventCounter,i,2}(m10);
%
