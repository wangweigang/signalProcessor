function ySmoothed = smoothOut(y, halfNumOfSample4Average)
% for each point i, take a few points from left anf right and get their everage and
% put it there

numOfSignal = length(y);

NumOfSample4Average = 2*halfNumOfSample4Average + 1;
% sumSignal   = double(0);
% yTmp        = zeros(1,numOfSignal); 
ySmoothed   = zeros(1,numOfSignal); 
i           = int32(0);
j           = int32(0);
iStart      = int32(0);
iEnd        = int32(0);
indice      = halfNumOfSample4Average+1:numOfSignal-halfNumOfSample4Average;
% after halfNumOfSample4Average, smoothing
for i = indice
    ySmoothed(i) = mean(y(i-halfNumOfSample4Average:i+halfNumOfSample4Average));
end

if halfNumOfSample4Average == 0,
    return;
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

