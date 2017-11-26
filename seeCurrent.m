function seeCurrent(inputFileFull, StrExtra4Var, theNumOfFile, filePathOutput)
% check out the current profiles from the Turblab test data
% usage: e.g., seeCurrent('APA227_6500_EVC_THPC90_2.dat')
%
% Note: lift, current acceleration have the same length
%
% landmark definition around V-shape
%  1: push-phase time
%  2: 1st peak angle/or its tangent
%  3: delta-t of 1st fall
%  4: delta-I of 1st fall
%  5: delta-I/delta-t
%  6: area 1
%  7: area 2
%  8: (area 1)/(area 2)
%  9: (area 1)/(area 1  +  area 2)
% 10: fullness of area 1
% 11: fullness of area 2
% 12: fullness of area 1 + 2
% 13: GC(t) of areal 1
% 14: GC(t) of areal 2
% 15: GC(t) of areal 3
% 16: GC(t) of areal 4
% 15: GC(I) of areal 1
% 16: GC(I) of areal 2
% 17: CoMoI with axis: jPeakStart
% landmark definition around tail
%  1: tmax
%  2: Imax
%  3-22: ...

if nargin == 0,
    fileName       = 'APA227_6500_EVC_THPC90_2.dat';
    fileName       = 'E:\herzo\projects\Issue\blockedSV\ImproveBlockedSVDiagByTakingBatteryVoltage\Test\testData\AET8641000_10_LVO_11k0V_10k5A_mdf.dat';
    StrExtra4Var   = '';
    theNumOfFile   = 1;
    filePathOutput = '.';
elseif nargin == 1,
    StrExtra4Var   = '';
    theNumOfFile   = 1;
    filePathOutput = '.';
end

delayDeviate            = eval(['[evalin(''base'',', '''delayDeviate'')]']);
threshold4DeviateDetect = eval(['[evalin(''base'',', '''threshold4DeviateDetect'')]']);
numOfSample4Area1AtPush = eval(['[evalin(''base'',', '''numOfSample4Area1AtPush'')]']);


%%%%%%%%%%%%%%%%%%%%%%%% output control %%%%%%%%%%%%%%%%%%%%%%%%%%%
moreOutput       = 1;
plotInForeground = 'off';
plotAllTails     = 1;
plotAllVs        = 1;
plotItAll        = 1;
angleBasedData   = 0;
plot4Report      = 0;   % 0: normal report; >0 other report
if plot4Report > 0,
    normSize  = 6;
    smallSize = 5;
else
    normSize  = 8;
    smallSize = 6;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% close all;
% close all hidden;
    
saveMemory       = 1;
numOfCylinder    = 4;

% start counting time elaps
tStart           = tic;

%%%%%%%%%%%%%%%%%% import one turblab (mdf) data %%%%%%%%%%%%%%%%%%
myMdfImport(inputFileFull, 'workspace', 'signalTime.txt', 'actual', 'ratenumber', '')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% my color order      k          r          b          g          c          y          m          brown
myColor            = [0   0   0; 1   0   0; 0   0   1; 0   1   0; 0   1   1; 1   1   0; 1   0   1; 0.5 0   0];   

numOfMaxLandmark   = 35;
numOfMaxEvent      = 40;
landmark           = cell(numOfMaxEvent,numOfCylinder,2);   % number of event   x  4 cylinder   x   2 landmark arrays
hdlOfPlot4VShape   = [];
hdlOfPlot4Tail     = [];
hdlOfPlot          = zeros(1,numOfCylinder);
numOfvalidAnalysis = zeros(1,numOfCylinder);

if ~isempty(myStrfind(inputFileFull, '\')),
    fileName = inputFileFull(max(myStrfind(inputFileFull, '\'))+1:end-4);
else
    fileName = inputFileFull;
end
fprintf('Processing %i. data file %s.dat ... ....', theNumOfFile, inputFileFull);


% get rpm, etc. from 
% AET8811000_10_xxx_360_620_mdf.dat
% AET8641000_10_LVO_11k0V_09k0A_mdf
% 1234567890123456789012345678901234
% AET8511000_10_FL_15k0V_13k0A_mdf
% C:\Project\Issue\blockedSV\ImproveBlockedSVDiagByTakingBatteryVoltage\Test\testData\20deg_fast_slow_nom_stuck_LVO\mdf
% 
% inputFileFull    = 'C:\Project\Issue\blockedSV\ImproveBlockedSVDiagByTakingBatteryVoltage\Test\testData\20deg_fast_slow_nom_stuck_LVO\mdf\AET8641000_10_LVO_11k0V_09k0A_mdf.dat';
caseDescription = cell(1,1);  
if 1,
    caseDescription = parseName(inputFileFull)
%     data format
%     {
%         '110deg'           'AET9021000'    'tailVShape'
%         'Ton-fast'         '10'            ''
%         'Ton-slow'         'LVO'                     []
%         'nom'              '370'                     []
%         'stuck-mid-SVT'    '620'                     []
%         []    '09k0A'                   []
%         []    '1000'                    []
%     }
else
    caseDescription = {...
        '98deg'           'AOD862'    'choppingCurrent'
        'Ton-slow'         ''            ''
        'Ton-nom'          ''                     []
        'Ton-fast'         ''                     []
        'Ton-stuck(cl)'    ''                     []
                 []        '12k5A'                []
                 []        '1000'                 []}
end

statisticResult = cell(1,1);
angleSVClose    = [-1e33 -1e33];
angleMVOpen     = [-1e33 -1e33];
liftMVMax       = [0 0];
angleLiftMVMax  = [0 0];

% convert turblab vars in my vars (variable names are dependent of test results)

% vars in time1 resolution
time1        = eval(['[evalin(''base'',', '''time_1'')]']);
samplingTime = mean(diff(time1));

% build current 
current = eval([...
    '[evalin(''base'',', '''Current_10_', StrExtra4Var, '1''),', ...
     'evalin(''base'',', '''Current_20_', StrExtra4Var, '1''),', ...
     'evalin(''base'',', '''Current_30_', StrExtra4Var, '1''),', ...
     'evalin(''base'',', '''Current_40_', StrExtra4Var, '1'')]'...
    ]);
[numOfAllCurrentPoint tmp] = size(current);

% build lift
fprintf('\nRemove offsets for lifts:\n');

lift = cell(numOfCylinder,2);
for i = 1:numOfCylinder
    for j = 1:2
        liftName = ['Lift_',num2str(i),num2str(j),'_', StrExtra4Var, '1'];
        if evalin('base', ['exist(''',liftName,''',', '''var''',')']),
            lift{i,j} = evalin('base',liftName);
            numOfLiftPoint = length(lift{i,j});
            % offset the lift
            lift{i,j} = offsetElimitate(lift{i,j});
        end
    end
end

% build acceleration
numOfAllAcclPoint = 0;
accel = cell(numOfCylinder,1);
% check if there are acceleration signal, if yes, check its size
for i = 1:numOfCylinder
    if evalin('base', ['exist(''Acceleration_', num2str(i), '0_1''',',''var'')']),
        [numOfAllAcclPoint numOfAccel] = size(evalin('base', ['Acceleration_', num2str(i), '0_1']));
        break;
    end         
end

if numOfAllAcclPoint ~= 0, % in case there is no acceleration signal
    for i = 1:numOfCylinder
        if evalin('base', ['exist(''Acceleration_', num2str(i), '0_1''',',''var'')']),
            accel{i,1} = evalin('base', ['Acceleration_', num2str(i), '0_1']);
        end
    end
end
%%%% [numOfAllAcclPoint numOfAccel] = size(current);  % xxx

% check if last part of data is corrupt
numOfGoodCurrentPoint = numOfAllCurrentPoint;
for i = 1:numOfCylinder
    for j = floor(numOfAllCurrentPoint/4*3):numOfAllCurrentPoint
        if current(j,i)-current(j-1,i) > 4, %17,
            numOfGoodCurrentPoint = min(j, numOfGoodCurrentPoint);
        end
    end
end

% cut off the bad data
if numOfAllCurrentPoint > numOfGoodCurrentPoint,
    numOfAllCurrentPoint = numOfGoodCurrentPoint - 11;
    currentTmp           = current(1:numOfAllCurrentPoint,:); clear current;
    current              = currentTmp;                        clear currentTmp;
    time1Tmp             = time1(1:numOfAllCurrentPoint);     clear time1;
    time1                = time1Tmp(1:numOfAllCurrentPoint);  clear time1Tmp;
end

% offseting offset
fprintf('\n\nRemove offsets for currents:\n');
current = offsetElimitate(current);

freeMemory = java.lang.Runtime.getRuntime.freeMemory;
fprintf('\nInfo: Free memory left: %i.\n', freeMemory);

figure(4); bringFigToFromBackground(4, 'off'); reLocateFigure(gcf, 836, 652); clf; 
figure(3); bringFigToFromBackground(3, 'off'); reLocateFigure(gcf, 836, 652); clf;
figure(2); bringFigToFromBackground(2, 'off'); 
if plot4Report>0,
    reLocateFigure(gcf, 720, 240); 
else
    reLocateFigure(gcf, 596, 432); 
end
clf;
figure(1); bringFigToFromBackground(1, 'off'); reLocateFigure(gcf, 596, 432); clf;

% plot all currents in figure(1)
for i = 1:numOfCylinder
    hdlOfPlot(i) = subplot(4,1,i);
    % plot(1000*time1, current(:,i),'b.'); hold on;
    plot(1000*time1, current(:,i),'b-'); axis('tight');
    ylabel(['Current', num2str(i), ' [A]']);
    set(hdlOfPlot(i), 'xtick',[], 'Ylim',[-5 15]);
end
% organize the plots
linkaxes(hdlOfPlot, 'x');
set(hdlOfPlot(4), 'xtickMode', 'auto')
title(hdlOfPlot(1), 'Current history');
if angleBasedData == 0,
    xlabel(hdlOfPlot(4), 'Time [ms]');
else
    xlabel(hdlOfPlot(4), 'Crank angle [degCA]');   
end

if 0,
    deltaTimePoint = 6000; % deltaTimePoint for one window
    for i = 1:1000:length(time1)-deltaTimePoint
        set(hdlOfPlot(1), 'Xlim',1000*time1([i,i+deltaTimePoint]));
        drawnow;
        pause(0.001);
    end
end

numOfMaxSubplot = 35;   % the max number of landmark

% load ylimits from a file, if any
if exist([filePathOutput, '\', 'yLimit.mat'], 'file'),
    load([filePathOutput, '\', 'yLimit.mat']);
    [nRow, nCol1, nCol2] = size(yLimit);
    yLimitTmp            = yLimit;
    clear yLimit;
    yLimit               = zeros(numOfMaxSubplot,2,2);
    yLimit(:,:,1)        =  1e33;
    yLimit(:,:,2)        = -1e33;
    yLimit(1:nRow,:,:)   = yLimitTmp;
    clear yLimitTmp;
else
    %                  landmark x fig x [ylim1 ylim2]
    yLimit          = zeros(numOfMaxSubplot,2,2);
    yLimit(:,:,1)   =  1e33;
    yLimit(:,:,2)   = -1e33;
end

% fprintf('\nscale of last plot 1 from %9.3e to %9.3e',yLimit(1,1,:));


%%%%%%%%%%%%%%%%%%%%% thresholds to detect landmarks %%%%%%%%%%%%%%%%%%%%%
thresHoldEnd2D      = -0.2; % -0.24; % -0.48; % -0.5   % -0.40; % -0.45; %-0.7;
thresHoldEndOrien   = -0.03; % -0.02;
thresHoldEndSTD     = -0.07; % -0.08; % -0.11; % -0.12; % -0.15;

thresPeakEnd        = -0.04; % -0.05; % -0.07; % -0.15  %-0.07; % -0.08; % -0.10;
thresPeakEndOrien   =  0.04; %  0.07; %  0.12;
thresPeakEndSTD     = -0.16; % -0.18; % -0.15;

thresPeakStart      = -0.02*1;  % -0.03;  % -0.04; %-0.11; % -0.15;
thresPeakStartOrien =  0.006; % 0.006; % 0.0075; % 0.0085; % 0.01; % 0.012; % 0.018;

thresPushStart      =  0.04; % 0.06; % 0.08; % 0.1; % 0.12;
thresPushStartOrien =  0.03; % 0.035;
thresPushStartSTD   =  0.20; % 0.12; 
numOfBackwardCount4PushPhase = 66; % used to get curvature, one type of slope
thresTailEnd        =  0.13; % 0.20; % 0.25;
thresTailStart      =  0.02; % 0.03;
thresTailStartOrien = -0.01;
thresTailStartSTD   = -0.07; % -0.05
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numOfPoint4Regression = 4;

numOfPoint2Select     = 16;  % points used to do gradient estimation, mean, etc. for chopping reduction

statisticResult{2} = {theNumOfFile, inputFileFull};
statisticResult{3} = caseDescription;
peakCurrentMax     = -1e33;
valleyCurrentMin   = -1e33;

% make a dir if no exist 
if ~exist([filePathOutput,'\current'],'dir'),
    mkdir([filePathOutput,'\current']);
end
if ~exist([filePathOutput,'\V'],'dir'),
    mkdir([filePathOutput,'\V']);
end
if ~exist([filePathOutput,'\tail'],'dir'),
    mkdir([filePathOutput,'\tail']);
end


% a var for lift angle 
saveAFewVar        = cell(1,1);
saveAFewVar{1}     = caseDescription;
% if select individual cylinder, modify here.
for i = 1:numOfCylinder   
    
    indexWidthSVCurrentEst = 11111;
    jPeakStart      = 1;
    jHoldEnd        = numOfPoint4Regression;
    jHoldEndLast    = 1;
    eventCounter    = 0;
    eventCounterRaw = 0;
    fprintf('\nProcessing for cylinder %i ', i);
    figure(2); bringFigToFromBackground(2, plotInForeground); 
    subplot(2,4,i, 'FontSize',6); hold('off'); grid('on'); box('on');
    
    set(gca, 'Ylim', [0 17]);
     
    if i == 1,
        title({['Case ',num2str(theNumOfFile),': Cylinder ', num2str(i)]; ['SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',smallSize);
    else
        title({['Cylinder ', num2str(i)]; ['SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',smallSize);
    end
    
    if i == 4,
        aaa=0;
    end
 
    subplot(2,4,i+4, 'FontSize',6); hold('off'); grid('on'); box('on');
    
%     subplot(2,1,2, 'FontSize',8);
%     plot(current(:,i)); 
%     title(['Current history for cylinder ', num2str(i), ' of case ', num2str(theNumOfFile)]);
%     xlabel('Sampling points'); grid('on');
%     axis('tight'); set(gca, 'Ylim', [0 17]);
%     ylabel('current [A]');
    
    bringFigToFromBackground(4, plotInForeground);
    bringFigToFromBackground(3, plotInForeground);
    bringFigToFromBackground(2, plotInForeground);
    bringFigToFromBackground(1, plotInForeground);    % get the first current profile by check if current > 4A
    
    j = get1stJumpIndex(current(:,i), 1, numOfAllCurrentPoint, 3);
    if j == 0,
        fprintf('\nWarning: no significant current profile found for event %i of cylinder %i.', eventCounterRaw, i);
        return;
    end
    j = max(1, j-111);

    if eventCounterRaw >= 56,
        aaa=0;
    end
    
    % do garbage collection to save run time memory for java
    freeMemory = java.lang.Runtime.getRuntime.freeMemory;
    if freeMemory < 32e6,
        java.lang.Runtime.getRuntime.gc
        fprintf('\nWarning: free memory too low (%i) and garbage colection performed (%i).\n', freeMemory, java.lang.Runtime.getRuntime.freeMemory);
    end
    
    peakCurrentMax   = -1e33;
    valleyCurrentMin =  1e33;
    angleSVClose     = [-1e33 -1e33];
    angleMVOpen      = [-1e33 -1e33];
    liftMVMax        = [0 0];
    
    figure(2); bringFigToFromBackground(2, plotInForeground);
    hdlCurrenti  = subplot(2,4,i, 'FontSize',6); 
    hdldCurrenti = subplot(2,4,i+4, 'FontSize',6);
   if plot4Report>0,
        set(hdlCurrenti, 'XTickLabel',[]);
        pos = get(hdldCurrenti, 'Position');
        set(hdldCurrenti, 'Position', [pos(1) pos(2)+0.15 pos(3) pos(4)]);
    end    
    while j<numOfAllCurrentPoint-0.06*indexWidthSVCurrentEst && eventCounterRaw<=5, % plot4Report+1, % we limit to 15 event here
        
        if eventCounterRaw > 15,
            aaa=0;
        end
        
        eventCounterRaw = eventCounterRaw + 1;
        eventCounter    = eventCounter    + 1;
        
        if mod(eventCounter,5) == 0,
            fprintf('.');
        end
        
        if  eventCounterRaw > 57,
            aaa=0;
        end

        peakCurrentMax    = -1e33;
        valleyCurrentMin  =  1e33;
        angleSVClose      = -1e33;
        angleMVOpen       = [-1e33 -1e33];
        angleMVClose      = [-1e33 -1e33];
        liftMVMax         = [0 0];
        AngleMax1stDeriv  = 0;
        angleSVBiasStart  = 0;
        angleSVPushStart  = 0;
        angleVShapeValley = 0;
        
        if eventCounter>=2,
            iLift = 1;
            fprintf('%\n6i %6i %6i %6i\n', eventCounter, eventCounterRaw, j , numOfAllCurrentPoint);
            statisticResult{4}{i, eventCounter-1,1} = landmark{eventCounter-1,i,1}; % V-Shape
            statisticResult{4}{i, eventCounter-1,2} = landmark{eventCounter-1,i,2}; % tail
            statisticResult{5}{i, eventCounter-1}   = [peakCurrentMax, valleyCurrentMin, angleSVClose, angleMVOpen(iLift), liftMVMax(1)]; % misc statistics, angle infor by acceleration signal
        end
        % plot derivative info
        if eventCounter == 3,
            indexWidthSVCurrentEst = jHoldEnd-jPushStart + 111;
        end
%         if eventCounterRaw == -2,
%             % make a short linear regression result here
%             eee    = zeros(1,numOfAllCurrentPoint);
%             numOfPoint2Use = numOfPoint4Regression + 4;
%             iStart = max(numOfPoint2Use, j+6666);
%             iEnd   = min(j+33333,numOfAllCurrentPoint);
%             for i1 = iStart:iEnd
%                 eee(i1) = gradientDifference(current(:,i), i1, 1, numOfPoint2Use);
%             end
%             if moreOutput,
%                 figure(1); bringFigToFromBackground(1, plotInForeground); hold(hdlOfPlot(i), 'on');
%                 plot(hdlOfPlot(i), 1000*time1, 10*eee, 'b-');
%                 set(hdlOfPlot(i), 'XLim',1000*[time1(iStart), time1(iEnd)]);
%                 
%                 drawnow; pause(0.01);
%             end
%         end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                        process current V-shape first
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % search hold phase end. 25000-points are about 720�CA
%         if jHoldEnd == 0, % if last jHoldEnd was not found
%             jStop2Search = j + 40000;
%         else   % if last jHoldEnd was found
%             jStop2Search = j + 25000;
%         end
        jStop2Search = get1stJumpIndex(current(:,i), j+111, numOfAllCurrentPoint, -2.5);
        if jStop2Search == 0,
            fprintf('\nWarning: no significant current profile found for event %i of cylinder %i.', eventCounterRaw, i);
            break;
        end
        jStop2Search = min(jStop2Search+111, numOfAllCurrentPoint);
        jHoldEndLast = max(1, jHoldEnd);
 
        jHoldEnd     = getHoldEnd(current(:,i), j, -1, jStop2Search, numOfPoint4Regression+4, thresHoldEnd2D, thresHoldEndOrien, thresHoldEndSTD);
        title(hdlOfPlot(1), ['Current history around event ', num2str(eventCounter), ' for cylinder ', num2str(i), ' of case ', num2str(theNumOfFile) ], 'FontSize',9);
        
        if jHoldEnd == 0,
            if numOfAllCurrentPoint-j < 3*indexWidthSVCurrentEst,
                % it is approaching the last points, therefore go to next cylinder
                j               = numOfPoint4Regression*2;
                break
            else                
                % if eventCounterRaw ~= 1,
                fprintf('\nWarning: no landmark found for jHoldEnd for event %i of cylinder %i and go to next event.', eventCounterRaw, i);
                % end
                j = jStop2Search + 400;
                % j = get1stJumpIndex(current(:,i), jStop2Search + 900, numOfAllCurrentPoint, 3);
                if j >= numOfAllCurrentPoint-111, % if j is approaching the last break it
                    break;
                end
                eventCounter = eventCounter - 1;
                continue;
            end
        else
            j = jHoldEnd + 900; % shift a litte to search for next current profile
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jHoldEnd),      current(jHoldEnd,i),      'rv', 'MarkerSize',3); hold on;
                % if it fails to get hold phase end, check if the curve after is flat by linear regression
                % ... ...
                drawnow;
            end
        end
        

       
        
        
        
        % search peak phase end
        jPeakEnd = get2ndPeak(current(:,i), jHoldEnd-5*numOfPoint4Regression, -1, jHoldEndLast, 4*numOfPoint4Regression, ...
            thresPeakEnd, thresPeakEndOrien, thresPeakEndSTD);
        
        if jPeakEnd <= 40,
            aaa=0;
            if eventCounterRaw ~= 1,
                fprintf('\nWarning: no landmark found for jPeakEnd for event %i of cylinder %i and go to next event.', eventCounterRaw,i);
            end
            j = get1stJumpIndex(current(:,i), jHoldEnd + 900, numOfAllCurrentPoint, 3);
%             eventCounterRaw = eventCounterRaw + 1;
            eventCounter = eventCounter - 1;
            continue;
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jPeakEnd),      current(jPeakEnd,i),      'rv', 'MarkerSize',3); hold on;
                
            end
        end
        
        
        
        jTpHLEnd     = getTpHLEnd(current(:,i), jPeakEnd, jHoldEnd);
         
        if jTpHLEnd == 0,
            if numOfAllCurrentPoint-j < 3*indexWidthSVCurrentEst,
                % it is approaching the last points, therefore go to next cylinder
                j               = numOfPoint4Regression*2;
                break
            else                
                % if eventCounterRaw ~= 1,
                fprintf('\nWarning: no landmark found for jTpHLEnd for event %i of cylinder %i and go to next event.', eventCounterRaw, i);
                % end
                j = jStop2Search + 400;
                % j = get1stJumpIndex(current(:,i), jStop2Search + 900, numOfAllCurrentPoint, 3);
                if j >= numOfAllCurrentPoint-111, % if j is approaching the last break it
                    break;
                end
                eventCounter = eventCounter - 1;
                continue;
            end
        else
            j = jHoldEnd + 900; % shift a litte to search for next current profile
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jTpHLEnd),      current(jTpHLEnd,i),      'mv', 'MarkerSize',3); hold on;
                % if it fails to get hold phase end, check if the curve after is flat by linear regression
                % ... ...
                drawnow;
            end
        end       
        
        
        
        
        
        
        % aaa=1000*(time1(jTpHLEnd)-time1(jPeakEnd))
 
        
        
        
        
        
        % search peak phase start by linearRegression
        jPeakStart = get1stPeak(current(:,i), jPeakEnd, -1, jHoldEndLast, 7*numOfPoint4Regression, thresPeakStart, thresPeakStartOrien, 0.15);
        if jPeakStart == 0,
            fprintf('\nWarning: no landmark found for jPeakStart for event %i of cylinder %i and go to next event.', eventCounterRaw,i);
            j = get1stJumpIndex(current(:,i), jHoldEnd + 900, numOfAllCurrentPoint, 3);
%             eventCounterRaw = eventCounterRaw + 1;
            eventCounter = eventCounter - 1;
            continue;
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jPeakStart),    current(jPeakStart,i),    'rv', 'MarkerSize',3); hold on;
            end
        end
        % search V-shape lower tip by minimal between peak start and end
        [tmp, jVShapeValley] = getMinAndIndex(current(jPeakStart:jPeakEnd,i), 1, jPeakEnd-jPeakStart+1);
        if jVShapeValley == 0,
            fprintf('\nWarning:  no landmark found for jVShapeValley for event %i of cylinder %i and go to next event.', eventCounterRaw);
            j = get1stJumpIndex(current(:,i), jHoldEnd + 900, numOfAllCurrentPoint, 3);
