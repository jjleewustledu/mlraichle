classdef TracerDirector2 < mlpipeline.AbstractDirector
	%% TRACERDIRECTOR2  

	%  $Revision$
 	%  was created 17-Nov-2018 10:26:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        anatomy 	
        reconstructionDir
        reconstructionFolder
    end

    methods (Static)
        function this = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
            
            mlpet.TracerDirector.prepareFreesurferData(varargin{:});            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));   
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructResolvedNAC;
            else
                this = this.instanceConstructResolvedAC;
            end
        end         
        function lst = prepareFreesurferData(varargin)
            lst = mlpet.TracerDirector.prepareFreesurferData(varargin{:});
        end
    end
    
	methods 
        
        %% GET/SET
        
        function g = get.anatomy(this)
            g = this.anatomy_;
        end
        function g = get.reconstructionDir(this)
            g = fullfile(this.sessionData.tracerConvertedLocation, this.reconstructionFolder, '');
        end
        function g = get.reconstructionFolder(~)
            g = 'reconstructed';
        end
        
        %%
        
        function this = instanceConstructResolvedAC(this)
            pwd0 = pushd(this.builder_.sessionData.tracerLocation);            
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
            this.builder_ = this.builder_.sumProduct;
            this.builder_.logger.save; 
            save('mlraichle.TracerDirector_instanceConstructResolvedAC.mat');           
            popd(pwd0);
        end
        function this = instanceConstructResolvedNAC(this)
            this          = this.prepareNipetTracerImages;
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            this.builder_ = this.builder_.partitionMonolith; 
            [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames;
            reconstituted = reconstituted.motionCorrectCTAndUmap;             
            this.builder_ = reconstituted.motionUncorrectUmap(epochs);
            this.builder_.logger.save;
            save('mlraichle.TracerDirector_instanceConstructResolvedNAC.mat');
        end
        function this = prepareNipetTracerImages(this)
            assert(isdir(this.reconstructionDir));
            ensuredir(this.sessionData.tracerRevision('typ', 'path'));
            if (~lexist_4dfp(this.sessionData.tracerRevision('typ', 'fqfp')))
                this.builder_.buildVisitor.nifti_4dfp_4( ...
                    this.sessionData.tracerNipet('typ', 'fqfp'), this.sessionData.tracerRevision('typ', 'fqfp'));
            end
            this.builder_ = this.builder_.packageProduct( ...
                mlfourd.ImagingContext2(this.sessionData.tracerRevision('typ', 'fqfn')));
        end      
		  
 		function this = TracerDirector2(varargin)
 			%% TRACERDIRECTOR2
 			%  @param builder must be an mlpet.TracerBuilder.
            %  @param anatomy is 4dfp, e.g., T1001.

 			this = this@mlpipeline.AbstractDirector(varargin{:});
            
            ip = inputParser;
            addOptional( ip, 'builder', [], @(x) isempty(x) || isa(x, 'mlpet.TracerBuilder'));
            addParameter(ip, 'anatomy', 'T1001', @ischar);
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
            this.anatomy_ = ip.Results.anatomy;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        anatomy_
    end
    
    %% HIDDEN
    
    methods (Hidden)
        function this = setBuilder__(this, s)
            %% for testing, debugging
            
            this.builder_ = s;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
