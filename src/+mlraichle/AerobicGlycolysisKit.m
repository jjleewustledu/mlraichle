classdef AerobicGlycolysisKit < handle & mlpet.AerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 10:54:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
    end
    
	methods (Static)
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
