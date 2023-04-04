classdef Ccir559754
    %% line1
    %  line2
    %  
    %  Created 22-Feb-2023 23:22:19 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
    %  Developed on Matlab 9.13.0.2126072 (R2022b) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function this = Ccir559754(varargin)
            %% CCIR559754 
            %  Args:
            %      arg1 (its_class): Description of arg1.
            
            ip = inputParser;
            addParameter(ip, "arg1", [], @(x) true)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
