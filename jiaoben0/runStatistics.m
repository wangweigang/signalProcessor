
% get to the directory for this pc
[tmp pcName] = system('hostname');
if strfind(pcName, 'Neptune'),
    workinDirName = 'H:\herzo\projects\';
elseif strfind(pcName,  'Uranus'),
    % workinDirName = 'E:\herzo\projects\';
    workinDirName = 'E:\herzo\projects\';
elseif strfind(pcName,  'Mercury'),
    workinDirName = 'J:\herzo\projects\';
else
    workinDirName = 'C:\project\';
end
lastFolder = '\d-48t0p1n48_';

tVeryStart  = tic;

filePathInputCell = {...
        '.\';                                                                                                            % 1
        [workinDirName, 'issue\blockedSV\tailVShape\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT', lastFolder];                        % 2  
        [workinDirName, 'issue\blockedSV\tailVShape\020deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT', lastFolder];                        % 3

        [workinDirName, 'issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_02', lastFolder];                       % 4     7 folders
        [workinDirName, 'issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0', lastFolder];                        % 5     
        [workinDirName, 'issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO', lastFolder];                          % 6 
        [workinDirName, 'issue\blockedSV\batteryEffect\020deg_fast_stuck-cl_nom_stuck-op_LVO', lastFolder];                          % 7 
        [workinDirName, 'issue\blockedSV\batteryEffect\020deg_fast_slow_nom_stuck-mid_LVO', lastFolder];                             % 8 
        [workinDirName, 'issue\blockedSV\batteryEffect\005deg_fast_stuck_nom_stuck_LVO', lastFolder];                                % 9 
        [workinDirName, 'issue\blockedSV\batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO', lastFolder];                             % 10

        [workinDirName, 'issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700', lastFolder];       % 11   % bad area 1
        [workinDirName, 'issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_ohne_vari_Close', lastFolder];   % 12   % bad area 1
        [workinDirName, 'issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC', lastFolder];                   % 13   % bad area 1

        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_700_mech_el_15W-40', lastFolder];           % 14     8 folders
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_4000_mech_el_15W-40', lastFolder];          % 15
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_FulliftToNolift', lastFolder];  % 16
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_HalfliftToNolift', lastFolder]; % 17
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40_mech', lastFolder];              % 18
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000', lastFolder];                         % 19
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000', lastFolder];                 % 20
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700', lastFolder];                  % 21
        
        [workinDirName, 'issue\blockedSV\tailEffect\000deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT', lastFolder];                            % 22    1 folder 
        
        [workinDirName, 'issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC', lastFolder];                              % 23    3 folders
        [workinDirName, 'issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000', lastFolder];                 % 24
        [workinDirName, 'issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700', lastFolder];                  % 25
        
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC', lastFolder];                              % 26    9 folders
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40', lastFolder];                  % 27
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_Half_to_No', lastFolder];       % 28
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_6000_15W-40', lastFolder];                  % 29
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40', lastFolder];                   % 30
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000', lastFolder];                 % 31
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000_15W-40', lastFolder];          % 32
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700', lastFolder];                  % 33
        [workinDirName, 'issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700_15W-40', lastFolder];           % 34
        
        [workinDirName, 'issue\blockedSV\tailEffect\080deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT', lastFolder];                            % 35     5 folders
        [workinDirName, 'issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC', lastFolder];                               % 36
        [workinDirName, 'issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000', lastFolder];                  % 37    bad area 1
        
        [workinDirName, 'issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000', lastFolder];                  % 38
        [workinDirName, 'issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700', lastFolder];                   % 39
        
        [workinDirName, 'issue\blockedSV\tailEffect\020deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT', lastFolder];                            % 40
        [workinDirName, 'issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_Welle_Tail', lastFolder];                   % 41

        [workinDirName, 'issue\blockedSV\CReffect\005deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT', lastFolder];                                      % 42   
        [workinDirName, 'issue\blockedSV\CReffect\080deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT', lastFolder];                                      % 43
        [workinDirName, 'issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT', lastFolder];                                      % 44
        [workinDirName, 'issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\angleBased', lastFolder];                           % 45
        [workinDirName, 'issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_angle_var', lastFolder];           % 46
        [workinDirName, 'issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_mode_var', lastFolder];            % 47
        [workinDirName, 'issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_rpm_var', lastFolder];             % 48

%         [workinDirName, 'issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700', lastFolder];    % 1
%         [workinDirName, 'issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO', lastFolder];                % 2
%         [workinDirName, 'issue\blockedSV\tailEffect\blindSpotArea1\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC', lastFolder];                % 3
    };
        
