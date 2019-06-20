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
    
    methods (Static)
        function obj = createProjectData(varargin)
            obj = mlraichle.ProjectData(varargin{:});
        end
    end

	methods 
        function sesf = subFolder2sesFolder(this, subf)
            %% requires well-defined cell-array this.subjectsJson.
            %  @param subf is a subject folder.
            %  @returns first-found non-trivial session folder in the subject folder.
            
            json = this.subjectsJson;
            subs = fields(json);
            substr = split(subf, '-');
            substr = substr{2};
            sesf = '';
            for sub = ensureRowVector(subs)
                jsonsub = json.(sub{1});
                if lstrfind(jsonsub.id, substr)
                    sesf = searchExperiments(jsonsub);
                    if isempty(sesf) && isfield(jsonsub, 'aliases')
                        for alias = ensureRowVector(fields(jsonsub.aliases))
                            jsonalias = jsonsub.aliases.(alias{1});
                            sesf = searchExperiments(jsonalias);
                        end
                    end
                end
            end   
            
            function sesf = searchExperiments(sub)
                sesf = '';
                if isfield(sub, 'experiments')
                    for e = ensureRowVector(sub.experiments)
                        sesstr = split(e{1}, '_');
                        sesstr = sesstr{2};
                        if foundScanIn(['ses-' sesstr])
                            sesf = ['ses-' sesstr];
                            return
                        end
                    end
                end
            end
                
            function tf = foundScanIn(sesf)
                dt = mlsystem.DirTool(fullfile(this.subjectPath, sesf, '*_DT*.000000-Converted-AC'));
                tf = ~isempty(dt.fqdns);
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
            
            this.studyRegistry_ = mlraichle.StudyRegistry.instance;
            this.subjectsJson_ = jsondecode( ...
                fileread(fullfile(this.subjectsDir, 'construct_ct.json')));
 		end
    end     

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

