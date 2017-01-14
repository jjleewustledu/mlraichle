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
                        FdgBuilder.printv('resolveFdg:  try pwd->%s\n', pwd);
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
                        FdgBuilder.printv('resolveFdg:  try pwd->%s\n', pwd);
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
                        FdgBuilder.printv('resolveFdg:  try pwd->%s\n', pwd);
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
            addParameter(ip, 'frames', ones(1,6), @isnumeric);
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
                        FdgBuilder.printv('resolveFdg:  try pwd->%s\n', pwd);
                        sessd = SessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}), ...
                            'tracer',      'FDG', ...
                            'ac',          false, ...
                            'rnumber',     ip.Results.rnumber);
                        this = FdgBuilder('sessionData', sessd);
                        this.sumTimes(sessd.tracerResolved('typ', 'fp'), 'frames', ip.Results.frames);
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
            this.framesToSkip = 12;
            if (isempty(this.frames_))
                sessd0 = this.adjustedSessionData('rnumber', max(1, this.sessionData.rnumber-1));
                maxFrames = this.readLength(sessd0.fdgNACResolved('typ', 'fqfp'));
                this.frames = [zeros(1, this.framesToSkip) ones(1, maxFrames - this.framesToSkip)];
            end
            this.finished = mlpipeline.Finished(this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
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
            ipr = struct('dest', '', 'frames', [], 'rnumber', []);
            ipr.dest = this.sessionData.fdgNACRevision('typ','fp');
            ipr.frames = [zeros(1,12) ones(1,60)];
            ipr.rnumber = 1;
            this.t4ResolveLog =  ...
                loggerFilename(ipr.dest, 'func', 'redoT4ResolveAndPaste', 'path', this.logPath);                
                
            dt = mlsystem.DirTool(fullfile(this.t4Path, '*_t4'));
            if (~isempty(dt.fqdns))
                movefile(fullfile(this.t4Path, '*'));
            end
            this.lazyExtractFrames(ipr);
            this.t4ResolveAndPaste(ipr);
            this.teardownLogs;
            this.teardownT4s;
            this.teardownResolve;
        end
        function this = resolve(this, varargin)
            this = this.resolve@mlfourdfp.T4ResolveBuilder(varargin{:});
        end
        function this = resolveFdg(this, varargin)
            if (1 == this.sessionData.rnumber)
                this = this.resolveRevision1(varargin{:});
                return
            end
            this = this.resolveRevision(varargin{:});
        end
        function this = resolveFdgPartitions(this, varargin)
            this.frames = [];
            Nframes = length(this.frames);
            [nonEmpty,this] = this.nonEmptyFrames;
            for v = 1:length(varargin)
                interval = varargin{v};
                assert(~isempty(interval) && isnumeric(interval));
                frames = zeros(1,Nframes);
                frames(interval(1):interval(end)) = ones(1, length(interval));
                this.frames = frames .* nonEmpty;
                if (1 == v)
                    this.targetFrame = interval(end);
                else
                    this.targetFrame = interval(1);
                end
                if (v == length(varargin))
                    this.keepForensics = false;
                end
                this.resolveTag = sprintf('frames%ito%i_op_frame%i', interval(1), interval(end), this.targetFrame);
                this = this.resolveFdg;
            end
        end        
        function fqfp = assembleFdgPartitions(this, varargin)
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
        function this = resolveOnCluster(this)
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = resolveRevision1(this, varargin)
            assert(1 == this.sessionData.rnumber);
            this.mkdirTracerLocation;
            this.sifTracer;
            this.ensureTracerSymlinks;
            
            sessd = this.sessionData;
            pwd0 = pushd(sessd.tracerLocation);
            this.printv('FdgBuilder.resolveRevision1.pwd -> %s\n', pwd);
            this = this.resolve( ...
                'dest',      sessd.tracerRevision('typ', 'fp'), ... 
                'source',    sessd.tracerNative('typ', 'fp'), ...
                'firstCrop', this.firstCrop, ...
                'frames',    this.frames, ...
                varargin{:});
            popd(pwd0);
        end
        function this = resolveRevision(this, varargin)
            assert(this.sessionData.rnumber > 1);
            %this.mkdirTracerLocation;
            this.ensureTracerSymlinks;
            
            sessd  = this.sessionData;
            sessd0 = this.sessionData;
            sessd0.rnumber = sessd.rnumber - 1;
            pwd0 = pushd(sessd.tracerLocation);
            this.printv('FdgBuilder.resolveRevision.pwd -> %s\n', pwd);
            this = this.resolve( ...
                'dest',      sessd.tracerRevision('typ', 'fp'), ... 
                'source',    sessd0.tracerResolved('typ', 'fp'), ...
                'firstCrop', 1, ...
                'frames',    this.frames, ...
                varargin{:});
            popd(pwd0);
        end
    end
        

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

