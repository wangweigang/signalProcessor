function tSwOn = currentAnalysis(fileName)

load(fileName);

plot(current1); grid on;

numOfCurrent = length(current1);
% use channel method and linear regression

channelHalfWidth = 0.7; % [A]


tStart = tic;

currentLeft  = current1(1);
currentRight = current1(numOfCurrent);

% simple search for min
currentMin = 1111;
indexMin   = 1;
for i = 1:numOfCurrent
    if current1(i) < currentMin,
        currentMin = current1(i);
        indexMin   = i;
    end
end

% fill left data in channel



tElapsed = toc(tStart)*1000 % [ms]
aaa=0;

