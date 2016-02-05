classdef tub < handle
    %tub
    %    The whole tub, containing many cubes, a faucet, a drain, and all
    %    that jazz.
    
    % motionPattern key:
    %   None:       no motion
    %   DiamondOp1: right moves opposite left. right moves clockwise
    %   DiamondOp2: right moves opposite left. left moves clockwise
    %   DiamondSm1: right moves same as left. clockwise
    %   DiamondSm2: right moves same as left. counter clockwise
    %   flailShort: limbs move randomly. change direction every tick
    %   flailLong:  limbs move randomly. change direction every 4 ticks
    %   8Op1:       right moves opposite left. 8 pattern. right starts clockwise
    %   8Op2:       right moves sane as left. 8 pattern. starts clockwise
    %   upDown:     moves together. goes down, then up
    
    properties
        tubX                 % Number of cubes per side length
        tubY
        tubZ
        cubes                     % Object array of cubes in tub
        volume                    % The total size of the tub
        airTemp                   % The thermon equivalent temperature of the air
        personTemp                % The thermon equivalent temperature of a person
        thermonDensity            % Desired thermon density for initial temp
        airToWaterHeatTransferCoef% Gives the heat transfer coefficient for air-water interfaces
        personToWaterHeatTransferCoef    % Gives the heat transfer coefficient for person-water interfaces0
        currentDecayConst         % A rough measure of the exponential die off rate of currents
        sameSpotCurrentDecayConst % Const of exp decay in same tile
        backwardsCurrentDecayConst% Const of exp decay from behind currents
        wallCurrentImpactFactor   % The fraction of a wave component removed when hitting a wall
        faucet                    % Stores the faucet
        drain                     % Stores the drain
        bather                    % Stores the person
        tempDiffHist              % Stores the temperature differences over time
        tempDiffDerivHist         % Stores the temperature derivs over time
        shape                     % String which suggests the shape the tub should take
        faucetRate                % The rate at which the faucet expels thermons
        motionPattern             % Arm and leg motion
    end
    
    methods
        
        
        function obj = tub(tubX, tubY, tubZ, airTemp, personTemp, thermonDensity, faucetRate, shape, motionPattern)
            if nargin < 8
                obj.shape = 'rectangle';
            else
                obj.shape = shape;
            end
            
            if nargin < 9
                obj.motionPattern = 'None';
            else
                obj.motionPattern = motionPattern;
            end
            
            obj.airToWaterHeatTransferCoef = 0.1;
            obj.personToWaterHeatTransferCoef = 0.1;
            obj.currentDecayConst = 0.5;
            obj.sameSpotCurrentDecayConst = obj.currentDecayConst/4;
            obj.backwardsCurrentDecayConst = obj.currentDecayConst/10;
            obj.wallCurrentImpactFactor = 0.5;
            
            obj.tempDiffHist = [];
            obj.tempDiffDerivHist = [];
            
            obj.faucetRate = faucetRate;
            obj.tubX = tubX;
            obj.tubY = tubY;
            obj.tubZ = tubZ;
            obj.airTemp = airTemp;
            obj.personTemp = personTemp;
            obj.thermonDensity = thermonDensity;
            generateCubes(obj);
            
            switch obj.shape
                case 'ellipse'
                    obj.initializeEllipsoid(obj.tubX, obj.tubY, obj.tubZ);
                case 'slant'
                    obj.initializeSlantedRect(obj.tubX,obj.tubY,obj.tubZ);
                otherwise
                    obj.initializeRect(obj.tubX, obj.tubY, obj.tubZ);
            end
        end
        
        % Fills all cubes with thermonDensity thermons;
        %   Clear these on special cubes (type>0) in initializers
        function obj = generateCubes(obj)
            cubesM = [];
            cubesL = [];
            cubesFinal = [];
            for k = 1:obj.tubZ
                for i = 1:obj.tubX
                    for j = 1:obj.tubY
                        % initialize all cubes as empty cubes
                        %obj.cubes(i,j,k).Values = cube(obj, [i,j,k], zeros(3), 0);
                        newCube = cube([i,j,k], zeros(1,3), 0);
                        newCube.addNThermons(obj.thermonDensity);
                        newCube.recordThermonCount();
                        cubesL = [cubesL, newCube];
                    end
                    cubesM = cat(1, cubesM, cubesL);
                    cubesL = [];
                end
                cubesFinal = cat(3,cubesFinal,cubesM);
                cubesM = [];
            end
            obj.cubes = cubesFinal;
        end
        
        % Initialize a rectangular prism tub
        %   Includes clearing thermons from special cubes
        function obj = initializeRect(obj, xLen, yLen, zLen)
            for x = 1:xLen
                for y = 1:yLen
                    for z = 1:zLen
                        tempCube = obj.getCube(x,y,z);
                        if and(z==zLen-1,and(y==floor(yLen/2),x==xLen))
                            tempCube.cubeType = 4;
                            tempCube.clearThermons();
                            obj.drain = tempCube;
                        elseif or(min(x,min(y,z))==1,or(x==xLen,y==yLen))
                            tempCube.cubeType = 1;
                            tempCube.clearThermons();
                        elseif (z==zLen)
                            tempCube.cubeType = 5;
                            tempCube.clearThermons();
                        end
                    end
                end
            end
            
            % Set faucet
            obj.getCube(2,floor(yLen/2),zLen-1).cubeType = 3;
            %obj.getCube(2,floor(yLen/2),zLen-1).clearThermons();
            obj.faucet = obj.getCube(2,floor(yLen/2),zLen-1);
            
            % Place person in initial position
            obj.bather = person(17,2,3,obj);
            obj.bather.placeTorso();
            obj.bather.placeLimbs();
        end
        
        function obj = initializeEllipsoid(obj, xLen, yLen, zLen)
            for x = 1:xLen
                for y = 1:yLen
                    for z = 1:zLen
                        tempCube = obj.getCube(x,y,z);
                        xValue = ((x - (xLen - 1)/2)/(xLen/2))^2;
                        yValue = ((y - (yLen - 1)/2)/(yLen/2))^2;
                        zValue = ((z - (zLen - 1))/zLen)^2;
                        if (xValue + yValue + zValue > 1)
                            tempCube.cubeType = 1;
                            tempCube.clearThermons;
                        end
                        if and(z==zLen-1,and(y==floor(yLen/2),x==xLen))
                            tempCube.cubeType = 4;
                            tempCube.clearThermons();
                            obj.drain = tempCube;
                        elseif or(min(x,min(y,z))==1,or(x==xLen,y==yLen))
                            tempCube.cubeType = 1;
                            tempCube.clearThermons();
                        elseif (z==zLen)
                            tempCube.cubeType = 5;
                            tempCube.clearThermons();
                        end
                    end
                end
            end
            
            % Set faucet
            obj.getCube(2,floor(yLen/2),zLen-1).cubeType = 3;
            %obj.getCube(2,floor(yLen/2),zLen-1).clearThermons();
            obj.faucet = obj.getCube(2,floor(yLen/2),zLen-1);
            
            % Place person in initial position
            obj.bather = person(17,2,3,obj);
            obj.bather.placeTorso();
            obj.bather.placeLimbs();
        end
        
         function obj = initializeSlantedRect(obj, xLen, yLen, zLen)
            for x = 1:xLen
                for y = 1:yLen
                    for z = 1:zLen
                        tempCube = obj.getCube(x,y,z);
                        xValue = -(zLen-2)/(xLen-1)*(x-1);
                        yValue = 0;
                        zValue = z;
                        if (xValue + yValue + zValue < 1)
                            tempCube.cubeType = 1;
                            tempCube.clearThermons;
                        end
                        if and(z==zLen-1,and(y==floor(yLen/2),x==xLen))
                            tempCube.cubeType = 4;
                            tempCube.clearThermons();
                            obj.drain = tempCube;
                        elseif or(min(x,min(y,z))==1,or(x==xLen,y==yLen))
                            tempCube.cubeType = 1;
                            tempCube.clearThermons();
                        elseif (z==zLen)
                            tempCube.cubeType = 5;
                            tempCube.clearThermons();
                        end
                    end
                end
            end
            
            % Set faucet
            obj.getCube(2,floor(yLen/2),zLen-1).cubeType = 3;
            %obj.getCube(2,floor(yLen/2),zLen-1).clearThermons();
            obj.faucet = obj.getCube(2,floor(yLen/2),zLen-1);
            
            % Place person in initial position
            obj.bather = person(17,2,3,obj);
            obj.bather.placeTorso();
            obj.bather.placeLimbs();
        end
        
        function obj = runFaucet(obj, rate)
            obj.faucet.addNThermons(rate);
        end
        
        function outCube = getCube(obj,x,y,z)
            outCube = obj.cubes(x,y,z);
        end
        
        function neighbor = getNeighbor(obj, original, intDifference)
            % Returns the neighbor of obj in the intDifference direction
            % Please do not use stupidly and get index out of range errors.
            location = original.position + intDifference;
            neighbor = obj.getCube(location(1),location(2),location(3));
        end
        
        function neighbors = getAllNeighbors(obj, singleCube)
            neighbors = [];
            directions = [1,0,0; -1,0,0; 0,1,0; 0,-1,0; 0,0,1; 0,0,-1];
            for i = 1 : 6
                neighbors = [neighbors, obj.getNeighbor(singleCube, directions(i,:))];
            end
        end
        
        function obj = neighborVelCombine(obj, currentCube)
            % Figures out the impact on the current cube from neighboring
            % currents.
            neighbors = obj.getAllNeighbors(currentCube);
            total = [0,0,0];
            speed = norm(currentCube.velocity);
            wallCount = 0;
            for k = 1:6
                if currentCube.motionState == 0
                    if or(neighbors(k).cubeType == 0, neighbors(k).cubeType == 3)
                        intDifference = neighbors(k).position() - currentCube.position();
                        velk = dot(abs(intDifference),neighbors(k).velocity());
                        if dot(intDifference, neighbors(k).velocity()) > 0
                            factor = obj.backwardsCurrentDecayConst;
                        else
                            factor = obj.currentDecayConst;
                        end
                        temp = neighbors(k).velocity();
                        if (sum(temp) ~= 0)
                            normalized = temp/norm(temp);
                            direction = (normalized + abs(intDifference))/2;
                            total = total + factor*velk*direction;
                        end
                    elseif or(neighbors(k).cubeType == 1, or(neighbors(k).cubeType == 2, neighbors(k).cubeType == 5))
                        intDifference = neighbors(k).position() - currentCube.position();
                        if dot(intDifference, currentCube.velocity()) > 0
                            wallCount = wallCount + 1;
                            currentCube.velocity = currentCube.velocity - obj.wallCurrentImpactFactor*intDifference;
                        end
                    end
                elseif currentCube.motionState == 1
                    totalvel = [0 0 0];
                    if neighbors(k).cubeType == 2
                        intDifference = neighbors(k).position() - currentCube.position();
                        velk = -intDifference./norm(intDifference);
                        totalvel = totalvel + velk;
                    end
                    if norm(totalvel) ~= 0
                        totalvel = totalvel./norm(totalvel);
                    end
                    currentCube.velocity = totalvel;
                    currentCube.motionState = 0;
                end
            end
            if and(wallCount < 3, norm(currentCube.velocity) ~= 0)
                currentCube.velocity = speed*currentCube.velocity/norm(currentCube.velocity);
            end
            currentCube.pendingVelocity = total;
        end
        
        function obj = currentPropagate(obj)
            % Propagates current throughout the tub.
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, state == 3)
                    obj.neighborVelCombine(obj.cubes(i));
                end
            end
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                obj.cubes(i).velocity = obj.cubes(i).velocity * obj.sameSpotCurrentDecayConst;
                obj.cubes(i).addVel(obj.cubes(i).pendingVelocity);
            end
        end
        
        function obj = heatTransmission(obj)
            % Figures out how many thermons to add/subtract from each cube.
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, state == 3)
                    neighbors = obj.getAllNeighbors(obj.cubes(i));
                    total = 0;
                    for k = 1:6
                        if (neighbors(k).cubeType == 2)
                            change = obj.personToWaterHeatTransferCoef*(obj.personTemp - size(obj.cubes(i).thermons,2));
                            total = total + change;
                        elseif (neighbors(k).cubeType == 5)
                            change = obj.airToWaterHeatTransferCoef*(obj.airTemp - size(obj.cubes(i).thermons,2));
                            total = total + change;
                        end
                    end
                    if and(total < 0, abs(total) > size(obj.cubes(i).thermons,2))
                        total = -1*size(obj.cubes(i).thermons,2);
                    end
                    obj.cubes(i).changeNumThermons(ceil(total));
                end
            end
        end
        
        function diff = tempDiff(obj)
            % Sums the difference between the number of thermons in each
            % cell and the desired number in each cell.
            total = 0;
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, state == 3)
                    temp = (obj.cubes(i).thermonSpot - 1 - obj.thermonDensity);
                    total = total + temp*temp;
                end
            end
            diff = real(sqrt(total));
        end
        
        function diffDeriv = tempDiffDeriv(obj)
            total = 0;
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, state == 3)
                    for k = 1:3
                        vec = [0,0,0];
                        vec(k) = 1;
                        neighbor = obj.getNeighbor(obj.cubes(i),vec(k));
                        neighborType = neighbor.cubeType;
                        if or(neighborType == 0, neighborType == 3)
                            temp = (neighbor.thermonSpot - obj.cubes(i).thermonSpot);
                            total = total + temp*temp;
                        end
                    end
                end
            end
            diffDeriv = real(sqrt(total));
        end
        
        function thrm = updatePos(obj, thrm)
            condi = 1;
            tempPos = thrm.position + thrm.velocity;
            while condi
                tempIndex = floor(tempPos);
                newParent = obj.getCube(tempIndex(1),tempIndex(2),tempIndex(3));
                
                if and(and(newParent.cubeType ~= 1, newParent.cubeType ~= 2), newParent.cubeType ~= 5)
                    thrm.position = tempPos;
                    thrm.newCube(newParent);
                    condi = 0;
                else
                    intDifference = tempIndex - floor(thrm.position);
                    normalized = intDifference*(1/norm(intDifference));
                    
                    offset = (intDifference==1).*ceil(thrm.position) + (intDifference==-1).*floor(thrm.position);
                    tempPos = offset + transpose((eye(3) - 2.*transpose(normalized)*normalized)*transpose(tempPos - offset));
                    
                    newVel = thrm.velocity - 2*dot(normalized,thrm.velocity)*normalized;
                    thrm.velocity = newVel;
                end
            end
        end
        
        function obj = updateThermons(obj, cubeThing)
            N = cubeThing.numThermons();
            for i = 1 : N
                obj.updatePos(cubeThing.thermons(cubeThing.thermonSpace(N+1-i)));
                cubeThing.thermons(cubeThing.thermonSpace(N+1-i)).updateVelocity();
            end
        end
        
        function obj = updateAllThermons(obj)
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, state == 3)
                    obj.updateThermons(obj.cubes(i));
                end
            end
            for i = 1:size(obj.cubes,1)*size(obj.cubes,2)*size(obj.cubes,3)
                state = obj.cubes(i).cubeType;
                if or(state == 0, or(state == 3, state == 4))
                    obj.cubes(i).commitWaitingThermons();
                end
            end
        end
        
        function obj = runATick(obj)
            if or(or(or(~isempty(obj.bather.handRQueue),~isempty(obj.bather.handLQueue)),~isempty(obj.bather.footRQueue)),~isempty(obj.bather.footLQueue))
                obj.bather.clearLimbs();
                if ~isempty(obj.bather.handRQueue)
                    obj.bather.handR = obj.bather.handRQueue(1,:);
                    obj.bather.handRQueue(1,:) = [];
                end
                if ~isempty(obj.bather.handLQueue)
                    obj.bather.handL = obj.bather.handLQueue(1,:);
                    obj.bather.handLQueue(1,:) = [];
                end
                if ~isempty(obj.bather.footRQueue)
                    obj.bather.footR = obj.bather.footRQueue(1,:);
                    obj.bather.footRQueue(1,:) = [];
                end
                if ~isempty(obj.bather.footLQueue)
                    obj.bather.footL = obj.bather.footLQueue(1,:);
                    obj.bather.footLQueue(1,:) = [];
                end
                obj.bather.placeLimbs();
                obj.bather.placeTorso();
            end
            obj.heatTransmission();
            obj.updateAllThermons();
            obj.bather.markLimbs();
            obj.currentPropagate();
            obj.runFaucet(obj.faucetRate);
            obj.tempDiffHist = [obj.tempDiffHist, obj.tempDiff()];
            obj.tempDiffDerivHist = [obj.tempDiffDerivHist, obj.tempDiffDeriv()];
        end
        
        function obj = runNTicks(obj,N)
            for i=1:N
                obj.runATick();
                switch obj.motionPattern
                    case 'None'
                        continue
                    case 'DiamondOp1'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,-2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,-2,-2],2);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,0,-4],2);
                            obj.bather.moveHandL(handInitL + [0,0,-4],2);
                            obj.bather.moveFootR(footInitR + [0,0,-4],2);
                            obj.bather.moveFootL(footInitL + [0,0,-4],2);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,-2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,2,-2],2);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR,2);
                            obj.bather.moveHandL(handInitL,2);
                            obj.bather.moveFootR(footInitR,2);
                            obj.bather.moveFootL(footInitL,2);
                        end
                    case 'DiamondOp2'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,-2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,2,-2],2);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,0,-4],2);
                            obj.bather.moveHandL(handInitL + [0,0,-4],2);
                            obj.bather.moveFootR(footInitR + [0,0,-4],2);
                            obj.bather.moveFootL(footInitL + [0,0,-4],2);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,-2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,-2,-2],2);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR,2);
                            obj.bather.moveHandL(handInitL,2);
                            obj.bather.moveFootR(footInitR,2);
                            obj.bather.moveFootL(footInitL,2);
                        end
                    case 'DiamondSm1'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,2,-2],2);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,0,-4],2);
                            obj.bather.moveHandL(handInitL + [0,0,-4],2);
                            obj.bather.moveFootR(footInitR + [0,0,-4],2);
                            obj.bather.moveFootL(footInitL + [0,0,-4],2);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,-2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,-2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,-2,-2],2);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR,2);
                            obj.bather.moveHandL(handInitL,2);
                            obj.bather.moveFootR(footInitR,2);
                            obj.bather.moveFootL(footInitL,2);
                        end
                    case 'DiamondSm2'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,-2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,-2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,-2,-2],2);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,0,-4],2);
                            obj.bather.moveHandL(handInitL + [0,0,-4],2);
                            obj.bather.moveFootR(footInitR + [0,0,-4],2);
                            obj.bather.moveFootL(footInitL + [0,0,-4],2);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,-2],2);
                            obj.bather.moveHandL(handInitL + [0,2,-2],2);
                            obj.bather.moveFootR(footInitR + [0,2,-2],2);
                            obj.bather.moveFootL(footInitL + [0,2,-2],2);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR,2);
                            obj.bather.moveHandL(handInitL,2);
                            obj.bather.moveFootR(footInitR,2);
                            obj.bather.moveFootL(footInitL,2);
                        end
                    case 'flailShort'
                        if mod(i,1) == 0
                            obj.bather.moveHandR([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],1);
                            obj.bather.moveHandL([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],1);
                            obj.bather.moveFootR([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],1);
                            obj.bather.moveFootL([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],1);
                        end
                    case 'flailLong'
                        if mod(i,4) == 0
                            obj.bather.moveHandR([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],4);
                            obj.bather.moveHandL([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],4);
                            obj.bather.moveFootR([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],4);
                            obj.bather.moveFootL([(17-1).*rand(1,1)+1,9.*rand(1,1)+1,6.*rand(1,1)+1],4);
                        end
                    case '8Op1'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,1,1],1);
                            obj.bather.moveHandL(handInitL + [0,-1,1],1);
                            obj.bather.moveFootR(footInitR + [0,1,1],1);
                            obj.bather.moveFootL(footInitL + [0,-1,1],1);
                        elseif mod(i+7,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,0],1);
                            obj.bather.moveHandL(handInitL + [0,-2,0],1);
                            obj.bather.moveFootR(footInitR + [0,2,0],1);
                            obj.bather.moveFootL(footInitL + [0,-2,0],1);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,1,-1],1);
                            obj.bather.moveHandL(handInitL + [0,-1,-1],1);
                            obj.bather.moveFootR(footInitR + [0,1,-1],1);
                            obj.bather.moveFootL(footInitL + [0,-1,-1],1);
                        elseif mod(i+5,8) == 0
                            obj.bather.moveHandR(handInitR,1);
                            obj.bather.moveHandL(handInitL,1);
                            obj.bather.moveFootR(footInitR,1);
                            obj.bather.moveFootL(footInitL,1);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-1,1],1);
                            obj.bather.moveHandL(handInitL + [0,1,1],1);
                            obj.bather.moveFootR(footInitR + [0,-1,1],1);
                            obj.bather.moveFootL(footInitL + [0,1,1],1);
                        elseif mod(i+3,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,0],1);
                            obj.bather.moveHandL(handInitL + [0,2,0],1);
                            obj.bather.moveFootR(footInitR + [0,-2,0],1);
                            obj.bather.moveFootL(footInitL + [0,2,0],1);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-1,-1],1);
                            obj.bather.moveHandL(handInitL + [0,1,-1],1);
                            obj.bather.moveFootR(footInitR + [0,-1,-1],1);
                            obj.bather.moveFootL(footInitL + [0,1,-1],1);
                        elseif mod(i+1,8) == 0
                            obj.bather.moveHandR(handInitR,1);
                            obj.bather.moveHandL(handInitL,1);
                            obj.bather.moveFootR(footInitR,1);
                            obj.bather.moveFootL(footInitL,1);
                        end
                        case '8Op2'
                        handInitR = obj.bather.handR;
                        handInitL = obj.bather.handL;
                        footInitR = obj.bather.footR;
                        footInitL = obj.bather.footL;
                        
                        if mod(i,8) == 0
                            obj.bather.moveHandR(handInitR + [0,1,1],1);
                            obj.bather.moveHandL(handInitL + [0,1,1],1);
                            obj.bather.moveFootR(footInitR + [0,1,1],1);
                            obj.bather.moveFootL(footInitL + [0,1,1],1);
                        elseif mod(i+7,8) == 0
                            obj.bather.moveHandR(handInitR + [0,2,0],1);
                            obj.bather.moveHandL(handInitL + [0,2,0],1);
                            obj.bather.moveFootR(footInitR + [0,2,0],1);
                            obj.bather.moveFootL(footInitL + [0,2,0],1);
                        elseif mod(i+6,8) == 0
                            obj.bather.moveHandR(handInitR + [0,1,-1],1);
                            obj.bather.moveHandL(handInitL + [0,1,-1],1);
                            obj.bather.moveFootR(footInitR + [0,1,-1],1);
                            obj.bather.moveFootL(footInitL + [0,1,-1],1);
                        elseif mod(i+5,8) == 0
                            obj.bather.moveHandR(handInitR,1);
                            obj.bather.moveHandL(handInitL,1);
                            obj.bather.moveFootR(footInitR,1);
                            obj.bather.moveFootL(footInitL,1);
                        elseif mod(i+4,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-1,1],1);
                            obj.bather.moveHandL(handInitL + [0,-1,1],1);
                            obj.bather.moveFootR(footInitR + [0,-1,1],1);
                            obj.bather.moveFootL(footInitL + [0,-1,1],1);
                        elseif mod(i+3,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-2,0],1);
                            obj.bather.moveHandL(handInitL + [0,-2,0],1);
                            obj.bather.moveFootR(footInitR + [0,-2,0],1);
                            obj.bather.moveFootL(footInitL + [0,-2,0],1);
                        elseif mod(i+2,8) == 0
                            obj.bather.moveHandR(handInitR + [0,-1,-1],1);
                            obj.bather.moveHandL(handInitL + [0,-1,-1],1);
                            obj.bather.moveFootR(footInitR + [0,-1,-1],1);
                            obj.bather.moveFootL(footInitL + [0,-1,-1],1);
                        elseif mod(i+1,8) == 0
                            obj.bather.moveHandR(handInitR,1);
                            obj.bather.moveHandL(handInitL,1);
                            obj.bather.moveFootR(footInitR,1);
                            obj.bather.moveFootL(footInitL,1);
                        end
                    case 'upDown'
                        if mod(i,8)
                            obj.bather.moveHandR([obj.bather.handR(1),obj.bather.handR(2),0],4);
                            obj.bather.moveHandL([obj.bather.handL(1),obj.bather.handL(2),0],4);
                            obj.bather.moveFootR([obj.bather.footR(1),obj.bather.footR(2),0],4);
                            obj.bather.moveFootL([obj.bather.footL(1),obj.bather.footL(2),0],4);
                        elseif mod(i+4,8)
                            obj.bather.moveHandR([obj.bather.handR(1),obj.bather.handR(2),7],4);
                            obj.bather.moveHandL([obj.bather.handL(1),obj.bather.handL(2),7],4);
                            obj.bather.moveFootR([obj.bather.footR(1),obj.bather.footR(2),7],4);
                            obj.bather.moveFootL([obj.bather.footL(1),obj.bather.footL(2),7],4);
                        end
                    otherwise
                        continue
                end
            end
        end
        
        function obj = plotTempHist(obj)
            figure()
            subplot(2,1,1)
            plot(obj.tempDiffHist)
            xlabel('Time (seconds/3)')
            ylabel('Heat Particles')
            title('Sum of Local Deviations from Initial Temperature Over Time')
            subplot(2,1,2)
            plot(obj.tempDiffDerivHist)
            xlabel('Time (seconds/3)')
            ylabel('Heat Particles')
            title('Sum of Local Finite Differences in Temperature Over Time')
        end
        
        function mat = spatialTypeMatrix(obj)
            mat = [];
            matx = [];
            maty = [];
            for k = 1 : obj.tubZ
                for i = 1 : obj.tubX
                    for j = 1 : obj.tubY
                        maty = [maty, obj.getCube(i,j,k).cubeType];
                    end
                    matx = [matx; maty];
                    maty = [];
                end
                mat = cat(3,mat,matx);
                matx = [];
            end
        end
        
        function fig = plotAllThermonCubes(obj)
            % Plots all thermon count histories of cubes in 1 plot
            figure
            hold on
            fig = plot(obj.thermonDensity.*ones(1,numel(obj.tempDiffHist)));
            for i = 1:numel(obj.cubes)
                plot(obj.cubes(i).numThermonsHist);
            end
            axis([0 numel(obj.tempDiffHist) 0 120])
            xlabel('t (seconds/3)')
            ylabel('Heat Particle Density')
            title('The Particle Density per Cube Over Time')
            box on
        end
        
        function fig = firstDerivAllThermonCubes(obj)
            % Plots the differences per tick of a thermon count history for
            % all cells in 1 plot
            figure
            hold on
            length = numel(obj.tempDiffHist)-1;
            fig = plot(0*ones(1,length));
            for i = 1:numel(obj.cubes)
                if (numel(obj.cubes(i).numThermonsHist) == length+2)
                    vec(1:length) = obj.cubes(i).numThermonsHist(2:length+1)-obj.cubes(i).numThermonsHist(1:length);
                    plot(vec(1:length));
                end
            end
            axis([0 numel(obj.tempDiffHist-1) -60 60])
            xlabel('t (seconds/3)')
            ylabel('Change in Heat Particle Density')
            title('Change in the Particle Density per Cube Over Time')
            box on
        end
        
        
        function fig = plotCubes(obj,xLow,yLow,zLow,xHigh,yHigh,zHigh,color)
            % Plots a 3d cube using the 2d polygonal faces.  Cube oriented
            % with grid.
            length = size(xLow,2);
            xOut = zeros(4,6*length);
            yOut = zeros(4,6*length);
            zOut = zeros(4,6*length);
            for i = 1:length
                xOut(:,6*i-5) = [xLow(i),xHigh(i),xHigh(i),xLow(i)];
                yOut(:,6*i-5) = [yLow(i),yLow(i),yHigh(i),yHigh(i)];
                zOut(:,6*i-5) = [zLow(i),zLow(i),zLow(i),zLow(i)];
                
                xOut(:,6*i-4) = [xLow(i),xHigh(i),xHigh(i),xLow(i)];
                yOut(:,6*i-4) = [yLow(i),yLow(i),yHigh(i),yHigh(i)];
                zOut(:,6*i-4) = [zHigh(i),zHigh(i),zHigh(i),zHigh(i)];
                
                xOut(:,6*i-3) = [xLow(i),xHigh(i),xHigh(i),xLow(i)];
                yOut(:,6*i-3) = [yLow(i),yLow(i),yLow(i),yLow(i)];
                zOut(:,6*i-3) = [zLow(i),zLow(i),zHigh(i),zHigh(i)];
                
                xOut(:,6*i-2) = [xLow(i),xHigh(i),xHigh(i),xLow(i)];
                yOut(:,6*i-2) = [yHigh(i),yHigh(i),yHigh(i),yHigh(i)];
                zOut(:,6*i-2) = [zLow(i),zLow(i),zHigh(i),zHigh(i)];
                
                xOut(:,6*i-1) = [xLow(i),xLow(i),xLow(i),xLow(i)];
                yOut(:,6*i-1) = [yLow(i),yHigh(i),yHigh(i),yLow(i)];
                zOut(:,6*i-1) = [zLow(i),zLow(i),zHigh(i),zHigh(i)];
                
                xOut(:,6*i) = [xHigh(i),xHigh(i),xHigh(i),xHigh(i)];
                yOut(:,6*i) = [yLow(i),yHigh(i),yHigh(i),yLow(i)];
                zOut(:,6*i) = [zLow(i),zLow(i),zHigh(i),zHigh(i)];
            end
            fig = fill3(xOut,yOut,zOut,color);
        end
        
        function fig = flowGraphNoTub(obj)
            count = obj.tubX*obj.tubY*obj.tubZ;
            x = zeros(1,count);
            y = zeros(1,count);
            z = zeros(1,count);
            u = zeros(1,count);
            v = zeros(1,count);
            w = zeros(1,count);
            for i = 1:obj.tubX*obj.tubY*obj.tubZ
                currentCube = obj.cubes(i);
                if or(currentCube.cubeType == 0, currentCube.cubeType == 3)
                    x(i) = currentCube.position(1);
                    y(i) = currentCube.position(2);
                    z(i) = currentCube.position(3);
                    u(i) = currentCube.velocity(3);
                    v(i) = currentCube.velocity(3);
                    w(i) = currentCube.velocity(3);
                end
            end
            figure
            fig = quiver3(x,y,z,u,v,w);
            axis([1 obj.tubX 1 obj.tubY 1 obj.tubZ])
            xlabel('x')
            ylabel('y')
            zlabel('z')
            box on
        end
        
        function fig = flowGraph(obj)
            count = obj.tubX*obj.tubY*obj.tubZ;
            x = zeros(1,count);
            y = zeros(1,count);
            z = zeros(1,count);
            u = zeros(1,count);
            v = zeros(1,count);
            w = zeros(1,count);
            xWall = zeros(1, count);
            yWall = zeros(1, count);
            zWall = zeros(1, count);
            xPerson = zeros(1,count);
            yPerson = zeros(1,count);
            zPerson = zeros(1,count);
            for i = 1:obj.tubX*obj.tubY*obj.tubZ
                currentCube = obj.cubes(i);
                if or(currentCube.cubeType == 0, currentCube.cubeType == 3)
                    x(i) = currentCube.position(1);
                    y(i) = currentCube.position(2);
                    z(i) = currentCube.position(3);
                    u(i) = currentCube.velocity(3);
                    v(i) = currentCube.velocity(3);
                    w(i) = currentCube.velocity(3);
                elseif currentCube.cubeType == 1
                    xWall(i) = currentCube.position(1);
                    yWall(i) = currentCube.position(2);
                    zWall(i) = currentCube.position(3);
                elseif currentCube.cubeType == 2
                    xPerson(i) = currentCube.position(1);
                    yPerson(i) = currentCube.position(2);
                    zPerson(i) = currentCube.position(3);
                end
            end
            figure
            fig = quiver3(x,y,z,u,v,w);
            axis([1 obj.tubX 1 obj.tubY 1 obj.tubZ])
            xlabel('x')
            ylabel('y')
            zlabel('z')
            box on
            hold on
            obj.plotCubes(xWall,yWall,zWall,xWall+1,yWall+1,zWall+1,'yellow');
            hold on
            obj.plotCubes(xPerson,yPerson,zPerson,xPerson+1,yPerson+1,zPerson+1,'red');
        end
        
    end
    
end