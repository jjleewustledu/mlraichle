classdef FdgBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% FDGBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    properties 
        framesPartitions
        partitionBoundaries
    end
    
    methods (Static)
        function assembleFdgAfterAC
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
            addParameter(ip, 'indicesLogical', ones(1,6), @isnumeric);
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
		  
 		function this = FdgBuilder(varargin)
 			%% FdgBuilder
 			%  Usage:  this = FdgBuilder()

 			this = this@mlfourdfp.AbstractTracerResolveBuilder(varargin{:});
            this.sessionData.tracer = 'FDG';            
            this.finished = mlpipeline.Finished(this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
        
        function this = buildNACimageComposite(this)
            this.mmrResolveBuilder_.sif;
            this.mmrResolveBuilder_.cropfrac;
            this.resolvePartitions;
            this.assemblePartitions;
        end
        function this = motionCorrectNACimageComposite(this)
        end
        function this = buildCarneyUmap(this)
        end
        function this = motionCorrectUmaps(this)
        end
        function this = buildACimageComposite(this)
        end
        function this = motionCorrectACimageComposite(this)
        end
        function this = assembleFdg(this)
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
            ipr.indicesLogical = [zeros(1,12) ones(1,60)];
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
        
        function parts = resolvePartitions(this)
                       
            lenParts = 8;
            Nparts = floor(this.imageComposite.length/lenParts);
            parts = cell(1, Nparts);
            
            parts{1} = this.imageComposite;
            parts{1}.indicesLogical = this.indicesInterval(1, lenParts);
            parts{1}.indexOfReference = lenParts;
            this.imageComposite = parts{1};
            this = this.resolvePartition( ...
                'resolveTag', sprintf('frames%i-%i_op_frame%i', 1, lenParts, parts{1}.indexOfReference));
            
            for p = 2:Nparts
                q = (p - 1)*lenParts + 1;
                parts{p} = this.imageComposite;
                parts{p}.indicesLogical = this.indicesInterval(q, q+lenParts-1);
                parts{p}.indexOfReference = q;
                this.imageComposite = parts{p};
                if (Nparts == p)
                    this.keepForensics = false;
                end
                this = this.resolvePartition( ...
                    'resolveTag', sprintf('frames%i-%i_op_frame%i', q, q+lenParts-1, parts{p}.indexOfReference));
            end
        end
        function this  = resolvePartition(this, varargin)
            this.mmrResolveBuilder_.ensureTracerLocation;
            this.mmrResolveBuilder_.ensureTracerSymlinks;
            
            sessd  = this.sessionData;
            sessd0 = this.sessionData;
            sessd0.rnumber = sessd.rnumber - 1;
            pwd_ = pushd(sessd.tracerLocation);
            this.printv('FdgBuilder.resolveRevision.pwd -> %s\n', pwd);
            this = this.resolve( ...
                'dest',      sessd.tracerRevision('typ', 'fp'), ... 
                'source',    sessd0.tracerResolved('typ', 'fp'), ...
                'indicesLogical', this.indicesLogical, ...
                varargin{:});
            popd(pwd_);
        end       
        function fqfp  = assemblePartitions(this, varargin)
            import mlfourd.*;
            parts = cell(size(varargin));
            part1 = NumericalNIfTId.load( ...
                this.sessionData.tracerPartition('typ', '4dfp.ifh', 'partition', varargin{1}));
            for p = 2:length(parts)
                parts{p} = NumericalNIfTId.load( ...
                    this.sessionData.tracerPartition('typ', '4dfp.ifh', 'partition', varargin{p}));
                part1.img = [part1.img parts{p}.img];
            end
            part1.fqfp = this.sessionData.tracerAssembled('typ', 'fqfp');
            fqfp = part.fqfp;
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function fr = firstFortranTimeFrame(this)
            NNativeFrames = this.imageComposite.readLength(this.sessionData.tracerRevision('typ', 'fqfp'));
            NUmapFrames   = this.imageComposite.readLength(this.sessionData.tracerResolved('typ', 'fqfp'));
            fr = NNativeFrames - NUmapFrames + 1;
        end
        function ii = indicesInterval(this, first, last)
            ii = false(1, this.imageComposite.length);
            for i = first:last
                ii(i) = true;
            end
        end
    end
        

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

