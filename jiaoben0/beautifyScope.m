function beautifyScope(hdlFig)
eee = get(hdlFig, 'Children');
gotTheFirst = 0;
for i = 1:length(eee)
    if strcmp(get(eee(i), 'Tag'),'ScopeAxes') && strcmp(get(eee(i), 'Type'),'axes'),
        if ~gotTheFirst,
            gotTheFirst = 1;
        else
            set(eee(i), 'XTickLabel', '');
        end
    end
end
WindowPos = get(hdlFig, 'Position');
set(hdlFig, 'Position',[WindowPos(1) WindowPos(2) 585 658]);
end
