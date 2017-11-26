% check out changes of SV and MV angle

% load saveAFewVar.mat;
% load('C:\Project\Issue\blockedSV\tailVShape\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\angleResult002.mat');
load('E:\herzo\projects\Issue\blockedSV\CReffect\110deg_Ton-fast_Ton-slow_nom_stuck-mid-SVT\System_Stability_rpm_var\angleResult001.mat');
[numOfCyl numOfEvent] = size(saveAFewVar);
% vars in saveAFewVar
% [current(jPeakStart,i) x 1, angleSVClose x 1, angleMVOpen x 2, angleMVClose x 2, liftMVMax x 2, AngleMax1stDeriv x 1]

ttt = zeros(numOfEvent,9);

for i = 1:numOfCyl
     
    fprintf('processing for cylinder %i ... ...\n', i);
    
    figure(6+i); clf

    for j = 1:numOfEvent
        if ~isempty(saveAFewVar{i,j}),
            ttt(j,:) = saveAFewVar{i,j}(1:9);
        end
    end
    
    % current
    subplot(6,1,6); 
    plot(ttt(:,1), '.')
    ylabel('Current [A]'); grid('on'); xlabel('Event');
    set(gca, 'YLim',[8 16]); set(gca, 'XLim',[1 numOfEvent]);
    
    % SV Close angle
    subplot(6,1,5)
    plot(rem(ttt(:,2),720), '.');
    ylabel({'Close angle'; 'SV [degCA]'}); grid('on'); % xlabel('Event');
    set(gca, 'YLim',[100 500]); set(gca, 'XLim',[1 numOfEvent]);
   
    % MV open angle 
    subplot(6,1,4)
    plot(rem(ttt(:,3:4), 720), '.')
    ylabel({'Open angle'; 'MV [degCA]'}); grid('on'); % xlabel('Event');
    set(gca, 'YLim',[300 600]);
    set(gca, 'XLim',[1 numOfEvent]);
    
    % MV close angle 
    subplot(6,1,3)
    plot(rem(ttt(:,5:6), 720), '.')
    ylabel({'Close angle'; 'MV [degCA]'}); grid('on'); % xlabel('Event');
    set(gca, 'YLim',[300 600]); set(gca, 'XLim',[1 numOfEvent]);
    
    % max lift
    subplot(6,1,2)
    plot(ttt(:,7:8), '.')
    ylabel({'Lift'; 'MV [mm]'}); grid('on'); % xlabel('Event');
    set(gca, 'YLim',[1 8]); set(gca, 'XLim',[1 numOfEvent]);
    
    subplot(6,1,1); 
    plot(ttt(:,9), '.');
    ylabel({'Delta-CA';  '[degCA]'}); grid('on'); % xlabel('Event');
    % set(gca, 'YLim',[300 600]);
    set(gca, 'XLim',[1 numOfEvent]);
    
    
    title(['Cylinder ', num2str(i)]);
    aaa = 0;
end
    