classdef UmapDirector 
	%% UMAPDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 01:52:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties
 		builder
 	end

	methods 
        function this = constructUmap(this)
            studyd = mlraichle.StudyData;
            pwd0 = pushd(studyd.subjectsDir);
            mlfourdfp.CarneyUmapBuilder.buildUmapAll;
            popd(pwd0);
        end
		  
 		function this = UmapDirector(varargin)
 			%% UMAPDIRECTOR
 			%  Usage:  this = UmapDirector()

 			this.builder = mlfourdfp.CarneyUmapBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

