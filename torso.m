classdef torso < handle
    %Torso
    %    A rectangular prism representing a rigid torso
    
    properties
        torsoHeight %Butt to shoulder
        torsoWidth  %Shoulder to shoulder
        torsoDepth  %Front to back
        shoulders   % Vertices [Front right, front left, back left, back right]
        hips        % Vertices [Front right, front left, back left, back right]
        tilt
    end
    
    methods
        
        function obj = torso(torsoHeight, torsoWidth, torsoDepth, bathtub)
            obj.torsoHeight = torsoHeight;
            obj.torsoWidth = torsoWidth;
            obj.torsoDepth = torsoDepth;
            
            obj.tilt = pi/2-real(asin((bathtub.tubZ-2)/obj.torsoHeight));
            
            obj.shoulders = cat(1,[obj.torsoDepth*cos(obj.tilt)+1,bathtub.tubY/2+torsoWidth/2,...
                bathtub.tubZ-1+obj.torsoDepth*sin(obj.tilt)],...
                [obj.torsoDepth*cos(obj.tilt)+1,bathtub.tubY/2-torsoWidth/2,...
                bathtub.tubZ-1+obj.torsoDepth*sin(obj.tilt)],[1,bathtub.tubY/2-torsoWidth/2,bathtub.tubZ-1]...
                ,[1,bathtub.tubY/2+torsoWidth/2,bathtub.tubZ-1]);
            
            obj.hips = cat(1,[real(sqrt(obj.torsoHeight^2-bathtub.tubZ^2))+1+obj.torsoDepth*cos(obj.tilt),bathtub.tubY/2+torsoWidth/2,2+obj.torsoDepth*sin(obj.tilt)],...
                [real(sqrt(obj.torsoHeight^2-bathtub.tubZ^2))+1+obj.torsoDepth*cos(obj.tilt),bathtub.tubY/2-torsoWidth/2,2+obj.torsoDepth*sin(obj.tilt)],...
                [real(sqrt(obj.torsoHeight^2-bathtub.tubZ^2))+1,bathtub.tubY/2-torsoWidth/2,2],...
                [real(sqrt(obj.torsoHeight^2-bathtub.tubZ^2))+1,bathtub.tubY/2+torsoWidth/2,2]);

        end
    end
    
end

