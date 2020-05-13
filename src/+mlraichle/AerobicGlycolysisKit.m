classdef AerobicGlycolysisKit < handle & mlpet.AerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 10:54:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
    end
    
	methods (Static)
        function constructSubjectsStudy(varargin)
            %% CONSTRUCTSUBJECTSSTUDY 
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param cpuIndex is char or is numeric. 
            %  Setting cpuIndex := {-1,0,Inf} also sets wallClockLimit := Inf. 
            %  @param useParfor is logical with default := ~ifdeployed().
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addRequired(ip, 'cpuIndex', @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'roisExpr', 'wmparc', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelTime', 90, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'wallClockLimit', 168*3600, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'useParfor', ~isdeployed(), @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if ischar(ipr.cpuIndex)
                ipr.cpuIndex = str2double(ipr.cpuIndex);
            end
            if ipr.cpuIndex < 1 || ~isfinite(ipr.cpuIndex)
                ipr.wallClockLimit = Inf;
            end
            if ischar(ipr.voxelTime)
                ipr.voxelTims = str2double(ipr.voxelTime);
            end
            if ischar(ipr.wallClockLimit)
                ipr.wallClockLimit = str2double(ipr.wallClockLimit);
            end
            fprintf('mlraichle.AerobicGlycolysis.constructSubjectsStudy():\n')
            disp(ipr)
            ss = strsplit(ipr.foldersExpr, '/'); 
            disp(ss)
    
            registry = mlraichle.StudyRegistry.instance();
            registry.voxelTime = ipr.voxelTime;
            registry.wallClockLimit = ipr.wallClockLimit;   
            registry.useParfor = ipr.useParfor;
            disp(registry)
            
            subPath = fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '');            
            pwd0 = pushd(subPath);
            fprintf('mlraichle.AerobicGlycolysisKit.constructSubjectsStudy():  pwd->%s\n', pwd)
            fprintf('mlraichle.AerobicGlycolysisKit.constructSubjectsStudy():  getenv(''CCIR_RAD_MEASUREMENTS_DIR'')->%s\n', ...
                getenv('CCIR_RAD_MEASUREMENTS_DIR'));
            subd = SubjectData('subjectFolder', ss{2});
            disp(subd)
            sesfs = subd.subFolder2sesFolders(ss{2});
            disp(sesfs)
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                disp(s{1})
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true); 
                disp(sesd)
                kit = AerobicGlycolysisKit.createFromSession(sesd);
                disp(kit)
                sstr = split(sesd.tracerResolvedOpSubject('typ', 'fqfn', 'tag', '_on_T1001'), ['Singularity' filesep]);
                kit.buildKs( ...
                    'filesExpr', sstr{2}, ...
                    'cpuIndex', ipr.cpuIndex, ...
                    'roisExpr', ipr.roisExpr, ...
                    'averageVoxels', false)
            end
            popd(pwd0)
        end
        function this = createFromSession(varargin)
            this = mlraichle.AerobicGlycolysisKit('sessionData', varargin{:});
        end
    end

	methods 
    end
		
    %% PROTECTED
    
    methods (Access = protected)
 		function this = AerobicGlycolysisKit(varargin)
 			this = this@mlpet.AerobicGlycolysisKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