%             eventCounterRaw = eventCounterRaw + 1;
            eventCounter = eventCounter - 1;
            continue;
        else
            jVShapeValley = jPeakStart+jVShapeValley-1;
            currentAtValley = mean(current(jVShapeValley-numOfPoint2Select:jVShapeValley+numOfPoint2Select,i));
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jVShapeValley), currentAtValley, 'r^', 'MarkerSize',3); hold on;
            end
        end
         
        % search bias end (Push Start)  by linearRegression
        jPushStart = getPushStart(current(:,i), jPeakStart-22, -1, max(jHoldEndLast,jPeakStart-1444), numOfPoint4Regression+8, thresPushStart, thresPushStartOrien, thresPushStartSTD);
        if jPushStart == 0,
            fprintf('\nWarning: no landmark found for jPushStart for event %i of cylinder %i and go to next event.', eventCounterRaw,i);
%             eventCounterRaw = eventCounterRaw + 1;
            j = get1stJumpIndex(current(:,i), jHoldEnd + 900, numOfAllCurrentPoint, 3);
           eventCounter = eventCounter - 1;
           continue;
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jPushStart),    current(jPushStart,i),    'rv', 'MarkerSize',3); hold on;
            end
        end

        % search bias start
        jBiasStart = getBiasStart(current(:,i), jPushStart-22, -1, max(jHoldEndLast,jPushStart-4444), numOfPoint4Regression+8, 0.09, thresPushStartOrien, thresPushStartSTD);
        if jBiasStart == 0,
            fprintf('\nWarning: no landmark found for jBiasStart for event %i of cylinder %i and go to next event.', eventCounterRaw,i);
            j = get1stJumpIndex(current(:,i), jHoldEnd + 900, numOfAllCurrentPoint, 3);
            eventCounter = eventCounter - 1;
            continue;
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jBiasStart),    current(jBiasStart,i),    'rv', 'MarkerSize',3); hold on;
            end
        end

        % correct PeakStart by max between jPushStart and jVShapeValley
        timeTmp    = time1(jPeakStart);
        [yPeakStart jPeakStart1]   = getMaxAndIndex(current(jPushStart:jVShapeValley,i), 1, jVShapeValley-jPushStart+1);
        if abs(time1(jPushStart+jPeakStart1-1)-timeTmp) > 1e-6,
            % fprintf('\nPeak start time modified from %8.3f to %8.3f [ms]\n', 1000*timeTmp, 1000*time1(jPushStart+jPeakStart1-1));
            jPeakStart = jPushStart+jPeakStart1-1;
        end
        

% make some corrections to jPeakStart by min/max method
%         timeTmp    = time1(jPeakStart);
%         [tmp, jPeakStart1] = getMaxAndIndex(current(jPushStart:jVShapeValley,i), 1, jVShapeValley-jPushStart+1);
%         
%         if abs(time1(jPushStart+jPeakStart1-1)-timeTmp) > 1e-6,
%             % fprintf('\nPeak start time modified from %8.3f to %8.3f [ms] at event %i for cylinder %i\n', ...
%             %    1000*timeTmp, 1000*time1(jPushStart+jPeakStart1-1), eventCounter, i);
%             jPeakStart = jPushStart+jPeakStart1-1;
%             if moreOutput,
%                 figure(1); bringFigToFromBackground(1, plotInForeground); 
%                 subplot(4,1,i, 'FontSize',8); hold on;
%                 plot(1000*time1(jPeakStart),    current(jPeakStart,i),    'mv', 'MarkerSize',3); hold on;
%             end
%         end
        
        dt = mean(diff(time1(jPushStart:jVShapeValley)));

        % search a better min if the min above is too close to the right
        % better min: first derivative goes from negtive to positive
        if jVShapeValley-jPeakStart > 3*(jPeakEnd-jVShapeValley),
            [currentAtValley1 jVShapeValley1] = getBetterMin(jPeakStart, jVShapeValley, dt, current(:,i));
                
            if jVShapeValley1 < jVShapeValley && jVShapeValley1 ~= 0,
                currentAtValley = currentAtValley1;
                jVShapeValley   = jVShapeValley1;
                
                if moreOutput,
                    figure(1); bringFigToFromBackground(1, plotInForeground); 
                    subplot(4,1,i, 'FontSize',8); hold on;
                    plot(1000*time1(jVShapeValley), currentAtValley, 'm^', 'MarkerSize',3); hold on;
                end
            end
        end
        % collect some min/max values for statistics
        peakCurrentMax   = max(current(jPeakStart,i), current(jPeakEnd,i));
        valleyCurrentMin = current(jVShapeValley,i);
        
        % get the sharpness of 1st peak
        [tmp, gbfore gafter]  = gradientDifference(current(:,i), jPeakStart, dt, numOfPoint4Regression+1, numOfPoint4Regression+16, 1, -1);
        sharpness41stPeak     = (gafter-gbfore)/(1+gafter*gbfore);
%         [tmp, gbfore gafter]  = gradientDifference(current(:,i), jPeakStart, dt, numOfPoint4Regression+1, 2);
%         sharpness41stPeakPeak = (gafter-gbfore)/(1+gafter*gbfore);
        
        % peak current at jPeakEnd can be flat, so do not do correction
        %         timeTmp    = time1(jPeakEnd);
        %         [yPeakStart jPeakEnd1]   = getMaxAndIndex(current(jVShapeValley:jHoldEnd,i), 1, jHoldEnd-jVShapeValley+1);
        %         if abs(time1(jVShapeValley+jPeakEnd1-1)-timeTmp) > 1e-6,
        %             fprintf('\nPeak end time modified from %8.3f to %8.3f [ms]\n', 1000*timeTmp, 1000*time1(jVShapeValley+jPeakEnd1-1));
        %             jPeakEnd = jVShapeValley+jPeakEnd1-1;
        %         end
        
        if ...
                0 == plausibilitCheck1(i, eventCounter, jPushStart, jPeakStart, jVShapeValley, jPeakEnd, jHoldEnd) || ...
                0 == plausibilitCheck2(i, eventCounter, current(:,i), jPushStart, jPeakStart, jVShapeValley, jPeakEnd, jHoldEnd),
            fprintf('\nWarning: no plausible landmark for event %i of cylinder %i but continue.', eventCounterRaw, i);
%             j = get1stJumpIndex(current(:,i), jHoldEnd, numOfAllCurrentPoint, 2);
%             eventCounterRaw = eventCounterRaw + 1;
%             continue;
        end
        if 0 == plausibilitCheck3(i, eventCounter, current(:,i),jPushStart, jPeakStart, jVShapeValley, jPeakEnd, jHoldEnd),
            fprintf('\nWarning: No V-Shape for event %i of cylinder %i (plausi check 3) but continue.', eventCounterRaw, i);
%             j = get1stJumpIndex(current(:,i), jHoldEnd, numOfAllCurrentPoint, 2);
%             eventCounterRaw = eventCounterRaw + 1;
%             continue;
        end
        
%         figure(2); bringFigToFromBackground(2, plotInForeground); 
%         hdlCurrenti = subplot(2,4,i, 'FontSize',6); hold on;
        % collect V-shape together
        if moreOutput || eventCounterRaw<=2 || eventCounterRaw == plot4Report,
            
            % ---------- plot current ----------
            % hdlCurrenti = subplot(2,4,i, 'FontSize',6); hold on;
            posPlot = get(hdlCurrenti, 'Position');
            set(hdlCurrenti, 'Position',[posPlot(1) posPlot(2) 0.1316 posPlot(4)]);
            iMin0   = jPushStart-22*0; % start a little earlier
            iLeft1  = max(1, iMin0);
            iRight1 = min(jPeakEnd+222, length(current(:,i)));
            axes(hdlCurrenti); bringFigToFromBackground(2, plotInForeground);
            plot((1:iRight1-iLeft1+1), current(iLeft1:iRight1,i), '-', 'Color',myColor(i,:)); hold('on');
            
            if eventCounterRaw == plot4Report, 
                axes(hdlCurrenti); bringFigToFromBackground(2, plotInForeground);
                hold off;
                plot((1:iRight1-iLeft1+1), current(iLeft1:iRight1,i), '-', 'Color',myColor(i,:)); hold('on');
                xlabel(''); set(gca, 'XTickLabel', []);
            end
            box('on');  grid('on');
           
            axis([0 iRight1-iLeft1+1 0 18]); hold('on');
            
            hdlOfYLable = ylabel('Current [A]', 'FontSize',normSize);
            posYLabel   = get(hdlOfYLable, 'Position');
            set(hdlOfYLable, 'Position',[-111, posYLabel(2), posYLabel(3)]);
            
            if plot4Report>0,
                set(hdlCurrenti, 'XTickLabel',[]);
            else
                xlabel('Sampling points', 'FontSize',8);
            end
            sameAxis = axis;
            
            % no subplot(2,4,i+4) after this point, or we destroy ax2

            % ---------- plot acceleration then lift ----------
            
            if eventCounterRaw == 4 || eventCounterRaw == plot4Report,   % plot only onece: make it more than 3
                % hdldCurrenti = subplot(2,4,i+4, 'FontSize',6); 
                if plot4Report>0, % do this only for other report
                    posPlot = get(hdldCurrenti, 'Position');
                    set(hdldCurrenti, 'Position',[posPlot(1) posPlot(2) 0.1316 posPlot(4)]);
                else
                    posPlot = get(hdldCurrenti, 'Position');
                    set(hdldCurrenti, 'Position',[posPlot(1) posPlot(2)  0.1316 posPlot(4)]);
                    
                end
                axes(hdldCurrenti); bringFigToFromBackground(2, plotInForeground);
                hold off;
                % set(hdldCurrenti, 'XTickLabel',[], 'YTickLabel',[]);
                [ax2, h21, h22] = plotyy((1:iRight1-iLeft1+1),zeros(1,iRight1-iLeft1+1), (1:iRight1-iLeft1+1),zeros(1,iRight1-iLeft1+1));
                set(ax2(2), 'XTickLabel',[]);
                titleText1 = '';
                titleText2 = '';

                % plot acceleration signal at top plot
                if ~isempty(accel{i,1}),  % no data no plot 
                    if length(accel{i,1})==numOfAllAcclPoint,   % avoid an accl signal with wrong number of points
                        % subplot(2,4,i, 'FontSize',6); hold on;

                        accelMax  = max(accel{i,1}(jPushStart:jHoldEnd));
                        accelMin  = min(accel{i,1}(jPushStart:jHoldEnd));
                        accelMean = mean(accel{i,1}(jPushStart:jHoldEnd));
                        if accelMax-accelMin > 0.1,
                            % axes(hdlCurrenti);
                            plot(hdlCurrenti, (1:iRight1-iLeft1+1), (accel{i,1}(iLeft1:iRight1)-accelMean)/8000 + round(current(jPeakStart,i)+1),'b');
                        end
                    end
                end
                
                if ~isempty(accel{i,1}) && accelMax-accelMin > 0.1 && length(accel{i,1})==numOfAllAcclPoint, % avoid an accl signal with wrong number of points
                    axes(hdldCurrenti); bringFigToFromBackground(2, plotInForeground);
%                     if plot4Report == 0,
%                         hold(ax2(1), 'on');
%                         plot(ax2(1), (1:iRight1-iLeft1+1), accel{i,1}(iLeft1:iRight1)*2, 'b');
%                         % axis(ax2(1), [0 iRight1-iLeft1 -1e5 1e4]);
%                         set(ax2(1), 'XLim',[0 iRight1-iLeft1], );
%                         set(ax2(1), 'YColor',[1 0 0], 'FontSize',6, 'XTickLabel',[]);
%                     else 
                        accelMax = max(abs(accel{i,1}(iLeft1:iRight1)));
                        axes(hdldCurrenti); bringFigToFromBackground(2, plotInForeground); % hold(ax2(2), 'on');
                        [ax2, h21, h22] = plotyy((1:iRight1-iLeft1+1),zeros(1,iRight1-iLeft1+1), (1:iRight1-iLeft1+1), accel{i,1}(iLeft1:iRight1)/accelMax);
                        set(h22, 'Color', [0 0 1]);
                        % h22 = line((1:iRight1-iLeft1+1), accel{i,1}(iLeft1:iRight1)/accelMax, 'Color','b','Parent',ax2(2));
                        % set(2, 'CurrentAxes', ax2(2));
                        % set(h22, 'XData',[1:iRight1-iLeft1+1], 'YData',accel{i,1}(iLeft1:iRight1)/accelMax,'ZData',zeros(1, iRight1-iLeft1+1));

                        % plot(ax2(2), (1:iRight1-iLeft1+1), accel{i,1}(iLeft1:iRight1)/accelMax, 'b');
%                    end
                end
                % subplot(2,4,i+4, 'FontSize',6);  % xxxx
                grid('on'); box('on'); 
                % xlabel('Sampling points', 'FontSize',8);  not working !
                
                % ---------- plot 1. lift
                if ~isempty(lift{i,1}) && plot4Report == 0,
                    hold(ax2(1), 'on');
                    iRight2 = min(iRight1, length(lift{i,1}));
                    plot(ax2(1), (1:iRight2-iLeft1+1),lift{i,1}(iLeft1:iRight2)*10, 'r');
                    if abs(lift{i,1}(iRight2))<0.1,
                        indexTmp = iRight2 - iLeft1;
                        hold(ax2(1), 'on');  
                        plot(ax2(1), (1:iRight2-iLeft1+1),lift{i,1}(iRight2:iRight2+indexTmp)*10, 'r');
                        % axis(ax2(2), [0 iRight1-iLeft1 -1 1]);
                        % set(ax2(2), 'YTickLabel',[]);
                    end
                end
                % ---------- plot 2. lift
                if ~isempty(lift{i,2}) && plot4Report == 0,
                    hold(ax2(1), 'on');
                    iRight2 = min(iRight1, length(lift{i,2}));
                    plot(ax2(1), lift{i,2}(iLeft1:iRight2)*10,'r');
                    if abs(lift{i,1}(iRight1))<0.1,  % rewind back for the next
                        indexTmp = iRight2 - iLeft1;
                        hold(ax2(1), 'on');  
                        plot(ax2(1), (1:iRight2-iLeft1+1),lift{i,2}(iRight2:iRight2+indexTmp)*10, 'r');
                    end
                    % axis(ax2(2), [0 iRight1-iLeft1 -1 1]);
                    % set(ax2(2), 'YTickLabel',[]);
                end

                % axes(hdldCurrenti);
