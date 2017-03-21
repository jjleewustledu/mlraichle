classdef HoDirector < mlpet.TracerDirector 
	%% HODIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = HoDirector(varargin)
 			%% HODIRECTOR
 			%  Usage:  this = HoDirector(hoBuilder)
            %  @param hoBuilder is an mlpipeline.IImageBuilder
            
            this = this@mlpet.TracerDirector(varargin{:});
            assert(isa(this.builder, 'mlraichle.HoBuilder')); 			
        end
        
        function ensureJSRecon(this)
        end
        function this = constructNAC(this)
            %this.builder.transferFromRawData;
            %this.builder.transferToE7tools('HO');
            %this.builder.transferFromE7tools('HO-Converted-NAC');
            this.builder.buildNACImageFrames;
            this.builder.motionCorrectNACImageFrames;
            this.builder.buildCarneyUmap;
            this.builder.motionCorrectUmaps;
            this.builder.product.view;
            this.builder.transferToE7tools('HO-Converted-NAC');
        end
        function this = constructAC(this)
            %this.builder.transferFromE7tools('HO-Converted-Frame*');
            %this.builder.buildACImageFrames;
            %this.builder.motionCorrectACImageFrames;
            this.builder.buildHoAC;
            this.builder.product.view;
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

