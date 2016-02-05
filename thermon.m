classdef thermon < handle
    %thermon:
    %   A single thermon chugging along.
    
    properties
        position                    % Marks the absolute location of the thermon
        velocity                    % Marks the current velocity, always has norm less than 1
        parentCube                  % Denotes the cube in which the thermon lies
        index                       % index in parent cube's thermon list
    end 
    
    methods
        function obj = thermon(position, velocity, parentCube, index)
            % Set default index to 0
            if nargin < 4
                index = 0;
            end
            
            obj.position = position;
            obj.velocity = velocity;
            obj.parentCube = parentCube;
            obj.index = index;
        end
        
        function pos = getPos(obj)
            pos = obj.position;
        end
        
        function vel = getVel(obj)
            vel = obj.velocity;
        end
        
        function cubeThing = getCube(obj)
            cubeThing = obj.parentCube;
        end
        
        function obj = newCube(obj,cubeThing)
            obj.parentCube.thermonSpot = obj.parentCube.thermonSpot - 1;
            [obj.parentCube.thermonSpace(obj.index),...
                obj.parentCube.thermonSpace(obj.parentCube.thermonSpot)] = ...
                deal(obj.parentCube.thermonSpace(obj.parentCube.thermonSpot),...
                obj.parentCube.thermonSpace(obj.index));
            obj.parentCube = cubeThing;
            obj.parentCube.enteringThermons = [obj.parentCube.enteringThermons, obj];
        end
        
        function obj = setVel(obj, newVel)
            obj.velocity = newVel;
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
        
        function obj = updateVelocity(obj)
            % Currently set to inertia-type updating.  
            % It is also possible to do a brownian type update using random
            % variables.
            obj.addVel(obj.parentCube.velocity);
        end
        
        function obj = updatePos(obj)  
            condi = 1;
            tempPos = obj.position + obj.velocity;
            while condi
                tempIndex = floor(tempPos);
                if tempIndex(1) == 0
                    disp(obj.parentCube);
                end
                newParent = obj.parentCube.parentTub.getCube(tempIndex(1),tempIndex(2),tempIndex(3));
                
                if and(and(newParent.cubeType ~= 1, newParent.cubeType ~= 2), newParent.cubeType ~= 5)
                    obj.position = tempPos;
                    obj.newCube(newParent);
                    condi = 0;
                else                
                    intDifference = tempIndex - floor(obj.position);
                    normalized = intDifference*(1/norm(intDifference));
                    
                    offset = (intDifference==1).*ceil(obj.position) + (intDifference==-1).*floor(obj.position);
                    tempPos = offset + transpose((eye(3) - 2.*transpose(normalized)*normalized)*transpose(tempPos - offset));
                
                    newVel = obj.velocity - 2*dot(normalized,obj.velocity)*normalized;
                    obj.velocity = newVel;
                end
            end
        end 
    end
    
end