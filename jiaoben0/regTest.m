clf
presManifold1= ... 
    [
   11.2091
   10.9131
   10.4523
   10.2997
   10.3790
   10.7666
   10.8521
   10.7147
   10.2753
   10.1593
   10.1990
   10.6262
   10.7117
   10.6537
   10.1898
   10.0647
   10.0464
   10.4767
   10.6232
   10.6049
   10.1563
    9.9945
    9.9762
   10.3760
   10.5499
   10.5804
   10.1501
    9.9457
    9.8969
   10.2814
   10.4980
   10.5530
   10.1593
    9.9365
    9.8633
   10.2051
   10.4858
   10.5652
   10.2203
    9.9548
    9.8663
   10.1685
   10.4645
];
%     (830:-1:800);
iMax = length(presManifold1);
dChop             = 0.6;
numOfChop         = 3;
numOfPointPerChop = 6;
iMax1 = numOfChop*numOfPointPerChop+0; %length(presManifold1)-10;
iMin1 = 1;
samplingTime = 5.5555e-6;

[g a] = linearRegression(presManifold1, samplingTime, iMin1, iMax1, -1)


plot((1:length(presManifold1))*samplingTime, presManifold1, 'b-o');
grid
hold on;
% plot([0 -a/g]/samplingTime, [a 0], 'r-');
plot([iMin1 iMax1]*samplingTime, [a+g*(iMin1-iMin1)*samplingTime a+g*(iMax1-iMin1)*samplingTime], 'r+');
plot([iMin1 iMax ]*samplingTime, [a+g*(iMin1-iMin1)*samplingTime a+g*(iMax -iMin1)*samplingTime], 'r-');
plot([iMin1 iMax ]*samplingTime, [min(presManifold1) min(presManifold1)]+0.6/2, 'r-');

axis([0 iMax*samplingTime min(presManifold1) max(presManifold1)]);
aaa=0;
