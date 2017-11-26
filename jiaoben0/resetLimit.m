function resetLimit(m, n, filePath)
% load ylimit and reset to row m for n'th figure from scratch and save it
% m is the index number behind the figure appearance
% e.g., resetLimit(2, 1, '.\tailEffect\0deg_stuck-op-SVT_stuck-mid-SVT_nom_stuck-cl-SVT')
load([filePath, '\', 'yLimit.mat']);
% save a copy
save([filePath, '\', 'yLimitBackup.mat'], 'yLimit');

yLimit(m,n,1) = 1e33;
yLimit(m,n,2) = -1e33;
save([filePath, '\', 'yLimit.mat'], 'yLimit');
fprintf('\nyLimit is reset for subplot %i to [%10.2e, %10.2e] in %i. figure.\n', m, yLimit(m,n,1), yLimit(m,n,2), n);