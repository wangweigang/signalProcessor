function theNumber = getANumberFrom(aString, dividerOrPosition1, LastLetterOrPosition1)
% get a number out from aString between frist divider to the second
% e.g., from PA227_3000_EVC_THPC90_2.dat

if nargin < 2,
    divider = '_';
    ind   = find(aString==divider);
    iPos1 = ind(1);
    iPos2 = ind(2);
elseif nargin == 2,
    divider = dividerOrPosition1;
    ind   = find(aString==divider);
    iPos1 = ind(1);
    iPos2 = ind(2);
elseif nargin == 3,
    if strcmpi(dividerOrPosition1, 'k') && strcmpi(LastLetterOrPosition1, 'A'),
        % for 12k5A
        aString = lower(aString);
        aString = strrep(aString, 'k', '.');
        aString = strrep(aString, 'a', '');
        
        iPos1   = 0;
        iPos2   = length(aString)+1;
    elseif strcmpi(dividerOrPosition1, 'k') && strcmpi(LastLetterOrPosition1, 'V'),
        % for 12k5V
        aString = lower(aString);
        aString = strrep(aString, 'k', '.');
        aString = strrep(aString, 'v', '');
        
        iPos1   = 0;
        iPos2   = length(aString)+1;
    else
        iPos1 = 0;
        iPos2 = 0;
    end
end

if iPos2*(iPos1+1)~=0,
    theNumber = str2double(aString(iPos1+1:iPos2-1));
else
    theNumber = NaN;
end
end
