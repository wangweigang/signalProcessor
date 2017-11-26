% convert fig to pdf
function fig2pdf(dirName)

fprintf('\n');

if strcmp(dirName(end-2:end),'fig'),
    convertfig2pdf(dirName);
    return 
end
dirNameStruc = dir(dirName);
lenOfName    = length(dirNameStruc);
dirNameCell  = {};

j = 0;
for i = 3:lenOfName  % skip \. and \..
    if dirNameStruc(i).isdir,
        j = j + 1;
        dirNameCell{j} = dirNameStruc(i).name;
    end
end

if j == 0,
    j = 1;
    dirNameCell{j} = '.';
end

close all;

% get all fig files and make the conversion
for k = 1:j
    fieNameStruc   = dir([dirName,'\',dirNameCell{k},'\*.fig']);
    lenOfName = length(fieNameStruc);
    
    for i = 1:lenOfName
        fileName = [dirName,'\',dirNameCell{k},'\',fieNameStruc(i).name];
        disp(['Processing ', fileName, '(', fieNameStruc(i).date,') ... ...']); 
        skipIt = input('skip it? [y](y: yes once/n: do not skip/a: skilp all):  ', 's');
        if isempty(skipIt) || strcmpi(skipIt, 'y'),
            continue;
        elseif strcmpi(skipIt, 'a'),
            return;
        end
        
        convertfig2pdf(fileName)

    end
end
end

function convertfig2pdf(fileName)
openfig(fileName);
set(gcf, 'visible','on', 'Position',[3 132 1200 560]);
% make line thinner and smaller marker for pdf
hdlOfLine = get(gca, 'Children');
for kkk = length(hdlOfLine):-1:1
    % hdlOflinei = get(hdlOfLine(kkk));
    if strcmpi(get(hdlOfLine(kkk), 'Type'), 'line'),
        if strcmp(version, '7.14.0.739 (R2012a)') || strcmp(version, '7.9.0.529 (R2009b)') ,  % for new matlab
            disp(['Message: do no nothing because this matlab (',version,') messes thing up.']);
            aaa=0;
        else
            
            set(hdlOfLine(kkk), 'LineWidth', 0.5*get(hdlOfLine(kkk), 'LineWidth'));
            if strcmpi(get(hdlOfLine(kkk), 'Marker'), '^') || strcmpi(get(hdlOfLine(kkk), 'Marker'), 'diamond'),
                set(hdlOfLine(kkk), 'MarkerSize', 0.5);
            end
                       
            if 1, % 1: delete certain curves according to their color  % remove green, grey, cyan, yellow and red curves
                if strcmpi(get(hdlOfLine(kkk),'Marker'),'none'), % no marker is deleted
                    if get(hdlOfLine(kkk),'Color') == [0 1 0],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [0.8 0.8 0.8],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [0.7 0.7 0.7],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [0 1 1],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [1 1 0],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [1 0 0],
                        delete(hdlOfLine(kkk));
                    end
                end
            else
                if strcmpi(get(hdlOfLine(kkk),'Marker'),'none'), % no marker is deleted
                    if get(hdlOfLine(kkk),'Color') == [0.8 0.8 0.8],
                        delete(hdlOfLine(kkk));
                    elseif get(hdlOfLine(kkk),'Color') == [0.7 0.7 0.7],
                       delete(hdlOfLine(kkk));
                    
                    end
                end
                
            end
        end
        
    end
end
disp(' ');
if exist('numOfEventLast', 'var'),
    numOfCol = input(['Enter the number of columns [', num2str(numOfEventLast/100), ']: ']);
else
    numOfCol = input('Enter the number of columns: ');
end
disp(' ');
if isempty(numOfCol),
    if exist('numOfEventLast', 'var'),
        numOfCol = numOfEventLast/100;
    else
        return;
    end
else
    if numOfCol == 0,
        return;
    end
    numOfEventLast = numOfCol*100;
end
set(gcf, 'PaperPositionMode','auto', 'PaperUnits','centimeters', ...
    'PaperType','A3', 'PaperPosition',1.4*[1 0.2 max(2,numOfCol*0.8) 28]);
grid('off');
print(gcf, '-dpdf', '-r720', 'aPDFFile.pdf');
close(gcf);
copyfile('aPDFFile.pdf', [fileName(1:end-4),'_a.pdf']);
disp(['Message: a fig file converted and saved in ', fileName(1:end-4),'_a.pdf']);
end