%                 if plot4Report == 0,
%                     % get the first derivative for push phase
%                     hold(ax2(2), 'on');
%                     plot(ax2(2), (1:jPeakStart-iLeft1+0),5*smoothOut(diff(smoothOut((current(iLeft1:jPeakStart,i)),2)),2), 'k-');
%                     hdlOfLabel = get(ax2(1),'Ylabel'); sameAxis = get(hdlOfLabel, 'Position');
%                     % do only ylabel
%                     set(hdlOfLabel,'String','Acceleration, dI/dt', 'FontSize',8, 'Color','b', ...
%                         'Position',[sameAxis(1)+80, sameAxis(2), sameAxis(3)]);
%                     sameAxis   = get(hdlOfLabel, 'Position');
%                     hdlOfLabel = get(ax2(2),'Ylabel');
%                     set(hdlOfLabel,'String','MV lift at close and open', 'FontSize',8, 'Color','r');
%                     sameAxis   = get(hdlOfLabel, 'Position');
%                     set(hdlOfLabel, 'Position',[sameAxis(1)-33, sameAxis(2), sameAxis(3)]);
%                     hdlOfLabel = get(ax2(1),'Xlabel');
%                     set(hdlOfLabel,'String','Sampling points', 'FontSize',8, 'Color','k');
%                 else
                    % get the first derivative for push phase
                    hold(ax2(1), 'on');
                    % firstDerivAtPush  = smoothOut(diff(smoothOut((current(iLeft1:jPeakStart+33,i)),2)),2);
                    firstDerivAtPush  = smoothOut(diff(current(iLeft1:jPeakStart+33,i)),4);
                    % secondDerivAtPush = smoothOut(diff(current(iLeft1:jPeakStart+33,i),2),6);
                    % secondDerivAtPush = diff(firstDerivAtPush);
                    secondDerivAtPush = smoothOut(diff(firstDerivAtPush),2);
                    
                    if angleBasedData == 0,
                        firstDerivAtPush  = firstDerivAtPush  ./ (diff(time1(iLeft1:jPeakStart+33)))' / 1000;   % [A/ms]
                        secondDerivAtPush = secondDerivAtPush ./ (diff(time1(iLeft1:iLeft1+length(secondDerivAtPush))))' / 1000;  % [A/ms^2]                        
                    else
                        firstDerivAtPush  = firstDerivAtPush*100;  % [cA/CA]
                        secondDerivAtPush = secondDerivAtPush*100; % [cA/CA^2]
                    end
                    hold(ax2(1),'on');
                    plot(ax2(1), (1:jPeakStart-iLeft1+1), firstDerivAtPush(1:jPeakStart-iLeft1+1),  'r-');
                    hold(ax2(1),'on');
                    plot(ax2(1), (1:jPeakStart-iLeft1-6), 10+5*secondDerivAtPush(1:jPeakStart-iLeft1-6), 'k-');
                    set(ax2(1), 'YTickMode', 'auto', 'YLim',[0 20]);
                    % [iRight1, iLeft1]
                    set(ax2(1), 'XTickMode', 'auto', 'XLim',[0 iRight1-iLeft1]);
                    hdlOfLabel = get(ax2(1),'Ylabel'); 
                    sameAxis   = get(hdlOfLabel, 'Position'); 
                    set(hdlOfLabel, 'Position',[sameAxis(1)+40, sameAxis(2), sameAxis(3)]);
                    
                    % draw a threshold and right border for firstDerivAtPush
                    % h31 = line([11 jPeakStart-iLeft1],    [10    10]+2, 'Color','g', 'LineStyle','--', 'LineWidth',2,   'Parent',ax2(1));
                    h41 = line([1 1]*(jPeakStart-iLeft1), [17.5  20]+0, 'Color','k', 'LineStyle',':',  'LineWidth',0.5, 'Parent',ax2(1));
                    h51 = line([1 1]*(jPeakStart-iLeft1), [9.6 10.4]+2, 'Color','k', 'LineStyle','-',  'LineWidth',0.5, 'Parent',ax2(1));
                    
                    if plot4Report == 0  && angleBasedData == 0 && i == 1,
                        set(hdlOfLabel, 'String','dI/dt[A/ms] d2I/dt2[A/ms2] lift[mm]', 'FontSize',8, 'Color','r');
                    elseif plot4Report > 0  && angleBasedData == 0,
                        set(hdlOfLabel, 'String','dI/dt d2I/dt2 lift', 'FontSize',normSize, 'Color','r');
                    elseif plot4Report == 0  && angleBasedData == 1,
                        set(hdlOfLabel, 'String','dI/dt[cA/CA] d2I/dt2[cA/CA2] lift[mm]', 'FontSize',8, 'Color','r');
                    elseif plot4Report > 0  && angleBasedData == 1,
                        set(hdlOfLabel, 'String','dI/dt d2I/dt2', 'FontSize',normSize, 'Color','r');
                    end
                    
                    set(ax2(1), 'YColor',[1 0 0], 'FontSize',6);
                    grid(ax2(1),'on');
                    
                    % get the acceleration right
                    set(ax2(2), 'YTickMode', 'auto', 'YLim',[-8 2]);
                    set(ax2(2), 'XTickMode', 'auto', 'XLim',[0 iRight1-iLeft1]);
                    set(ax2(2), 'YColor',[0 0 1], 'FontSize',6);
                    hdlOfLabel = get(ax2(2),'Ylabel'); sameAxis = get(hdlOfLabel, 'Position');
                    
                    if i == numOfCylinder,
                        set(hdlOfLabel,'String','Acceleration', 'FontSize',normSize, 'Color','b');
                    end
                    sameAxis   = get(hdlOfLabel, 'Position');
                    set(hdlOfLabel, 'Position',[sameAxis(1)-22, sameAxis(2), sameAxis(3)]);
                    hdlOfLabel = get(ax2(1),'Xlabel');
                    set(hdlOfLabel,'String','Sampling points', 'FontSize',normSize, 'Color','k');
                    grid(ax2(2),'on');
                    
                    if plot4Report > 0,
                        break;
                    end
%                 end
            end
            jRef4EstimatedCA = jHoldEnd;
            jSVClose         = jRef4EstimatedCA;
            if eventCounterRaw >= 1,
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % get SV close angle by acceleration signal related to time1(jHoldEnd)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ~isempty(accel{i,1}),
                    
                    for kk = jPushStart:min(2*jHoldEnd-jPushStart, length(accel{i,1})-55)
                        % if the average of next few point higher than a threshold
                        % [numOfAllCurrentPoint, kk, i]
                        if sum(abs(accel{i,1}(kk:kk+55)))/55 >= 660,
                            jSVClose = kk;
                            break;
                        end
                    end
                    if jSVClose ~= jRef4EstimatedCA && jSVClose<=length(time1),  % in case jSVClose is too big
                        if angleBasedData == 0,
                            angleSVClose = round(100*6*str2double(caseDescription{6,2})*(time1(jSVClose)-time1(jRef4EstimatedCA)))/100;
                        else
                            angleSVClose = time1(jSVClose);
                        end
                        titleText1   = ['SV closes at: ', num2str(angleSVClose), '[�CA]'];
                    else
                        angleSVClose = 0;
                        titleText1   = [''];
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % get MV1 open angle by lift signal related to time1(jRef4EstimatedCA)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ~isempty(lift{i,1}),
                    jMVOpen    = [jRef4EstimatedCA jRef4EstimatedCA];
                    jMVClose   = [jRef4EstimatedCA jRef4EstimatedCA];
                    liftMVMax  = [0 0];
                    
                    iLift = 1;
                    while iLift <= 2 && ~isempty(lift{i,iLift}),
                        jSearchMax = min(min(2*jHoldEnd-jPushStart, numOfAllCurrentPoint), length(lift{i,iLift})-11);
                        for kk = jPushStart:jSearchMax
                            if mean(abs(lift{i,iLift}(kk:kk+11))) >= 0.02,  % 0.04 0.1
                                jMVOpen(iLift) = kk;
                                break;
                            end
                        end
                        % find lift max
                        if jPushStart<jSearchMax,
                            [liftMVMax(iLift) indexLiftMVMax] = max(lift{i,iLift}(jPushStart:jSearchMax));
                            indexLiftMVMax                    = indexLiftMVMax + jPushStart-1;
                            angleLiftMVMax(iLift)             = time1(indexLiftMVMax);
                            liftMVMax                         = round(100*liftMVMax)/100;
                        else
                            indexLiftMVMax = 1
                            angleLiftMVMax(iLift)             = 0;
                            liftMVMax      = -1e33;
                        end
                        % find lift end
                        jSearchMax = min(2*jHoldEnd-jPeakStart, length(lift{i,iLift})-11);
                        for kk = jHoldEnd:jSearchMax
                            if mean(abs(lift{i,iLift}(kk:kk+11))) <= 0.02,  % 0.04 0.1
                                jMVClose(iLift) = kk;
                                break;
                            end
                        end
                        
                        % we found an MV open and close point
                        if jMVOpen(iLift) ~= jRef4EstimatedCA,
                            if angleBasedData == 0,
                                angleMVOpen(iLift) = round(100*6*str2double(caseDescription{6,2})*(time1(jMVOpen(iLift))-time1(jRef4EstimatedCA)))/100;
                            else
                                angleMVOpen(iLift) = time1(jMVOpen(iLift));
                            end
                            titleText2         = ['MV opens:', num2str(angleMVOpen(iLift)), '[�CA] with max:', num2str(liftMVMax)];
                        else
                            angleMVOpen(iLift) = 0;
                            titleText2         = [''];
                        end
                        if jMVClose(iLift) ~= jRef4EstimatedCA,
                            if angleBasedData == 0,
                                angleMVClose(iLift) = round(100*6*str2double(caseDescription{6,2})*(time1(jMVClose(iLift))-time1(jRef4EstimatedCA)))/100;
                            else
                                angleMVClose(iLift) = time1(jMVClose(iLift));
                            end
                        else
                            angleMVClose(iLift) = 0;
                            titleText2         = [''];
                        end
                        
                        iLift = iLift + 1;
                    end
                end  
                % get the max position of the first derivative od current
                % of push phase
                
                % smoothOut(diff(smoothOut((current(iLeft1:jPeakStart,i)),2)),2)
                iMin0    = jPushStart-22; % start a little earlier
                iLeft1   = max(1, iMin0);
                iMiddle1 = floor((iLeft1+jPeakStart)/2);
                [tmp, indexMax]  = max(smoothOut(diff(smoothOut((current(iMiddle1:jPeakStart,i)),2)),2));
                % if the max is at left, ignore it
                if indexMax<floor((jPeakStart-iMiddle1)/2),
                    indexMax = jRef4EstimatedCA;
                else
                    indexMax = indexMax + iMiddle1-1;
                end
                
                indexMax = min(indexMax, numOfAllCurrentPoint);
                
                angleSVPushStart  = time1(jPushStart);
                angleSVBiasStart  = time1(jBiasStart);
                angleVShapeValley = time1(jVShapeValley);
                
%                 if angleBasedData == 0,
%                     AngleMax1stDeriv = round(6*str2double(caseDescription{6,2})*(time1(indexMax)-time1(jSVClose)));
%                 else
                AngleMax1stDeriv = time1(indexMax) - 0*time1(min(numOfAllCurrentPoint, jSVClose));
%                 end
                saveAFewVar{2}{i,eventCounter} = [current(jPeakStart,i), angleSVClose, angleMVOpen, angleMVClose, mean(angleLiftMVMax), AngleMax1stDeriv, angleSVBiasStart, angleSVPushStart, angleVShapeValley];
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


                if (~isempty(lift{i,1}) || ~isempty(accel{i,1})) && eventCounterRaw == 4 && plot4Report == 0,
                    % set(2, 'CurrentAxes', ax2(1));
                    % axes(ax2(1)); bringFigToFromBackground(2, plotInForeground);
                    title(ax2(1), {titleText1; titleText2}, 'FontSize',normSize);
                    titleText1 = '';
                    titleText2 = '';
                end
           
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%% plot landmarks for V-shape %%%%%%%%%%%%%%%%%%%%%%%%%%%
        if plotAllVs >= 1,
            yLimit = plotLandmark4V(plotAllVs, i, current, landmark, yLimit, eventCounter, eventCounterRaw, jPushStart, jPeakStart, ...
                jVShapeValley, jPeakEnd, jTpHLEnd, jHoldEnd, numOfBackwardCount4PushPhase, sharpness41stPeak, currentAtValley, delayDeviate, ...
                threshold4DeviateDetect, numOfSample4Area1AtPush, time1, samplingTime, caseDescription, ...
                theNumOfFile, plotInForeground);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if i <= 4,
                set(hdlOfPlot(1), 'Xlim',1000*time1([max(1,jPushStart-33333), ...
                    min(jHoldEnd+33333,numOfAllCurrentPoint)]));
                drawnow;
                pause(0.01);
            end
            plotIt = plotItAll;
        end
        
        % count V-Shape analysis successful
        numOfvalidAnalysis(i) = numOfvalidAnalysis(i) + 1;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                           process current tail
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        jTailEnd = getLowerEdge(current(:,i), jHoldEnd+222-72, 1, ...
            jHoldEnd+floor(max(1111, 0.5*indexWidthSVCurrentEst)), ...
            numOfPoint4Regression, thresTailEnd, 0.08, 0.1);
        
        if jTailEnd == 0,
            if numOfAllCurrentPoint-j < 0.5*indexWidthSVCurrentEst,
                % it is approaching the last points, therefore go to next cylinder
                j = numOfPoint4Regression*2;
%                 if j == 0,
%                     fprintf('\nWarning: no significant current profile found for cylinder %i after event %i.', i, eventCounterRaw);
%                     return;
%                 end
%                 
                break; % break for next cylinder
            else
                % comment out to save some time
                fprintf('\nWarning: no landmark found for jTailEnd for event %i of cylinder %i (%i) and go to next event.', eventCounterRaw,i,jHoldEnd);
                j = get1stJumpIndex(current(:,i), jHoldEnd+900, numOfAllCurrentPoint, 3);
               
%                 eventCounterRaw = eventCounterRaw + 1;
%                 eventCounter    = eventCounter    + 1;
                 continue;  % continue to next event
            end
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jTailEnd),      current(jTailEnd,i),      'gv', 'MarkerSize',3); hold on;
            end
        end
            
        % get tail start
        jTailStart = getLowerEdge(current(:,i), jTailEnd-22, -1, jHoldEnd, ...
            numOfPoint4Regression+4, thresTailStart, thresTailStartOrien, thresTailStartSTD);
        if  jTailStart == 0,
            fprintf('\nWarning: no landmark found for jTailStart for event %i of cylinder %i and go to next event.', eventCounterRaw, i);
%             eventCounterRaw = eventCounterRaw + 1;
%             eventCounter    = eventCounter    + 1;
            j = get1stJumpIndex(current(:,i), jHoldEnd+900, numOfAllCurrentPoint, 3);

            continue;
        else
            if moreOutput,
                figure(1); bringFigToFromBackground(1, plotInForeground); 
                subplot(4,1,i, 'FontSize',8); hold on;
                plot(1000*time1(jTailStart),    current(jTailStart,i),    'gv', 'MarkerSize',3); hold on;
            end
        end

        % get the max of tail
        [tmp, jTailMax] = getMaxAndIndex(current(jTailStart:jTailEnd,i), 1, jTailEnd-jTailStart+1);
        jTailMax        = jTailStart+jTailMax-1;
        jTailMid        = floor(jTailStart+(jTailEnd-jTailStart)/3);
        if 0 == plausibilitCheck4(i, eventCounter, current, jTailStart, jTailMax, jTailEnd),
            fprintf('\nWarning: tail current too high (%f No tail?) for event %i of cylinder %i and go to next event.', current(jTailMax,i), eventCounterRaw,i);
            j = get1stJumpIndex(current(:,i), jHoldEnd+900, numOfAllCurrentPoint, 3);
            continue;
        end

%         eventCounterRaw = eventCounterRaw + 1;
%         eventCounter    = eventCounter    + 1;
        
        % make a marker for Tail max
        if moreOutput,
            figure(1); bringFigToFromBackground(1, plotInForeground); 
            subplot(4,1,i, 'FontSize',8); hold on;
            plot(1000*time1(jTailMax),    current(jTailMax,i),    'kd', 'MarkerSize',3); hold on;
        end
              
        % do only one current profile and go out if we do other report
%         if plot4Report>0,
%             break;
%         end    
            
        % collect tail curve together
        if moreOutput && plot4Report == 0,
            figure(2); bringFigToFromBackground(2, plotInForeground); 
            % subplot(2,4,i, 'FontSize',6); hold on;
            % plot tail current 
            jTailAdvance2   = jTailStart-22*0; %  -55;
            jPeakShif2Left  = jPeakStart-iLeft1 -55; 
            tailIndex       = (jTailAdvance2:min(jTailEnd+44, length(current(:,i))));
            tailIndex       = tailIndex - tailIndex(1);
            plot(hdlCurrenti, jPeakShif2Left+1 + tailIndex, current(jTailAdvance2+tailIndex,i), '-', 'Color',myColor(i,:));
