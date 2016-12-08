classdef SynthStudyData < mlraichle.StudyData
	%% SYNTHSTUDYDATA  

	%  $Revision$
 	%  was created 06-Dec-2016 19:25:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
    methods (Static)        
        function d    = subjectsDir
            d = fullfile(getenv('PPG'), 'jjleeSynth', '');
        end
    end

	methods		
        function sess = sessionData(this, varargin)
            %% SESSIONDATA
            %  @param [parameter name,  parameter value, ...] as expected by mlraichle.SessionData are optional;
            %  'studyData' and this are always internally supplied.
            %  @returns for empty param:  mlpatterns.CellComposite object or it's first element when singleton, 
            %  which are instances of mlraichle.SessionData.
            %  @returns for non-empty param:  instance of mlraichle.SessionData corresponding to supplied params.
            
            if (isempty(varargin))
                sess = this.sessionDataComposite_;
                if (1 == length(sess))
                    sess = sess.get(1);
                end
                return
            end
            sess = mlraichle.SynthSessionData('studyData', this, varargin{:});
        end  
 		function this = SynthStudyData(varargin)
 			%% SYNTHSTUDYDATA
 			%  Usage:  this = SynthStudyData()

 			this = this@mlraichle.StudyData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

