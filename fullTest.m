function output = fullTest( numSteps, xLen, yLen, zLen, initAirTemp, initPersonTemp, initThermons, faucetRate, shape, motion)

% Testing Script
%   Try to maintain some kind of quality this time...

clear('TestBath')
clear('ans')

rng('shuffle');

T = numSteps;

XLEN = xLen;
YLEN = yLen;
ZLEN = zLen;
INITAIRTEMP = initAirTemp;
INITPERSONTEMP = initPersonTemp;
INITTHERMONS = initThermons;
FAUCETRATE = faucetRate;
SHAPE = shape;
MOTION = motion;

folderName = strcat('normSize',shape,'Shape',motion,'Motion',int2str(initPersonTemp),'PTemp',int2str(faucetRate),'Fauc','NoSoap/');
mkdir(folderName);

TestBath = tub(XLEN,YLEN,ZLEN,INITAIRTEMP,INITPERSONTEMP,INITTHERMONS,FAUCETRATE,SHAPE,MOTION);

TestBath.runNTicks(T);

% A bunch of plots
temperatureHist = TestBath.plotTempHist();
print(strcat(folderName,'temperatureHist'),'-dpng');
thermonCounts = TestBath.plotAllThermonCubes();
print(strcat(folderName,'thermonCounts'),'-dpng');
thermonChanges = TestBath.firstDerivAllThermonCubes();
print(strcat(folderName,'thermonChanges'),'-dpng');
simpleFlowGraph = TestBath.flowGraphNoTub();
print(strcat(folderName,'simpleFlowGraph'),'-dpng');
%tubFlowGraph = TestBath.flowGraph();
%print(strcat(folderName,'tubFlowGraph'),'-dpng');

fig1 = figure;
subplot(2,2,1)
TestBath.faucet.plotThermonCountHist();         % The faucet
subplot(2,2,2)
TestBath.getCube(9,8,4).plotThermonCountHist(); % Typical cell
subplot(2,2,3)
TestBath.getCube(4,4,4).plotThermonCountHist(); % A representative of the corner
subplot(2,2,4)
TestBath.getCube(16,5,6).plotThermonCountHist(); % Adjacent to the drain ((17,5,6))
print(strcat(folderName,'quiverThermonsCubesHist'),'-dpng');

fig2 = figure;
subplot(2,2,1)
TestBath.faucet.plotThermons();         % The faucet
subplot(2,2,2)
TestBath.getCube(9,8,4).plotThermons(); % Typical cell
subplot(2,2,3)
TestBath.getCube(4,4,4).plotThermons(); % A representative of the corner
subplot(2,2,4)
TestBath.getCube(16,5,6).plotThermons(); % Adjacent to the drain ((17,5,6))
print(strcat(folderName,'quiverThermons'),'-dpng');


end