%           plot(jPeakStart-iMin0+(0:jTailEnd+22-jTailStart)', current(tailIndex,i), '-', 'Color',myColor(i,:));
            
            % plot acceleration for SV open
            if eventCounterRaw == 4 % 5, % make it more than 4
                iMax = min(jTailEnd+222,numOfAllAcclPoint);
                if ~isempty(accel{i,1}) && length(accel{i,1})==numOfAllAcclPoint, % avoid an accl signal with wrong number of points,
                    % plot acceleration at top plot
                    accelMax  = max(accel{i,1}(jTailAdvance2+tailIndex));
                    accelMin  = min(accel{i,1}(jTailAdvance2+tailIndex));
                    accelMean = mean(accel{i,1}(jTailAdvance2+tailIndex));
                    if accelMax-accelMin > 1,
                        hold('on');
                        plot(hdlCurrenti, jPeakShif2Left+1 + tailIndex, ...
                            (accel{i,1}(jTailAdvance2+tailIndex)-accelMean)/3000+3,'c');
                        
                        % plot acceleration at bottom plot
                        
                        hold(ax2(1), 'on');
                        plot(ax2(1),jPeakShif2Left+1 + tailIndex, ...
                            (accel{i,1}(jTailAdvance2+tailIndex)-accelMean)/1000+3,'c');
                    end
                end
                 
                iLift = 1;
                for iLift = 1:2
                    % plot first lift
                    if ~isempty(lift{i,iLift}) && jTailAdvance2+max(tailIndex)<length(lift{i,iLift}),  % also check if the schifting hoes too far
                        % iMax = min(jTailEnd+222,numOfLiftPoint);
                        % plot lift at bottom plot: right axis
                        hold(ax2(1), 'on');
                        % [jTailAdvance2 min(tailIndex) max(tailIndex) length(lift{i,iLift})]
                        plot(ax2(1), jPeakShif2Left+1 + tailIndex, ...
                            lift{i,iLift}(jTailAdvance2+tailIndex), 'm');  % use same scale
                        
                        indexTmp = max(tailIndex);
                        if abs(lift{i,iLift}(jTailAdvance2))<0.2, % lift is already gone
                            hold(ax2(1),'on');
                            plot(ax2(1), jPeakShif2Left+1 + tailIndex, ...
                                lift{i,iLift}((jTailAdvance2+tailIndex)-indexTmp), 'm');
                        end
                        if abs(lift{i,iLift}(jTailAdvance2-indexTmp))<0.2, % lift is already long gone
                            indexTmp = 2*max(tailIndex);
                            hold(ax2(2),'on');
                            plot(ax2(2), jPeakShif2Left+1 + tailIndex, ...
                                lift{i,iLift}((jTailAdvance2+tailIndex)-indexTmp), 'r');
                        end
                        if abs(lift{i,iLift}(jTailAdvance2-indexTmp))<0.2, % lift is already long gone
                            indexTmp = 3*max(tailIndex);
                            hold(ax2(2),'on');
                            plot(ax2(2), jPeakShif2Left+1 + tailIndex, ...
                                lift{i,iLift}((jTailAdvance2+tailIndex)-indexTmp), 'r');
                        end
                    end
                end
            end
        end
        
        if plotAllTails >= 1,
            %%%%%%%%%%%%%%%%%% plot landmarks for current tail %%%%%%%%%%%%%%%%
            yLimit = plotLandmark4Tail(plotAllTails, i, current, landmark, yLimit, eventCounter, eventCounterRaw, jTailStart, jTailMid, jTailMax, jTailEnd, numOfBackwardCount4PushPhase, sharpness41stPeak, currentAtValley, time1, samplingTime, caseDescription, ...
                theNumOfFile, plotInForeground);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % plotAllTails = 2;
        end
        
    end
    
    figure(2); 
    if i ~= numOfCylinder || plot4Report>0,
        bringFigToFromBackground(2, plotInForeground);
    end
    % subplot(2,4,i, 'FontSize',6); grid('on');
    axes(hdlCurrenti); bringFigToFromBackground(2, plotInForeground);
    if i == 1,
        if plot4Report > 0,
            title({['Case ',num2str(theNumOfFile),': Cylinder ', num2str(i), ' SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',normSize);
        else
            title({['Case ',num2str(theNumOfFile),': Cylinder ', num2str(i)]; ['SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',normSize);
        end
        
    else
        if plot4Report > 0,
            title({['Cylinder ', num2str(i), ' SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',normSize);
        else
            title({['Cylinder ', num2str(i)]; ['SV:',caseDescription{i+1,1},'(',num2str(numOfvalidAnalysis(i)),')']}, 'FontSize',normSize);
        end
    end

    % save the lift Sv angles for CR test
    aaa=0; 
end

if plot4Report == 0,
    bringFigToFromBackground(4, 'on');
    bringFigToFromBackground(3, 'on');
    bringFigToFromBackground(2, 'on');
    bringFigToFromBackground(1, 'on');
end
% close(4);
% close(3);
% close(2);
% close(1);

% make a dir if no exist
if ~exist(filePathOutput,'dir'),
    mkdir(filePathOutput);
end

% save the y limits to yLimit.dat
save([filePathOutput, '\', 'yLimit.mat'],'yLimit');
tmpStr = num2str(theNumOfFile);
ooo    = '000';
if length(tmpStr) < 3,
    tmpStr = [ooo(1:3-length(tmpStr)), tmpStr];
end
% save statistics
save([filePathOutput, '\', 'statisticResult', tmpStr, '.mat'],'statisticResult');
% save some angle infor
save([filePathOutput, '\', 'angleResult', tmpStr, '.mat'], 'saveAFewVar');

% save some figures in disk
if ~exist([filePathOutput,'\current'],'dir'),
    mkdir([filePathOutput,'\current']);
end
if ~exist([filePathOutput,'\V'],'dir'),
    mkdir([filePathOutput,'\V']);
end
if ~exist([filePathOutput,'\tail'],'dir'),
    mkdir([filePathOutput,'\tail']);
end

set(2, 'PaperPositionMode','auto', 'PaperOrientation','portrait');
print(['-f',num2str(2)], '-dpng', [filePathOutput, '\current\', fileName, '_Current.png']);
print(['-f',num2str(3)], '-dpng', [filePathOutput, '\V\',       fileName, '_V.png']);
print(['-f',num2str(4)], '-dpng', [filePathOutput, '\tail\',    fileName, '_Tail.png']);

tElapse = toc(tStart);
fprintf('\n------------------- Finishing seeCurrent (%f[m])-------------------\n\n\n', tElapse/60);
end

function iMaxAtRight = get1stDerivativeAtPushRight(current, dt, iLeft1, jPeakStart)
% get max dI/di from right at push phase
numOfPoint = length(current);
iLeft1     = max(iLeft1, jPeakStart-55);
% deriv1st   = smoothOut(diff(smoothOut(current,2)),2)/dt/1000; % [A/ms]
% deriv1st   = smoothOut(diff(current),4)/dt/1000; % [A/ms]
deriv1st   = diff(current) / dt / 1000; % [A/ms]
[tmp, iMaxAtRight] = max(deriv1st);
% figure(6); hold off; plot(current,'b'); hold on; plot(deriv1st,'r-'); grid;
iMaxAtRight        = jPeakStart - (numOfPoint-iMaxAtRight);
aaa=0;
end



function yLimit = plotLandmark4Tail(plotAllTails, i, current, landmark, yLimit, eventCounter, eventCounterRaw, jTailStart, jTailMid, jTailMax, jTailEnd, numOfBackwardCount4PushPhase, sharpness41stPeak, currentAtValley, time1, samplingTime, caseDescription, ...
    theNumOfFile, plotInForeground)

% plotAllTails=1: everyone is plotted
% plotAllTails=2: plot part of all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot landmarks for current tail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iDummy = 1;
% get graphic handle from called
hdlOfPlot4Tail = evalin('caller', 'hdlOfPlot4Tail');


%  1: tmax
k= 2; m1=1; landmark{eventCounter,i,2}(m1)  = (time1(jTailMax)-time1(jTailStart))*1000;
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m1), caseDescription, theNumOfFile, plotInForeground); yLimit(m1,2,:)=updateYlimit(eventCounter, yLimit(m1,2,:), hdlOfPlot4Tail(k), plotInForeground);
%  2: Imax
k= 1; m2=2; landmark{eventCounter,i,2}(m2)  = current(jTailMax,i);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m2), caseDescription, theNumOfFile, plotInForeground); yLimit(m2,2,:)=updateYlimit(eventCounter, yLimit(m2,2,:), hdlOfPlot4Tail(k), plotInForeground);
currentMax   = current(jTailMax,i);
currentStart = current(jTailStart,i);
currentEnd   = current(jTailEnd,i);
% area 1 based on portion of tmax
% simplified area 1
k= 3; m3=3; landmark{eventCounter,i,2}(m3)  = getArea1(samplingTime, current(:,i), jTailStart, jTailMax, jTailEnd, jTailEnd, 0.275, 2, 0.25); %[A x ms];
% whole curved triangle
% k= 3; m3=3; landmark{eventCounter,i,2}(m3)  = getArea1(samplingTime, current(:,i), jTailStart, jTailMax, jTailEnd, 0.275, 1); %[A x ms];
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m3), caseDescription, theNumOfFile, plotInForeground); yLimit(m3,2,:)=updateYlimit(eventCounter, yLimit(m3,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 1- (based on approximation)
k= 4; m24=24; landmark{eventCounter,i,2}(m24)  = getArea1(samplingTime, current(:,i), jTailStart, jTailMax, jTailEnd, jTailEnd, 0.275, 2, 0.33); %[A x ms]
% % area 1* (based on Imax position)
% % k= 4; m24=24; landmark{eventCounter,i,2}(m24)  = integrateIt(samplingTime, currentMax, -current(:,i), jTailStart, jTailMax)*1000; %[A x ms]
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m24), caseDescription, theNumOfFile, plotInForeground); yLimit(m24,2,:)=updateYlimit(eventCounter, yLimit(m24,2,:), hdlOfPlot4Tail(k), plotInForeground);
% % % % curve length of 150 sampling points
% % % k= 4; m24=24; landmark{eventCounter,i,2}(m24)  = lengthOfCurve(samplingTime*1000, current(:,i), jTailStart, jTailStart+249)*1000;
% % % hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m24), caseDescription, theNumOfFile, plotInForeground); yLimit(m24,2,:)=updateYlimit(eventCounter, yLimit(m24,2,:), hdlOfPlot4Tail(k), plotInForeground);

if plotAllTails == 2,
    assignin('caller', 'hdlOfPlot4Tail', hdlOfPlot4Tail);
    assignin('caller', 'landmark', landmark);
    return;
end

% area1 based on current max
k= 7; m4=4; landmark{eventCounter,i,2}(m4)  = getArea1(samplingTime, current(:,i), jTailStart, jTailMax, jTailEnd, jTailEnd, 0.90, 3, 0.25); %[A x ms]
% area 2
% k= 7; m4=4; landmark{eventCounter,i,2}(m4)  = integrateIt(samplingTime, currentMax, -current(:,i), jTailMax, jTailEnd)*1000; %[A x ms];
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m4), caseDescription, theNumOfFile, plotInForeground); yLimit(m4,2,:)=updateYlimit(eventCounter, yLimit(m4,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 1 + area 2
k=19; m5=5; landmark{eventCounter,i,2}(m5)  = landmark{eventCounter,i,2}(m3) + landmark{eventCounter,i,2}(m4);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m5), caseDescription, theNumOfFile, plotInForeground); yLimit(m5,2,:)=updateYlimit(eventCounter, yLimit(m5,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 1 / area 2
k=20; m6=6; landmark{eventCounter,i,2}(m6)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m4);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m6), caseDescription, theNumOfFile, plotInForeground); yLimit(m6,2,:)=updateYlimit(eventCounter, yLimit(m6,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 1 / (area 1 + area 2)
k=24; m7=7; landmark{eventCounter,i,2}(m7)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m5);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m7), caseDescription, theNumOfFile, plotInForeground); yLimit(m7,2,:)=updateYlimit(eventCounter, yLimit(m7,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 1
k= 5; m8=8; landmark{eventCounter,i,2}(m8)  = landmark{eventCounter,i,2}(m3)/((currentMax-currentStart)*(jTailMax-jTailStart)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m8), caseDescription, theNumOfFile, plotInForeground); yLimit(m8,2,:)=updateYlimit(eventCounter, yLimit(m8,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 2
k= 9; m9=9; landmark{eventCounter,i,2}(m9)  = landmark{eventCounter,i,2}(m4)/((currentMax-currentEnd)*(jTailEnd-jTailMax)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m9), caseDescription, theNumOfFile, plotInForeground); yLimit(m9,2,:)=updateYlimit(eventCounter, yLimit(m9,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 1+2
k=21; m10=10; landmark{eventCounter,i,2}(m10)  = (landmark{eventCounter,i,2}(m3)+landmark{eventCounter,i,2}(m4))...
    /((currentMax-currentEnd)*(jTailEnd-jTailStart)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m10), caseDescription, theNumOfFile, plotInForeground); yLimit(m10,2,:)=updateYlimit(eventCounter, yLimit(m10,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 3
k=11; m11=11; landmark{eventCounter,i,2}(m11)  = integrateIt(samplingTime, 0, current(:,i), jTailStart, jTailMid)*1000; %[A x ms];
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m11), caseDescription, theNumOfFile, plotInForeground); yLimit(m11,2,:)=updateYlimit(eventCounter, yLimit(m11,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 4
k=15; m12=12; landmark{eventCounter,i,2}(m12)  = integrateIt(samplingTime, 0, current(:,i), jTailMid, jTailEnd)*1000; %[A x ms];
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m12), caseDescription, theNumOfFile, plotInForeground); yLimit(m12,2,:)=updateYlimit(eventCounter, yLimit(m12,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 3 + 4
k=23; m13=13; landmark{eventCounter,i,2}(m13)  = landmark{eventCounter,i,2}(m11) + landmark{eventCounter,i,2}(m12);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m13), caseDescription, theNumOfFile, plotInForeground); yLimit(m13,2,:)=updateYlimit(eventCounter, yLimit(m13,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 3 / area 4
k=27; m14=14; landmark{eventCounter,i,2}(m14)  = landmark{eventCounter,i,2}(m11)/landmark{eventCounter,i,2}(m12);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m14), caseDescription, theNumOfFile, plotInForeground); yLimit(m14,2,:)=updateYlimit(eventCounter, yLimit(m14,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 3 / area 3+4
k=28; m15=15; landmark{eventCounter,i,2}(m15)  = landmark{eventCounter,i,2}(m11)/(landmark{eventCounter,i,2}(m11)+landmark{eventCounter,i,2}(m12));
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m15), caseDescription, theNumOfFile, plotInForeground); yLimit(m15,2,:)=updateYlimit(eventCounter, yLimit(m15,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 3
k=13; m16=16; landmark{eventCounter,i,2}(m16)  = landmark{eventCounter,i,2}(m11)/((currentMax-currentStart)*(jTailMid-jTailStart)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m16), caseDescription, theNumOfFile, plotInForeground); yLimit(m16,2,:)=updateYlimit(eventCounter, yLimit(m16,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 4
k=17; m17=17; landmark{eventCounter,i,2}(m17)  = landmark{eventCounter,i,2}(m11)/((currentMax-currentEnd)*(jTailEnd-jTailMid)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m17), caseDescription, theNumOfFile, plotInForeground); yLimit(m17,2,:)=updateYlimit(eventCounter, yLimit(m17,2,:), hdlOfPlot4Tail(k), plotInForeground);
% fullness of area 3 + 4
k=25; m18=18; landmark{eventCounter,i,2}(m18)  = (landmark{eventCounter,i,2}(m11)+landmark{eventCounter,i,2}(m12))...
    /((currentMax-currentEnd)*(jTailEnd-jTailStart)*samplingTime*1000);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m18), caseDescription, theNumOfFile, plotInForeground); yLimit(m18,2,:)=updateYlimit(eventCounter, yLimit(m18,2,:), hdlOfPlot4Tail(k), plotInForeground);
% area 1 / area 3
k=22; m19=19; landmark{eventCounter,i,2}(m19)  = landmark{eventCounter,i,2}(m3)/landmark{eventCounter,i,2}(m11);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m19), caseDescription, theNumOfFile, plotInForeground); yLimit(m19,2,:)=updateYlimit(eventCounter, yLimit(m19,2,:), hdlOfPlot4Tail(k), plotInForeground);
% GC(t) of areal 1
k= 6; m20=20; landmark{eventCounter,i,2}(m20)  = (time1(getCoG4t(samplingTime, currentMax-current(:,i), ...
    0.5*0.001*landmark{eventCounter,i,2}(m3), jTailStart, jTailMax)) - time1(jTailStart))*1e6;
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m20), caseDescription, theNumOfFile, plotInForeground); yLimit(m20,2,:)=updateYlimit(eventCounter, yLimit(m20,2,:), hdlOfPlot4Tail(k), plotInForeground);
% GC(t) of areal 2
k=10; m21=21; landmark{eventCounter,i,2}(m21)  = (time1(getCoG4t(samplingTime, currentMax-current(:,i), ...
    0.5*0.001*landmark{eventCounter,i,2}(m4), jTailMax, jTailEnd)) - time1(jTailStart))*1000;
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m21), caseDescription, theNumOfFile, plotInForeground); yLimit(m21,2,:)=updateYlimit(eventCounter, yLimit(m21,2,:), hdlOfPlot4Tail(k), plotInForeground);
% GC(t) of areal 3
k=14; m22=22; landmark{eventCounter,i,2}(m22)  = (time1(getCoG4t(samplingTime, current(:,i), ...
    0.5*0.001*landmark{eventCounter,i,2}(m11), jTailStart, jTailMid)) - time1(jTailStart))*1e6;
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m22), caseDescription, theNumOfFile, plotInForeground); yLimit(m22,2,:)=updateYlimit(eventCounter, yLimit(m22,2,:), hdlOfPlot4Tail(k), plotInForeground);
% GC(t) of areal 4
k=18; m23=23; landmark{eventCounter,i,2}(m23)  = (time1(getCoG4t(samplingTime, current(:,i), ...
    0.5*0.001*landmark{eventCounter,i,2}(m12), jTailMid, jTailEnd)) - time1(jTailStart))*1000;
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m23), caseDescription, theNumOfFile, plotInForeground); yLimit(m23,2,:)=updateYlimit(eventCounter, yLimit(m23,2,:), hdlOfPlot4Tail(k), plotInForeground);

% Area ratio13/fullness3
k=12; m25=25; landmark{eventCounter,i,2}(m25)  = landmark{eventCounter,i,2}(m20)/landmark{eventCounter,i,2}(m16);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m25), caseDescription, theNumOfFile, plotInForeground); yLimit(m25,2,:)=updateYlimit(eventCounter, yLimit(m25,2,:), hdlOfPlot4Tail(k), plotInForeground);

% Area2 based on portion of Imax
k= 8; m26=26; [tmp,landmark{eventCounter,i,2}(m26)] = getArea1(samplingTime, current(:,i), jTailStart, jTailMax, jTailEnd, jTailEnd, 0.90, 3, 0.33); %[A x ms]
% Area ratio12*Fullness1
% k= 8; m26=26; landmark{eventCounter,i,2}(m26)  = landmark{eventCounter,i,2}(m6)/landmark{eventCounter,i,2}(m8);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m26), caseDescription, theNumOfFile, plotInForeground); yLimit(m26,2,:)=updateYlimit(eventCounter, yLimit(m26,2,:), hdlOfPlot4Tail(k), plotInForeground);
% (Fullness 1) / (Fullness 3)
k=26; m27=27; landmark{eventCounter,i,2}(m27)  = landmark{eventCounter,i,2}(m8)/landmark{eventCounter,i,2}(m10);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m27), caseDescription, theNumOfFile, plotInForeground); yLimit(m27,2,:)=updateYlimit(eventCounter, yLimit(m27,2,:), hdlOfPlot4Tail(k), plotInForeground);
% (Area ratio 12)/(Fullness 3)
k=16; m28=28; landmark{eventCounter,i,2}(m28)  = landmark{eventCounter,i,2}(m6)/landmark{eventCounter,i,2}(m10);
hdlOfPlot4Tail=plotInFig(hdlOfPlot4Tail, 4, k, eventCounterRaw, i, landmark{eventCounter,i,2}(m28), caseDescription, theNumOfFile, plotInForeground); yLimit(m28,2,:)=updateYlimit(eventCounter, yLimit(m28,2,:), hdlOfPlot4Tail(k), plotInForeground);

% update graphic handles
assignin('caller', 'hdlOfPlot4Tail', hdlOfPlot4Tail);
assignin('caller', 'landmark', landmark);

end


    
    
function yLimit = plotLandmark4V(plotAllTails, i, current, landmark, yLimit, eventCounter, eventCounterRaw, jPushStart, jPeakStart, ...
    jVShapeValley, jPeakEnd, jTpHLEnd, jHoldEnd, numOfBackwardCount4PushPhase, sharpness41stPeak, currentAtValley, delayDeviate, threshold4DeviateDetect, ...
    numOfSample4Area1AtPush, time1, samplingTime, caseDescription, theNumOfFile, plotInForeground)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot landmarks for V-shape %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iDummy = 1;
% get graphic handle from called
hdlOfPlot4VShape = evalin('caller', 'hdlOfPlot4VShape');

% push phase time
k= 4; m1=1; landmark{eventCounter,i,1}(m1)  = (time1(jPeakStart) - time1(jPushStart))*1000;  % [ms]
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m1), caseDescription, theNumOfFile, plotInForeground);
yLimit(m1,1,:)=updateYlimit(eventCounter, yLimit(m1,1,:), hdlOfPlot4VShape(k), plotInForeground);

% hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, 180/pi*atan(landmark{eventCounter,i,1}(k)), rpm, phi2Start, phi2End);

%  3: delta-t of 1st fall
k= 2; m3=3; landmark{eventCounter,i,1}(m3)  = (time1(jVShapeValley) - time1(jPeakStart))*1000;    % [ms]
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m3), caseDescription, theNumOfFile, plotInForeground); yLimit(m3,1,:)=updateYlimit(eventCounter, yLimit(m3,1,:), hdlOfPlot4VShape(k), plotInForeground);

%  4: delta-I of 1st fall
k= 1; m4=4; landmark{eventCounter,i,1}(m4)  = current(jPeakStart,i) - currentAtValley;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m4), caseDescription, theNumOfFile, plotInForeground); yLimit(m4,1,:)=updateYlimit(eventCounter, yLimit(m4,1,:), hdlOfPlot4VShape(k), plotInForeground);

%  5: 1st peak delta-I/delta-t
k= 31; m5=5; landmark{eventCounter,i,1}(m5)  = landmark{eventCounter,i,1}(m4)/landmark{eventCounter,i,1}(m3);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m5), caseDescription, theNumOfFile, plotInForeground); yLimit(m5,1,:)=updateYlimit(eventCounter, yLimit(m5,1,:), hdlOfPlot4VShape(k), plotInForeground);
% dt                             = mean(diff(time1(jPeakStart:jVShapeValley)));

%  6: area 1
k= 3; m6=6; landmark{eventCounter,i,1}(m6)  = integrateIt(samplingTime, -currentAtValley, current(:,i), jPeakStart, jVShapeValley)*1000; %[A x ms]
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m6), caseDescription, theNumOfFile, plotInForeground); yLimit(m6,1,:)=updateYlimit(eventCounter, yLimit(m6,1,:), hdlOfPlot4VShape(k), plotInForeground);

