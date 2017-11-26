
tVeryStart  = tic;

filePathInputCell = {...
        'H:\herzo\projects\Issue\blockedSV\tailVShape\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT';                                 % 1  
        'H:\herzo\projects\Issue\blockedSV\tailVShape\020deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT';                                 % 2

        'H:\herzo\projects\Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_02';                       % 3     7 folders
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0';                        % 4     
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO';                          % 5 
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\020deg_fast_stuck-cl_nom_stuck-op_LVO';                          % 6 
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\020deg_fast_slow_nom_stuck-mid_LVO';                             % 7 
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\005deg_fast_stuck_nom_stuck_LVO';                                % 8 
        'H:\herzo\projects\Issue\blockedSV\batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO';                             % 9 

        'H:\herzo\projects\Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700';                % 10   % bad area 1
        'H:\herzo\projects\Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_ohne_vari_Close';            % 11   % bad area 1
        'H:\herzo\projects\Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC';                            % 12   % bad area 1

        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_700_mech_el_15W-40';           % 13     8 folders
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_4000_mech_el_15W-40';          % 14
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_FulliftToNolift';  % 15
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_HalfliftToNolift'; % 16
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40_mech';              % 17
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000';                         % 18
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000';                 % 19
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700';                  % 20
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\000deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT';                            % 21    1 folder 
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC';                              % 22    3 folders
        'H:\herzo\projects\Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000';                 % 23
        'H:\herzo\projects\Issue\blockedSV\tailEffect\015deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700';                  % 24
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC';                              % 25    9 folders
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40';                  % 26
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_4000_15W-40_Half_to_No';       % 27
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_6000_15W-40';                  % 28
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\EVC_700_15W-40';                   % 29
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000';                 % 30
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_4000_15W-40';          % 31
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700';                  % 32
        'H:\herzo\projects\Issue\blockedSV\tailEffect\025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_mech_el_700_15W-40';           % 33
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\080deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT';                            % 34     5 folders
        'H:\herzo\projects\Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC';                               % 35
        'H:\herzo\projects\Issue\blockedSV\tailEffect\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000';                  % 36    bad area 1
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_4000';                  % 37
        'H:\herzo\projects\Issue\blockedSV\tailEffect\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700';                   % 38
        
        'H:\herzo\projects\Issue\blockedSV\tailEffect\020deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT';                            % 39
        'H:\herzo\projects\Issue\blockedSV\tailEffect\005deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT\LVO_Welle_Tail';                   % 40

        'H:\herzo\projects\Issue\blockedSV\CReffect\005deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT';                                   % 41   
        'H:\herzo\projects\Issue\blockedSV\CReffect\080deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT';                                   % 42
        'H:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT';                                   % 43
        'H:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\angleBased';                        % 44
        'H:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_angle_var';        % 45
        'H:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_mode_var';         % 46
        'H:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_rpm_var';          % 47

        'H:\herzo\projects\Issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO_mech_el_700'; % 1
        'H:\herzo\projects\Issue\blockedSV\tailEffect\blindSpotArea1\080deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\LVO';             % 2
        'H:\herzo\projects\Issue\blockedSV\tailEffect\blindSpotArea1\110deg_Toff-slow_Toff-fast_nom_stuck-cl-SVT\EVC';             % 3
    };
        
filePathOutput = '.';

numOffolderMax       = length(filePathInputCell);
numOfFolderAcc       = 0;
numOfFolder          = 0;
numOfFiles           = 0;
numOfFileAcc         = 0;


for j = [1 2] % 3 6 9] % 13:numOffolderMax  % folderNo2Start:numOffolderMax
    numOfFolderAcc = numOfFolderAcc + 1;
    
    filePathInput = filePathInputCell{j};
    fileNames     = dir([filePathInput,'\angleResult*.mat']);
    numOfFiles    = length(fileNames);
    if numOfFiles == 0,
        fprintf('\n Warning: no files in %i. folder %s\n', j, filePathInput);
        aaa=0;
    end
    numOfFilesInFolder = 0;
    numOfEventSaved1   = 0;
    numOfEventSaved2   = 0;
    numOfFileAcc       = 0;
    for i = 1:numOfFiles
        fprintf('\nInfo: Processing %i. file: %s in %i. directory: %s ...\n',i, fileNames(i,1).name, j, filePathInput);
        numOfEventSaved1 = saveAngles(j, i, filePathInput, fileNames(i,1).name);
        numOfFileAcc     = numOfFileAcc+ 1;        
    end
    fprintf('\nInfo: Finished %i files in Directory %s.\n', numOfFiles, filePathInput);
    % make a copy to check temporarily
    % dos('copy /Y evaluation.xls evaluationTmp.xls');
    aaa=0;
end

tTotalElapse = toc(tVeryStart);
fprintf('\n------- runtSwOnChange has finished %i files  in %i folders for %f [H] -------\n', numOfFileAcc, numOfFolderAcc, tTotalElapse/3600);

