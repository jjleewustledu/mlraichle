classdef OoDirector < mlpet.TracerDirector
	%% OODIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties
 		
 	end

	methods 
		  
 		function this = OoDirector(varargin)
 			%% OODIRECTOR
            %  @param required 'builder' is an 'mlraichle.OoBuilder'

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'builder', @(x) isa(x, 'mlraichle.OoBuilder'));
            parse(ip, varargin{:});
            this = this@mlpet.TracerDirector(varargin{:});
            this.sessionData.tracer = 'OO';
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