%  7: area 2
k= 8; m7=7; landmark{eventCounter,i,1}(m7)  = integrateIt(samplingTime, -currentAtValley, current(:,i), jVShapeValley, jPeakEnd)*1000;   %[A x ms]
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m7), caseDescription, theNumOfFile, plotInForeground); yLimit(m7,1,:)=updateYlimit(eventCounter, yLimit(m7,1,:), hdlOfPlot4VShape(k), plotInForeground);


%  9: (area 1)/(area 1  +  area 2)
% k=18; m9=9; landmark{eventCounter,i,1}(m9)  = landmark{eventCounter,i,1}(m6)/(landmark{eventCounter,i,1}(m6)+landmark{eventCounter,i,1}(m7)); % 1.0/(1.0+1.0/landmark{eventCounter,i,1}(m8));
% TpHL
k=18; m9=9; landmark{eventCounter,i,1}(m9)  = 1000*(time1(jTpHLEnd)-time1(jPeakEnd));
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m9), caseDescription, theNumOfFile, plotInForeground); yLimit(m9,1,:)=updateYlimit(eventCounter, yLimit(m9,1,:), hdlOfPlot4VShape(k), plotInForeground);

currentMax = max(current(jPeakStart,i),current(jPeakEnd,i));

% 11: fullness of area 2
% k=28; m11=11; landmark{eventCounter,i,1}(m11)  = abs(landmark{eventCounter,i,1}(m7)/(jPeakEnd-jVShapeValley)/samplingTime/(currentMax-currentAtValley));

% area 1 for tpHL curve (use 80 sampling points)
k=28; m11=11; landmark{eventCounter,i,1}(m11)  = getArea1(samplingTime, current(:,i), jTpHLEnd-80, jTpHLEnd, jTpHLEnd, jTpHLEnd, 1, 2, 0.33);


hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m11), caseDescription, theNumOfFile, plotInForeground); yLimit(m11,1,:)=updateYlimit(eventCounter, yLimit(m11,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 12: fullness of area 1 + 2
k=33; m12=12; landmark{eventCounter,i,1}(m12)  = (landmark{eventCounter,i,1}(m6)+landmark{eventCounter,i,1}(m7)) ...
    /((currentMax-currentAtValley)*(jPeakEnd-jPeakStart)*samplingTime*1000);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m12), caseDescription, theNumOfFile, plotInForeground); yLimit(m12,1,:)=updateYlimit(eventCounter, yLimit(m12,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 13: GC(t) of areal 1
k= 7; m13=13; landmark{eventCounter,i,1}(m13)  = (time1(getCoG4t(samplingTime, current(:,i)-currentAtValley, ...
    0.5*0.001*landmark{eventCounter,i,1}(m6), jPeakStart, jVShapeValley)) - time1(jPeakStart))*1e6;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m13), caseDescription, theNumOfFile, plotInForeground); yLimit(m13,1,:)=updateYlimit(eventCounter, yLimit(m13,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 14: GC(t) of areal 2
k=17; m14=14; landmark{eventCounter,i,1}(m14)  = (time1(getCoG4t(samplingTime*1000, current(:,i)-currentAtValley, ...
    0.5*landmark{eventCounter,i,1}(m7), jVShapeValley, jPeakEnd)) - time1(jPeakStart))*1000;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m14), caseDescription, theNumOfFile, plotInForeground); yLimit(m14,1,:)=updateYlimit(eventCounter, yLimit(m14,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 15: GC(t) of areal 3
k=22; m15=15; landmark{eventCounter,i,1}(m15)  = (time1(getCoG4t(samplingTime*1000, currentMax-current(:,i), ...
    0.5*((jVShapeValley-jPeakStart)*(current(jPeakStart,i)-currentAtValley)*samplingTime*1000-landmark{eventCounter,i,1}(m6)), jPeakStart, jVShapeValley)) - time1(jPeakStart))*1e6;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m15), caseDescription, theNumOfFile, plotInForeground); yLimit(m15,1,:)=updateYlimit(eventCounter, yLimit(m15,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 16: cross point of min I and 2/3 first fall with fitted slope                               previously: GC(t) of areal 4
k=27; m16=16; landmark{eventCounter,i,1}(m16)  = 1000*(time1(getFallInterceptTime(current(:,i), jPushStart, jPeakStart, jPeakEnd, samplingTime, i, plotInForeground)) -time1(jPeakStart));
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m16), caseDescription, theNumOfFile, plotInForeground); yLimit(m16,1,:)=updateYlimit(eventCounter, yLimit(m16,1,:), hdlOfPlot4VShape(k), plotInForeground);
%         ICross = 1/4*(current(jPeakStart,i) - current(jVShapeValley,i));
%         k=27; m16=16; landmark{eventCounter,i,1}(m16)  = 1000*(time1(getCrossTime(samplingTime, current(:,i)-current(jVShapeValley,i), jPeakStart,  jVShapeValley, ICross)) -time1(jPeakStart));
%         hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m16), caseDescription, theNumOfFile, plotInForeground); yLimit(m16,1,:)=updateYlimit(eventCounter, yLimit(m16,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 17: GC(I) of areal 1
k= 6; m17=17; landmark{eventCounter,i,1}(m17)  = current(getCoG4I(samplingTime*1000, current(:,i)-currentAtValley, ...
    0.5*landmark{eventCounter,i,1}(m6), jPeakStart, jVShapeValley),i) - current(jPeakStart,i);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m17), caseDescription, theNumOfFile, plotInForeground); yLimit(m17,1,:)=updateYlimit(eventCounter, yLimit(m17,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 18: GC(I) of areal 2
k=11; m18=18; landmark{eventCounter,i,1}(m18)  = current(getCoG4I(samplingTime*1000, current(:,i), ...
    0.5*landmark{eventCounter,i,1}(m7), jVShapeValley, jPeakEnd),i) - current(jPeakStart,i);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m18), caseDescription, theNumOfFile, plotInForeground); yLimit(m18,1,:)=updateYlimit(eventCounter, yLimit(m18,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 19: CoMoI with axis: jPeakStart
%         k=32; m19=19; landmark{eventCounter,i,1}(m19)  = sqrt(integrateMI(samplingTime*1000, ...
%             current(:,i), jPeakStart, jVShapeValley)/abs(landmark{eventCounter,i,1}(m6)));
% position for max dI/samplingTime from right at push phase
k=32; m19=19; landmark{eventCounter,i,1}(m19)  = -1000*time1(jPeakStart)+1000*time1(get1stDerivativeAtPushRight(current(jPeakStart-55:jPeakStart,i), samplingTime, jPeakStart-55, jPeakStart));
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m19), caseDescription, theNumOfFile, plotInForeground); yLimit(m19,1,:)=updateYlimit(eventCounter, yLimit(m19,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 20: gradient of upper push phase with liniear regression [A/ms]
k=34; m20=20; landmark{eventCounter,i,1}(m20)  =  0.001*linearRegression(current(jPeakStart-numOfBackwardCount4PushPhase:jPeakStart,i), samplingTime);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m20), caseDescription, theNumOfFile, plotInForeground); yLimit(m20,1,:)=updateYlimit(eventCounter, yLimit(m20,1,:), hdlOfPlot4VShape(k), plotInForeground);

% deviation time and index
k=14; m28=28; [landmark{eventCounter,i,1}(m28), jDeviate]  = getDeviationStart(time1, current(:,i), jPushStart, jPeakStart, jPeakEnd, delayDeviate, threshold4DeviateDetect);
% 28: use part of the push time to get slope of the last push phase
% k=14; m28=28; landmark{eventCounter,i,1}(m28)  = pushGradUpper / 1000;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m28), caseDescription, theNumOfFile, plotInForeground); yLimit(m28,1,:)=updateYlimit(eventCounter, yLimit(m28,1,:), hdlOfPlot4VShape(k), plotInForeground);

% area 1 at push after deviation
k=19; m21=21; landmark{eventCounter,i,1}(m21)  = getArea1(samplingTime, current(:,i), jDeviate, jDeviate+numOfSample4Area1AtPush, jDeviate+numOfSample4Area1AtPush, jPeakStart, 1, 2, 0.33); %[A x ms];
% gradient of push-phase at half of 9A
% [pushGradUpper , tmp, pushGradLower pushTimeLower] = pushPhaseGradient(time1, current(:,i), 9, jPushStart, jPeakStart, jVShapeValley);
% k=19; m21=21; landmark{eventCounter,i,1}(m21)  = pushGradLower / 1000;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m21), caseDescription, theNumOfFile, plotInForeground); yLimit(m21,1,:)=updateYlimit(eventCounter, yLimit(m21,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 22: push-phase slope
k= 9; m22=22; landmark{eventCounter,i,1}(m22)  = (current(jPeakStart,i)-current(jPushStart,i)) / landmark{eventCounter,i,1}(m1);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m22), caseDescription, theNumOfFile, plotInForeground); yLimit(m22,1,:)=updateYlimit(eventCounter, yLimit(m22,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 23: slope of CoG of area 1 (1) shifted -- GC(I)/GC(t)(s)
k=16; m23=23; landmark{eventCounter,i,1}(m23)  = (3.5+landmark{eventCounter,i,1}(m17)) / landmark{eventCounter,i,1}(m13) ;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m23), caseDescription, theNumOfFile, plotInForeground); yLimit(m23,1,:)=updateYlimit(eventCounter, yLimit(m23,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 24: slope of CoG of area 1 (2) no shift
k=21; m24=24; landmark{eventCounter,i,1}(m24)  = landmark{eventCounter,i,1}(m17) / landmark{eventCounter,i,1}(m13) ;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m24), caseDescription, theNumOfFile, plotInForeground); yLimit(m24,1,:)=updateYlimit(eventCounter, yLimit(m24,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 25: slope of 1st fall based on CoG1: delta-I/CoG1(t)
k=26; m25=25; landmark{eventCounter,i,1}(m25)  = landmark{eventCounter,i,1}(m4) / landmark{eventCounter,i,1}(m13) ;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m25), caseDescription, theNumOfFile, plotInForeground); yLimit(m25,1,:)=updateYlimit(eventCounter, yLimit(m25,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 26: last slope of push phase
[temp1 gradBefore temp2]= gradientDifference(current(:,i), jPeakStart, samplingTime, 7, 2, 1, -1);
k=29; m26=26; landmark{eventCounter,i,1}(m26)  = gradBefore/1000;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m26), caseDescription, theNumOfFile, plotInForeground); yLimit(m26,1,:)=updateYlimit(eventCounter, yLimit(m26,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 27: GC(t) of areal 1 after smoothing
k=12; m27=27; landmark{eventCounter,i,1}(m27)  =(time1(getCoG4t(samplingTime, current(:,i)-currentAtValley, ...
    0.5*0.001*landmark{eventCounter,i,1}(m6), jPeakStart, jVShapeValley, 1)) - time1(jPeakStart))*1e6;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m27), caseDescription, theNumOfFile, plotInForeground); yLimit(m27,1,:)=updateYlimit(eventCounter, yLimit(m27,1,:), hdlOfPlot4VShape(k), plotInForeground);

% curvature info in later push phase
[curvatureMax curvatureMin iPosMax iNegMin curvaturePosMean curvatureNegMean] = ...
    curvature(current(:,i), 1000*samplingTime, jPeakStart-numOfBackwardCount4PushPhase, jPeakStart, 5);
% push-phase curvature max(upper part)
% k= 5; m29=29; landmark{eventCounter,i,1}(m29)  = curvatureMax;
% Area2(u) at push phase
% k= 5; m29=29; landmark{eventCounter,i,1}(m29)  = 1000*0.5*samplingTime*(80+40)*(current(jPeakStart-40,i)-current(jPeakStart-80,i)) + ...
%     1000*0.5*50*samplingTime*(current(jPeakStart,i)-current(jPeakStart-40,i));
% Area1(u) at push phase
upSegment    = 80; % how may sampling points at upper segment
halfUpSegmet = ceil(0.5*upSegment);
k= 5; m29=29; landmark{eventCounter,i,1}(m29)  = 1000*samplingTime*upSegment*(current(jPeakStart,i)-current(jPeakStart-upSegment,i)) - ...
    1000*0.5*samplingTime*1.5*upSegment*(current(jPeakStart-halfUpSegmet,i)-current(jPeakStart-upSegment,i)) - ...
    1000*0.5*samplingTime*0.5*upSegment*(current(jPeakStart,i)-current(jPeakStart-halfUpSegmet,i));

hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m29), caseDescription, theNumOfFile, plotInForeground); yLimit(m29,1,:)=updateYlimit(eventCounter, yLimit(m29,1,:), hdlOfPlot4VShape(k), plotInForeground);
% push-phase positive curvature mean (upper part)
% k=10; m30=30; landmark{eventCounter,i,1}(m30)  = curvaturePosMean;
% Area2(l) at push phase from �push start with xxx points
% k=10; m30=30; landmark{eventCounter,i,1}(m30)  = 1000*0.5*samplingTime*(120+60)*(current(jPushStart+60,i)-current(jPushStart,i)) + ...
%    1000*0.5*80*samplingTime*(current(jPushStart+120,i)-current(jPushStart+60,i));

% Area1(l) at push phase from push start with xxx points: make the start
% point also movable to accomodate the later move of a SV
jPushStart1   = jPushStart + 1;
lowSegment    = 50; % how may sampling points at low segment
halfLowSegmet = ceil(0.5*lowSegment);
k=10; m30=30; landmark{eventCounter,i,1}(m30)  = 1000*samplingTime*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1,i)) - ...
    1000*0.5*samplingTime*1.5*lowSegment*(current(jPushStart1+halfLowSegmet,i)-current(jPushStart1,i)) - ...
    1000*0.5*samplingTime*0.5*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1+halfLowSegmet,i));

hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m30), caseDescription, theNumOfFile, plotInForeground); yLimit(m30,1,:)=updateYlimit(eventCounter, yLimit(m30,1,:), hdlOfPlot4VShape(k), plotInForeground);
% push-phase negative curvature mean (upper part)
% k=15; m31=31; landmark{eventCounter,i,1}(m31)  = curvatureNegMean;
% ratio of areax u/l
k=15; m31=31; landmark{eventCounter,i,1}(m31)  = landmark{eventCounter,i,1}(m29) / landmark{eventCounter,i,1}(m30);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m31), caseDescription, theNumOfFile, plotInForeground); yLimit(m31,1,:)=updateYlimit(eventCounter, yLimit(m31,1,:), hdlOfPlot4VShape(k), plotInForeground);

% push-phase curvature min (upper part)
% k=20; m32=32; landmark{eventCounter,i,1}(m32)  = curvatureMin;
% ratio of area1/area2 (u)
ccc = landmark{eventCounter,i,1}(m29) / (1000*samplingTime*80*(current(jPeakStart,i)-current(jPeakStart-80,i)));
k=20; m32=32; landmark{eventCounter,i,1}(m32)  = ccc/(1-ccc);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m32), caseDescription, theNumOfFile, plotInForeground); yLimit(m32,1,:)=updateYlimit(eventCounter, yLimit(m32,1,:), hdlOfPlot4VShape(k), plotInForeground);

% time before peakMax for push-phase curvature max (upper part)
% k=25; m33=33; landmark{eventCounter,i,1}(m33)  = 1e6*(time1(jPeakStart) - time1(iPosMax));
% ratio of area1/area2 (l)
ccc = landmark{eventCounter,i,1}(m30) / (1000*samplingTime*120*(current(jPushStart+120,i)-current(jPushStart,i)));
k=25; m33=33; landmark{eventCounter,i,1}(m33)  = ccc/(1-ccc);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m33), caseDescription, theNumOfFile, plotInForeground); yLimit(m33,1,:)=updateYlimit(eventCounter, yLimit(m33,1,:), hdlOfPlot4VShape(k), plotInForeground);

% time before peakMax for push-phase curvature min (upper part)
% k=30; m34=34; landmark{eventCounter,i,1}(m34)  = 1e6*(time1(jPeakStart) - time1(iNegMin));
% Area1(u) at push phase, same dela-A
upSegment = jPeakStart - getIndex4deltaA(current(:,i), 2, jPeakStart, -1, jPushStart)+1; %80; % how may sampling points at upper segment
halfUpSegmet = ceil(0.5*upSegment);
k=30; m34=34; landmark{eventCounter,i,1}(m34)  = 1000*samplingTime*upSegment*(current(jPeakStart,i)-current(max(1,jPeakStart-upSegment),i)) - ...
    1000*0.5*samplingTime*1.5*upSegment*(current(max(1,jPeakStart-upSegment),i)-current(max(1,jPeakStart-upSegment),i)) - ...
    1000*0.5*samplingTime*0.5*upSegment*(current(jPeakStart,i)-current(max(1,jPeakStart-upSegment),i));
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m34), caseDescription, theNumOfFile, plotInForeground); yLimit(m34,1,:)=updateYlimit(eventCounter, yLimit(m34,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 2: 1st peak angle/or its tangent
% k= 35; m2=2; landmark{eventCounter,i,1}(m2)  = abs(sharpness41stPeak)*1.0e3;  % [A/ms]

jPushStart1 = jPushStart + 1;
lowSegment  = getIndex4deltaA(current(:,i), 3, jPushStart1, 1, jPeakStart) - jPushStart1+1; % 50; % how may sampling points at low segment
halfLowSegmet = ceil(0.5*lowSegment);
% fprintf('\nlowSegment upSegment= %i %i',lowSegment, upSegment);
k= 35; m2=2; landmark{eventCounter,i,1}(m2)  = 1000*samplingTime*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1,i)) - ...
    1000*0.5*samplingTime*1.5*lowSegment*(current(jPushStart1+halfLowSegmet,i)-current(jPushStart1,i)) - ...
    1000*0.5*samplingTime*0.5*lowSegment*(current(jPushStart1+lowSegment,i)-current(jPushStart1+halfLowSegmet,i));
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m2), caseDescription, theNumOfFile, plotInForeground); yLimit(m2,1,:)=updateYlimit(eventCounter, yLimit(m2,1,:), hdlOfPlot4VShape(k), plotInForeground);

% area 2 from deviation point 
k=24; m35=35; [tmp landmark{eventCounter,i,1}(m35)] = getArea1(samplingTime, current(:,i), jDeviate, jDeviate+numOfSample4Area1AtPush, jDeviate+numOfSample4Area1AtPush, jPeakStart, 1, 2, 0.33);
% gradient of push-phase: at a middle point of 2 times the current between 1st peak
% and valley down from peak
% [pushGradUpper , tmp, pushGradLower pushTimeLower] = ...
%     pushPhaseGradient(time1, current(:,i), 2*current(jVShapeValley,i)-current(jPeakStart,i), jPushStart, jPeakStart, jVShapeValley);
% k=24; m35=35; landmark{eventCounter,i,1}(m35)  = pushGradUpper / 1000;
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m35), caseDescription, theNumOfFile, plotInForeground); yLimit(m35,1,:)=updateYlimit(eventCounter, yLimit(m35,1,:), hdlOfPlot4VShape(k), plotInForeground);

% 10: fullness of area 1
%k=23; m10=10; landmark{eventCounter,i,1}(m10)  = abs(landmark{eventCounter,i,1}(m6) ...
%    /(jVShapeValley-jPeakStart)/samplingTime/(currentAtValley-currentMax));
% deviation time x Area2 (push)
k=23; m10=10; landmark{eventCounter,i,1}(m10)  = landmark{eventCounter,i,1}(m35)*landmark{eventCounter,i,1}(m28);
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m10), caseDescription, theNumOfFile, plotInForeground); yLimit(m10,1,:)=updateYlimit(eventCounter, yLimit(m10,1,:), hdlOfPlot4VShape(k), plotInForeground);

%  8: (area 2)/(area 1)
% k=13; m8=8; landmark{eventCounter,i,1}(m8)  = landmark{eventCounter,i,1}(m7)/landmark{eventCounter,i,1}(m6);
% dt^2+dI^2 between push start to deviation point
k=13; m8=8; landmark{eventCounter,i,1}(m8)  = 1e8*(time1(jDeviate)-time1(jPushStart))^2 + (current(jDeviate,i)-current(jPushStart,i))^2; % [(0.1*ms x I)^2]
hdlOfPlot4VShape=plotInFig(hdlOfPlot4VShape, 3, k, eventCounterRaw, i, landmark{eventCounter,i,1}(m8), caseDescription, theNumOfFile, plotInForeground); yLimit(m8,1,:)=updateYlimit(eventCounter, yLimit(m8,1,:), hdlOfPlot4VShape(k), plotInForeground);

