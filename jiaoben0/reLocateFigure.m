function reLocateFigure(hdlOfFigure, widthFig, heightFig)
% resize and move the window, let it not accross the monitor
% Dell desktop WxH 1280x1024
% Sony WxH 1366x768
% HP desktop WxH 1920x1080
% HP Notebook (Schaeffler) WxH 1366x702


[tmp pcName] = system('hostname');
if strfind(pcName, 'Neptune'),
    % HP desktop WxH 1920x1080
    moniSize   = [1920 1004];
elseif strfind(pcName,  'Uranus'),
    % Sony WxH 1366x768
    moniSize   = [1366, 668];
elseif strfind(pcName,  'Mercury'),
    % Dell desktop WxH 1280x1024
    moniSize   = [1280, 1024];
else
    % HP Notebook (Schaeffler) WxH 1366x702
    moniSize   = [1366, 702];
end


maxAllowed = moniSize;
pos        = get(hdlOfFigure, 'Position'); 

if pos(2) < 48,
    pos(2) = 48;
    maxAllowed(2) = (moniSize(2)-pos(2));
elseif pos(2)+heightFig > maxAllowed(2);
    pos(2) = max(48, maxAllowed(2)-heightFig);
end
if pos(1) < 16,
    pos(1) = 16;
    maxAllowed(1) = (moniSize(1)-pos(1));
end

heightFig = min(heightFig, maxAllowed(2));
widthFig  = min(widthFig, maxAllowed(1));

if pos(2)+heightFig > maxAllowed(2),
    pos(2) = max(48, maxAllowed(2) - heightFig);
end

if pos(1)+widthFig > maxAllowed(1),
    pos(1) = max(1, maxAllowed(1) - widthFig);
end

set(hdlOfFigure, 'Position', [pos(1), pos(2), widthFig, heightFig]);
