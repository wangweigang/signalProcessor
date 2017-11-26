function [g, a, yc] = linearRegression(y, samplingTime, iMin1, iMax1, iMethod)
% linearReg uses linear regression method to get a curve slop
% by normal LSQ (iMethod=0) or my special one for fix the first point
% (iMethod=1)
% 20121115 wangwig@schaeffler.com

if nargin == 1,
    samplingTime = 1;
    iMin1        = 1;
    iMax1        = length(y);
    iMethod      = 0;
elseif nargin == 2,
    iMin1        = 1;
    iMax1        = length(y);
    iMethod      = 0;
elseif nargin == 3,
    iMax1        = length(y);
    iMethod      = 0;
elseif nargin == 4,
    iMethod      = 0;
end

% start and end indexes for evaluation window 
iStartWin     = min(iMax1, iMin1); 
iEndWin       = max(iMax1, iMin1);

if iStartWin == iEndWin,
    g  = -1e33;
    a  = 0.0;
    xc = 0;
    yc = y(iStartWin);
    return;
end

% linear regression on all points within the evaluation window

% 1. preparation
nIntv         = iEndWin - iStartWin;
n             = nIntv + 1;
sumXi         = 0;
sumXi2        = 0;
sumYi         = 0;
sumXiYi       = 0;

% 2. pressure difference based on the first pressure point
yStart        = y(iStartWin);
yEnd          = y(iEndWin);
y             = y - 0*yStart;

% 3. linear regression preparation
sumXi         = 0.5*double(nIntv*(nIntv+1));
sumXi2        = (double(2*nIntv+1)/6)*double(nIntv*(nIntv+1));
for i = 1:n
    ii        = (iStartWin-1) + i;
    sumXiYi   = sumXiYi + double(i-1)*y(ii); 
%    sumYi     = sumYi   + y(ii);
end
sumYi         = sum(y(iStartWin:iEndWin));

sumXi         = sumXi*samplingTime;
sumXi2        = sumXi2*samplingTime*samplingTime;
sumXiYi       = sumXiYi*samplingTime;

% 4. linear regression
if iMethod == -1,
    % modified LSQ with fixed point at left
    % y = yl + g*(x-xl)
    xFirst    = 0;
    yFirst    = y(iStartWin);
    % gradient
    g         = (sumXiYi - yFirst*sumXi - xFirst*sumYi + xFirst*yFirst) / ...
                (sumXi2 + xFirst*xFirst - 2*xFirst*sumXi);
    % interception
    a         = yFirst-g*xFirst + yStart;
    aaa = 0;
elseif iMethod == 1,
    % modified LSQ with fixed point at right
    % y = yl + g*(x-xl)
    xLast     = double(iEndWin-iStartWin)*samplingTime;
    yLast     = y(iEndWin);
    % gradient
    g         = (sumXiYi - yLast*sumXi - xLast*sumYi + xLast*yLast) / ...
                (sumXi2 + xLast*xLast - 2*xLast*sumXi);
    % interception
    a         = yLast-g*xLast + yStart;
else
    % normal LSQ
    % y = yl + g*(x-xl)
    % gradient
    g         = (sumXi*sumYi - sumXiYi*double(n)) / ...
                (sumXi*sumXi - sumXi2*double(n));
    % interception
    a         = (sumYi - g*sumXi) /double(n) + yStart;
    % xc, yc
    yc        = sumYi/n - g*sumXi/n;
end
end