% update graphic handles
assignin('caller', 'hdlOfPlot4VShape', hdlOfPlot4VShape);
assignin('caller', 'landmark', landmark);

end
        


function jdTime = getFallInterceptTime(current, jPushStart, jPeakStart, jPeakEnd, dt, i, plotInForeground)
% get the intercepting point of first falling line (LS) and a horizonal
% line a little above the V-shap minimal 
% how many point: about 7 chopings
numOfChop         = 3;
numOfPointPerChop = 6;
halfChop          = 0.3;
numOfFitPoint     = numOfChop*numOfPointPerChop;
currentMin        = min(min(current(jPeakStart:jPeakEnd)));
[g, a]            = linearRegression(current, dt, jPeakStart,jPeakStart+numOfFitPoint, -1);
% x = (y-a)/g  y=a+g*x
jdTimeLocal       = round((currentMin+halfChop-current(jPeakStart))/g/dt);
jdTime            = jdTimeLocal + jPeakStart;

if 0, % plot around interecption point 
    figure(2); bringFigToFromBackground(2, plotInForeground);
    subplot(2,4,i, 'FontSize',6); hold('on');
    iFromPush  = jPeakStart-jPushStart + 22;
    iMin1      = 1;
    iMax1      = 3*numOfFitPoint;
    iMax       = jPeakEnd-jPeakStart;
    hold('on');
    % plot((1:iMax+1)*dt, current(jPeakStart:jPeakEnd), 'b-');  % plot V-shape current profile
    % hold('on');
%     plot((1:iMax+1)*dt, current(jPeakStart:jPeakEnd), 'b.');  % 
%     hold('on');
    
    % plot([0 -a/g]/samplingTime, [a 0], 'r-');
    % plot([iMin1 iMax1]*dt, [a+g*(iMin1-iMin1)*dt a+g*(iMax1-iMin1)*dt], 'r+');
    plot(iFromPush+[iMin1 iMax1], [a+g*(iMin1-iMin1)*dt a+g*(iMax1-iMin1)*dt], 'y-');  % plot falling line
    % plot(iFromPush+[iMin1 iMax ], [1 1]*currentMin+halfChop, 'y-'); % plot horizontal line
    plot(iFromPush+[jdTimeLocal-44 jdTimeLocal+44], [1 1]*currentMin+halfChop, 'y-'); % plot horizontal line
    plot(iFromPush+jdTimeLocal, currentMin+halfChop,'y+');          % plot interception point
    %axis([0 iMax*dt currentMin max(current(jPeakStart:jPeakEnd))]);
    %grid;
    %title(['Push Start Index jPeakStart = ', num2str(jPeakStart)]);
    
end




end

function [index4Dt, a, g]  = getCrossTime(dt, current, iStart, iEnd, ICross) 
% get the LS fitting                     line for the first fall of the first 4/5 points and get the cross point
% index4Dt - absolute index
% a - intercept relative to       
% g - slope
% current - current related to jVShapeValley
% ICross - current relative to current(jVShapeValley)
iEnd1 = iEnd;
for i = iStart:iEnd
    if current(i) <= ICross,
        iEnd1 = i;
        break;
    end
end

% [g, a]   = linearRegression(dt, current(iStart:iEnd1));
% index4Dt = max(1, floor((ICross-a)/(g*dt)));
% index4Dt = iStart + index4Dt-1;
end


function iJump = get1stJumpIndex(current, jStart, jEnd, threshold)
% get 

iJump = jEnd;
for j = jStart+1:jEnd
    if j == 3452,
        aaa=0;
    end
    if threshold > 0, % get a jump up
%        if current(j)>=current(j-1)+threshold && current(j-1)>=1.5 && current(j-1)<4,
        if current(j-1)<threshold && current(j)>threshold,
            iJump = j;
            break;
        end
    else % get jump down
%         if current(j-1)>abs(threshold) && current(j)<=abs(threshold)-threshold && current(j-1)>=1.5 && current(j-1)<4,
        if current(j-1)>abs(threshold) && current(j)<abs(threshold),
            iJump = j;
            break;
        end
    end
end
aaa=0;
end
    
function [yVShapeValley jVShapeValley] = getBetterMin(jPeakStart, jPeakEnd, dt, current)
% better min: idea is that first derivative goes from negtive to positive
yVShapeValley = current(jPeakEnd);
jVShapeValley = jPeakEnd;

% first step: find a segment where gradient goes from negtive to positive
numOfPoint2Select = 16;  % points used to do gradient estimation, mean, etc. for chopping reduction
kMax              = 1;   % segment number for searching -to+ gradient
k                 = 1;
k2p               = 0;   % kMax = 2^k2p
[k1Prev, k2Prev, k3Prev] = reArrangeIndex(jPeakStart+numOfPoint2Select, jPeakEnd-numOfPoint2Select);
[k1,     k2,     k3    ] = reArrangeIndex(k1Prev, k3Prev);
deltak                   = jPeakEnd-numOfPoint2Select - jPeakStart-numOfPoint2Select;
while k <= kMax
    [k1, k2, k3] = reArrangeIndex(k1, k1+deltak);
    [GradAtLeft GradInMiddle GradAtRight] = get3Gradient(dt, current, k1, k2, k3);
    if (GradAtLeft<0 && GradInMiddle>=0) || (GradInMiddle<0 && GradAtRight>=0),  % goes from negative to positive
        % if GradAtLeft*GradInMiddle<=0 || GradInMiddle*GradAtRight<=0,
        break;
    elseif k2p >= 5,
        % the whole curve is with positive or negtive 
        % but not + to - or - to +
        fprintf('\nWarning: no minimum in between jPeakStart (%i) and jPeakEnd (%i).', jPeakStart, jPeakEnd);
        return
    end
    if k == kMax,
        k            = 1;
        k2p          = k2p + 1;
        kMax         = 2^k2p;
        deltak       = floor((jPeakEnd-numOfPoint2Select - jPeakStart-numOfPoint2Select)/kMax);
        [k1, k2, k3] = reArrangeIndex(jPeakStart+numOfPoint2Select, jPeakEnd-numOfPoint2Select);
        continue;
    else
        k = k + 1;
    end
    k1 = k3;
end

% second step: divide the selected segment (-to+) further and further till
% within 3 indices
[k1Prev, k2Prev, k3Prev] = reArrangeIndex(k1, k3);
for k = 1:111
    if GradAtLeft<0 && GradInMiddle>=0,
        % a min is at left side: between GradAtLeft and GradInMiddle
        if k3-k1 <= 3,
            jVShapeValley = k2;
            break;
        end
        [k1,     k2,     k3    ]              = reArrangeIndex(k1, k2);
        [GradAtLeft GradInMiddle GradAtRight] = get3Gradient(dt, current, k1, k2, k3);
        [k1Prev, k2Prev, k3Prev]              = reArrangeIndex(k1, k3);
    end
    
    if GradInMiddle<0 && GradAtRight>=0,
        % a min is at right side: between GradInMiddle and GradAtRight
        if k3-k1 <= 3,
            jVShapeValley = k2;
            break;
        end
        [k1, k2, k3]                          = reArrangeIndex(k2Prev,k3Prev);
        [GradAtLeft GradInMiddle GradAtRight] = get3Gradient(dt, current, k1, k2, k3);
        [k1Prev, k2Prev, k3Prev]              = reArrangeIndex(k1, k3);
    end
    %                 figure(5);hold on; plot(k2,    current(k2,i),
    %                 'mv',
    %                 'MarkerSize',6); hold on;
end
% make a average around min point because it is one of the points in intensive chopping
yVShapeValley = mean(current(jVShapeValley-floor(numOfPoint2Select/2):jVShapeValley+floor(numOfPoint2Select/2)));

end


function [GradAtLeft GradInMiddle GradAtRight] = get3Gradient(dt, current, iLeft, iMiddle, iRight)

% number of points at borders
numOfPoint2Select = 16;
% halfOfPoint2Selet = 8;
GradAtLeft   = linearRegression(current(iLeft-numOfPoint2Select  :iLeft+numOfPoint2Select),   dt, 1, 2*numOfPoint2Select+1, -1);
GradInMiddle = linearRegression(current(iMiddle-numOfPoint2Select:iMiddle+numOfPoint2Select), dt, 1, 2*numOfPoint2Select+1, 0);
GradAtRight  = linearRegression(current(iRight-numOfPoint2Select :iRight+numOfPoint2Select),  dt, 1, 2*numOfPoint2Select+1, 1);
end

function [iLeft, iMiddle, iRight] = reArrangeIndex(iLeft, iRightPrev)
    
iLeft   = iLeft;
iRight  = iRightPrev;
iMiddle = floor((iLeft+iRightPrev)/2);

end


function [pushGradUpper pushTimeUpper pushGradLower pushTimeLower] = ...
    pushPhaseGradient(time1, current, currentAtMidPoint, jPushStart, jPeakStart, jVShapeValley)
% pushGradUpper, pushTimeUpper -- calculated for the delta-I from V-valley
% to first peak;
% pushGradLower pushTimeLower  -- calculated from push start to 50% push
% current.

%%%%%%%%%%%%%%%%%%%%%%%%% for upper part %%%%%%%%%%%%%%%%%%%%%%%%%
% middle point: current at valley 
% currentAtMidPoint = current(jVShapeValley);
% middle poit: fixed at 9 A -- calibratable and easy to measure
% currentAtMidPoint = 9;  

currentAtMidPoint = max(currentAtMidPoint, current(jPushStart));

if current(jPeakStart) >= currentAtMidPoint,
    for i = jPeakStart:-1:jPushStart
        if current(i) > currentAtMidPoint,
            j2 = i;
        end
        if current(i) <= currentAtMidPoint,
            j1 = i;
            break;
        end
    end
    
    if ~exist('j1'),
        aaa=0;
    end
    pushTimeUpper = time1(jPeakStart) - (time1(j2) - (time1(j2)-time1(j1)) ...
        * (current(j2) - currentAtMidPoint) / (current(j2) - current(j1)));
    pushGradUpper = (current(jPeakStart) - currentAtMidPoint) / pushTimeUpper;
else % condition is not reached and no right value
    pushTimeUpper = NaN;
    pushGradUpper = NaN;
end

% do an interploation for upper part

%%%%%%%%%%%%%%%%%%%%%%%%%% for lower part %%%%%%%%%%%%%%%%%%%%%%%%%
% middle point: middle
% halfCurrent = 0.5*(current(jPeakStart)+current(jPushStart));

if current(jPeakStart) >= currentAtMidPoint,
    for i = jPushStart:jPeakStart
        if current(i) > currentAtMidPoint,
            j4 = i;
            break;
        end
        if current(i) <= currentAtMidPoint,
            j3 = i;
        end
    end
    
    pushTimeLower = (time1(j3) + (time1(j4)-time1(j3)) * (current(j4) - currentAtMidPoint) ...
        / (current(j4) - current(j3))) -  time1(jPushStart);
    if 0,  % make a better gradient
        pushGradLower = linearRegression(current(jPushStart:j3), mean(diff(time1(jPushStart:j3))), 1, j3-jPushStart+1);
    else  % simple 2-point gradient
        pushGradLower = (currentAtMidPoint - current(jPushStart)) / pushTimeLower;
    end
else
    pushTimeLower = NaN;
    pushGradLower = NaN;
end

% fprintf('\npushGradh pushTime=%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f', ...
%     pushGradUpper, pushTimeUpper*1000, current(jPeakStart), current(j2), currentAtMidPoint, current(j1));
% fprintf('\npushGradl pushTime=%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f', ...
%     pushGradLower, pushTimeLower*1000, current(j4), halfCurrent, current(j3), current(jPushStart));
aaa=0;
end


function [curvatureMax curvatureMin iPosMax iNegMin curvaturePosMean curvatureNegMean] = ...
    curvature(y, dx, iStart, iEnd, numOfPoint4Estimation)
% dx -- [ms]
% iStart = iStart - 2*numOfPoint4Estimation;
if 1,  % smooth them
    numOfPoint4Smooth = 5;
    y(iStart-numOfPoint4Smooth-numOfPoint4Estimation-1:iEnd) = ...
        smoothOut(y(iStart-numOfPoint4Smooth-numOfPoint4Estimation-1:iEnd), numOfPoint4Smooth);
end

curvaturei = zeros(1,iEnd-iStart+1);
for i = iStart+numOfPoint4Estimation:iEnd-numOfPoint4Estimation-numOfPoint4Smooth-1
    j             = i - iStart-numOfPoint4Estimation + 1;
    
    if 0,   % descrited way
        s1            = sqrt(dx+(y(i)-y(i-1))^2);
        s2            = sqrt(dx+(y(i)-y(i+1))^2);
        alfa          = atan(gradientDifference(y, i-2, dx, numOfPoint4Estimation) + gradientDifference(y, i+2, dx, numOfPoint4Estimation));
        curvaturei(j) =  alfa / (s1+s2);
    else   % methmatical way
        [gradDiff gradAvg1 gradAvg2] = gradientDifference(y, i, dx, numOfPoint4Estimation, numOfPoint4Estimation, 1, -1);
        gradAvg        = 0.5*(gradAvg1 + gradAvg2);
        curvaturei(j) = gradDiff/dx / (1+gradAvg^2)^1.5;
    end
    % fprintf('\ns1/2 alfa=%5i %+8.3e %+8.3e %+8.3e %+8.3e %+8.3e',i, curvature(i), s1,s2,alfa, cSmt(i)-cSmt(i-1));
end

vectorTmp              = curvaturei(~isinf(curvaturei));

[curvatureMax iPosMax] = max(vectorTmp);
iPosMax                = iPosMax + iStart+numOfPoint4Estimation-1;
[curvatureMin iNegMin] = min(vectorTmp);
iNegMin                = iNegMin + iStart+numOfPoint4Estimation-1;

curvaturePosMean       = mean(vectorTmp(curvaturei>0));
curvatureNegMean       = mean(vectorTmp(curvaturei<0));

% fprintf('\ns1/2 alfa=%7i %+8.3e %+8.3e %+8.3e %+8.3e',iPosMax, curvatureMax, curvaturePosMean,curvatureNegMean,curvatureMin);
aaa=0;
end


function caseDescription = parseName(inputFileFull)
% parse out all case properties out of file path and file name 
if ~isempty(myStrfind(inputFileFull, '\')),
    fileName = inputFileFull(max(myStrfind(inputFileFull, '\'))+1:end-4);
else
    fileName = inputFileFull;
end
bSlashPos       = myStrfind(inputFileFull, '\');
numOfbSlash     = length(bSlashPos);
caseDescription = cell(1,1);  % 1: temp, 2: cyl1; 3: cyl2; 4: cyl3; 5: cyl4
if numOfbSlash > 0,
    % find a sub-folder name with '_' and '-' which are the SV layout info
    numOfDeeperFolder = 1;
    
    while numOfDeeperFolder < 3,
        iStart4FolderName = 0;
        for i = numOfbSlash:-1:2
            % things between the last two '\'
            indexBetweenSlashes = bSlashPos(i-1):bSlashPos(i);
            foundMinus          = myStrfind(inputFileFull(indexBetweenSlashes), '_');
            foundUnderscore     = myStrfind(inputFileFull(indexBetweenSlashes), '-');
            if ~isempty(foundMinus) && ~isempty(foundUnderscore),
                iStart4FolderName = i-1;
                break;
            end
        end
        if iStart4FolderName,
            folderName      = inputFileFull(bSlashPos(iStart4FolderName)+1:bSlashPos(iStart4FolderName+1)-1);
            numOfUnderscore = length(myStrfind(folderName, '_'));
            remain          = folderName;
            if numOfUnderscore < 3, % a short one: auxilary info -- e.g., EVC_6000_15W-40
                i2Store = 3;
            else % lot of understcores-- long name with more info 025deg_Toff-slow_Toff-fast_nom_stuck-mid-SVT
                i2Store = 1;
            end
            for i = 1:numOfUnderscore+1
                [tok remain] = strtok(remain, '_');
                caseDescription{i,i2Store} = tok;
            end
            aaa= 0;
        else
            fprintf('\nWarning: No further SV layout info found in %i. depth of folder name and program continues ... ...', numOfDeeperFolder);
        end
        numOfDeeperFolder = numOfDeeperFolder + 1;
        numOfbSlash       = numOfbSlash -  1;
    end
    
end
% extract things from file name
numOfUnderscore = length(myStrfind(fileName, '_'));
remain          = fileName;
for i = 1:numOfUnderscore
    [tok remain] = strtok(remain, '_');
    caseDescription{i,2} = tok;
end
caseDescription{numOfUnderscore+1,2} = caseDescription{1,2}(end-3:end);
aaa=0;
end


function hdlOfPlot = plotInFig(hdlOfPloti, j, landmarki, eventCounter, i, y, caseDescription, theNumOfFile, plotInForeground)

% if ~plotIt && ~isempty(hdlOfPloti),
%     hdlOfPlot = hdlOfPloti;
%     return;
% end

if nargin < 8,
    theNumOfFile           = 0;
elseif nargin < 9,
    plotInForeground = 'on';
end    
    
% plot point by point of landmark
figure(j); bringFigToFromBackground(j, plotInForeground); 
if isempty(hdlOfPloti), % prepare the subplots and add thresholds there
    if j == 3,
        k= 4; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Push-phase';'time [ms]'});
       %k=35; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'1st peak';'sharpness'});       xlabel('Event No');
        k=35; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'push-phase';'Area1(l)A'});       xlabel('Event No');
        k= 2; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'delta-t of';'1. fall[ms]'});
        k= 1; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'delta-I of';'1. fall[A]'});
        k=31; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'Slope';'of 1st fall'});        xlabel('Event No');
        k= 3; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 1';'[A.ms]'});
        k= 8; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 2';'[A.ms]'});
        k=13; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'tI-distance^2'});
        k=18; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'TpHL'});
        k=23; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area2(p)xdt';'[A*us]'});
        k=28; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(tpHL)'});
        k=33; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'Fullness12'});                 xlabel('Event No');   % xxxxxx
        k= 7; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1 in time';'[us]'});
        k=17; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG2 in time';'[ms]'});
        k=22; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG3 in time';'[us]'});
        k=27; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fall-';'Intercept[ms]'});      
        k= 6; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1 in';'current[A]'});
        k=11; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG2 in';'current[A]'});
        k=32; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'max dI/dt ';'at push'});       xlabel('Event No');
        k=34; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8);                  ylabel({'push-phase';'slope(u,reg)'});  xlabel('Event No');
        k=19; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(push)';'[A*us]'});  
        k= 9; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'slope(w)'});         
        k=16; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1';'slope(1)'});               
        k=21; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1';'slope(2)'});               
        k=26; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Slope of';'1. fall(CoG1)'});   
        k=29; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'slope(last)'});  
        k=12; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1 in time';'(smt)[us]'});
        k=14; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'I-deviating';'time [us]'});
        % k= 5; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'cvt max(u)'});
        k= 5; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'Area1(u)'});
        % k=10; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'Pcvt avg(u)'});
        k=10; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'Area1(l)'});
        % k=15; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'Ncvt avg(u)'});
        k=15; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'AreaX u/l'});
        % k=20; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'cvt min(u)'});
        k=20; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'ratio u(1/2)'});
        % k=25; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'sameAxis. max c';'[us]'});
        k=25; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'ratio l(1/2)'});
        % k=30; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'sameAxis. min c';'[us]'});
        k=30; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'push-phase';'Area1(u)A'});
        k=24; hdlOfPlot(k) = subplot(7,5,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area2(push)';'[A*us]'}); 

        title(hdlOfPlot(3), {['Analysis of current V-shape (krbg) of case ', num2str(theNumOfFile)];buildTitle(caseDescription)}, 'FontSize',9);
        for n = 1:length(hdlOfPlot)
           resizeSubplot(hdlOfPlot(n), 1.2, 1, 1.28, 1.29);
        end
    else
        k= 2; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'tmax [ms]'});
        k= 1; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Imax [A]'});
        k= 3; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(0.25t)';'[A.ms]'});
        k= 7; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(0.25I)';'[A.ms]'});
        k=19; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 1+2'});
        k=20; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area Ratio';'1/2'});
        k=24; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area Ratio';'1/12'});
        k= 5; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fullness1'});
        k= 9; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fullness2'});
        k=21; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fullness12'});
        k=11; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 3';'[A.ms]'});
        k=15; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 4';'[A.ms]'});
        k=23; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area 3+4'});
        k=27; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8                 ); ylabel({'Area Ratio';'3/4'});               xlabel('Event No'); 
        k=28; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8                 ); ylabel({'Area Ratio';'3/34'});              xlabel('Event No'); 
        k=13; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fullness3'});
        k=17; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Fullness4'});
        k=25; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8                 ); ylabel({'Fullness';'34'});                  xlabel('Event No'); 
        k=22; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area ratio13'});
        k= 6; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1 in';'time[us]'});
        k=10; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG2 in';'time[ms]'});
        k=14; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG3 in';'time[us]'});
        k=18; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG4 in';'time[ms]'});
        k= 4; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(0.33t)';'[A.ms]'}); % ylabel({'Curve length';'(250)'});
        k=12; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'CoG1';'/Fullness3'});             
        k= 8; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area1(0.33I)';'[A.ms]'});  
        k=26; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8                 ); ylabel({'Fullness';'ratio13'});         xlabel('Event No'); 
        k=16; hdlOfPlot(k) = subplot(7,4,k, 'FontSize',8, 'XTickLabel',[]); ylabel({'Area ratio12';'/Fullness3'});  % xlabel('Event No');     
        title(hdlOfPlot(2), {['Analysis of current tail (krbg) of case ', num2str(theNumOfFile)];buildTitle(caseDescription)}, 'FontSize',9);

        % resizeSubplot(hdlOfPlot(k), 0.2, 0.26); 
        for n = 1:length(hdlOfPlot)
           resizeSubplot(hdlOfPlot(n), 1.2, 1, 1.3, 1.29);
        end
        
    end
    hdlOfPloti = hdlOfPlot;
    linkaxes(hdlOfPlot, 'x');
