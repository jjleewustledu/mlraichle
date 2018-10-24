classdef (Sealed) ProjectKit < mlxnat.ProjectKit
	%% PROJECTKIT  

	%  $Revision$
 	%  was created 18-Oct-2018 16:22:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods (Static)
    end
		
    %% PRIVATE
    
    methods (Access = private)
 		function this = ProjectKit(varargin)
 			%% PROJECTKIT
 			%  @param .

 			this = this@mlxnat.ProjectKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

