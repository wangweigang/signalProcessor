function saveThingsInXLS(item2Save, xlsFileName, sheetName, rowNum2Start, colStr2Start)
% save data in xls file

try
    % ------------------ save V-Shape ------------------
    % collect landmark and save their mean
    xlswrite(xlsFileName, item2Save, sheetName,    [colStr2Start,num2str(rowNum2Start)]);
end

end


function flatedCell = flatIt(y)
% fill all elements in a cell to be fit to xls row
% y{cylinder, event} = {1 2 3 4 5}

flatedCell   = cell(1,1);
[nRow nCol]  = size(y);
numOfElement = -1e33;
for i = 1:nRow
    for j = 1:nCol
        numOfElement = max(numOfElement, length(y{i,j}));
    end
end

if numOfElement ~= 5,
    fprintf('\nWarning: numOfElement is not 5 (instead %i)', numOfElement);
    aaa= 0;
end

for i = 1:nRow
    for j = 1:nCol
        for k = 1:numOfElement
            if numOfElement>length(y{i,j}) || isempty(y{i,j}(k)),
                flatedCell{(i-1)*nCol*numOfElement + (j-1)*numOfElement + k} = 1e33;
            else
                flatedCell{(i-1)*nCol*numOfElement + (j-1)*numOfElement + k} = y{i,j}(k);
            end
        end
    end
    aaa=0;
end
end
