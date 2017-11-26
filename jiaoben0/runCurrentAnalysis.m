% function runCurrentAnalysis(filePathInput, filePathOutput)
% run series of seeCurrent
% usagH: runCurrentAnalysis(filePathInput, filePathOutput)
% filePathInput--file path without trailing '\'
% dependency: runCurrentAnalysis, seeCurrent, seeCurrentSpecial,
% myMdfImport, offsetElimitate, bringFigToFromBackground, reLocateFigure, movefile, getHoldEnd, get2ndPeak,  
% clc;clear all;close force all; close all hidden;
java.lang.Runtime.getRuntime.gc;

tVeryStart  = tic;

filePathInputCell  = {};
filePathOutputCell = {};

% get to the directory for this pc
[tmp pcName] = system('hostname');
if strfind(pcName, 'Neptune'),
    workinDirName  = 'H:\herzo\projects\';
    workinDirName1 = 'I:\herzo\projects\';
elseif strfind(pcName,  'Uranus'),
    % workinDirName = 'E:\herzo\projects\';
    workinDirName  = 'E:\herzo\projects\';
    workinDirName1 = 'E:\herzo\projects\';
elseif strfind(pcName,  'Mercury'),
    workinDirName  = 'J:\herzo\projects\';
    workinDirName1 = 'J:\herzo\projects\';
elseif strfind(pcName,  'PLUTO'),
    workinDirName  = 'F:\projects\herzo\';
    workinDirName1 = 'F:\projects\herzo\';
else
    workinDirName  = 'C:\project\';
    workinDirName1 = 'C:\project\';
end


specialCase = 0; % 1: run special case. OPL199, 205, 014

filePathInputCell = {...
    [workinDirName, 'issue\blockedSV\OPL014a'];
    [workinDirName, 'issue\blockedSV\OPL014'];
    [workinDirName, 'issue\blockedSV\OPL_205'];
    [workinDirName, 'issue\blockedSV\OPL199'];
    [workinDirName, 'Issue\blockedSV\tailVShape\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT'];                        % 1
    [workinDirName, 'Issue\blockedSV\tailVShape\020deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT'];                        % 2
    
    [workinDirName, 'Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_02'];                       % 3     7 folders
    [workinDirName, 'Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0'];                        % 4
    [workinDirName1,'Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO'];                          % 5
    [workinDirName, 'Issue\blockedSV\batteryEffect\020deg_fast_stuck-cl_nom_stuck-op_LVO'];                          % 6
    [workinDirName, 'Issue\blockedSV\batteryEffect\020deg_fast_slow_nom_stuck-mid_LVO'];                             % 7
    [workinDirName, 'Issue\blockedSV\batteryEffect\005deg_fast_stuck_nom_stuck_LVO'];                                % 8
    [workinDirName, 'Issue\blockedSV\batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO'];                             % 9
    
    [workinDirName, 'Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700'];                   % 10   % bad area 1
    % [workinDirName, 'Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_ohne_vari_Close'];             % 11   % bad area 1
    [workinDirName, 'Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC'];                               % 12   % bad area 1
      
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_700_mech_el_15W-40'];           % 13     8 folders
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_4000_mech_el_15W-40'];          % 14
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_FulliftToNolift'];  % 15
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_HalfliftToNolift']; % 16
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40_mech'];              % 17
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000'];                         % 18
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000'];                 % 19
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700'];                  % 20
    
    [workinDirName, 'Issue\blockedSV\tailEffect\000deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT'];                            % 21    1 folder
    
    [workinDirName, 'Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC'];                              % 22    3 folders
    [workinDirName, 'Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000'];                 % 23
    [workinDirName, 'Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700'];                  % 24
    
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC'];                              % 25    9 folders
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40'];                  % 26
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_Half_to_No'];       % 27
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_6000_15W-40'];                  % 28
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40'];                   % 29
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000'];                 % 30
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000_15W-40'];          % 31
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700'];                  % 32
    [workinDirName, 'Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700_15W-40'];           % 33
    
    [workinDirName, 'Issue\blockedSV\tailEffect\080deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT'];                            % 34     5 folders
    [workinDirName, 'Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC'];                               % 35
    [workinDirName, 'Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000'];                  % 36    bad area 1
    
    [workinDirName, 'Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000'];                  % 37
    [workinDirName, 'Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700'];                   % 38
    
    [workinDirName, 'Issue\blockedSV\tailEffect\020deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT'];                            % 39
    [workinDirName, 'Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_Welle_Tail'];                   % 40
    
    [workinDirName, 'Issue\blockedSV\CReffect\005deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT'];                                      % 41
    [workinDirName, 'Issue\blockedSV\CReffect\080deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT'];                                      % 42
    [workinDirName, 'Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT'];                                      % 43
    % [workinDirName, 'Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\angleBased'];                         % 44
    [workinDirName, 'Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_angle_var'];           % 45
    [workinDirName, 'Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_mode_var'];            % 46
    [workinDirName, 'Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_rpm_var'];             % 47
    
    % [workinDirName, 'Issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700'];  % 1
    % [workinDirName, 'Issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO'];              % 2
    % [workinDirName, 'Issue\blockedSV\tailEffect\blindSpotArea1\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC'];              % 3
    };

filePathOutputCell = filePathInputCell;