end

myColor = [0   0   0; 1   0   0; 0   0   1; 0   1   0; 0   1   1; 1   1   0; 1   0   1; 0.5 0   0];   % my color order k r b g c y m brown

x = eventCounter; % phiSweep1 + eventCounter*(phiSweep2-phiSweep1);
axes(hdlOfPloti(landmarki)); bringFigToFromBackground(j, plotInForeground); 
hold('on'); plot(x, y, '.', 'Color',myColor(i,:)); grid('on'); 

hdlOfPlot = hdlOfPloti;

end



function [deviatStart, jDeviate]= getDeviationStart(time1, current, jPushStart, jPeakStart, jPeakEnd, delayDeviate, threshold4DeviateDetect)
% get current deviation counting from push start to deviation starting point 
% unit ms

% delayDeviate            = 0; % -48;  % > 0 delay; <0 in advance
% threshold4DeviateDetect = 0.3; % [log(A)]
time2 = 1000*(time1(jPushStart:jPeakEnd)-time1(jPushStart));
y     = log(current(jPeakStart)-current(jPushStart:jPeakStart));

iMid  = 1 + floor((jPeakStart-jPushStart)/3);   % do linear regression from 0-1/3 of the push phase
iEnd  = 1 + (jPeakStart-jPushStart);

% do regression
[g, a, yc] = linearRegression(y(1:iMid), 1, 1, iMid, 0);

jDeviate = 0;
for i = iMid:iEnd
    if (yc+g*(0:jPeakStart-jPushStart+1))-y(i)>=threshold4DeviateDetect,
        jDeviate = i;
        break;
    end
end

if jDeviate==0,
    aaa=0;
end


jDeviate     = jDeviate + jPushStart-1 + delayDeviate; % 48 point ~ 0.25ms for advancing the time point a little
deviatStart  = 1000*(time1(jDeviate)-time1(jPushStart));

if 0,
    % make a figure to show the log thing
    i = i+delayDeviate;
    figure(9);clf; set(gcf, 'MenuBar','figure');
    plot(time2, current(jPushStart:jPeakEnd), 'k'); hold on
    plot(time2(1:8:iEnd),y(1:8:iEnd), 'b.'); hold on; 
    plot(time2(i), y(i), 'ro'); hold on;
    plot(time2(1:iEnd),yc+g*(0:iEnd-1), 'r');
    % plot Area 1
    iStart    = jDeviate;
    iMax      = jDeviate+48;
    iLast     = jDeviate+48;
    fractioni = 1;
    factor1   = 0.33;
    iEnd1     = min(iMax, round(iStart+(1+iLast-iStart)*fractioni));
    iMid      = floor(iStart + factor1*(iEnd1-iStart));
    plot(1000*(time1([iStart,iMid,iEnd1,iEnd1,iStart])-time1(jPushStart)), current([iStart,iMid,iEnd1,iStart,iStart]), 'r-');
    plot(1000*(time1(iMid)-time1(jPushStart)), current(iMid), 'k+');
    
    grid('on');
    title(['Deviation starting index/time=',num2str(i),'/',num2str(deviatStart),'[ms]']);
    ylabel({'Currents: original, ';'treated with loarithmic function and its linear fit'});
    xlabel('time [ms]');
    set(gcf, 'Color',[1 1 1]);
end;

aaa = 0;
end


% function yLimitiNew = updateYlimit(eventCounter, yLimiti, hdlOfPloti, plotInForeground)
% 
% if nargin < 4,
%     plotInForeground = 'off';
% end
% 
% yLimitiNew = yLimiti;
% if eventCounter > 4,
%     axes(hdlOfPloti); bringFigToFromBackground(gcf, plotInForeground);
% 
%     axis('tight');
%     xyLimit   = axis;
%     if 0,
%         yLimitiNew(1) = xyLimit(3);
%         yLimitiNew(2) = xyLimit(4);
%     else
%         
%         yLim1     = floor(100*xyLimit(3))/100;  % round it up
%         yLim2     = ceil(100*xyLimit(4))/100;   % round it up
% %           yLim1     = xyLimit(3);  % round it up
% %           yLim2     = xyLimit(4);   % round it up
%         
%         if yLim1 < yLimiti(1),  % update if a still lower limit is there
%             yLimitiNew(1) = yLim1;
%         end
%         if yLim2 > yLimiti(2),  % update if a still higher limit is there
%             yLimitiNew(2) = yLim2;
%         end
%         
%         set(hdlOfPloti, 'YLim',yLimitiNew);
%         if xyLimit(1)<xyLimit(2),
%             set(hdlOfPloti, 'XLim',[xyLimit(1) xyLimit(2)]);
%             %        set(hdlOfPloti, 'XLim',[xyLimit(1) min(xyLimit(2),25)]);
%         end
%     end
% end
% end

function resizeSubplot(hdlOfPlot, xShift, yShift, xFactor, yFactor, spaceBetween)

if nargin == 3,
    xShift = 0;
    yShift = 0;
    spaceBetween = 0;
end
hold('on');
drawnow;
ppp = get(hdlOfPlot, 'Position');

% set(hdlOfPlot, 'Position', ppp .* [1+xFactor 1 1 1+yFactor] - [0.07 0.7*yFactor*ppp(4) 0 0], ...
%     'FontSize',8, 'Box','on');
% xShift = -0.08;
% yShift = -0.01;
set(hdlOfPlot, 'Position', ppp .* [xShift yShift xFactor yFactor] + [-0.11 -0.02 0 0], ...
    'FontSize',8, 'Box','on');

grid('on'); 
axis('tight');
 
end


function titleText = buildTitle(caseDescription)
%                  folder name       file name
% caseDescription = '20deg'    'AET8641000'
%                   'fast'     '10'        
%                   'slow'     'LVO'       
%                   'nom'      '11k0V'     
%                   'stuck'    '09k0A'     
%                   'LVO'      '1000'
% or
%                   'TailAnalyse'       'AET8511000'
%                   '20deg'             '10'        
%                   'stuck-op-Softw'    'FL'        
%                   'stuck-cl-Softw'    '11k0V'     
%                   'nom'               '13k0A'     
%                   'stuck-cl-Soft'     '1000'      
% or
%                                       AET8811000
%                                       10
%                                       xxx
%                                       360
%                                       620
%                                       1000
%
titleText = '';
[nRow nCol] = size(caseDescription);
% get rid of []
for i = 1:nRow
    for j = 1:nCol
        if isempty(cell2mat(caseDescription(i,j))),
            caseDescription{i,j} = 'empty';
        end  
    end
end

