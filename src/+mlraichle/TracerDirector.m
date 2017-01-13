classdef TracerDirector 
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties 		
 		parCluster
 	end

	methods 
		  
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector()			

 			this.parCluster = mlraichle.ParCluster;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