%     filePathOutputCell = {...
%         'H:\herzo\projects\Issue\blockedSV\batteryEffect\110deg_fast_stuck_nom_stuck_LVO_02';              % 1
%         };
% end

if ~isempty(filePathOutputCell),
    numOffolder = length(filePathInputCell);
else
    numOffolder        = 1;
    filePathInputCell  = {filePathInput};
    filePathOutputCell = {filePathOutput};
end

delayDeviate            = -48;   % -48;  % < 0 delay; >0 in advance
threshold4DeviateDetect = 0.1; % [log(A)]
numOfSample4Area1AtPush = 48;  %

if specialCase == 0,
    % fro normal case seeCurrent
    resultFolderName0 = ['d',num2str(delayDeviate), 't',num2str(threshold4DeviateDetect), 'n',num2str(numOfSample4Area1AtPush)];
    otherCaseID       = '';
    resultFolderName  = [regexprep(resultFolderName0, '\.','p'), '_', otherCaseID];
else
    % for case OPL205 seeCurrent205
    resultFolderName  = 'delay2TDC';
end

finishOne         = 0;
numOfCaseFinished = 0;
for j = [24] % numOffolder-6:-1:1 % 47 % 16 % 1:numOffolder
    tFolderStart   = tic;
    %     caseNo2Start   = 1;
    filePathInput  = filePathInputCell{j};
    filePathParentName = filePathOutputCell{j};

    aaa=0;
    if 0,
        % move current, V, tail to a subdirectory
        % nameOfSubFolder = 'factorMid0p25_0p33';
        nameOfSubFolder = 'area1_12060_8040';
        if ~exist([filePathOutput, '\', nameOfSubFolder], 'file'),
            mkdir([filePathOutput, '\', nameOfSubFolder]);
            % end
            if exist([filePathOutput,'\current'], 'file'),
                movefile([filePathOutput,'\current'], [filePathOutput,'\', nameOfSubFolder]);
            end
            if exist([filePathOutput,'\tail'], 'file'),
                movefile([filePathOutput,'\tail'], [filePathOutput,'\', nameOfSubFolder]);
            end
            if exist([filePathOutput,'\V'], 'file'),
                movefile([filePathOutput,'\V'], [filePathOutput,'\', nameOfSubFolder]);
            end
            
            if exist([filePathOutput,'\angleResult001.mat'], 'file'),
                movefile([filePathOutput,'\angleResult*.mat'], [filePathOutput,'\', nameOfSubFolder]);
            end
            if exist([filePathOutput,'\statisticResult001.mat'], 'file'),
                movefile([filePathOutput,'\statisticResult*.mat'], [filePathOutput,'\', nameOfSubFolder]);
            end
            if exist([filePathOutput,'\yLimit.mat'], 'file'),
                movefile([filePathOutput,'\yLimit.mat'], [filePathOutput,'\', nameOfSubFolder]);
            end
        end
    else
        % build folder for results
        filePathOutput = [filePathParentName, '\', resultFolderName];
        if ~exist(filePathOutput, 'dir'),
            mkdir(filePathOutput);
        end
        % do simulation
        % fileNames      = dir([filePathInput,'\*_mdf.dat']);
        fileNames      = dir([filePathInput,'\*.dat']);
        
        % fileNames    = dir([filePathInput,'\*.dat']);
        fprintf('\n======================================================================================================');
        fprintf('\nStart to analyse data in %i. folder %s ... ...\n', j, filePathInput);
        fprintf('Result and output folder: %s ... ...\n', filePathOutput);

        if isempty(fileNames),
            fprintf('\nWarning: No file found and check file search pattern.\n');
            continue;
        end
        
        % if it is continuous running, get the startinf point from disk
        if exist([filePathOutput, '\', 'caseNo2Start.dat'], 'file'),
            load([filePathOutput, '\', 'caseNo2Start.dat']);
            caseNo2Start = floor(caseNo2Start);
        else
            caseNo2Start = 1; 
        end
        caseNo2Start=1;
        for i = caseNo2Start:length(fileNames)  %  caseNo2Start:length(fileNames)
            cleanWorkspace;
            % collect some memory back
            java.lang.Runtime.getRuntime.gc
            
            fileNamei = fileNames(i,1).name;
            if ~strcmp(fileNamei, 'caseNo2Start.dat')
                if specialCase == 0,
                    seeCurrent([filePathInput, '\', fileNames(i,1).name], '', i, filePathOutput);
                else
                    seeCurrentSpecial([filePathInput, '\', fileNamei], '', i, filePathOutput);
                end
                numOfCaseFinished = numOfCaseFinished + 1;
            end
            % save a start point for next run
            caseNo2Start = i + 1;
            save([filePathOutput, '\', 'caseNo2Start.dat'], '-ASCII', 'caseNo2Start');
            finishOne = finishOne + 1;
            
            pause
            %         break;
        end
        
    end
    tFolderElapse = toc(tFolderStart);
    disp(['---- Folder ', num2str(j), ' finished for an accumulated time of ',num2str(tFolderElapse/3600), ' [Hr] ----']);
end

tTotalElapse = toc(tVeryStart);

tTotalElapse = toc(tVeryStart);
disp(['-------------- ', num2str(numOfCaseFinished), ' cases finished for ',num2str(tTotalElapse/3600), ' [Hr]--------------']);

% close all;
% clear all;
