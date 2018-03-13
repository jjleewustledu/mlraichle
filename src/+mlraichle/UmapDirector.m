classdef UmapDirector < mlpipeline.AbstractDataDirector
	%% UMAPDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 01:52:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    properties (Dependent)
        result
    end
    
    methods 
        
        %% GET
        
        function g = get.result(this)
            g = this.result_;
        end
    end
    
    methods (Static)
        function this = constructUmaps(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            sessd = ip.Results.sessionData;
            pwd0 = pushd(sessd.vLocation);
            fv = mlfourdfp.FourdfpVisitor;
            try
                if (~fv.lexist_4dfp(sessd.T1('typ','fp')))
                    fv.copyfile_4dfp(sessd.T1('typ','fqfp'), pwd);
                end
            catch ME
                dispwarning(ME);
            end
            popd(pwd0);
            
            this = mlraichle.UmapDirector( ...
                mlfourdfp.CarneyUmapBuilder(varargin{:}));              
            this = this.instanceConstructUmaps;
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
    end

    %% PRIVATE
    
    properties (Access = private)
        buildVisitor_
        result_
    end
    
	methods (Access = private)
        function [this,umap] = instanceConstructUmaps(this)
            pwd0 = pushd(this.sessionData.vLocation);
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            [umap,this.builder_] = this.builder_.buildUmap;
            popd(pwd0);
        end
        function this = instanceConstructPhantomUmap(this, phantomNumber)
            bv = this.buildVisitor_;
            bv.sif_4dfp(this.tracerListmodeMhdr, this.tracerRevision);
            bv.cropfrac_4dfp(0.5, this.tracerRevision, this.tracerRevision);
            [~,fp] = bv.align_multiSpectral( ...
                'dest',   this.tracerRevision, ...
                'source', this.umapPhantom(phantomNumber));
            bv.copy_4dfp(fp, this.umap);
            this.builder_.convertUmapToE7Format(this.umap)
        end
        function this = instanceConstructPhantomCalibration(this)
            bv = this.buildVisitor_;
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
            mskNN.filesuffix = '.4dfp.ifh';
            mskNN.save;
            
            tracerNN = NumericalNIfTId.load(this.sessionData.tracerRevision);
            this     = this.setResultRoi(tracerNN, mskNN);
        end
        function this = setResultRoi(this, tracerNN, mskNN)            
            tracerNN.view(this.sessionData.umap('frame0','typ','.4dfp.img'), [mskNN.fqfileprefix '.4dfp.img']);
            maskedImg = tracerNN.img(logical(mskNN.img));
            this.result_.roiMean   = mean( maskedImg);
            this.result_.roiStd    = std(  maskedImg);
            this.result_.roiVoxels = numel(maskedImg);
            this.result_.roiVol    = this.result_.roiVoxels * prod(mskNN.mmppix/10); % mL
            this.result_.roiMin    = min(  maskedImg);
            this.result_.roiMax    = max(  maskedImg);
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
        function fp   = umap(this)
            fp = this.sessionData.umap('frame0','typ','fp');
        end
        function fqfp = umapPhantom(this, idx)
            fqfp = this.sessionData.umapPhantom( ...
                'sessionFolder', sprintf('CAL_PHANTOM%i', idx), 'typ', 'fqfp');
        end
		  
 		function this = UmapDirector(varargin)
 			%% UMAPDIRECTOR
 			%  Usage:  this = UmapDirector()

            this = this@mlpipeline.AbstractDataDirector(varargin{:});
            this.buildVisitor_ = mlfourdfp.FourdfpVisitor;
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

