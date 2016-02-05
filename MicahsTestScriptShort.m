% Testing Script
%   Try to maintain some kind of quality this time...

clear('TestBath')
clear('ans')

rng('shuffle');

T = 20;

XLEN = 17;
YLEN = 10;
ZLEN = 7;
INITAIRTEMP  = 18;
INITPERSONTEMP = 23;
INITTHERMONS = 30;
FAUCETRATE = 30;
TUBSHAPE = 'rectangle';
MOTIONPATTERN = '8Op1';

TestBath = tub(XLEN,YLEN,ZLEN,INITAIRTEMP,INITPERSONTEMP,INITTHERMONS,FAUCETRATE,TUBSHAPE,MOTIONPATTERN);

TestBath.runNTicks(T);

% A bunch of plots
temperatureHist = TestBath.plotTempHist();
thermonCounts = TestBath.plotAllThermonCubes();
thermonChanges = TestBath.firstDerivAllThermonCubes();
simpleFlowGraph = TestBath.flowGraphNoTub();
tubFlowGraph = TestBath.flowGraph();
