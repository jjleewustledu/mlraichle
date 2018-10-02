classdef StudyContext 
	%% STUDYCONTEXT  

	%  $Revision$
 	%  was created 02-Jun-2018 20:16:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        STUDY_CENSUS_XLSX = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'census 2018may31.xlsx')
    end
    
	properties (Dependent) 		
        studyCensus
 	end

	methods 
        
        %% GET/SET
        
        function g = get.studyCensus(this) 
            g = this.studyCensus_;
        end
		
        %%
        
 		function this = StudyContext(varargin)
 			%% STUDYCONTEXT
 			%  @param .

            this.sessionContext_ = [];
 			this.legacy_ = mlraichle.SessionData( ...
                'sessionDate', this.sessionContext_.sessionDate, ...
                'sessionFolder', this.sessionContext_.sessionFolder, ...
                'vnumber', this.sessionContext_.vnumber, ...
                'ac', true);
 			this.studyCensus_ = mlraichle.StudyCensus(this.STUDY_CENSUS_XLSX);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        legacy_
        sessionContext_
        studyCensus_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

