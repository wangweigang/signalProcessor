function ySmooth = smoothIt(y, interval)
% smooth y and pick up point in interval
lenOfy  = length(y);
ySmooth = y(1:interval:lenOfy);
if 0,
    yTmp    = smooth(y,0.07,'rloess');
else
    yTmp    = smooth(y,11);
end
ySmooth = yTmp(1:interval:lenOfy);
aaa=0;
end
