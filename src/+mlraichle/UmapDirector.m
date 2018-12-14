classdef UmapDirector < mlpipeline.AbstractDirector
	%% UMAPDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 01:52:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    properties (Dependent)
        roiStats
    end
    
    methods (Static)
        function this = constructUmaps(varargin)
            import mlraichle.UmapDirector;
            UmapDirector.prepareFreesurferData(varargin{:});            
            this = UmapDirector( ...
                mlfourdfp.CarneyUmapBuilder(varargin{:})); 
            pwd0 = pushd(this.sessionData.vLocation);
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            this.sessionData.attenuationCorrected = false;
            this.builder_ = this.builder_.buildUmap;
            popd(pwd0);
        end
        function this = constructPhantomCalibration(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'phantomNumber', 2, @isnumeric);
            parse(ip, varargin{:});            
            this = mlraichle.UmapDirector( ...
                mlfourdfp.CarneyUmapBuilder(varargin{:})); 
            
            pwd0 = pushd(ensuredir(this.sessionData.tracerLocation));              
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructPhantomUmap(ip.Results.phantomNumber);
            else
                this = this.instanceConstructPhantomCalibration;
                this = this.instanceConstructPhantomSpecificActivity;
            end            
            popd(pwd0);
        end
        function lst  = prepareFreesurferData(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'))
            parse(ip, varargin{:});
            sess = ip.Results.sessionData;
            sess.attenuationCorrected = false;
            
            lst  = mlpet.TracerDirector.prepareFreesurferData(varargin{:});
            pwd0 = pushd(sess.vLocation);
            fv   = mlfourdfp.FourdfpVisitor;
            try
                if (~fv.lexist_4dfp(sess.T1('typ','fp')))
                    fv.copyfile_4dfp(sess.T1('typ','fqfp'), sess.T1('typ','fp'));
                end
            catch ME
                dispwarning(ME);
            end
            popd(pwd0);            
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.roiStats(this)
            g = this.roiStats_;
        end
    end

    %% PRIVATE
    
    properties (Access = private)
        roiStats_
    end
    
	methods (Access = private)
        function this = instanceConstructPhantomUmap(this, phantomNumber)
            bv = this.builder.buildVisitor;
            bv.sif_4dfp(this.tracerListmodeMhdr, this.tracerRevision);
            bv.cropfrac_4dfp(0.5, this.tracerRevision, this.tracerRevision);
            [~,fp] = bv.align_multiSpectral( ...
                'dest',   this.tracerRevision, ...
                'source', this.umapPhantom(phantomNumber));
            bv.copy_4dfp(fp, this.umap);
            this.builder_.convertUmapToE7Format(this.umap)
        end
        function this = instanceConstructPhantomCalibration(this)
            bv = this.builder.buildVisitor;
            bv.sif_4dfp(this.tracerListmodeMhdr, this.tracerRevision);
            bv.cropfrac_4dfp(0.5, this.tracerRevision, this.tracerRevision);
            bv.IFhdr_to_4dfp(this.tracerListmodeUmap, this.umap);
            bv.cropfrac_4dfp(0.5, this.umap, this.umap);
        end
        function this = instanceConstructPhantomSpecificActivity(this)
            import mlfourd.*;
            mskNN = NumericalNIfTId.load(this.sessionData.tracerRevision);
            mskNN = mskNN.blurred(16);
            mskNN = mskNN.thresh(0.75*mskNN.dipmax);
            mskNN = mskNN.binarized;
            mskNN.filesuffix = '.4dfp.hdr';
            mskNN.save;
            
            tracerNN = NumericalNIfTId.load(this.sessionData.tracerRevision);
            this     = this.constructRoiStats(tracerNN, mskNN);
        end
        function this = constructRoiStats(this, tracerNN, mskNN)
            tracerNN.view(this.sessionData.umapTagged('frame0','typ','.4dfp.img'), [mskNN.fqfileprefix '.4dfp.img']);
            maskedImg = tracerNN.img(logical(mskNN.img));
            this.roiStats_.roiMean   = mean( maskedImg);
            this.roiStats_.roiStd    = std(  maskedImg);
            this.roiStats_.roiVoxels = numel(maskedImg);
            this.roiStats_.roiVol    = this.roiStats_.roiVoxels * prod(mskNN.mmppix/10); % mL
            this.roiStats_.roiMin    = min(  maskedImg);
            this.roiStats_.roiMax    = max(  maskedImg);
        end
        function fqfn = tracerListmodeMhdr(this)
            fqfn = this.sessionData.tracerListmodeMhdr;
        end
        function fqfn = tracerListmodeUmap(this)
            fqfn = this.sessionData.tracerListmodeUmap;
        end
        function fp   = tracerRevision(this)
            fp = this.sessionData.tracerRevision('typ','fp');
        end
        function fp   = umapTagged(this)
            fp = this.sessionData.umapTagged('frame0','typ','fp');
        end
        function fqfp = umapPhantom(this, idx)
            fqfp = this.sessionData.umapPhantom( ...
                'sessionFolder', sprintf('CAL_PHANTOM%i', idx), 'typ', 'fqfp');
        end
		  
 		function this = UmapDirector(varargin)
 			%% UMAPDIRECTOR
 			%  Usage:  this = UmapDirector()

            this = this@mlpipeline.AbstractDirector(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

