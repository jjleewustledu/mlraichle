classdef TracerDirector2 < mlpipeline.AbstractDirector
	%% TRACERDIRECTOR2  

	%  $Revision$
 	%  was created 17-Nov-2018 10:26:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        anatomy 	
        outputDir
        outputFolder
        reconstructionDir
        reconstructionFolder
    end

    methods (Static)  
        function ic2 = flipKLUDGE____(ic2)
            if (mlnipet.Resources.instance.FLIP1)
                assert(isa(ic2, 'mlfourd.ImagingContext2'), 'mlraichle:TypeError', 'TracerDirector2.flipKLUDGE____');
                warning('mlraichle:RuntimeWarning', 'KLUDGE:TracerDirector2.flipKLUDGE____ is active');
                ic2 = ic2.flip(1);
                ic2.ensureSingle;
            end
        end
        
        function this = cleanResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
                      
            import mlraichle.TracerDirector2;
            inst = mlnipet.Resources.instance;
            inst.keepForensics = false;
            this = TracerDirector2(mlpet.TracerResolveBuilder(varargin{:}));   
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceCleanResolvedNAC;
            else
                this = this.instanceCleanResolvedAC;
            end
        end  
        function this = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
                      
            import mlraichle.TracerDirector2;
            this = TracerDirector2(mlpet.TracerResolveBuilder(varargin{:}));   
            if (~this.sessionData.attenuationCorrected)
                TracerDirector2.prepareFreesurferData(varargin{:});
                TracerDirector2.constructUmaps(varargin{:});
                this = this.instanceConstructResolvedNAC;
            else
                this = this.instanceConstructResolvedAC;
            end
        end   
        function objs = migrateResolvedToVall(varargin)
            import mlraichle.TracerDirector2;
            import mlfourd.ImagingContext2;
            this = TracerDirector2(mlpet.TracerResolveBuilder(varargin{:}));  
            sess = this.sessionData;
            targ = fullfile( ...
                '/data/nil-bluearc/raichle/PPGdata/jjlee4', ...
                sess.sessionLocation('typ','folder'), ...
                sess.vallLocation('typ','folder'), '');
            ensuredir(targ);
            res  = mlnipet.Resources.instance;
            res.keepForensics = false;
            
            % migrate PET without flipping
            cd(sess.vLocation);
            kinds = {'' '_sumt'};
            for k = 1:length(kinds)
                movefile( ...
                    sprintf('fdgv%ir2_op_fdgv%ie1to4r1_frame4%s.4dfp.*', sess.vnumber, sess.vnumber, kinds{k}), ...
                    targ);
            end            
            
            % migrate and resolve T1001
            movefile('T1001.4dfp.*', targ);
            pwd0 = pushd(targ);
            theImages = {trac.fqfileprefix 'T1001'};
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sess, ...
                'theImages', theImages, ...
                'blurArg', [4.3 4.3], ...
                'maskForImages', {'Msktgen' 'T1001'}, ...
                'NRevisions', 1);
            ct4rb = ct4rb.resolve;            
            popd(pwd0);
            
            res.keepForensics = true;
            objs = {trac, ct4rb};
        end      
        function lst  = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session & visit-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlraichle.SessionData.
            %  @return 4dfp copies of this.freesurferData in sessionData.vLocation.
            %  @return lst, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.            
        
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});            
            sess = ip.Results.sessionData;
            
            pwd0    = pushd(sess.vLocation);
            fv      = mlfourdfp.FourdfpVisitor;
            fsd     = { 'aparc+aseg' 'aparc.a2009s+aseg' 'brainmask' 'T1' };  
            safefsd = fsd; safefsd{4} = 'T1001';
            safefsd = fv.ensureSafeFileprefix(safefsd);
            lst     = cell(1, length(safefsd));
            sess    = ip.Results.sessionData;
            for f = 1:length(fsd)
                if (~fv.lexist_4dfp(fullfile(sess.vLocation, safefsd{f})))
                    try
                        sess.mri_convert([fullfile(sess.mriLocation, fsd{f}) '.mgz'], [safefsd{f} '.nii']);
                        ic2 = mlfourd.ImagingContext2([safefsd{f} '.nii']);
                        ic2.saveas([safefsd{f} '.4dfp.hdr']);
                        lst{f} = fullfile(pwd, safefsd{f});
                    catch ME
                        dispwarning(ME);
                    end
                end
            end
            if (~lexist('T1001_to_TRIO_Y_NDC_t4', 'file'))
                fv.msktgenMprage('T1001');
            end
            popd(pwd0);
        end
        function this = constructUmaps(varargin)
            import mlraichle.TracerDirector2;    
            this = TracerDirector2(mlfourdfp.CarneyUmapBuilder2(varargin{:}));
            if (this.builder.isfinished)
                return
            end 
            
            import mlfourd.ImagingContext2;
            import mlpet.Resources;
            pwd0 = pushd(this.sessionData.vLocation);   
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
    end
    
	methods 
        
        %% GET/SET
        
        function g = get.anatomy(this)
            g = this.anatomy_;
        end
        function g = get.outputDir(this)
            g = fullfile(this.sessionData.tracerConvertedLocation, this.outputFolder, '');
        end
        function g = get.outputFolder(~)
            g = 'output';
        end
        function g = get.reconstructionDir(this)
            g = fullfile(this.sessionData.tracerConvertedLocation, this.reconstructionFolder, '');
        end
        function g = get.reconstructionFolder(~)
            g = 'reconstructed';
        end
        
        %%
        
        function this = instanceCleanResolvedAC(this)
            %  @return removes non-essential files from workspaces to conserve storage costs.
            
            pwd0 = pushd(this.sessionData.tracerLocation);  
            mlnipet.NipetBuilder.CleanPrototype(this.sessionData);
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
            this.builder_ = this.builder_.sumProduct;
            this.builder_.logger.save; 
            save('mlraichle.TracerDirector_instanceConstructResolvedAC.mat');   
            this.builder_.markAsFinished;
            %this.builder_.deleteWorkFiles;
            popd(pwd0);
        end
        function this = instanceCleanResolvedNAC(this)    
            %  @return removes non-essential files from workspaces to conserve storage costs.
            
            mlnipet.NipetBuilder.CleanPrototype(this.sessionData);
            this.builder_ = this.builder_.partitionMonolith; 
            [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames;
            reconstituted = reconstituted.motionCorrectCTAndUmap;             
            this.builder_ = reconstituted.motionUncorrectUmap(epochs);     
            this.builder_ = this.builder_.aufbauUmaps;     
            this.builder_.logger.save;       
            p = this.flipKLUDGE____(this.builder_.product); % KLUDGE:  bug at interface with NIPET
            p.save;            
            save('mlraichle.TracerDirector2_instanceConstructResolvedNAC.mat');
            this.builder_.markAsFinished;
            %this.builder_.deleteWorkFiles;
        end
        function this = instanceConstructResolvedAC(this)
            pwd0 = pushd(this.sessionData.tracerLocation);  
            mlnipet.NipetBuilder.CreatePrototypeAC(this.sessionData);
            this          = this.prepareFourdfpTracerImages;   
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
            this.builder_ = this.builder_.sumProduct;
            this.builder_.logger.save; 
            save('mlraichle.TracerDirector_instanceConstructResolvedAC.mat');   
            this.builder_.markAsFinished;
            %this.builder_.deleteWorkFiles;
            popd(pwd0);
        end
        function this = instanceConstructResolvedNAC(this)              
            mlnipet.NipetBuilder.CreatePrototypeNAC(this.sessionData);
            this          = this.prepareFourdfpTracerImages;
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            this.builder_ = this.builder_.partitionMonolith; 
            [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames;
            reconstituted = reconstituted.motionCorrectCTAndUmap;             
            this.builder_ = reconstituted.motionUncorrectUmap(epochs);     
            this.builder_ = this.builder_.aufbauUmaps;     
            this.builder_.logger.save;       
            p = this.flipKLUDGE____(this.builder_.product); % KLUDGE:  bug at interface with NIPET
            p.save;            
            save('mlraichle.TracerDirector2_instanceConstructResolvedNAC.mat');
            this.builder_.markAsFinished;
            %this.builder_.deleteWorkFiles;
        end
        function this = prepareFourdfpTracerImages(this)
            %% copies reduced-FOV NIfTI tracer images to this.sessionData.tracerLocation in 4dfp format.
            
            import mlfourd.*;
            assert(isdir(this.outputDir));
            ensuredir(this.sessionData.tracerRevision('typ', 'path'));
            if (~lexist_4dfp(this.sessionData.tracerRevision('typ', 'fqfp')))
                ic2 = ImagingContext2(this.sessionData.tracerNipet('typ', '.nii.gz'));
                ic2 = this.flipKLUDGE____(ic2); % KLUDGE:  bug at interface with NIPET
                ic2.saveas(this.sessionData.tracerRevision('typ', '.4dfp.hdr'));
            end
            this.builder_ = this.builder_.packageProduct( ...
                ImagingContext2(this.sessionData.tracerRevision('typ', '.4dfp.hdr')));
        end    
		  
 		function this = TracerDirector2(varargin)
 			%% TRACERDIRECTOR2
 			%  @param builder must be an mlpet.TracerBuilder.
            %  @param anatomy is 4dfp, e.g., T1001.

 			this = this@mlpipeline.AbstractDirector(varargin{:});
            
            ip = inputParser;
            addOptional( ip, 'builder', [], @(x) isempty(x) || isa(x, 'mlfourdfp.AbstractSessionBuilder'));
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

