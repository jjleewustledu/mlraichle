classdef UmapDirector2 < mlpipeline.AbstractDirector 
	%% UMAPDIRECTOR2  

	%  $Revision$
 	%  was created 15-Nov-2018 15:32:19 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
    
    methods (Static)
        function this = constructUmaps(varargin)
            import mlraichle.UmapDirector2;
            UmapDirector2.prepareFreesurferData(varargin{:});      
            this = UmapDirector2(mlfourdfp.CarneyUmapBuilder2(varargin{:}));
            if (this.builder.isfinished)
                return
            end 
            
            import mlfourd.ImagingContext2;
            import mlpet.Resources;
            pwd0 = pushd(this.sessionData.sessionPath);   
            this.builder_ = this.builder.prepareMprToAtlasT4;
            ctm  = this.builder.buildCTMasked2;
            ctm  = this.builder.rescaleCT(ctm);
            umap = this.builder.assembleCarneyUmap(ctm);
            umap = ImagingContext2([umap '.4dfp.hdr']);
            umap = umap.blurred(Resources.instance.pointSpread);
            umap.save;
            this.builder_ = this.builder.packageProduct(umap);
            this.builder.teardownBuildUmaps;
            popd(pwd0);
        end
        function safefsd = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session & visit-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlraichle.SessionData.
            %  @return 4dfp copies of this.freesurferData in sessionData.sessionPath.
            %  @return safefsd, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.  
            %  TO DO:  replace with TracerDirector2.prepareFreesurferData
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'))
            parse(ip, varargin{:});
            sess = ip.Results.sessionData;
            sess.attenuationCorrected = false;            
            
            import mlfourd.ImagingContext2;
            fv      = mlfourdfp.FourdfpVisitor;
            fsd_    = { 'aparc+aseg' 'aparc.a2009s+aseg' 'brainmask' 'T1' };  
            fsd     = cellfun(@(x) fullfile(sess.mriLocation, x),   fsd_, 'UniformOutput', false);
            safefsd = fv.ensureSafeFileprefix(fsd_); safefsd{4} = [safefsd{4} '001'];
            safefsd = cellfun(@(x) fullfile(sess.sessionPath, x), safefsd, 'UniformOutput', false);
            for f = 1:length(fsd)
                ic2 = ImagingContext2([fsd{f} '.mgz']);
                ic2.saveas([safefsd{f} '.4dfp.hdr']);
            end
            if (~lexist('T1001_to_TRIO_Y_NDC_t4', 'file'))
                fv.msktgenMprage('T1001');
            end         
        end
    end

    %% PRIVATE
    
	methods (Access = private)
		  
 		function this = UmapDirector2(varargin)
            this = this@mlpipeline.AbstractDirector(varargin{:}); 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

