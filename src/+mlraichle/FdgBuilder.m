classdef FdgBuilder < mlraichle.TracerKineticsBuilder
	%% FDGBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    
    properties (Dependent)
        epoch
    end    
    
    methods (Static)
        function staticAssembleFdgAfterAC
            import mlsystem.* mlfourdfp.*;
            studyd = mlraichle.StudyData;            
            eSess = DirTool(fullfile(studyd.subjectsDir, 'HYGLY*'));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    if (~isempty(regexp(eVisit.dns{iVisit}, '^V[1-2]$', 'match')))
                        fdgRawdata = sprintf('FDG_%s', eVisit.dns{iVisit});
                        pthAC = fullfile(eVisit.fqdns{iVisit}, [fdgRawdata '-AC'], '');
                        
                        if (isdir(pthAC))
                            rmdir(pthAC, 's');
                        end
                        
                        ensuredir(pthAC);
                        fprintf('FDGResolveBuilder.assembleFdgAfterAC:  working in -> %s\n', pthAC);                            
                        sessd = mlraichle.SessionData('studyData', studyd, ...
                                                      'sessionPath', eSess.fqdns{iSess}, ...
                                                      'tracer', 'FDG', ...
                                                      'vnumber', T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FDGResolveBuilder('sessionData', sessd);  
                        firstFortranTimeFrame_ = this.firstFortranTimeFrame;                          
                        fdgACRevision = sessd.fdgACRevision('typ', 'fp');
                        fdgPrefix = sprintf('FDG_%s-LM-00-OP', eVisit.dns{iVisit});
                        fv = FourdfpVisitor;
                        eFrame = DirTool(fullfile(eVisit.fqdns{iVisit}, sprintf('%s-Converted-Frame*', fdgRawdata), ''));
                        for iFrame = 1:length(eFrame.fqdns)
                            try
                                pwd0 = pushd(eFrame.fqdns{iFrame});
                                fortranNumFrame = T4ResolveBuilder.frameNumber(eFrame.dns{iFrame}, 1);
                                fdgFramename = this.fileprefixIndexed(fdgACRevision, fortranNumFrame);
                                fv.sif_4dfp(fdgPrefix);
                                fdgT4 = sprintf('%s_frame%i_to_resolved_t4', ...
                                                sessd.fdgNACRevision('typ', 'fp'), fortranNumFrame);
                                fqFdgT4 = fullfile(sessd.fdgT4Location, fdgT4);
                                fv.cropfrac_4dfp(0.5, fdgPrefix, fdgACRevision);
                                if (fortranNumFrame >= firstFortranTimeFrame_ && ...
                                    lexist(fqFdgT4, 'file'))
                                    fv.lns(fqFdgT4);
                                    fv.t4img_4dfp(fdgT4, fdgACRevision, 'options', ['-O' fdgACRevision]);                            
                                    fv.move_4dfp([fdgACRevision '_on_resolved'], ...                                
                                                 fullfile(pthAC, [fdgFramename '_on_resolved']));
                                else                           
                                    fv.move_4dfp(fdgACRevision, ...                                
                                                 fullfile(pthAC, [fdgFramename '_on_resolved']));
                                end
                                delete('*.4dfp.*')
                                delete([fdgACRevision '_frame*_to_resolved_t4']);
                                popd(pwd0);
                            catch ME
                                handwarning(ME);
                            end
                        end
                        pwd0 = pushd(fullfile(pthAC, ''));
                        ipr.dest = fdgACRevision;
                        ipr.indicesLogical = ones(1, length(eFrame.fqdns));
                        this.pasteImageIndices(ipr, 'on_resolved');
                        fv.imgblur_4dfp([fdgACRevision '_on_resolved'], 5.5);
                        delete(fullfile(pthAC, [fdgACRevision '_frame*_on_resolved.4dfp.*']));
                        popd(pwd0);
                    end
                end                
            end
        end
        function extractFramesResolveSequenceAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            fv = mlfourdfp.FourdfpVisitor;
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth  = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        v    = lower(eVisit.dns{iVisit});
                        pwd0 = pushd(fullfile(pth, ['ResolveSequence' v], ''));
                        FdgBuilder.printv('extractFramesResolveSequenceAll:  try pwd->%s\n', pwd);
                        for fr = 1:3
                            fv.extract_frame_4dfp(sprintf('resolveSequence%sr2_%s', v, this.resolveTag), fr);
                        end
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
        function reconstituteEarlyFramesAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            parfor iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*')); %#ok<PFBNS>
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('resolvePartition:  try pwd->%s\n', pwd);
                        sessd = SessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          false, ...
                            'tracer',      'FDG', ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FdgBuilder('sessionData', sessd);
                        this.reconstituteEarlyFrames();
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end         
        function redoT4ResolveAndPasteForAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = SynthStudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            parfor iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*')); %#ok<PFBNS>
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}), '');
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('resolvePartition:  try pwd->%s\n', pwd);
                        sessd = SynthSessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          false, ...
                            'tracer',      'FDG', ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FdgBuilder('sessionData', sessd);
                        this.redoT4ResolveAndPaste;                        
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function resolveRevisionAll(varargin)
            ip = inputParser;
            addParameter(ip, 'rnumber', nan, @(x) isnumeric(x) && ~isnan(x));
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = SynthStudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('resolvePartition:  try pwd->%s\n', pwd);
                        sessd = SynthSessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          false, ...
                            'tracer',      'FDG', ...
                            'rnumber',     ip.Results.rnumber, ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        sessd0 = sessd; 
                        sessd0.rnumber = max(ip.Results.rnumber - 1, 1);
                        this = FdgBuilder('sessionData', sessd);
                        this.pushFilesToCluster( ...
                            T4ResolveUtilities.cell_4dfp( ...
                                sessd0.fdgNACResolved('typ', 'fqfp')));
                        this.resolveOnCluster;
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
        function resolveRevisionOnCluster
            
            import mlraichle.*;
            sessp = fullfile('/scratch/jjlee/raichle/PPGdata/jjleeSynth/HYGLY00');
            sessd = SynthSessionData( ...
                    'studyData',   SynthStudyData, ...
                    'sessionPath', sessp, ...
                    'ac',          false, ...
                    'tracer',      'FDG', ...
                    'rnumber',     2, ...
                    'vnumber',     1);            
            c = parcluster;
            ClusterInfo.setEmailAddress('jjlee.wustl.edu@gmail.com');
            ClusterInfo.setMemoryUsage('16000');
            ClusterInfo.setWallTime('04:00:00');
            for fss = 1:3
                c.batch(FdgBuilder.resolveFrameSubset, 1, {sessd, fss});
            end
        end 
        function sumTimesAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'indicesLogical', true(1,6), @islogical);
            addParameter(ip, 'rnumber', 1, @isnumeric);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('resolvePartition:  try pwd->%s\n', pwd);
                        sessd = SessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}), ...
                            'tracer',      'FDG', ...
                            'ac',          false, ...
                            'rnumber',     ip.Results.rnumber);
                        this = FdgBuilder('sessionData', sessd);
                        this.sumTimes(sessd.tracerResolved('typ', 'fp'), 'indicesLogical', ip.Results.indicesLogical);
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
        function test(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'useTracerResolvedSumtAC', false, @islogical);
            parse(ip, varargin{:});

            import mlfourdfp.* mlsystem.* mlraichle.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-AC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('testT4ResolveFdgAC:  try pwd->%s\n', pwd);
                        sessd = SessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          true, ...
                            'tracer',      'FDG', ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FdgBuilder('sessionData', sessd);
                        mprT = sessd.mpr('typ', 'fp', 'orientation', 'transverse');
                        tracerResSumt = mybasename(this.fileprefixSumt(this.sessionData.tracerResolved));
                        this.buildVisitor.t4img_4dfp( ...
                            fullfile(this.t4Path, [tracerResSumt '_to_' mprT '_t4']), ...
                            tracerResSumt, 'out', 'test', 'options', ['-O' mprT]);
                        this.buildVisitor.t4img_4dfp( ...
                            fullfile(this.t4Path, [mprT '_to_' tracerResSumt '_t4']), ...
                            mprT, 'out', 'test2', 'options', ['-O' tracerResSumt]);
                        mlbash(sprintf('fslview test.4dfp.img -l Cool %s.4dfp.img -t 0.5',    mprT));
                        mlbash(sprintf('fslview %s.4dfp.img   -l Cool test2.4dfp.img -t 0.5', tracerResSumt));
                        delete('test.4dfp.*');
                        delete('test2.4dfp.*');
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
    end
    
	methods 
        
        %% GET
        
        function g = get.epoch(this)
            g = this.sessionData_.epoch;
        end
        
        %%
		  
 		function this = FdgBuilder(varargin)
 			%% FDGBUILDER
 			%  Usage:  this = FdgBuilder()

 			this = this@mlraichle.TracerKineticsBuilder(varargin{:});
            this.sessionData_.tracer = 'FDG';
            this.indexOfReference = this.MAX_MONOLITH_LENGTH;
            %this.kinetics_ = mlraichle.FdgKinetics('sessionData', this.sessionData);            
            %this.finished = mlpipeline.Finished( ...
            %    this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
        
        function this = motionCorrectFrames(this)
            %% MOTIONCORRECTNACFRAMES may split the monolith image into partitioned epochs 
            %  using hierarchically organized data and filesystems.
            %  @return single motion-corrected epoch.
            %  @return multiple, internally stored, motion-corrected epochs and a single epoch that is the 
            %  the motion-correction of the summed images from descendent branches of the partitioning hierarchy tree.  
            
            this.vendorSupport_.cropfrac(this.vendorSupport_.sif);
            this.vendorSupport_.ensureTracerLocation;
            this.vendorSupport_.ensureTracerSymlinks;            
            this = this.inspectMonolith;
            
            if (~isempty(this.aComposite_))             
                for e = 1:length(this.aComposite_)
                    fdgbE = this.aComposite_{e};
                    this.aComposite_{e} = fdgbE.motionCorrectFrames;
                end
                this = this.reconstituteComposites;
                this = this.motionCorrectEpochs;
                return
            end
            
            % continue with leaf
            this.product_ = mlpet.PETImagingContext(this.sessionData.tracerRevision('typ','fqfn')); % fdgv1e*r1
            this = this.motionCorrectEpochs;
        end
        function this = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS resolves a single epoch with one or more frames at a time.
            
            sz  = this.buildVisitor.ifhMatrixSize([this.product_.fqfileprefix '.4dfp.ifh']);
            if (length(sz) < 4 || 1 == sz(4))
                return % fdgv1e*r1
            end
            
            this.indexOfReference = sz(4); % duration of this epoch

            this.t4rb_ = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', this.product_.fqfileprefix, ...
                'indexOfReference', this.indexOfReference, ...
                'NRevisions', 2); % this.product_.fqfp ~= this.sessionData.fqfp from this.motionCorrectFrames
                                  % following this.reconstituteComposites
            this.resolveTag = this.sessionData.resolveTagFrame(this.indexOfReference);
            this.t4rb_ = this.t4rb_.resolve('resolveTag', this.resolveTag);
            this.sessionData_ = this.t4rb_.sessionData; % fdgv1e*r2
            this.product_ = this.t4rb_.product; % fdgv1e*r2_op_fdgv1e1r1_frame8
            this = this.sumProduct;
        end
        function this = motionCorrectModalities(this)
            this.sessionData.rnumber = 1;      
            assert(strcmp(this.resolveTag, 'op_fdgv1e1to9r1_frame9'));                      
            bv = this.buildVisitor;
            bv.lns_4dfp(this.sessionData.T1('typ','fqfp'));            
            bv.lns_4dfp(this.sessionData.t2('typ','fqfp'));            
            bv.lns_4dfp(this.sessionData.tof('typ','fqfp'));
            ctFp = 'ctMaskedOnT1001r2_op_T1001';
            ctFqfp = fullfile(this.sessionData.vLocation, ctFp);
            bv.lns_4dfp(ctFqfp);
            bv.lns_4dfp(this.sessionData.umapSynth('tracer', '', 'typ', 'fqfp'));
            theImages = {[this.product_.fileprefix '_sumt'] ... 
                         ctFp ...
                         this.sessionData.T1( 'typ','fp') ...
                         this.sessionData.t2( 'typ','fp')}; 
                         % 'fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt' 
            pwd0 = this.product_.filepath; 
            
            this.ct4rb_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', theImages, ...
                'NRevisions', 2);               
            %this.resolveTag = this.sessionData.resolveTag; % redundant
            this.ct4rb_ = this.ct4rb_.resolve; % 'resolveTag', this.resolveTag); % redundant
            this.ct4rb_ = this.ct4rb_.t4img_4dfp( ...
                fullfile(pwd0, sprintf('%sr0_to_%s_t4', ctFp, this.ct4rb_.resolveTag)), ...
                fullfile(pwd0, this.sessionData.umapSynth('tracer','','typ','fp')));
            this.sessionData_ = this.ct4rb_.sessionData;
            this.product_ = this.ct4rb_.product;
        end
        function this = backProjectUmapToEpochs(this)
            %% BACKPROJECTUMAPTOEPOCHS back-resolves a single epoch with one or more frames at a time.
            
            for idxOfRef = 1:length(this.aComposite_) 
                
                % resolve umapSynth to idxOfRef   
                pwd0 = pushd(this.product_.filepath); % umap
                t4rbPrev = this.t4rb_; % fdg
                this.sessionData = t4rbPrev.sessionData;
                this.sessionData.rnumber = 1;       
                this.resolveTag = '';
                this.resolveTag = this.sessionData.resolveTagFrame(idxOfRef);
                %assert(strcmp(this.resolveTag, ...
                %       sprintf('op_fdgv1e%ir1_frame%i', this.aComposite_{idxOfRef}.epoch, idxOfRef)));
                
                this.t4rb_ = mlfourdfp.T4ResolveBuilder( ...
                    'sessionData', this.sessionData, ...
                    'theImages', t4rbPrev.theImages, ...
                    'indexOfReference', idxOfRef, ...
                    'NRevisions', 2);
                this.t4rb_ = this.t4rb_.resolve('resolveTag', this.resolveTag);    
                idxPrevRef = t4rbPrev.sessionData.epoch(end);
                this.t4rb_ = this.t4rb_.t4img_4dfp( ...
                    fullfile(pwd0, sprintf('%sr0_frame%i_to_%s_t4', this.t4rb_.sessionData.tracerEpoch('typ','fp'), idxPrevRef, this.resolveTag)), ...
                    fullfile(pwd0, this.product_.fileprefix), ...
                    'out', this.umapShort(this.resolveTag));
                    % t4 := fdgv1e1to9r2_frame9_to_op_fdgv1e1to9r1_frame[1-9]
                    % source := umapSynth_op_T1001_b40r2_op_fdgv1e1to9r1_frame9
                    % out := umapSynth_op_fdgv1e1to9r1_frame[1-9]
                    
                this.sessionData_ = this.t4rb_.sessionData;                                                          
                this.product_ = this.t4rb_.product;
                popd(pwd0);
            end
        end
        function this = backProjectUmapToFrames(this)
            %% BACKPROJECTUMAPTOFRAMES uses previously split and motion-corrected monolithic image with 
            %  hierarchically partitioned epochs.  The internally specified umap is back-projected onto the hierarchy.
            %  @return single back-projected umap.
            %  @return multiple, internally stored back-projections and a single back-projection onto the 
            %  the motion-correction of the summed images from descendent branches of the partitioning hierarchy tree.  
            
            % first manage leaf
            this = this.backProjectUmapToEpochs;
            
            if (~isempty(this.aComposite_))
                for e = 1:length(this.aComposite_)                    
                    fdgbE = this.aComposite_{e};                      
                    this.aComposite_{e} = fdgbE.backProjectUmapToFrames;                    
                end
                this = this.reconstituteComposites;
                return
            end
        end
        function this = backProjectToEpochs(this)
            %% BACKPROJECTTOEPOCHS back-resolves a single epoch with one or more frames at a time.
            
            sz  = this.buildVisitor.ifhMatrixSize([this.product_.fqfileprefix '.4dfp.ifh']);
            if (length(sz) < 4)
                sz(4) = 1;
            end
            for idxOfRef = 1:sz(4)
                
                % resolve umapSynth to idxOfRef   
                pwd0 = pushd(this.product_.filepath);  
                t4rbPrev = this.t4rb_;   
                this.sessionData = t4rbPrev.sessionData;
                this.sessionData.rnumber = 1;       
                this.resolveTag = '';
                this.resolveTag = this.sessionData.resolveTagFrame(idxOfRef);
                %assert(strcmp(this.resolveTag, ...
                %       sprintf('op_fdgv1e%ir1_frame%i', this.aComposite_{idxOfRef}.epoch, idxOfRef)));
                
                this.t4rb_ = mlfourdfp.T4ResolveBuilder( ...
                    'sessionData', this.sessionData, ...
                    'theImages', t4rbPrev.theImages, ...
                    'indexOfReference', idxOfRef, ...
                    'NRevisions', 2);
                this.t4rb_ = this.t4rb_.resolve('resolveTag', this.resolveTag);                
                this.t4rb_ = this.t4rb_.t4img_4dfp( ...
                    fullfile(pwd0, sprintf('%sr0_frame%i_to_%s_t4', this.t4rb_.tracerEpoch('typ','fp'), idxOfRef, this.t4rb_.resolveTag)), ...
                    fullfile(pwd0, this.product_.fileprefix), ...
                    'out', this.umapShort(this.t4rb_.resolveTag));
                    % t4 := fdgv1e1to9r2_frame9_to_op_fdgv1e1to9r1_frame[1-9]
                    % source := umapSynth_op_T1001_b40r2_op_fdgv1e1to9r1_frame9
                    % out := umapSynth_op_fdgv1e1to9r1_frame[1-9]
                    
                this.sessionData_ = this.t4rb_.sessionData;                                                          
                this.product_ = this.t4rb_.product;
                popd(pwd0);
            end
        end
        function this = backProjectToFrames(this)
            %% BACKPROJECTTOFRAMES uses self-similar epochs, hierarchically organized data and filesystems
            %  for scalable organization.
            
            if (~isempty(this.aComposite_))
                for e = 1:length(this.aComposite_)                    
                    fdgbE = this.aComposite_{e};                      
                    this.aComposite_{e} = fdgbE.backProjectToFrames;                    
                 end
                this = this.reconstituteComposites;
                this = this.backProjectToEpochs;
                return
            end
            
            % continue with leaf
            this.product_ = mlfourdfp.ImagingContext(this.umapShort(this.resolveTag));
            this = this.backProjectToEpochs;
        end
        function this = sumProduct(this)
            assert(isa(this.product_, 'mlfourd.ImagingContext'))
            if (this.buildVisitor.lexist_4dfp([this.product_.fqfp '_sumt']))
                return
            end
            this.product_ = this.product_.timeSummed;
            this.product_.fourdfp;
            this.product_.save; % _sumt
        end
        function this = buildFdgAC(this)
            
            import mlsystem.* mlfourdfp.*;
            sessd = this.sessionData;
            Fdg = sprintf('FDG_V%i', sessd.vnumber);
            pthFdgAC = fullfile(sessd.vLocation, [Fdg '-AC'], '');     
            if (isdir(pthFdgAC))
                movefile(pthFdgAC, [pthFdgAC '-Backup-' datestr(now, 30)]);
            end
            ensuredir(pthFdgAC);
            
            firstFortranFrame_ = 1;
            fdgACRevision = sessd.fdgACRevision('typ', 'fp');
            fdgLMPrefix = sprintf('FDG_%s-LM-00-OP', sessd.vLocation('typ','folder'));
            bv = this.buildVisitor;
            eFrame = DirTool(fullfile(sessd.vLocation, sprintf('%s-Converted-Frame*', Fdg), ''));
            for iFrame = 1:length(eFrame.fqdns)
                try
                    pwd0 = pushd(eFrame.fqdns{iFrame});
                    fortranFrame = this.frameNumber(eFrame.dns{iFrame}, 1);
                    fdgFramename = this.frameFileprefix(fdgACRevision, fortranFrame);
                    bv.sif_4dfp(fdgLMPrefix);
                    fdgT4 = sprintf('%s_frame%i_to_resolved_t4', ...
                        sessd.fdgNACRevision('typ', 'fp'), fortranFrame);
                    sessdNac = sessd;
                    sessdNac.attenuationCorrected = false;
                    fqFdgT4 = fullfile(sessdNac.fdgT4Location, fdgT4);
                    bv.cropfrac_4dfp(0.5, fdgLMPrefix, fdgACRevision);
                    if (fortranFrame >= firstFortranFrame_ && lexist(fqFdgT4, 'file'))
                        bv.lns(fqFdgT4);
                        bv.t4img_4dfp(fdgT4, fdgACRevision, 'options', ['-O' fdgACRevision]);
                        bv.move_4dfp([fdgACRevision '_on_resolved'], ...
                            fullfile(pthFdgAC, [fdgFramename '_on_resolved']));
                    else
                        bv.move_4dfp(fdgACRevision, ...
                            fullfile(pthFdgAC, [fdgFramename '_on_resolved']));
                    end
                    delete('*.4dfp.*')
                    delete([fdgACRevision '_frame*_to_resolved_t4']);
                    popd(pwd0);
                catch ME
                    handwarning(ME);
                end
            end
            pwd1 = pushd(fullfile(pthFdgAC, ''));
            ipr.dest = fdgACRevision;
            ipr.frames = ones(1, length(eFrame.fqdns));
            this.pasteFrames(ipr, 'on_resolved');
            bv.imgblur_4dfp([fdgACRevision '_on_resolved'], 5.5);
            delete(fullfile(pthFdgAC, [fdgACRevision '_frame*_on_resolved.4dfp.*']));
            popd(pwd1);
        end
        function        printSessionData(this)
            mlraichle.FdgBuilder.printv('FdgBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
        function this = reconstituteEarlyFrames(this, varargin)
            ip = inputParser;
            addParameter(ip, 'rnumberLast', 1, @isnumeric);
            parse(ip, varargin{:});            
            sessd0 = this.sessionData;
            sessd0.rnumber = ip.Results.rnumberLast;
            pwd0 = pushd(sessd0.tracerLocation);
            
            import mlfourd.*;
            mlfourdfp.FourdfpVisitor.backupn( ...
                                 sessd0.tracerResolved('typ', 'fqfp'), 1);
            niiRevision = NIfTId(sessd0.tracerRevision('typ', 'fqfn'));
            niiResolved = NIfTId(sessd0.tracerResolved('typ', 'fqfn')); 
            NtEarly     = niiRevision.size(4) - niiResolved.size(4);
            img1        = niiRevision.img;
            img1(:,:,:,NtEarly+1:end) = niiResolved.img;
            nii1        = niiResolved.clone;
            nii1.img    = img1;
            nii1.noclobber = false;
            nii1.saveas(this.sessionData.tracerResolved('typ', '4dfp.ifh'));
            delete('*.nii.gz', '*.nii');
            popd(pwd0);
        end
        function this = redoT4ResolveAndPaste(this)
            ipr = struct('dest', '', 'indicesLogical', [], 'rnumber', []);
            ipr.dest = this.sessionData.fdgNACRevision('typ','fp');
            ipr.indicesLogical = [false(1,12) true(1,60)];
            ipr.rnumber = 1;
            this.resolveLog =  ...
                loggerFilename(ipr.dest, 'func', 'redoT4ResolveAndPaste', 'path', this.logPath);                
                
            dt = mlsystem.DirTool(fullfile(this.t4Path, '*_t4'));
            if (~isempty(dt.fqdns))
                movefile(fullfile(this.t4Path, '*'));
            end
            this.lazyStageImages(ipr);
            this.resolveAndPaste(ipr);
            this.teardownLogs;
            this.teardownT4s;
            this.teardownResolve;
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
        ct4rb_
        t4rb_
    end
    
    methods (Access = protected)
        function this = inspectMonolith(this)
            %% INSPECTMONOLITH for need to split monolithic image object and partition image data into
            %  FdgBuilder objects in this.aComposite_.
            %  @return without mutations if rank(monolith) < 4.
            %  @return with monolith partititioned into epochs stored internally as hierarchically ordered 
            %  FdgBuilder objects with each length(partition) <= this.MAX_MONOLITH_LENGTH.  Save epochs as
            %  needed.
            
            sz = this.buildVisitor.ifhMatrixSize(this.sessionData.tracerRevision('typ', '4dfp.ifh'));
            if (length(sz) < 4 || 1 == sz(4))
                return
            end
            
            if (sz(4) > this.MAX_MONOLITH_LENGTH)
                Nepochs = ceil(sz(4)/this.MAX_MONOLITH_LENGTH);
                this.aComposite_ = cell(1, Nepochs);
                for e = 1:Nepochs
                    sessd = this.sessionData;
                    sessd.epoch = e;
                    if (~this.buildVisitor.lexist_4dfp(sessd.tracerRevision('typ','fqfp')))
                        ic   = mlfourd.ImagingContext();
                        this = this.saveEpoch(ic.fourdfp, sessd);
                    end
                    this.aComposite_{e} = mlraichle.FdgBuilder( ...
                        'sessionData', sessd, ...
                        'buildVisitor', this.buildVisitor, ...
                        'roisBuild', this.roisBuilder, ...
                        'framesResolveBuild', this.framesResolveBuilder, ...
                        'compositeResolveBuild', this.compositeResolveBuilder, ...
                        'vendorSupport', this.vendorSupport_);
                end
            end
        end
        function this = saveEpoch(this, ffp, sessd)
            %% SAVEEPOCH
            %  @param ffp is an mlfourd.INIfTI with frames specified by this.splitTimes.  ffp is saved to filesystem.
            %  @param sessd is an mlpipeline.SessionData containing frames/epoch informations.
            %  @return after saving ffp partitioned by specified frames/epoch.
            
            this.activeFrames = this.splitTimes(sessd.epoch, ffp.size);
            ffp.img = ffp.img(:,:,:,this.activeFrames);
            ffp.fqfileprefix = sessd.tracerRevision('typ', 'fqfp');
            ffp.save;
        end
        function times = splitTimes(this, epoch, sz)
            %% SPLITTIMES 
            %  @param epoch := sz(4)/this.MAX_MONOLITH_LENGTH is a scalar.
            %  @param sz is the size of an image object with rank > 3.
            %  @return array of frames numbers appropriate for partition epoch chosen from image with size sz.  
            
            assert(isscalar(epoch));
            assert(length(sz) > 3);
            L = floor(sz(4)/this.MAX_MONOLITH_LENGTH);
            if (epoch*L > sz(4))
                times = (epoch-1)*L+1:sz(4);
                return
            else
                times = (epoch-1)*L+1:epoch*L;
            end
        end
        function this = reconstituteComposites(this)
            import mlfourd.*;
            fdgb = this.aComposite_{1}; % fdgb.product =: fdgv1e1r2_op_fdgv1e1r1_frame8_sumt
            ffp  = ImagingContext(fdgb.sessionData.tracerResolvedSumt('typ','4dfp.ifh')); % ffp := fdgb.product
            ffp  = ffp.fourdfp;
            if (~fdgb.isfinished)
                assert(3 == ffp.rank);            
            end
            for e = 2:length(this.aComposite_)
                fdgb = this.aComposite_{e};
                if (~fdgb.isfinished)
                    if (this.buildVisitor.lexist_4dfp( ...
                            fdgb.sessionData.tracerResolvedSumt('typ','4dfp.ifh')))
                        ffp_ = ImagingContext(fdgb.sessionData.tracerResolvedSumt('typ','4dfp.ifh'));
                        % fdgv1e*r2_sumt
                    elseif (this.buildVisitor.lexist_4dfp( ...
                            fdgb.sessionData.tracerRevision('typ','4dfp.ifh')))
                        ffp_ = ImagingContext(fdgb.sessionData.tracerRevision('typ','4dfp.ifh'));
                        % fdgv1e*r2
                    else
                        error('mlraichle:filesystemErr', ...
                            'FdgBuilder.reconstituteComposites could not find %s', ffp_.fqfn);
                    end
                    ffp_ = ffp_.fourdfp;
                    assert(3 == ffp_.rank);
                    ffp.img(:,:,:,e) = ffp_.img;
                end
            end            
            if (~fdgb.isfinished)
                this.activeFrames = 1:length(this.aComposite_);
                this.sessionData.epoch = this.activeFrames;
                fdgb.sessionData.epoch = this.sessionData.epoch;
                ffp.fqfilename = fdgb.sessionData.tracerRevision; % E1to9/fdgv1e1to9r1
                if (lexist(ffp.fqfilename, 'file'))
                    warning('mlraichle:IOWarn:overwritingExistingFile', ...
                            'FdgBuilder.reconstituteComposites is overwriting %s', ffp.fqfilename);
                end
                ffp.save;
                this.product_ = mlpet.PETImagingContext(ffp);
            end
        end
        function tf   = isfinished(this)
            tf1 = false;
            if (~isempty(this.t4rb_))
                tf1 = this.t4rb_.isfinished;
            end
            tf2 = false;
            if (~isempty(this.ct4rb_))
                tf2 = this.ct4rb_.isfinished;
            end
            tf = tf1 && tf2;
        end
        function fqfp = umapShort(this, tag)
            fqfp = fullfile(this.product_.filepath, sprintf('umapSynth_%s', tag));
%             if (~this.buildVisitor.lexist_4dfp(fqfp))
%                 fqfp = this.sessionData.umapSynth('tracer', '', 'typ', 'fqfp');
%             end
%             assert(this.buildVisitor.lexist_4dfp(fqfp));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

