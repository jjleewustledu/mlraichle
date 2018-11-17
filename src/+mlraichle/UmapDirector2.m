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
            
            pwd0 = pushd(this.sessionData.vLocation);   
            this.builder_ = this.builder.prepareMprToAtlasT4;
            ctm = this.builder.buildCTMasked2;
            %ctm  = this.builder.buildCTMasked3(this.builder.prepareBrainmaskMskt); 
            ctm  = this.builder.rescaleCT(ctm);
            umap = this.builder.assembleCarneyUmap(ctm);
            umap = this.builder.buildVisitor.imgblur_4dfp(umap, mlpet.Resources.instance.pointSpread);
            this.builder_ = this.builder.packageProduct(umap);
            this.builder.teardownBuildUmaps;
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
                    fv.copyfile_4dfp(sess.T1('typ','fqfp'), pwd);
                end
            catch ME
                dispwarning(ME);
            end
            popd(pwd0);            
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

