function doubleV()

load current.mat;

numOfPoint = length(ccc);

samplingTime = 5.555e-6*1000

figure(1); clf;
hdlOfPlot = zeros(1,5);
for i = 1:5
    hdlOfPlot(i) = subplot(5,1,i);
end
linkaxes(hdlOfPlot, 'x');


subplot(5,1,1);
plot(ccc); 
axis('tight'); set(gca, 'XLim', [108 519]); grid on;
title('current signal');

cSmt = smoothOut(ccc, 5);

% cSmt = smoothOut(cSmt, 5);
% cSmt = ccc';
subplot(5,1,1); hold on
plot(cSmt, 'r-'); 
axis('tight'); set(gca, 'XLim', [108 519]); grid on;
title('current signal smoothed/original');

cSmt = smoothOut(cSmt, 5);
cSmt = smoothOut(cSmt, 5);
cSmt = smoothOut(cSmt, 5);
cSmt = smoothOut(cSmt, 5);


cSmt = ccc(:);
num4Regresssion = 15;
curvature       = zeros(numOfPoint,2);
%for i = num4Regresssion:numOfPoint-num4Regresssion
for i = 108:519
    s1                           = sqrt(samplingTime^2+(cSmt(i)-cSmt(i-1))^2);
    s2                           = sqrt(samplingTime^2+(cSmt(i)-cSmt(i+1))^2);
    [gradDiff gradAvg1 gradAvg2] = gradientDifference(cSmt, i, samplingTime*1000, num4Regresssion, num4Regresssion);
    alfa           = atan(gradDiff)*50;
    % alfa           = atan(gradientDifference(cSmt, i-1, samplingTime, num4Regresssion) + gradientDifference(cSmt, i+1, samplingTime, num4Regresssion));
    curvature(i,2) = alfa / (s1+s2);
    
    gradAvg        = 0.5*(gradAvg1 + gradAvg2);
    curvature(i,1) = gradDiff/samplingTime / (1+gradAvg^2)^1.5;

    
    fprintf('\ns1/2 alfa=%5i %+8.3e %+8.3e %+8.3e %+8.3e %+8.3e',i, curvature(i), s1,s2,alfa, cSmt(i)-cSmt(i-1));
end
subplot(5,1,2); hold off  
plot(curvature, '-'); 
axis('tight'); axis([108 519 -4 4]); grid on;
title('curvature');

dc = diff(cSmt);
subplot(5,1,3);
plot(smoothOut(smoothOut(dc))); 
axis('tight'); set(gca, 'XLim', [108 519]); grid on;
title('1st derivative');


jjj = getBetterMin(ccc(108:519), 11) + 108-1;


ddc = diff(dc);
subplot(5,1,4);
plot(smoothOut(smoothOut(ddc))); 
axis('tight'); set(gca, 'XLim', [108 519]); grid on;
title('2nd derivative');

dddc = diff(ddc);
subplot(5,1,5);
plot(smoothOut(smoothOut(dddc))); 
axis('tight'); set(gca, 'XLim', [108 519]); grid on;
title('3rd derivative');
end


function jMin = getBetterMin(y, numOfPoint4Regression)
% find a segment with 1st derivative from - to +
numOfPoint            = length(y);
% numOfPoint4Regression = 11;
for i = 1:5
    num4Divide = 2^i;
    iStep    = floor(numOfPoint/num4Divide);
    jSegmentStart = 0;
    for j = 1+numOfPoint4Regression:iStep:numOfPoint-iStep-numOfPoint4Regression
        j1 = j;
        j2 = min(j+iStep, numOfPoint);
        if linearRegression(1, y(j1-numOfPoint4Regression:j1+numOfPoint4Regression), 2*numOfPoint4Regression+1)<0 ...
                && linearRegression(1, y(j2-numOfPoint4Regression:j2+numOfPoint4Regression), 2*numOfPoint4Regression+1)>0,
            jSegmentStart = j;
            break
        end
    end
    if jSegmentStart ~= 0,
        break
    end
end
jSegmentEnd = jSegmentStart+iStep;
subplot(5,1,1); hold on;
plot(107+[jSegmentStart jSegmentEnd], [y(jSegmentStart) y(jSegmentEnd)], 'k*');

num4Divide = 2;
while jSegmentStart<jSegmentEnd-1
    
    jMidPoint  = floor((jSegmentStart+jSegmentEnd)/num4Divide);
    subplot(5,1,1); hold on;
    plot(107+[jMidPoint jMidPoint], [y(jMidPoint) y(jMidPoint)], 'ro');
    
    dy = linearRegression(1, y(jMidPoint-numOfPoint4Regression:jMidPoint+numOfPoint4Regression), 2*numOfPoint4Regression+1);
    if dy>0,
        jSegmentEnd = jMidPoint;
    else
        jSegmentStart = jMidPoint;
    end
    aaa=0;
end
jMin = jMidPoint;
end


function [differenceOfGradient gradBefore gradAfter]= ...
    gradientDifference(current, j, dx, numOfPointBefore, numOfPointAfter)
if nargin < 5,
    numOfPointAfter = numOfPointBefore;
end
% difference of gradients around point j with numOfPoint4Regression separated by dx
gradAfter  = linearRegression(dx, current(j:j+numOfPointAfter-1), numOfPointAfter);
gradBefore = linearRegression(dx, current(j-numOfPointBefore+1:j), numOfPointBefore);

differenceOfGradient = (gradAfter - gradBefore) / (1.0+gradAfter*gradBefore);
end


function gradient = linearRegression(dx, y, n)
% linear regression for uniform delta x, based on n points
% y is a colum vector
if n < 2,
    fprintf('Error: Too few data (%i<2) and Ctrl+C to stop. ', n);
    pause
end
gradient = (0.5*n*(n-1)*dx * sum(y(1:n)) - n*dx* (linspace(1, n-1, n-1) * y(2:n))) ...
    / (0.25*n^2*(n-1)^2*dx*dx - n*dx*dx*sum((1:n-1).^2));
end


function ySmoothed = smoothOut(y, halfNumOfSample4Average)
% for each point i, take a few points from left anf right and get their everage and
% put it there

if nargin == 1,
    halfNumOfSample4Average = 5;
end

numOfSignal = length(y);
NumOfSample4Average = 2*halfNumOfSample4Average + 1;
sumSignal   = double(0);
yTmp        = zeros(1,numOfSignal); 
ySmoothed   = zeros(1,numOfSignal); 
i           = int32(0);
j           = int32(0);
indice      = halfNumOfSample4Average+1:numOfSignal-halfNumOfSample4Average;
% after halfNumOfSample4Average, smoothing
for i = indice
    yTmp(i) = sum(y(i-halfNumOfSample4Average:i+halfNumOfSample4Average));
end
ySmoothed(indice)      = yTmp(indice) / double(NumOfSample4Average);
% the first few points
for i = halfNumOfSample4Average:-1:1
    ySmoothed(i) = mean(y(i:i+halfNumOfSample4Average-1));
end
% the last few points
for i = numOfSignal-halfNumOfSample4Average+1:numOfSignal
    ySmoothed(i) = mean(y(i-halfNumOfSample4Average:i));
end

aaa=0;
end

