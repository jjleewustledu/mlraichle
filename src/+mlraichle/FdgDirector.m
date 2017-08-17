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
            %% CONSTRUCTNAC
            %  @return this with this.builder updated with motion-corrections and back-projections of umap 
            %  onto individual fames of native NAC PET data.  Attenuation correction := false always.
            
            this.sessionData.attenuationCorrected = false;
            this.builder_ = this.builder_.locallyStageTracer;
            this.builder_ = this.builder_.motionCorrectFrames;
            this.builder_ = this.builder_.motionCorrectModalities;
            this.builder_ = this.builder_.backProjectUmapToFrames;
            %this.builder_ = this.builder_.backProjectToFrames;
            %this.builder_ = this.builder_.backProjectToEpochs;
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