if isempty(myStrfind('k',cell2mat(caseDescription(:,2)'))),  % no k in the string
    if ~isempty(caseDescription{5,2}),
        titleText = [titleText, 'with parameters of Phi1/2, etc. ', caseDescription{4,2}, ...
            ', ', caseDescription{5,2}, '[�CA]'];
    end
    if ~isempty(caseDescription{1,1}),
        titleText = [titleText, ' at ', caseDescription{6,2}, '[rpm]']; % rpm
    end
else  % some 09k5A like string is there in the second column
    if ~isempty(caseDescription{5,2}),
        titleText = [titleText, 'with current ', caseDescription{5,2}];  % I
    end    
    if ~isempty(caseDescription{4,2}),
        titleText = [titleText, ' and battery voltage ', caseDescription{4,2}]; % V
    end    
    if ~isempty(caseDescription{3,2}),
        titleText = [titleText, ' in ', caseDescription{3,2}, ' mode'];  % mode
    end    
end

if ~isempty(caseDescription{1,1}),  % check if the first or the second is temperature
    kTemp  = 1;
    while kTemp < nRow,
        strTmp = caseDescription{kTemp,1};
        if ~isempty(myStrfind(strTmp, 'deg')),
            break
        end
        kTemp = kTemp + 1;
    end
    titleText = [titleText, ' at ', caseDescription{kTemp,1}]; % temperature
end
if ~isempty(caseDescription{kTemp+1,1}) && kTemp+4<=nRow,
    titleText = [titleText, ' (SV:', caseDescription{kTemp+1,1},'/',caseDescription{kTemp+2,1},'/',caseDescription{kTemp+3,1},'/',caseDescription{kTemp+4,1},')'];
end

aaa=0;

end


function lengthi = lengthOfCurve(dt, y, iStart, iEnd)
% calculate squared curve lengthi from iStart, iEnd
if 0,
    lengthi = 0;
    for i = iStart+1:iEnd
        lengthi = lengthi + (y(i)-y(i-1))^2;
    end
    lengthi = lengthi +  dt*dt * double(iEnd-iStart);
end

if 1,   % with some averaging, first numOfPoint4Everage/2 and the last numOfPoint4Everage/2 are not counted points are
    lengthi = 0;
    numOfPoint4Everage = 5;   % do average with extra 2 fromthe left and extra 2 at the right
    for i = iStart:iEnd-numOfPoint4Everage
        lengthi = lengthi + sqrt(dt*dt + (y(i)-y(i+numOfPoint4Everage))^2/double(numOfPoint4Everage)/double(numOfPoint4Everage));
    end
    lengthi = lengthi/1000;  % change here and not out 
%     lengthi =  * lengthi ...
%         +  * double(iEnd-numOfPoint4Everage-iStart);  
end
aaa=0;
end

function indexOfGC4t = getCoG4t(dt, y, halfWeight, iStart, iEnd, iSmooth)

if nargin == 5,
    iSmooth = 0;
end

if iEnd-iStart <= 1,   % if almost no area
    indexOfGC4t = iEnd;
    return
end

if iSmooth,
    ySmoothed   = smoothOut(y(iStart:iEnd), 12); 
    [yMin jMin] = min(ySmoothed);
    integral1   = dt * sum(ySmoothed(1:jMin));
    i1          = findCenterOfGravity(ySmoothed, 0.5*integral1, 1, jMin, dt);
    indexOfGC4t = floor(iStart+i1-1);
else
    % unit: A, s
    i1 = findCenterOfGravity(y, halfWeight, iStart, iEnd, dt);
    indexOfGC4t = floor(i1);
end
end


function i1 = findCenterOfGravity(y, halfWeight, iStart, iEnd, dt)
% find middle point of an area; halfWeight can be negative
tmp = 0.0;
i1  = iStart;
for i = iStart:iEnd
    tmp = tmp + y(i); 
    if halfWeight < 0,
        if tmp <= halfWeight/dt,
            i1 = i;
            break
        end
    elseif halfWeight > 0,
        if tmp >= halfWeight/dt,
            i1 = i;
            break
        end
    else
        i1 = iStart;
    end
end 
end

function ySmoothed = smoothOut(y, halfNumOfSample4Average)
% for each point i, take a few points from left anf right and get their everage and
% put it there

numOfSignal = length(y);
halfNumOfSample4Average = min(halfNumOfSample4Average, floor(0.4*numOfSignal));
NumOfSample4Average = 2*halfNumOfSample4Average + 1;
sumSignal   = double(0);
yTmp        = zeros(1,numOfSignal); 
ySmoothed   = zeros(1,numOfSignal); 
i           = int32(0);
j           = int32(0);
indice      = halfNumOfSample4Average+1:numOfSignal-halfNumOfSample4Average;
% after halfNumOfSample4Average, smoothing
for i = indice
    ySmoothed(i) = mean(y(i-halfNumOfSample4Average:i+halfNumOfSample4Average));
end
%ySmoothed(indice)      = yTmp(indice) / double(NumOfSample4Average);

% the first few points
for i = halfNumOfSample4Average:-1:1
    iEnd = i+halfNumOfSample4Average-1;
    if iEnd <= numOfSignal, % do not overdo for ine point
       ySmoothed(i) = mean(y(1:iEnd));
    end
end

% the last few points
for i = numOfSignal-halfNumOfSample4Average+1:numOfSignal
    iStart = i-halfNumOfSample4Average;
    if iStart >= 1,
        ySmoothed(i) = mean(y(iStart:numOfSignal));
    end
end
aaa=0;
end


function indexOfGC4I = getCoG4I(dt, y, halfWeight, iStart, iEnd)

% find the center of gravity
if iStart == iEnd,
    indexOfGC4I = iStart;
    return
end

tmp = 0.0;
i1  = iStart+1;
for i = iStart+1:iEnd
    tmp = tmp + (y(i)-y(i-1))*double(i-iStart);
    if abs(tmp)*dt >= halfWeight,
        i1 = i;
        break
    end
end
indexOfGC4I = floor(i1);
end


function integral = integrateMI(dt, y, iStart, iEnd)
integral = 0.0;
tmp      = y(iEnd);
for i = iStart+1:iEnd
    integral = integral + double((i-iStart)^2)*abs(y(i)-tmp);
end
integral = dt*dt * integral;
end

function integral = integrateIt(dt, yRef, y, iStart, iEnd)
% it can be negative
integral = sum(y(iStart:iEnd));
integral = dt*(yRef*double(iEnd-iStart)+integral);
end

function [area1 area2] = getArea1(dt, y, iStart, iMax, iLast, jPeakStart, fractioni, iMethod, factor1)
% integrate to a specific point: 2/5 point or Imax which is first
% iMethed = 1: whole curved triagle
% iMethed = 2: approximation of the curved triagle based on tmax portion
% iMethed = 3: approximation of the curved triagle based Imax portion
% fractioni: fraction of 0 to tmax for Method=2 (or 0 to Imax forciMethod=3)
% factor1: fraction of fractioni for middle point only based on tmax

if iMethod == 1,
    % whole curved triagle
    iEnd1    = min(iMax, round(iStart+(1+iLast-iStart)*fractioni));
    area2 = 1000*dt*sum(y(iStart:iEnd1));
    area1 = 1000*dt*double(iEnd1-iStart)*y(iEnd1) - area2;
elseif iMethod == 2,
    % simplified triangle
    if iLast>jPeakStart,
        area1 = NaN;
        area2 = NaN;
    else
        yStart = y(iStart);
        iEnd1  = min(iMax, round(iStart+(1+iLast-iStart)*fractioni));
        iMid   = floor(iStart + factor1*(iEnd1-iStart));
        yMid   = y(iMid)  - yStart;
        yEnd1  = y(iEnd1) - yStart;
        
        % area 2: between curve and x-axis
        area2 = 1000*0.5*dt*(double(iMid-iStart)*yMid + double(iEnd1-iMid)*(yMid+yEnd1));
        % complementary of area 2
        area1 = 1000*dt*(double(iEnd1-iStart)*yEnd1) - area2;
        area1 = abs(area1);
        area2 = abs(area2);
    end
elseif iMethod == 3,
    % simplified triangle based on portion according to Imax
    
    iEnd1 = iMax;
    yFraction  = y(iMax)*fractioni;
    for i = iMax:iLast
        if y(i) >= yFraction
            iEnd1 = i;
            break;
        end
    end
    iMid  = floor(iStart + factor1*(iEnd1-iStart));
    yMid  = y(iMid);
    area2 = 1000*0.5*dt*(double(iMid-iStart)*yMid + double(iEnd1-iMid)*(yMid+y(iEnd1)));
    area1 = 1000*dt*(double(iEnd1-iStart)*y(iEnd1)) - area2;
    
end

end


function currentCorrected = offsetElimitate(current)
% offsetElimitate --- use median to get rid of offset of signal SV current
% Method          --- find the median for all data points of which the
%                     values are less than the their mean.
% current         --- array with size of
%                     (number of current data points) x (number of SV/cylinder)

% 20120808 wangwig@schaeffler.com


% the size of current is nRow x nCol
[nRow nCol]      = size(current);

% current without offset
currentCorrected = zeros(nRow,nCol);

% mean (1xnCol) of all current points
currentMean      = mean(current);

% offset (1xnCol) obtained from current points
currentOffset    = zeros(1, nCol);

for i = 1:nCol
    currentOffset(i) = median(current(current(:,i) < currentMean(i),i));
    % get the final current value with offset removed
    currentCorrected(:,i) = current(:,i) - currentOffset(i);
end
fprintf('\nOffsets of lift/current for %i. cylinders/SV''s: %10.6f %10.6f %10.6f %10.6f\n', nCol, currentOffset);
end



function isTailOK = plausibilitCheck4(i, eventCounter, current, jTailStart, jTailMax, jTailEnd)
% check if V-shape is there
isTailOK = 0;

if current(jTailMax, i) < 3,
    isTailOK = 1;
end

end


function isVShape = plausibilitCheck3(i, eventCounter, current, jPushStart, jPeakStart,jVShapeValley,jPeakEnd, jHoldEnd)
% check if V-shape is there
isVShape = 0;
[differenceOfGradient gradBefore gradAfter]= gradientDifference(current, jVShapeValley, 1, ...
    max(2,jVShapeValley-jPeakStart), max(2,jPeakEnd-jVShapeValley));
isVShape = (abs(differenceOfGradient)>0.003 || abs(gradBefore)>0.003 || abs(gradAfter)>0.003);

if isVShape,
    if current(jPeakStart) < current(jHoldEnd),
        isVShape = 0;
    end
end

aaa=0;
end

function okFlag = plausibilitCheck2(i, eventCounter, current, jPushStart,jPeakStart,jVShapeValley,jPeakEnd,jHoldEnd)
okFlag = 1;
if current(jPushStart)>=current(jPeakStart),
    fprintf('\nError: not plausible caused by current at jPushStart(%i)>=jPeakStart(%i) for event %i from cylinder %i.',...
        jPushStart,jPeakStart,eventCounter, i);
    okFlag = 0;
end
if current(jPeakStart)<current(jVShapeValley),
    fprintf('\nError: not plausible caused by current at jPeakStart(%i)<jVShapeValley(%i) for event %i from cylinder %i.',...
        jPeakStart,jVShapeValley,eventCounter, i);
    okFlag = 0;
end

end


function okFlag = plausibilitCheck1(i, eventCounter, jPushStart,jPeakStart,jVShapeValley,jPeakEnd,jHoldEnd)
% plausibility check 1:
% jPushStart<jPeakStart<jVShapeValley<jPeakEnd<jHoldEnd
okFlag = 1;
if jPushStart>=jPeakStart,
    fprintf('\nError: not plausible caused by jPushStart(%i)>=jPeakStart(%i) for event %i from cylinder %i.',...
        jPushStart,jPeakStart,eventCounter, i);
    okFlag = 0;
end
if jPeakStart>=jVShapeValley,
    fprintf('\nError: not plausible caused by jPeakStart(%i)>=jVShapeValley(%i) for event %i from cylinder %i.',...
        jPeakStart,jVShapeValley,eventCounter, i);
    okFlag = 0;
end
if jVShapeValley>jPeakEnd,
    fprintf('\nError: not plausible caused by jVShapeValley(%i)>=jPeakEnd(%i) for event %i from cylinder %i.',...
        jVShapeValley,jPeakEnd,eventCounter, i);
    okFlag = 0;
end
if jPeakEnd>=jHoldEnd,
    fprintf('\nError: not plausible caused by jPeakEnd(%i)>=jHoldEnd(%i) for event %i from cylinder %i.',...
        jPeakEnd,jHoldEnd,eventCounter, i);
    okFlag = 0;
end

end


function [yMax indexYMax] = getMaxAndIndex(signal, iStart, iEnd)
indexYMax  = int32(1);
yMax       = -1e20;
for i = iStart:min(length(signal),iEnd)
    if signal(i) >= yMax,
        yMax = signal(i);
        indexYMax  = i;
    end
end
end

function [yMin indexYMin] = getMinAndIndex(signal, iStart, iEnd)
indexYMin  = int32(0);
yMin       = 1e20;
for i = iStart:min(length(signal),iEnd)
    if signal(i) < yMin,
        yMin = signal(i);
        indexYMin  = i;
    end
end
end


function indexPeak = get2ndPeak(current, jStart, jStep, jEnd, numOfPoint4Regression, ...
    thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHoldHorizLeft = 0: check also orientation at right of a point
%           1111: no orientation check
% thresSTD = 0.15: check also zigzag at left of a point;
%          negative: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = 1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jEnd = max(jEnd, numOfPoint4Regression-jStep);
end

for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
    [differenceOfGradient orientationBefore orientationAfter] = gradientDifference(current, j, 1, ...
        numOfPoint4Regression);
%     if j >= 11616-22 && j <= 11616+22,
%         jTmp  = max(1, j-24);
%         jTmp1 = max(1, j+24);        
%         fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%             j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%     end
    
    if thresSTD <= 0, % check the std at left
        jTmp = max(1, j-24);  % take left 24 point to do std
    else
        jTmp = min(numOfCurrentPoint, j+24);  % take left 24 point to do std
    end
    
    if thresHorizo <= 0, % check the orientation at left
        if differenceOfGradient<thresGradi && abs(orientationBefore)>abs(thresHorizo),
            if std(current(jTmp:j)) >= abs(thresSTD),
                j2 = j;
                break;
            end
        end
    else % check the orientation at right
        % first a special case
%         if differenceOfGradient<2.5*thresGradi && abs(orientationAfter)>thresHorizo && ...
%                 orientationBefore>=-0.003,
%             if std(current(jTmp:j)) >= abs(thresSTD),
%                 j2 = j;
%                 break;
%             end           
        if differenceOfGradient<thresGradi && abs(orientationAfter)>thresHorizo ...
                && (current(j+2)-current(j))*(current(j)-current(j-2))<=0 && (current(j+2)-current(j))<=0,
            % if differenceOfGradient<2.5*thresGradi && orientationBefore>=-0.003,
            % check std at left
            if std(current(jTmp:j)) >= abs(thresSTD),
                j2 = j;
                break;
            end
        elseif differenceOfGradient>-0.3*thresGradi && orientationBefore<-0.015 && orientationAfter>0.03,    % check if the hold end is a valley
            jTmp = min(numOfCurrentPoint, j+24);
            if std(current(j:jTmp)) >= abs(thresSTD),
                j2 = j;
                break;
            end
            
        end
    end
end

if j2 == jEnd,
    indexPeak = 0;
%     fprintf('\nWarning: found no landmark.');
else
    indexPeak = j2;
end
end

function indexPeak = getHoldEnd(current, jStart, jStep, jEnd, numOfPoint4Regression, ...
    thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHorizo = 0: check also orientation at right of a point
%           1111: no orientation check
% thresSTD = -0.15: check also zigzag at left of a point;
%              =  0.15: check zigzag at right of a point;
%          negative: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = 1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jTmp   = jStart;
    jStart = min(jEnd-numOfPoint4Regression, numOfCurrentPoint-numOfPoint4Regression);
    jEnd   = jTmp;
end

for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
    [differenceOfGradient orientationBefore orientationAfter] = gradientDifference(current, j, 1, 2*numOfPoint4Regression, numOfPoint4Regression);
%     if (j >= 87143-20 && j <= 87143+20),
%         jTmp = max(1, j-24);
%         jTmp1 = max(1, j+24);        
%         fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%             j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%     end
    
    if thresSTD <= 0, % check the std at left
        jTmp = max(1, j-24);  % take left 24 point to do std
    else
        jTmp = min(numOfCurrentPoint, j+24);  % take left 24 point to do std
    end
    if thresHorizo <= 0, % check the orientation at left
        if differenceOfGradient<thresGradi && abs(orientationBefore)<abs(thresHorizo),
            if std(current(jTmp:j)) >= abs(thresSTD),
                j2 = j;
                % check if this is only a spike
                if mean(current(max(1,jTmp-200):j))<0.4*max(current(jTmp:j)),
                    indexPeak = 0;
                    return;
                else
                    break;
                end
            end
        end
    else
        if differenceOfGradient<thresGradi && abs(orientationAfter)<thresHorizo,
            if std(current(j:jTmp)) >= abs(thresSTD),
                j2 = j;
                break;
            end
        end
    end
end


if j2 == jEnd,  % if it goest to end, not found
    indexPeak = 0;
%     fprintf('\nWarning: found no landmark.');
else
    indexPeak = j2;
end
end


function indexPeak = get1stPeak(current, jStart, jStep, jEnd, numOfPoint4Regression, thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHorizo = 0: check also orientation at right of a point
%           1111: no orientation check
% thresSTD = -0.15: check also zigzag at left of a point;
%              =  0.15: check zigzag at right of a point;
%          negative: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = 1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jEnd = max(jEnd, numOfPoint4Regression-jStep);
end

for j = jStart+2*numOfPoint4Regression*sign(jStep):jStep:jEnd
    [differenceOfGradient orientationBefore orientationAfter] = gradientDifference(current, j, 1, 8, 16, 0, 0);
%     if (j >= 19656-20 && j <= 19656+20),
%         jTmp = max(1, j-24);
%         jTmp1 = max(1, j+24);        
%         fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%             j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%     end
    
    if thresSTD <= 0, % check the std at left
        jTmp = max(1, j-24);  % take left 24 point to do std
    else
        jTmp = min(numOfCurrentPoint, j+24);  % take left 24 point to do std
    end
    if thresHorizo <= 0, % check the orientation at left???
        if differenceOfGradient<thresGradi && abs(orientationBefore)>abs(thresHorizo),
            if std(current(jTmp:j)) >= abs(thresSTD),
                j2 = j;
                if j2 == jEnd, % it marches to the end already
                    j2 = 0;
                elseif j2 == 0,
                    j2 = 0;
                elseif current(j2) <= 5,  % it marches back to push phase already
                    indexPeak = 0;
                else
                    break;
                end
            end
        end
    else  % check the orientation at left and right
        % get how smooth is at push phase
        jIndex      = j-8:j;
        xm          = mean(jIndex);
        ym          = mean(current(jIndex));
        smoothOrNot = std(current(jIndex)-(ym+orientationBefore*(jIndex'-xm)));
        
        if differenceOfGradient<thresGradi && orientationBefore>thresHorizo ...
                && orientationAfter<-0.006 ...  % -0.01 ...
                && smoothOrNot<0.15 ...    % 0.1 ...
                && (current(j+2)-current(j))*(current(j)-current(j-2))<=0 && (current(j)-current(j-2))>=0,
            if std(current(j:jTmp)) >= abs(thresSTD),
                j2 = j;
                % check if it is plausible
                if j2 == jEnd, % it marches to the end already
                    j2 = 0;
                elseif j2 == 0,
                    j2 = 0;
                elseif current(j2) <= 5,  % it marches back to push phase already
                    indexPeak = 0;
                else
                    break;
                end
            end
        end
    end
end

if j2 == jEnd, % it marches to the end already
    indexPeak = 0;
elseif j2 == 0,
    indexPeak = 0;
elseif current(j2) <= 5,  % it marches back to push phase already
    indexPeak = 0;
else
    indexPeak = j2;
end
end


function indexPeak = getLowerEdge(current, jStart, jStep, jEnd, numOfPoint4Regression, thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHorizo = -0.08: check also orientation at left of a point
%                   0.08: check also orientation at right of a point
%           1111: no orientation check
% thresSTD = 0.01: check also zigzag at left of a point;
%           1111: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = -1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jEnd = max(jEnd, numOfPoint4Regression-jStep);
end

for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
    [differenceOfGradient orientationBefore orientationAfter] = gradientDifference(current, j, 1, numOfPoint4Regression);

%     if (j >= 62052+222-20 && j <= 62052+222+20),
%         jTmp = max(1, j-24);
%         jTmp1 = max(1, j+24);        
%         fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%             j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%     end
    
    if thresSTD <= 0, % check the std at left
        jTmp = max(1, j-24):j;  % take left 24 point to do std
    else
        jTmp = j:min(numOfCurrentPoint, j+24);  % take left 24 point to do std
    end
    
    if thresGradi < 0,
        if differenceOfGradient<thresGradi,
            if thresHorizo <= 0, % check the orientation at left
                if abs(orientationBefore)<abs(thresHorizo) && std(current(jTmp))<=abs(thresSTD),
                    j2 = j;
                    break;
                end
            else
                if abs(orientationAfter)<abs(thresHorizo) && std(current(jTmp))<=abs(thresSTD),
                    j2 = j;
                    break;
                end
            end
        end
    else
        if differenceOfGradient>=thresGradi,
            if thresHorizo <= 0, % check the orientation at left
                if abs(orientationBefore)<abs(thresHorizo) && std(current(jTmp))<=abs(thresSTD),
                    j2 = j;
                    break;
                end
            else
                if abs(orientationAfter)<abs(thresHorizo), %  && std(current(jTmp))<=abs(thresSTD),
                    j2 = j;
                    break;
                end
            end
        end
    end
end

if j2 == jEnd,
    indexPeak = 0;
%     fprintf('\nWarning: found no landmark.');
else
    indexPeak = j2;
end
end

function indexPeak = getPushStart(current, jStart, jStep, jEnd, ...
    numOfPoint4Regression, thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHorizo = 0.08: check also orientation at left of a point
%           1111: no orientation check
% thresSTD = 0.01: check also zigzag at left of a point;
%           1111: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = -1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jEnd = max(jEnd, numOfPoint4Regression-jStep);
end
 
if 0,
    for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
        [differenceOfGradient orientationBefore, orientationAfter] = gradientDifference(current, j, 1, numOfPoint4Regression);
        
%         if (j >= 4316-20 && j <= 4316+20),
%             jTmp = max(1, j-24);
%             jTmp1 = max(1, j+24);
%             fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%                 j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%         end
        
        if differenceOfGradient>thresGradi && abs(orientationBefore)<thresHorizo,
            jTmp = max(1, j-24);  % take left 24 point to do std
            if std(current(jTmp:j)) >= thresSTD,
                j2 = j;
                break;
            end
        end
    end
end

if j2 == 0, % if not found, try to find one ditch bias case
    thresGradi   = 0.06; % 0.07; % 0.08; % 0.10; % 0.13; % 0.15;
    thresMaxDiff = 0.11; % 0.15;
    for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
        [differenceOfGradient orientationBefore, orientationAfter] = gradientDifference(current, j, 1, 24, 8);
%         if (j >= 34093-20 && j <= 34093+20),
%             jTmp = max(1, j-24);
%             jTmp1 = max(1, j+24);
%             fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%                 j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%             aaa=0;
%         end
        % get how smooth is at push phase
        jIndex      = max(1,j-24):j;
        xm          = mean(jIndex);
        ym          = mean(current(jIndex));
        smoothOrNot = std(current(jIndex)-(ym+orientationBefore*(jIndex'-xm)));

%         if differenceOfGradient>thresGradi ...
%            && orientationBefore<0 ...
%            && orientationAfter>0 ...
%            && max(abs(diff(current(j-8:j+4))))>thresMaxDiff,
        if differenceOfGradient>thresGradi ...
           && smoothOrNot>0.1 ...
           && abs(orientationBefore)<0.02 ...
           && orientationAfter>0 ...
           && max(abs(diff(current(j-8:j+4))))>thresMaxDiff,
           j2 = j;
           % check if it is plausible
           if j2 == jEnd,
               j2 = 0;
           elseif current(j2) > 6,  % it is not a bias current
               j2 = 0;
           else
               break;
           end
        end
    end
end

% last check
if j2 == jEnd,
    indexPeak = 0;
%     fprintf('\nWarning: found no landmark.');
elseif j2 == 0,
    indexPeak = 0;
elseif current(j2) > 6, 
    indexPeak = 0;
else
    indexPeak = j2;
end
end


function indexPeak = getBiasStart(current, jStart, jStep, jEnd, ...
    numOfPoint4Regression, thresGradi, thresHorizo, thresSTD)
% get a peak based on difference of gradients around a point.
% jStep > 0: search forwards  from jStart
% jStep < 0: search backwards from jStart
% thresHorizo = 0.08: check also orientation at left of a point
%           1111: no orientation check
% thresSTD = 0.01: check also zigzag at left of a point;
%           1111: no check

j                    = jStart;
numOfCurrentPoint    = length(current);
indexPeak            = 0;
differenceOfGradient = -1.0e33;
orientationBefore    = 1.0e33;
j2                   = 0;
if jStep > 0,
    jEnd = min(jEnd, numOfCurrentPoint-numOfPoint4Regression);
else
    jEnd = max(jEnd, numOfPoint4Regression-jStep);
end
 

if j2 == 0, % if not found, try to find one ditch bias case
    for j = jStart+numOfPoint4Regression*sign(jStep):jStep:jEnd
        [differenceOfGradient orientationBefore, orientationAfter] = gradientDifference(current, j, 1, 24, 8);
%         if (j >= 17268-20 && j <= 17268+20),
%             jTmp = max(1, j-24);
%             jTmp1 = max(1, j+24);
%             fprintf('\ngDiff orien std=%i %8.4f %8.4f %8.4f %8.4f %8.4f', ...
%                 j,differenceOfGradient,orientationBefore, orientationAfter, std(current(jTmp:j)), std(current(j:jTmp1)));
%             aaa=0;
%         end
        if differenceOfGradient>thresGradi ...
           && abs(orientationBefore)<0.0005 ...
           && orientationAfter>0.9*thresGradi,
           j2 = j;
           % check if it is plausible
           if j2 == jEnd,
               j2 = 0;
           elseif current(j2) > 0.1,  % it is not a current before bias start
               j2 = 0;
           else
               break;
           end
        end
    end
end

% last check
if j2 == jEnd,
    indexPeak = 0;
%     fprintf('\nWarning: found no landmark.');
elseif j2 == 0,
    indexPeak = 0;
elseif current(j2) > 6, 
    indexPeak = 0;
else
    indexPeak = j2;
end
end

function jTpHLEnd = getTpHLEnd(current, jPeakEnd, jHoldEnd)
% get the end of TpHL

jTpHLEnd       = 0;
for j = jPeakEnd:jHoldEnd
    if current(j)<current(j+3),
        jTpHLEnd = j;
        break;
    end
    
end

% jTpHLEnd0      = 0;
% HoldCurrentMin = 6.5; % 5
% HoldCurrentMax = 7;   % 6
% % check 15 points
% threshold1 = max(current(jHoldEnd),HoldCurrentMin);
% for j = jHoldEnd:-1:1
%     if current(j) > threshold1,
% %         for i = j:-1:max(1, j-15)
% %             if current(i+1)>current(i),
% %                 break;
% %             end
% %         end
% %         if i == max(1, j-15),
% %             jTpHLEnd0 = j;
% %             break;
% %         end
%        jTpHLEnd0 = j;
%        break
%     end
%     % raise the threshold to overcome current at jHoldENd too small
%     if j<jHoldEnd-33, % 33 = 4 chops
%         threshold1 = min(1.15*mean(current(j:jHoldEnd)),HoldCurrentMax);
%     end
% end
% % refine jTpHLEnd
% for j = jTpHLEnd0:jTpHLEnd0+111
%     if current(j)<current(j+3),
%         jTpHLEnd = j;
%         break;
%     end
%     
% end

end

function [differenceOfGradient gradBefore gradAfter]= gradientDifference(current, j, dx, numOfPointBefore, numOfPointAfter, iMethodBefore, iMethodAfter)
% numOfPointAfter  -- includes point j
% numOfPointBefore -- includes point j

if nargin < 5,
    numOfPointAfter = numOfPointBefore;
    iMethodBefore   = 0; % nomal LSQ
    iMethodAfter    = 0; % nomal LSQ
elseif nargin < 6,
    iMethodBefore   = 0;
    iMethodAfter    = 0;
elseif nargin < 7,
    iMethodAfter    = iMethodBefore;
end
% difference of gradients around point j with numOfPoint4Regression separated by dx
jStart     = max(1, j-numOfPointBefore+1);
jEnd       = j+numOfPointAfter-1;
gradAfter  = linearRegression(current(j:jEnd),   dx, 1, jEnd-j+1,    iMethodAfter);
gradBefore = linearRegression(current(jStart:j), dx, 1, j-jStart+1,  iMethodBefore);

differenceOfGradient = (gradAfter - gradBefore) / (1.0+gradAfter*gradBefore);
end


function [g, a] = linearRegression0(dx, y, n)
% linear regression for uniform delta x, based on n(>1) points
% y = a + g * x

if nargin == 2,
    n = length(y);
end
g = (0.5*n*(n-1)*dx * sum(y(1:n)) - n*dx* (linspace(1, n-1, n-1) * y(2:n))) / (0.25*n^2*(n-1)^2*dx*dx - n*dx*dx*sum((1:n-1).^2));
a = mean(y(1:n)) - g * double(n-1)/2*dx;
end






function theWord = getAWordFrom(aString, arg1, arg2)
% get a number out from aString between frist divider to the second
% e.g., from PA227_3000_EVC_THPC90_2.dat

if nargin < 2,
    divider = '_';
    ind   = find(aString==divider);
    iPos1 = ind(1);
    iPos2 = ind(2);
elseif nargin == 2,
    divider = arg1;
    ind   = find(aString==divider);
    iPos1 = ind(1);
    iPos2 = ind(2);
elseif nargin == 3,
    iPos1 = arg1;
    iPos2 = arg2;
end

theWord = aString(iPos1+1:iPos2-1);
end

function indexi = getIndex4deltaA(current, deltaA, jPushStart, iStep, jPeakStart)
% get an index for a delta-A
% iStep=-1: search from first peak
% iStep= 1: search from push start

signOfStep = sign(iStep);
indexi   = -1;
current1 = current(jPushStart);

for i = jPushStart:iStep:jPeakStart
    if current(i)*signOfStep >= signOfStep*current1+deltaA,
        indexi = i;
        break;
    end
end
aaa=0;
end



