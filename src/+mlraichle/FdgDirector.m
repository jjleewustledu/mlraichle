classdef FdgDirector < mlpet.TracerKineticsDirector
	%% FDGDIRECTOR is a strategy

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties 
    end
    
	methods
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR
            %  @param required 'builder' is an 'mlraichle.FdgBuilder'

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'builder', @(x) isa(x, 'mlraichle.FdgBuilder'));
            parse(ip, varargin{:});
            this = this@mlpet.TracerKineticsDirector(varargin{:});
            this.sessionData.tracer = 'FDG';
        end
        
        function this = ensureJSRecon(this)
        end
        function this = constructNAC(this)
            this.sessionData.attenuationCorrected = false;
            this.builder_ = this.builder_.locallyStageTracer;
            this.builder_ = this.builder_.motionCorrectNACFrames;
            this.builder_ = this.builder_.motionCorrectUmaps;
            this.builder_.product.view;
        end        
        function this = constructAC(this)
            this.sessionData.attenuationCorrected = true;
            this.builder_ = this.builder_.locallyStageTracer;
            this.builder_ = this.builder_.motionCorrectACFrames;
            this.builder_ = this.builder_.recombineAC;
            this.builder_ = this.builder_.product.view;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
    end
    
    methods (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

