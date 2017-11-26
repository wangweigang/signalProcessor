function [g a] = linearRegTest(iMax1, iMin1, presManifold1, samplingCA)
% linearReg uses linear regression method to get the pressure slop
% based on CA. 
% it does the following,
% 1. dynamically locate a proper evaluation window;
% 2. use linear regression to calculate slope within the window
% 20120202 wangwig@schaeffler.com

% start and end indexes for evaluation window 
iStartWin     = min(iMax1, iMin1); 
iEndWin       = max(iMax1, iMin1);

if iStartWin == iEndWin,
    presSlope1 = -1e33;
    return;
end

% linear regression on all points within the evaluation window

% 1. preparation
nIntv         = iEndWin - iStartWin;
n             = nIntv + 1;
sumYi         = 0;
sumXiYi       = 0;

% 2. pressure difference based on the first pressure point
presStart     = presManifold1(iStartWin);
presManifold1 = presManifold1 - presStart;

% 3. linear regression
sumXi         = 0.5*double(nIntv*(nIntv+1));
sumXi2        = (double(2*nIntv+1)/6)*double(nIntv*(nIntv+1));
for i = iStartWin:iEndWin
    sumXiYi   = sumXiYi + double(i-iStartWin)*presManifold1(i); 
    sumYi     = sumYi   + presManifold1(i);
end
sumXiYi       = sumXiYi*samplingCA;
sumXi         = sumXi*samplingCA;
sumXi2        = sumXi2*samplingCA*samplingCA;

if 1,
    % modified LSQ with fixed point at left
    x1        = 0;
    y1        = presManifold1(iStartWin);
    % gradient
    g         = (sumXiYi - y1*sumXi - x1*sumYi + double(n)*x1*y1) / ...
                (sumXi2 + double(n)*x1*x1 - 2*x1*sumXi);
    % interception
    a         = y1 + presStart;
else
     % normal LSQ 
     % gradient
    g         = (sumXi*sumYi - sumXiYi*double(n)) / ...
                (sumXi*sumXi - sumXi2*double(n));
    % interception
    a         = (sumYi - g*sumXi) /double(n) + presStart;   
end
end

