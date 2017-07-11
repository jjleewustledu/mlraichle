classdef HoKinetics < mlkinetics.AbstractHoKinetics
	%% HOKINETICS  
    %  See also:  mlpet.AbstractHerscovitch1985

	%  $Revision$
 	%  was created 31-May-2017 21:17:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 	end

	methods		  
        
 		function this = HoKinetics(varargin)
 			%% HOKINETICS
 			%  Usage:  this = HoKinetics()
 			
 			this = this@mlkinetics.AbstractHoKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