filePathOutput   = '.';
folderNo2Start   = 2;
fileNo2Start     = 1;
numOfEventSaved1 = 13;
numOfEventSaved2 = 13;
if exist([filePathOutput, '\', 'nextCase2Start.dat'], 'file'),
    load([filePathOutput, '\', 'nextCase2Start.dat']);
    folderNo2Start   = floor(nextCase2Start(1));
    fileNo2Start     = floor(nextCase2Start(2));
    numOfEventSaved1 = floor(nextCase2Start(3));
    numOfEventSaved2 = floor(nextCase2Start(4));
end

numOffolderMax       = length(filePathInputCell);
numOfFolderAcc       = 0;
numOfFolder          = 0;
numOfFiles           = 0;
numOfFileAcc         = 0;


for j = 2:numOffolderMax % folderNo2Start:numOffolderMax
    numOfFolderAcc = numOfFolderAcc + 1;
    
    % make a back copy of case indicators
    if j > folderNo2Start,
        dos('copy /Y nextCase2Start.dat nextCase2StartTmp.dat');
    end
    
    filePathInput = filePathInputCell{j};
    fileNames     = dir([filePathInput,'\statisticResult*.mat']);
    numOfFiles    = length(fileNames);
    if numOfFiles == 0,
        fprintf('\n Warning: no files in %i. folder %s\n', j, filePathInput);
        continue;
        aaa=0;
    end
    numOfFilesInFolder = 0;
    for i = 1:numOfFiles % fileNo2Start:numOfFiles
        numOfFileAcc = numOfFileAcc + 1;
        fprintf('\nInfo: Processing %i. file: %s in %i. directory: %s ...\n',i, fileNames(i,1).name, j, filePathInput);
        [numOfEventSaved1, numOfEventSaved2] = saveStatistics(j, i, filePathInput, fileNames(i,1).name, numOfEventSaved1, numOfEventSaved2);
        numOfFiles                           = numOfFiles + 1;
        numOfFilesInFolder                   = numOfFilesInFolder + 1;
        if i >= length(fileNames),
            iNext = 1;
            jNext = min(j+1, numOffolderMax);
        else
            iNext = i + 1;
            jNext = j;
        end
        
        save([filePathOutput, '\', 'nextCase2Start.dat'], '-ASCII', 'jNext', 'iNext', 'numOfEventSaved1', 'numOfEventSaved2');

        % save  pointer to xls for next run
%         try
%             xlswrite(['evaluation', '.xls'], {jNext;iNext;numOfEventSaved1;numOfEventSaved2}, 'landmarkTail',    ['AS',num2str(numOfEventSaved1+1)]);
%         catch ME3
%             fprintf('\nWarning: Pointer not saved in possibly-locked evaluation.xls.\n');
%         end
        
    end
    fprintf('\nInfo: Finished %i files in Directory %s.\n', numOfFilesInFolder, filePathInput);
    if length(fileNames) == 0,
        iNext = 1;
        jNext = min(j+1, numOffolderMax);
        save([filePathOutput, '\', 'nextCase2Start.dat'], '-ASCII', 'jNext', 'iNext', 'numOfEventSaved1', 'numOfEventSaved2');
        fprintf('\nWarning: Empty folder (%s) and processing continues... \n', filePathInput);
        continue;
    end
    
    % save  pointer to xls for next run
    if 0,
        try
            xlswrite(['evaluation', '.xls'], {jNext;iNext;numOfEventSaved1;numOfEventSaved2}, 'landmarkTail',    ['AS',num2str(numOfEventSaved1+1)]);
        catch ME3
            fprintf('\nWarning: Pointer not saved in possibly-locked evaluation.xls.\n');
        end
        % make a copy to check temporarily
        dos('copy /Y evaluation.xls evaluationTmp.xls');
    end
    
end

tTotalElapse = toc(tVeryStart);
fprintf('\n------- runStatistics has finished %i files  in %i folders for %f [H] -------\n', numOfFileAcc, numOfFolderAcc, tTotalElapse/3600);

