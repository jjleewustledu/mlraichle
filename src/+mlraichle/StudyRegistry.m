classdef (Sealed) StudyRegistry < handle
	%% STUDYREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64. 	
        
    methods (Static)
        function this = instance()
            this = mlraichle.Ccir559754Registry.instance();
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

