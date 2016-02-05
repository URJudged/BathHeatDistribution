classdef cube < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        position    % [x, y, z] with 1 unit being ~5cm
        velocity    % [x, y, z] in 5cm/0.1s
        thermons    % list of thermon objects
        thermonSpace % list of open spots in thermons
        thermonSpot % position of first nonzero index of thermonSpace
        enteringThermons % Updating thermons add themselves to this list
        numThermonsHist % History array of thermon count
        cubeType    % int
        motionState % int
        pendingVelocity % updating velocity for the next step
    end
    
    methods
        function obj = cube(pos, vel, type)
            obj.position = pos;
            obj.velocity = vel;
            obj.thermons = repelem(thermon([0,0,0],[0,0,0],obj),200); % Preallocation. Increase if running out of space
            obj.thermonSpace = (1:200);
            obj.thermonSpot = 1;
            obj.numThermonsHist = [];
            obj.cubeType = type;
            obj.motionState = 0; % WARNING! May change when we figure out what state means
            obj.pendingVelocity=  [0,0,0];
        end
        
        function pos = getPos(obj)
            pos = obj.position;
        end
        
        function min = getMin(obj)
            % obj.position measures one corner of the cube
            min = obj.position;
        end
        
        function max = getMax(obj)
            % adding one to all coordinates gives opposite corner
            max = obj.position + [1, 1, 1];
        end
        
        function center = getCenter(obj)
            % halfway through each cube is the center
            center = obj.position + [0.5, 0.5, 0.5];
        end
        
        function vel = getVel(obj)
            vel = obj.velocity;
        end
        
        function obj = addVel(obj, newVel)
            obj.velocity = obj.velocity + newVel;
            if (norm(obj.velocity)>1)
                obj.velocity = obj.velocity / norm(obj.velocity);
            end
        end
        
        function randThing = randomOnSphere(obj)
            theta = 2*pi*rand();
            u = 2*rand()-1;
            randThing = real([sqrt(1-u*u)*cos(theta),sqrt(1-u*u)*sin(theta),u]);
        end
        
        function randThing = randomInSphere(obj)
            r = real(rand()^(1/3));
            randThing = r*obj.randomOnSphere();
        end
        
        function obj = addThermon(obj)
            tpos = rand(1,3) + obj.getPos(); % pos is in this cube
            tvel = obj.randomInSphere(); % velocity
            thrm = thermon(tpos, tvel, obj, obj.thermonSpace(obj.thermonSpot));
            obj.thermons(thrm.index) = thrm;
            obj.thermonSpot = obj.thermonSpot + 1;
            if obj.thermonSpot == length(obj.thermonSpace)
                obj.thermonSpace = [obj.thermonSpace, obj.thermonSpot+1:obj.thermonSpot+50];
            end
        end
        
        function obj = addNThermons(obj, N)
            for i = 1 : N
                obj.addThermon();
            end
        end
        
        function obj = removeNThermons(obj,N)
            % Don't remove more thermons than you have, dumbass.
            for i = 1 : N
                if obj.thermonSpot == 1
                    break;
                end
                num = ceil(rand()*(obj.thermonSpot-1));
%                 obj.thermons(obj.thermonSpace(num)) = thermon([0,0,0],[0,0,0],0);
                obj.thermonSpot = obj.thermonSpot - 1;
                [obj.thermonSpace(num),obj.thermonSpace(obj.thermonSpot)] = deal(obj.thermonSpace(obj.thermonSpot),obj.thermonSpace(num));
            end
        end
        
        function obj = changeNumThermons(obj,N)
            if N > 0
                obj.addNThermons(N);
            else
                obj.removeNThermons(N);
            end
        end
        
        function obj = clearThermons(obj)
%             obj.thermons = repelem(thermon([0,0,0],[0,0,0],obj),200); % Preallocation. Increase if running out of space
            obj.thermonSpace = (1:200);
            obj.thermonSpot = 1;
        end
        
        function obj = updateThermons(obj)
            N = obj.numThermons();
            for i = 1 : N
%                 disp(obj.thermonSpace(N+1-i));
                obj.thermons(obj.thermonSpace(N+1-i)).updatePos();
                obj.thermons(obj.thermonSpace(N+1-i)).updateVelocity();
            end
        end
        
        function obj = commitWaitingThermons(obj)
            for i = 1:length(obj.enteringThermons)
                obj.enteringThermons(i).index = obj.thermonSpace(obj.thermonSpot);
                obj.thermons(obj.thermonSpace(obj.thermonSpot)) = obj.enteringThermons(i);
                obj.thermonSpot = obj.thermonSpot + 1;
                if obj.thermonSpot == length(obj.thermonSpace)
                    obj.thermonSpace = [obj.thermonSpace, obj.thermonSpot+1:obj.thermonSpot+50];
                end
            end
            obj.enteringThermons = [];
            obj.recordThermonCount();
        end
        
        function n = numThermons(obj)
            n = obj.thermonSpot-1;
        end
        
        function fig = plotThermons(obj)
            n = obj.numThermons();
            xs = []; % accumulators
            ys = [];
            zs = [];
            us = [];
            vs = [];
            ws = [];
            for i = 1 : n
                tpos = obj.thermons(i).position - obj.position;
                tvel = obj.thermons(i).velocity;
                xs = [xs, tpos(1)];
                ys = [ys, tpos(2)];
                zs = [zs, tpos(3)];
                us = [us, tvel(1)];
                vs = [vs, tvel(2)];
                ws = [ws, tvel(3)];
            end
            fig = quiver3(xs, ys, zs, us, vs, ws);
            axis([0 1 0 1 0 1])
            xlabel('x')
            ylabel('y')
            zlabel('z')
            title(['Particles in Cube ' num2str(obj.position)])
            box on
        end
        
        function obj = recordThermonCount(obj)
            obj.numThermonsHist = [obj.numThermonsHist, obj.numThermons()];
        end
        
        function fig = plotThermonCountHist(obj)
            fig = plot(obj.numThermonsHist);
            axis([0 size(obj.numThermonsHist,2) 0 120])
            xlabel('Time (cs)')
            ylabel('Thermons')
            title(['History of Cube ' num2str(obj.position)])
        end
        
        function t = getType(obj)
            t = obj.cubeType;
        end
        
        function s = getState(obj)
            s = obj.motionState;
        end       
        
    end
    
end

