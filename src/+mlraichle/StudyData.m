classdef StudyData < handle & mlpipeline.StudyData
	%% STUDYDATA  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
    
    
    properties (Dependent)
        atlVoxelSize
        dicomExtension
        rawdataDir
        projectsDir
        subjectsDir
        YeoDir
    end
    
    methods
        
        %% GET
        
        function g = get.atlVoxelSize(~)
            g = mlraichle.RaichleRegistry.instance.atlVoxelSize;            
        end
        function g = get.dicomExtension(~)
            g = mlraichle.RaichleRegistry.instance.dicomExtension;
        end
        function g = get.rawdataDir(~)
            g = mlraichle.RaichleRegistry.instance.rawdataDir;
        end
        function g = get.projectsDir(~)
            g = mlraichle.RaichleRegistry.instance.projectsDir;
        end
        function g = get.subjectsDir(~)
            g = mlraichle.RaichleRegistry.instance.subjectsDir;
        end
        function g = get.YeoDir(~)
            g = mlraichle.RaichleRegistry.instance.YeoDir;
        end
        
        %% LEGACY
        
        function a    = seriesDicomAsterisk(this, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*' this.dicomExtension]);
        end        
        function f    = subjectsDirFqdns(this)
            if (isempty(this.subjectsDir))
                f = {};
                return
            end            
            dt = mlsystem.DirTools(this.subjectsDir);
            f = {};
            for di = 1:length(dt.dns)
                if (strncmp(dt.dns{di}, 'sub-', 4))
                    f = [f dt.fqdns(di)]; %#ok<AGROW>
                end
            end
        end
        
        %%
        
 		function this = StudyData(varargin)
 			this = this@mlpipeline.StudyData(varargin{:});
            ip = inputParser;
            addParameter(ip, 'dicomExtension', '', @ischar);
            addParameter(ip, 'rawdataDir', '', @ischar);
            addParameter(ip, 'projectsDir', '', @ischar);
            addParameter(ip, 'subjectsDir', '', @ischar);
            addParameter(ip, 'YeoDir', '', @ischar);
            parse(ip, varargin{:});
            
            inst = mlraichle.RaichleRegistry.instance();
            if ~isempty(ip.Results.dicomExtension)
                inst.dicomExtension = ip.Results.dicomExtension;
            end
            if ~isempty(ip.Results.rawdataDir)
                inst.rawdataDir = ip.Results.rawdataDir;
            end
            if ~isempty(ip.Results.projectsDir)
                inst.projectsDir = ip.Results.projectsDir;
            end
            if ~isempty(ip.Results.subjectsDir)
                inst.subjectsDir = ip.Results.subjectsDir;
            end
            if ~isempty(ip.Results.YeoDir)
                inst.YeoDir = ip.Results.YeoDir;
            end
        end        
    end  

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

