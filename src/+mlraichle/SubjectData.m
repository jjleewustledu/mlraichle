classdef SubjectData < mlnipet.SubjectData
	%% SUBJECTDATA

	%  $Revision$
 	%  was created 05-May-2019 22:06:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        TRACERS = {'FDG' 'OC' 'OO' 'HO'}
        EXTS = {'.4dfp.hdr' '.4dfp.ifh' '.4dfp.img' '.4dfp.img.rec'};
    end

	methods 
        
        %%
        
        function        aufbauSubjectsDir(this)
            %% e. g., /subjectsDir/{sub-S123456, sub-S123457, ...}
            
            S = this.subjectsStruct_;
            for sub = fields(S)'
                d = this.ensuredirSub(S.(sub{1}).sid);
                this.aufbauSubjectPath(d, S.(sub{1}));
            end
        end
        function        aufbauSubjectPath(this, sub_pth, S_sub)
            %% e. g., /subjectsDir/sub-S40037/{ses-E182819, ses-E182853, ...}/tracer.4dfp.*, with sym-linked tracer.4dfp.*
            
            if isfield(S_sub, 'aliases')
                for asub = fields(S_sub.aliases)'
                    this.aufbauSubjectPath(sub_pth, S_sub.aliases.(asub{1}));
                end
            end
            
            % base case
            assert(isfield(S_sub, 'experiments'))
            for e = S_sub.experiments'
                d = this.ensuredirSes(sub_pth, e{1});
                fcell = this.ensuredirsScans(d);
                if (~isempty(fcell))
                    e1 = this.experimentID_to_ses(e{1});
                    try
                        this.lns_tracers( ...
                            fullfile(this.projectData_.getProjectPath(e1), e1, ''), ...
                            fullfile(sub_pth, e1, ''), ...
                            fcell);
                        this.lns_surfer( ...
                            fullfile(this.projectData_.getProjectPath(e1), e1, ''), ...
                            fullfile(sub_pth, e1, ''));
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function sub  = subjectID_to_sub(~, sid)
            %% abbreviates sub-CNDA01_S12345 -> sub-S12345
            
            split = strsplit(sid, '_');
            sub = ['sub-' split{2}];
        end
		  
 		function this = SubjectData(varargin)
 			%% SUBJECTDATA
 			%  @param .

 			this = this@mlnipet.SubjectData(varargin{:});
            
            this.registry_ = mlraichle.StudyRegistry.instance;
            this.subjectsStruct_ = jsondecode( ...
                fileread(fullfile(this.subjectsDir, 'construct_ct.json')));
            this.projectData_ = mlraichle.ProjectData();
 		end
    end     

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

