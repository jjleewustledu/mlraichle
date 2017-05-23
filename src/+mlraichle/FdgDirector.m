classdef FdgDirector < mlpet.TracerDirector
	%% FDGDIRECTOR is a strategy

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties 
    end
    
	methods
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR
 			%  Usage:  this = FdgDirector(fdgBuilder)
            %  @param fdgBuilder is an mlpipeline.IImageBuilder
            
            this = this@mlpet.TracerDirector(varargin{:});
            assert(isa(this.builder, 'mlraichle.FdgBuilder'));
        end
        
        function ensureJSRecon(this)
        end
        function this = constructNAC(this)
            %this.builder.transferFromRawData;
            %this.builder.transferToE7tools('FDG');
            %this.builder.transferFromE7tools('FDG-Converted-NAC');
            this.builder.buildNACImageFrames;
            this.builder.motionCorrectNACImageFrames;
            this.builder.buildCarneyUmap;
            this.builder.motionCorrectUmaps;
            this.builder.product.view;
            this.builder.transferToE7tools('FDG-Converted-AC');
        end        
        function this = constructAC(this)
            %this.builder.transferFromE7tools('FDG-Converted-Frame*');
            %this.builder.buildACImageFrames;
            %this.builder.motionCorrectACImageFrames;
            this.builder.buildFdgAC;
            this.builder.product.view;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
    end
    
    methods (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

