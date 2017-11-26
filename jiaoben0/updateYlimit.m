function yLimitiNew = updateYlimit(eventCounter, yLimiti, hdlOfPloti, plotInForeground)

if nargin < 4,
    plotInForeground = 'off';
end

yLimitiNew = yLimiti;
if eventCounter > 4,
    axes(hdlOfPloti); bringFigToFromBackground(gcf, plotInForeground);
    
    axis('tight');
    xyLimit   = axis;
    yLim1     = floor(100*xyLimit(3))/100;  % round it up
    yLim2     = ceil(100*xyLimit(4))/100;   % round it up
    
    if yLim1 < yLimiti(1),  % update if a still lower limit is there
        yLimitiNew(1) = yLim1;
    end
    if yLim2 > yLimiti(2),  % update if a still higher limit is there
        yLimitiNew(2) = yLim2;
    end
    
    set(hdlOfPloti, 'YLim',yLimitiNew);
    if xyLimit(1)<xyLimit(2),
        set(hdlOfPloti, 'XLim',[xyLimit(1) xyLimit(2)]);
        %        set(hdlOfPloti, 'XLim',[xyLimit(1) min(xyLimit(2),25)]);
    end
end
end