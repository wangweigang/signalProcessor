function [yMean,yStd] = myMean4Cell(y, i, j, k, iMean)
% get  mean along iMean
% i numOfCyl  
% j numOfEvent
% k numOfLandmarkGroup

[numOfCyl numOfEvent numOfLandmarkGroup] = size(y);


numOfLandmark = length(y{1,1,k});  % number of landmarks
yMean         = zeros(1,max(1,numOfLandmark)) - 1e33;

switch iMean
    case 1       
        if j>numOfEvent || k>numOfLandmarkGroup, 
            return;
        end

        yTmp = zeros(numOfCyl, numOfLandmark);
        numOfLandmarki = numOfLandmark;
        m              = 1;
        while m <= numOfLandmarki,
%        for m = 1:numOfLandmark
            for i = 1:numOfCyl
                numOfLandmarki = length(y{i,j,k});  % use actual length, in case error in seeCurrent
                yTmp(i, m) = y{i,j,k}(m);
            end
            m = m + 1;
        end
    case 2
        if i>numOfCyl || k>numOfLandmarkGroup,
            return;
        end
        yTmp           = zeros(numOfEvent, numOfLandmark);
        numOfLandmarki = numOfLandmark;
        m              = 1;
        while m <= numOfLandmarki,
        % for m = 1:numOfLandmarki
            for j = 1:numOfEvent
                numOfLandmarki = length(y{i,j,k});  % use actual length, in case error in seeCurrent
%                 if m > length(y{i,j,k}),
%                     [i,j,k,m,numOfCyl, numOfEvent, numOfLandmarkGroup,length(y{i,j,k})]
%                 end
                if isempty(y{i,j,k}), % if collection is empty
%                     yMean = yMean-1e33; 
%                     return
                    yTmp(j, m) = -1e33;
                else
                    yTmp(j, m) = y{i,j,k}(m);
                end
                
            end
            m = m + 1;
        end
    case 3
        if i>numOfCyl || j>numOfEvent,
            return;
        end
        yTmp           = zeros(numOfLandmarkGroup, numOfLandmark);
        numOfLandmarki = numOfLandmark;
        m              = 1;
        while m <= numOfLandmarki,
        %        for m = 1:numOfLandmark
            for k = 1:numOfLandmarkGroup
                numOfLandmarki = length(y{i,j,k});  % use actual length, in case error in seeCurrent
                yTmp(k, m) = y{i,j,k}(m);
            end
            m = m + 1;
        end
end

for i = 1:numOfLandmark
    indices  = find(~isnan(yTmp(:,i)));
    yTmp1    = yTmp(indices,i);
    indices1 = find(yTmp1>-1000000);
    yMean(i) = mean(yTmp1(indices1));
    yStd(i)  = std(yTmp1(indices1));
end

aaa=0;
end