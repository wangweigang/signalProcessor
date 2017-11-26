function plotXYwithEnvolop(x,y, points2See, titlei)
% plot the curve (current maybe) x,y and its envolop with consideration of
% point2See number of points (the smaller, the more influence on the
% envolop by the individual points
%
% Usage:  plotXYwithEnvolop(time, y, 22)
%
% call the function "env_secant.m" by Andreas Martin, Volkswagen AG, Germany
%
% Weigang 20151016
%

if nargin < 4,
    titlei = '';
end

% plot the curve
hold off; plot(x,y);
% get a segment from left max to right max

numOfPoint = length(x);

[~, i1] = max(y(1:floor(numOfPoint/2)));
[~, i2] = max(y(floor(numOfPoint/2):end));
i2      = i2 + floor(numOfPoint/2) - 1;
x1 = max([x(1), x(max([i1-10,1]))]);
x2 = min([x(numOfPoint), x(min([i2+10,numOfPoint]))]);

x          = x(i1:i2);
y          = y(i1:i2);
numOfPoint = i2-i1+1;

% get the envolop
eTop = env_secant(x, y, points2See, 'top');
eBot = env_secant(x, y, points2See, 'bottom');
% plot the envolop
hold on; plot(x,eTop,'b', x,eBot,'k');
% plot the envolop value but cut off a few points at the begining and at 
% the end
% find the first local min
i3 = i1;
for i = 1:floor(numOfPoint/4)
    if y(i)<y(i+1), 
        i3 = i;
        break;
    end
end
% find the last local min
i4 = i2;
for i = numOfPoint:-1:floor(numOfPoint*3/4)
    if y(i)<y(i-1), 
        i4 = i;
        break;
    end
end
hold on; plot(x(i3:i4), 10*(eTop(i3:i4)-eBot(i3:i4)), 'r');
set(gca, 'XLim',[x1, x2]);
set(gca, 'YLim',[0, 14]);
xlabel('time [s]'); ylabel('Current [A]'); 
title(['Current chopping and its envolop (', titlei,')'], 'Interpret','none');
grid on; hold off; 


