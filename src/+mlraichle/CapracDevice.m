classdef CapracDevice < handle & mlcapintec.CapracDevice
	%% CAPRACDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:15:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = CapracDevice(varargin)
 			%% CAPRACDEVICE
 			%  @param .

 			this = this@mlcapintec.CapracDevice(varargin{:});
            assert(isa(this.radMeasurements, 'mlraichle.CCIRRadMeasurements'));
 		end
 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

