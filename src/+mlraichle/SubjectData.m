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

