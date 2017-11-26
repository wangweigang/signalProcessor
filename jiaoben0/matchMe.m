function [shiftIndex shiftItself] = matchMe()  % xy1, xy2)
% match to similar curves and function its shifting and synchronozing
% xy1(1:numofPoint, 2) --- INCA low resultion
% xy2(1:numofPoint, 2) --- turbolab high resolution
% 

% load xy1.mat;
load tt.mat;
xy1 = tt;

[numOfx1 tmp] = size(xy1);

if 1,
    % construct test example
    shiftIndex0   = 1111;
    xy1           = xy1(1+shiftIndex0:numOfx1-4*shiftIndex0,:);
    [numOfx1 tmp] = size(xy1);

    % make a xy2
    xy2           = xy1(1+shiftIndex0:numOfx1-shiftIndex0,:);
    % modify xy1
    xy1           = xy1(1:1:numOfx1,:);
    [numOfx1 tmp] = size(xy1);
    
    minDiffx = min(diff(xy2(:,1)));
    
    maxDiffy = max(diff(xy2(:,2)));
    
    % add some random shift in x and y
    xy2(:,1)      = xy2(:,1) + 111*minDiffx;
    [numOfx2 tmp] = size(xy2);
    xy2(:,1)      = xy2(:,1) + 0*0.5*minDiffx .* rand(numOfx2,1);
    xy2(:,2)      = 1*xy2(:,2) + 0*(5*maxDiffy + 2*maxDiffy .* rand(numOfx2,1));
    shiftTime0    = 111*minDiffx;
else
    load xy2.mat;
    [numOfx2 tmp] = size(xy2);
    shiftIndex0   = 0;
    shiftTime0    = 0;
end

figure(1); clf;

% plot for original 2 signals
hdlOfSubplot1 = subplot(3,1,1);
plot(xy1(:,1), xy1(:,2), 'b-'); hold('on');
plot(xy2(:,1), xy2(:,2), 'r-'); grid('on');
title(['Original signal 1 (', num2str(max(diff(xy1(:,1)))), ') and 2 (', num2str(max(diff(xy2(:,1)))), ') with shift of ', num2str(shiftTime0), '[s]']);
xlabel('time [s]'); ylabel('n [rpm]');

aaa=0;

% normalize signal
xMean   = mean(xy1(:,1));
xSTD    = std(xy1(:,1));

yMean1  = mean(xy1(:,2));
ySTD1   = std(xy1(:,2));
xy1Norm = [(xy1(:,1) - xMean)/xSTD, (xy1(:,2) - yMean1)/ySTD1];

yMean2  = mean(xy2(:,2));
ySTD2   = std(xy2(:,2));
xy2Norm = [(xy2(:,1) - xMean)/xSTD, (xy2(:,2) - yMean2)/ySTD2];

% plot for fiting animation
hdlOfPlot2 = subplot(3,1,2);
plot(xy1Norm(:,1), xy1Norm(:,2), 'b-'); hold('on');
hdlOfPlot1 = plot(xy1Norm(:,1), xy1Norm(:,2), 'r-'); grid('on');
xlabel('time [normalized]'); ylabel('n [normalized]');
title('Original signal and signal in shifting process');
axis tight;

numOfPar     = 1;
startingVals = 0;
whichFitFunc = 1;
coefEsts     = startingVals;
fitoutputfun = @(x,optimvalues,state) fitoutputfun(x,optimvalues,state, whichFitFunc, xy1Norm, xy2Norm, hdlOfPlot1);
options      = optimset('OutputFcn',fitoutputfun, 'TolX',1e-5, 'MaxIter',88);
coefEsts     = fminsearch(@(x)fitfun(x, xy1Norm, xy2Norm, whichFitFunc), startingVals, options);

subplot(3,1,3);
plot(xy1(:,1), xy1(:,2), 'b-'); hold('on');
plot(xy2(:,1) - coefEsts(1)*xSTD, xy2(:,2), 'r-'); grid('on');
title(['Original and signal (normalized) shifted by ',num2str(coefEsts(1)*xSTD), '[s] +/-',num2str(0.5*max(diff(xy2(:,1)))), '[s]']);
xlabel('time [s]'); ylabel('n [rpm]');

aaa=0;
end

function stop = fitoutputfun(p, optimvalues, state, whichFitFunc,x,y,handle)
% FITOUTPUT Output function for intermediate fitting results
% only for pring purpose

stop = false;
z    = function4Fit(p, x, y, whichFitFunc);
% z    = z';

myFprintf(1, 'fminsearch runs %4i iterations with results of %9.6f (err: %10.6f)\n ', ...
    optimvalues.iteration, p, norm(z-x(:,2)));

% the state comes from fminsearch
switch state
    case 'init'
        set(handle, 'ydata',z)
        drawnow
    case 'iter'
        set(handle, 'ydata',z)
        drawnow
    case 'done'
        set(handle, 'ydata',z)
        drawnow
        hold off;
end

end

function err = fitfun(p, xy1, xy2, whichFitFunc)
% get error norm
%   FITFUN(p,x,y) returns the error between the data and the values
%   computed by the current function based on p.
%
z   = function4Fit(p, xy1, xy2, whichFitFunc);
% z   = z';
err = norm(z-xy1(:,2));
end

function z = function4Fit(p, xy1, xy2, whichFitFunc)
% my fitting function
 
switch whichFitFunc
    case 1
        z = interp1(xy2(:,1), xy2(:,2), p(1)+xy1(:,1), 'linear', 0);        
    otherwise
        z = 0;
end

end

