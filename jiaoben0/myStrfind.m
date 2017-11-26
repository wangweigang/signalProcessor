function pos = myStrfind(aString, aPattern)
% modifed strfind: if not found, return 0 and not []
pos = strfind(aString, aPattern);
if isempty(pos),
    pos = 0;
end
