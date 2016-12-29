classdef FdgBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% FDGBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		framesToSkip = 3
 	end

    methods (Static)
        function tf = completed(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            this = mlraichle.FdgBuilder('sessionData', sessd);
            tf = lexist(this.completedTouchFile, 'file');
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
                            fv.extract_frame_4dfp(sprintf('resolveSequence%sr2_resolved', v), fr);
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

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
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
        function resolveRNumberAll(varargin)
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
        function sumTimesAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'NFrames', 6, @isnumeric);
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
                            'ac',          false, ...
                            'tracer',      'FDG', ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FdgBuilder('sessionData', sessd);
                        this.sumTimes(sessd.tracerResolved('typ', 'fp'), 'NFrames', ip.Results.NFrames);
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
            maxFrames = this.readSize(sessd0.fdgNACResolved('typ', 'fqfp'));
            this.frames = [zeros(1, this.framesToSkip) ones(1, maxFrames - this.framesToSkip)];
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
        function this = resolve(this)
            if (1 == this.sessionData.rnumber)
                this = this.resolveR1;
                return
            end
            this = this.resolveRNumber;
        end
        function this = resolveOnCluster(this)
            c = parcluster;
            c.batch(@this.resolve, 1, {});
        end
        function printSessionData(this)
            mlraichle.FdgBuilder.printv('FdgBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = resolveR1(this)
            assert(1 == this.sessionData.rnumber);
            this.mkdirTracerLocation;
            this.sifTracer;
            this.ensureTracerSymlinks;
            
            sessd = this.sessionData;
            pwd0 = pushd(sessd.tracerLocation);
            this.printv('FdgBuilder.resolveR1.pwd -> %s\n', pwd);
            this = this.resolve( ...
                'dest',      sessd.tracerRevision('typ', 'fp'), ... 
                'source',    sessd.tracerNative('typ', 'fp'), ...
                'firstCrop', this.firstCrop, ...
                'frames',    this.frames);
            popd(pwd0);
        end
        function this = resolveRNumber(this)
            assert(this.sessionData.rnumber > 1);
            this.mkdirTracerLocation;
            this.ensureTracerSymlinks;
            
            sessd  = this.sessionData;
            sessd0 = this.sessionData;
            sessd0.rnumber = sessd.rnumber - 1;
            pwd0 = pushd(sessd.tracerLocation);
            this.printv('FdgBuilder.resolveRNumber.pwd -> %s\n', pwd);
            this = this.resolve( ...
                'dest',      sessd.tracerRevision('typ', 'fp'), ... 
                'source',    sessd0.tracerRevision('typ', 'fp'), ...
                'firstCrop', 1, ...
                'frames',    this.frames);
            popd(pwd0);
        end
    end
        

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

