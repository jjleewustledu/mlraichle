classdef Scan < handle & mlxnat.Scan
	%% SCAN  

	%  $Revision$
 	%  was created 18-Oct-2018 16:44:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods 
		  
 		function this = Scan(varargin)
 			%% SCAN
 			%  @param session is mlraichle.Session.
            %  @param scanDetails.

 			this = this@mlxnat.Scan(varargin{:});  
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

