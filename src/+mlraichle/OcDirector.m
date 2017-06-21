classdef OcDirector < mlpet.TracerDirector  
	%% OCDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:40
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties
 		
 	end

	methods 
		  
 		function this = OcDirector(varargin)
 			%% OCDIRECTOR
            %  @param required 'builder' is an 'mlraichle.OcBuilder'

            ip = inputParser;
            addRequired(ip, 'builder', @(x) isa(x, 'mlraichle.OcBuilder'));
            parse(ip, varargin{:}); 			
            this = this@mlpet.TracerDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

