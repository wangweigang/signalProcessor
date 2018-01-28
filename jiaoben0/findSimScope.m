
function hdlOfScope = findSimScope()
% find simulink scope
set(0,'ShowHiddenHandles','On');
hdlOfScopei = findobj(0, 'Tag', 'SIMULINK_SIMSCOPE_FIGURE');
if isempty(hdlOfScopei), 
    hdlOfScope=[]; 
    return; 
end

j = 0;
hdlOfScope(1)  = hdlOfScopei(1);
for i = 1:length(hdlOfScopei)
    if ishandle(hdlOfScopei(i)) && isempty(strfind(get(hdlOfScopei(i),'Name'),'Viewer')),
        j = j + 1;
        hdlOfScope(j) = hdlOfScopei(i);
        % break;
    end
end