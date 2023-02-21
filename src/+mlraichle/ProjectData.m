classdef ProjectData < mlpipeline.ProjectData2022
	%% PROJECTDATA2022  

	%  $Revision$
 	%  was created 08-May-2019 19:15:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Dependent)
        jsonDir	
        projectsDir
    end
    
	methods 
        
        %% GET
        
        function g    = get.jsonDir(this)
            g = fullfile(this.projectsDir, 'subjects', '');
        end        
        function g    = get.projectsDir(~)
            g = mlraichle.StudyRegistry.instance().projectsDir;
        end
        
        %% 
        
        function p = session2project(this, s)
            %% e.g.:  {'CNDA_E1234','ses-E1234'} -> 'CCIR_00123'
            
            if ~strncmp(s, 'ses-', 4)
                split = strsplit(s, '_');
                s = ['ses-' split{2}];
            end
            p = this.session2projectMap_(s);
        end
		  
 		function this = ProjectData(varargin)
 			%% PROJECTDATA
 			%  @param sessionStr is char.
            %  See also mlraichle.ProjectData.session2project.

 			this = this@mlpipeline.ProjectData2022(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionStr', '', @ischar)
            parse(ip, varargin{:})
            
            this = this.aufbauMap; % session2projectMap_
            if ~isempty(ip.Results.sessionStr)
                this.projectFolder_ = this.session2project(ip.Results.sessionStr);
            end
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        session2projectMap_
    end
    
    methods (Access = private)
        function this = aufbauMap(this)
            %% map:  session-folder -> project-folder
            
            project754Struct_ = jsondecode( ...
                fileread(fullfile(this.jsonDir, 'CCIR_00754.json')));
            project559Struct_ = jsondecode( ...
                fileread(fullfile(this.jsonDir, 'CCIR_00559.json')));
            
            this.session2projectMap_ = containers.Map('KeyType','char','ValueType','char');
            for sub = fields(project754Struct_)'
                for e = project754Struct_.(sub{1}).experiments'
                    split = strsplit(e{1}, '_');
                    ses = ['ses-' split{2}];
                    this.session2projectMap_(ses) = 'CCIR_00754';
                end
            end
            for sub = fields(project559Struct_)'
                for e = project559Struct_.(sub{1}).experiments'
                    split = strsplit(e{1}, '_');
                    ses = ['ses-' split{2}];
                    this.session2projectMap_(ses) = 'CCIR_00559';
                end
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

