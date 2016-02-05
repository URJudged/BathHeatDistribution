classdef person < handle
    %NUDE DUDE
    %    A very boxy human with no head
    
    properties
        height
        chestDepth
        shoulderWidth
        torso
        torsoLength%7/18 height
        handLength %7/18 height
        legLength %4/9 height
        handR
        handRQueue
        handL
        handLQueue
        footR
        footRQueue
        footL
        footLQueue
        bathtub
    end
    
    methods
        function obj = person(height, chestDepth, shoulderWidth, bathtub)
            obj.height = height;
            obj.chestDepth = chestDepth;
            obj.shoulderWidth = shoulderWidth;
            obj.bathtub = bathtub;
            obj.torsoLength = obj.height * 7/18;
            obj.handLength = obj.height*7/18;
            obj.legLength = obj.height*4/9;
            
            obj.torso = torso(obj.torsoLength, obj.shoulderWidth, ...
                obj.chestDepth,obj.bathtub);
            obj.handR = obj.torso.shoulders(1,:)+[obj.handLength,0,0];
            obj.handL = obj.torso.shoulders(2,:)+[obj.handLength,0,0];
            
            obj.footR = obj.torso.hips(1,:) + [obj.legLength,0,0];
            obj.footL = obj.torso.hips(2,:) + [obj.legLength,0,0];
        end
        
        function obj = placeTorso(obj)
            tHeightN = ceil(obj.torso.torsoHeight)*2;
            tWidthN = ceil(obj.torso.torsoWidth)*2;
            tDepthN = ceil(obj.torso.torsoDepth)*2;
            % Start at front right shoulder
            % Move in all directions
            downHeight = obj.torso.shoulders(1,:) - obj.torso.hips(1,:);
            acrossWidth = obj.torso.shoulders(1,:) - obj.torso.shoulders(2,:);
            throughDepth = obj.torso.shoulders(1,:) - obj.torso.shoulders(4,:);
            for i = 0 : tHeightN
                for j = 0 : tWidthN
                    for k = 0 : tDepthN
                        vector = ceil(obj.torso.shoulders(1)+...
                            (i/tHeightN).*downHeight+...
                            (j/tWidthN).*acrossWidth+...
                            (k/tDepthN).*throughDepth);
                        x = vector(1);
                        y = vector(2);
                        z = vector(3);
                        if or(or(x > obj.bathtub.tubX, y > obj.bathtub.tubY),...
                                z > obj.bathtub.tubZ)
                            continue
                        end
                        relevantCube = obj.bathtub.getCube(x,y,z);
                        if relevantCube.cubeType == 0
                            relevantCube.cubeType = 2;
                        end
                    end
                end
            end
        end
        
        function obj = placeLimbs(obj)
            armN = ceil(obj.handLength)*2;
            legN = ceil(obj.legLength)*2;
            % Hands
            for i = 0 : armN
                vecR = ceil(obj.torso.shoulders(1,:) + (i/armN).*(obj.handR-obj.torso.shoulders(1,:)));
                xR = vecR(1);
                yR = vecR(2);
                zR = vecR(3);
                
                if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                        zR > obj.bathtub.tubZ), xR <= 0), yR <= 0), zR <= 0)
                    continue
                end
                
                relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                
                if relevantCubeR.cubeType == 0
                    relevantCubeR.cubeType = 2;
                end
            end
            for i = 0 : armN
                vecL = ceil(obj.torso.shoulders(2,:) + (i/armN).*(obj.handL-obj.torso.shoulders(2,:)));
                xL = vecL(1);
                yL = vecL(2);
                zL = vecL(3);
                
                if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                        zL > obj.bathtub.tubZ), xL <= 0), yL <= 0), zL <= 0)
                    continue
                end
                
                relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                
                if relevantCubeL.cubeType == 0
                    relevantCubeL.cubeType = 2;
                end
            end
            % Feet
            for i = 0 : legN
                vecR = ceil(obj.torso.hips(1,:) + (i/legN).*(obj.footR-obj.torso.hips(1,:)));
                xR = vecR(1);
                yR = vecR(2);
                zR = vecR(3);
                
                if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                        zR > obj.bathtub.tubZ), xR <= 0), yR <= 0), zR <= 0)
                    continue
                end
                
                relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                
                if relevantCubeR.cubeType == 0
                    relevantCubeR.cubeType = 2;
                end
            end
            for i = 0 : legN
                vecL = ceil(obj.torso.hips(2,:) + (i/legN).*(obj.footL-obj.torso.hips(2,:)));
                xL = vecL(1);
                yL = vecL(2);
                zL = vecL(3);
                
                if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                        zL > obj.bathtub.tubZ), xL <= 0), yL <= 0), zL <= 0)
                    continue
                end
                
                relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                
                if relevantCubeL.cubeType == 0
                    relevantCubeL.cubeType = 2;
                end
            end
        end
        
        function obj = markLimbs(obj)
            armN = ceil(obj.handLength)*2;
            legN = ceil(obj.legLength)*2;
            if size(obj.handRQueue,1) > 0
                newHandR = obj.handRQueue(1);
                for i = 0 : armN
                    vecR = ceil(obj.torso.shoulders(1,:) + (i/armN).*(newHandR-obj.torso.shoulders(1,:)));
                    xR = vecR(1);
                    yR = vecR(2);
                    zR = vecR(3);
                    if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                            zR > obj.bathtub.tubZ),xR <= 0), yR <=0), zR <=0)
                        continue
                    end
                    relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                    if relevantCubeR.cubeType == 0
                        relevantCubeR.motionState = 1;
                    end
                end
            end
            if size(obj.handLQueue,1) > 0
                newHandL = obj.handLQueue(1);
                for i = 0 : armN
                    vecL = ceil(obj.torso.shoulders(2,:) + (i/armN).*(newHandL-obj.torso.shoulders(2,:)));
                    xL = vecL(1);
                    yL = vecL(2);
                    zL = vecL(3);
                    if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                            zL > obj.bathtub.tubZ),xL <= 0), yL <=0), zL <=0)
                        continue
                    end
                    relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                    if relevantCubeL.cubeType == 0
                        relevantCubeL.motionState = 1;
                    end
                end
            end
            if size(obj.footRQueue,1) > 0
                newFootR = obj.footRQueue(1);
                for i = 0 : legN
                    vecR = ceil(obj.torso.hips(1,:) + (i/legN).*(newFootR-obj.torso.hips(1,:)));
                    xR = vecR(1);
                    yR = vecR(2);
                    zR = vecR(3);
                    if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                            zR > obj.bathtub.tubZ),xR <= 0), yR <=0), zR <=0)
                        continue
                    end
                    relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                    if relevantCubeR.cubeType == 0
                        relevantCubeR.motionState = 1;
                    end
                end
            end
            if size(obj.footLQueue,1) > 0
                newFootL = obj.footLQueue(1);
                for i = 0 : legN
                    vecL = ceil(obj.torso.hips(2,:) + (i/legN).*(newFootL-obj.torso.hips(2,:)));
                    xL = vecL(1);
                    yL = vecL(2);
                    zL = vecL(3);
                    if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                            zL > obj.bathtub.tubZ),xL <= 0), yL <=0), zL <=0)
                        continue
                    end
                    relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                    if relevantCubeL.cubeType == 0
                        relevantCubeL.motionState = 1;
                    end
                end
            end
        end
        
        % Cubes return to simulation with whatever thermon distribution
        % they had before they were part of the person.
        function obj = clearLimbs(obj)
            armN = ceil(obj.handLength)*2;
            legN = ceil(obj.legLength)*2;
            % Hands
            for i = 0 : armN
                vecR = ceil(obj.torso.shoulders(1,:) + (i/armN).*(obj.handR-obj.torso.shoulders(1,:)));
                xR = vecR(1);
                yR = vecR(2);
                zR = vecR(3);
                
                if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                        zR > obj.bathtub.tubZ), xR <= 0), yR <= 0), zR <= 0)
                    continue
                end
                
                relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                
                if relevantCubeR.cubeType == 2
                    relevantCubeR.cubeType = 0;
                end
            end
            for i = 0 : armN
                vecL = ceil(obj.torso.shoulders(2,:) + (i/armN).*(obj.handL-obj.torso.shoulders(2,:)));
                xL = vecL(1);
                yL = vecL(2);
                zL = vecL(3);
                
                if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                        zL > obj.bathtub.tubZ), xL <= 0), yL <= 0), zL <= 0)
                    continue
                end
                
                relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                
                if relevantCubeL.cubeType == 2
                    relevantCubeL.cubeType = 0;
                end
            end
            % Feet
            for i = 0 : legN
                vecR = ceil(obj.torso.hips(1,:) + (i/legN).*(obj.footR-obj.torso.hips(1,:)));
                xR = vecR(1);
                yR = vecR(2);
                zR = vecR(3);
                
                if or(or(or(or(or(xR > obj.bathtub.tubX, yR > obj.bathtub.tubY),...
                        zR > obj.bathtub.tubZ), xR <= 0), yR <= 0), zR <= 0)
                    continue
                end
                
                relevantCubeR = obj.bathtub.getCube(xR,yR,zR);
                
                if relevantCubeR.cubeType == 2
                    relevantCubeR.cubeType = 0;
                end
            end
            for i = 0 : legN
                vecL = ceil(obj.torso.hips(2,:) + (i/legN).*(obj.footL-obj.torso.hips(2,:)));
                xL = vecL(1);
                yL = vecL(2);
                zL = vecL(3);
                
                if or(or(or(or(or(xL > obj.bathtub.tubX, yL > obj.bathtub.tubY),...
                        zL > obj.bathtub.tubZ), xL <= 0), yL <= 0), zL <= 0)
                    continue
                end
                
                relevantCubeL = obj.bathtub.getCube(xL,yL,zL);
                
                if relevantCubeL.cubeType == 2
                    relevantCubeL.cubeType = 0;
                end
            end
        end
        
        %  Makes sure towardPoint is a point within the handLength sphere
        % from the appropriate shoulder
        %  Creates and stores locally a vector holding the intermediate
        % positions between the current hand location and the target, with
        % a total of time entries in this vector, each step being
        % total-distance/time further than the last.
        %  Another function, such as updateAllLimbs, should actually move
        % the limbs along these paths when instructed to do so by the
        % bathtub governing this person (yes, that's how information flows).
        function obj = moveHandR(obj,towardPoint,time)
            if towardPoint(1)^2 + towardPoint(2)^2 + towardPoint(3)^2 ~= obj.handLength^2
                towardPoint = (towardPoint - obj.torso.shoulders(1,:)).*obj.handLength./...
                    (real(sqrt(towardPoint(1)^2+towardPoint(2)^2+towardPoint(3)^2)));
            end
            vecToTravelAlong = towardPoint - obj.handR;
            newHandRQueue = [];
            for i = 1:time
                newHandRQueue = cat(1,newHandRQueue, i.*vecToTravelAlong./time);
            end
            obj.handRQueue = newHandRQueue;
        end
        
        function obj = moveHandL(obj,towardPoint,time)
            if towardPoint(1)^2 + towardPoint(2)^2 + towardPoint(3)^2 ~= obj.handLength^2
                towardPoint = (towardPoint - obj.torso.shoulders(2,:)).*obj.handLength./...
                    (real(sqrt(towardPoint(1)^2+towardPoint(2)^2+towardPoint(3)^2)));
            end
            vecToTravelAlong = towardPoint - obj.handL;
            newHandLQueue = [];
            for i = 1:time
                newHandLQueue = cat(1,newHandLQueue, i.*vecToTravelAlong./time);
            end
            obj.handLQueue = newHandLQueue;
        end
        
        function obj = moveFootR(obj,towardPoint,time)
            if towardPoint(1)^2 + towardPoint(2)^2 + towardPoint(3)^2 ~= obj.legLength^2
                towardPoint = (towardPoint - obj.torso.hips(1,:)).*obj.legLength./...
                    (real(sqrt(towardPoint(1)^2+towardPoint(2)^2+towardPoint(3)^2)));
            end
            vecToTravelAlong = towardPoint - obj.footR;
            newFootRQueue = [];
            for i = 1:time
                newFootRQueue = cat(1,newFootRQueue, i.*vecToTravelAlong./time);
            end
            obj.footRQueue = newFootRQueue;
        end
        
        function obj = moveFootL(obj,towardPoint,time)
            if towardPoint(1)^2 + towardPoint(2)^2 + towardPoint(3)^2 ~= obj.legLength^2
                towardPoint = (towardPoint - obj.torso.hips(2,:)).*obj.legLength./...
                    (real(sqrt(towardPoint(1)^2+towardPoint(2)^2+towardPoint(3)^2)));
            end
            vecToTravelAlong = towardPoint - obj.footL;
            newFootLQueue = [];
            for i = 1:time
                newFootLQueue = cat(1,newFootLQueue, i.*vecToTravelAlong./time);
            end
            obj.footLQueue = newFootLQueue;
        end
        
    end
    
end


