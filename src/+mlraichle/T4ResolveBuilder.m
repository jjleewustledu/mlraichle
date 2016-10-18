classdef T4ResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 18-Apr-2016 19:22:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	
        
    properties (Constant)
        cluster = 'dtn01.chpc.wustl.edu'
        clusterSubjectsDir = '/scratch/jjlee/raichle/PPGdata/jjlee'
        MinFrames = 64
    end
    
	properties
        Nframes = 72
        recoverNACFolder = false 
    end

    methods (Static)
        function s     = hello()
            s = cell(7,2);
            parfor j = 1:7
                for k = 1:2
                    s{j,k} = sprintf('hello world!  This is mlraichle.T4ResolveBuilder.hello: %i %i!\n', j, k);
                end
            end
        end
        function these = parTriggeringOnConvertedNAC(varargin)

            studyd = mlraichle.StudyDataSingleton.instance('initialize');

            ip = inputParser;
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'iVisit', 1, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            if (~strcmp(ip.Results.subjectsDir, studyd.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end
            iVisit = ip.Results.iVisit;
            tag    = ip.Results.tag;

            import mlsystem.* mlraichle.*;
            eSess = DirTool(ip.Results.subjectsDir);
            eSessFqdns = eSess.fqdns;
            fprintf('mlraichle.T4ResolveBuilder.parTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
            these = cell(length(eSessFqdns), 2);
            parfor iSess = 1:length(eSessFqdns)

                eVisit = DirTool(eSessFqdns{iSess});
                assert(iVisit <= length(eVisit.fqdns));
                if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))

                    eTracer = DirTool(eVisit.fqdns{iVisit});
                    for iTracer = 1:length(eTracer.fqdns)

                        pth = eTracer.fqdns{iTracer};
                        these{iSess,iVisit} = [pth ' was skipped'];
                        if ( T4ResolveBuilder.isTracer(pth) && ...
                             T4ResolveBuilder.isConvertedC(pth) && ...
                            ~T4ResolveBuilder.hasNACFolder(pth) && ...
                             T4ResolveBuilder.hasOP(pth, T4ResolveBuilder.MinFrames) && ...
                             T4ResolveBuilder.matchesTag(eSessFqdns{iSess}, tag)) %% && ~T4ResolveBuilder.isEmpty(pth)

                            try
                                sessd = SessionData( ...
                                    'studyData',   studyd, ...
                                    'sessionPath', eSessFqdns{iSess}, ...
                                    'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                    'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                    'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                this = T4ResolveBuilder('sessionData', sessd);
                                this = this.excludeFrames(1); 
                                this = this.t4ResolveConvertedNAC;   
                                these{iSess,iVisit} = this;
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end          
            end
        end
        function this  = runSingleOnConvertedNAC(varargin)
            
            studyd = mlraichle.StudyDataSingleton.instance;

            ip = inputParser;
            addParameter(ip, 'NRevisions', 2, @isnumeric);
            addParameter(ip, 'studyData', studyd, @(x) isa(x, 'mlpipeline.StudyDataSingleton'));
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'sessionFolder', '', @(x) ischar(x) && ~isempty(x));
            addParameter(ip, 'visitFolder', '', @(x) ischar(x) && ~isempty(x));
            addParameter(ip, 'tracerFolder', '', @(x) ischar(x) && ~isempty(x)); 
            addParameter(ip, 'frames', [], @isnumeric);
            parse(ip, varargin{:});
            studyd = ip.Results.studyData;
            if (~strcmp(studyd.subjectsDir, ip.Results.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end

            import mlraichle.*;
            pth = fullfile(ip.Results.subjectsDir, ip.Results.sessionFolder, ip.Results.visitFolder, ip.Results.tracerFolder);
            %mlraichle.T4ResolveBuilder.revertToLM00(pth);
            this = [pth ' was skipped'];
            if ( T4ResolveBuilder.isVisit(pth) && ...
                 T4ResolveBuilder.isTracer(pth) && ...
                 T4ResolveBuilder.isNAC(pth))
             % && ~T4ResolveBuilder.hasNACFolder(pth)) 
             % && T4ResolveBuilder.hasOP(pth, length(ip.Results.frames))) 
             % && ~T4ResolveBuilder.isEmpty(pth)
                try
                    cd(pth);
                    sessd = SessionData( ...
                        'studyData',   studyd, ...
                        'sessionPath', fullfile(ip.Results.subjectsDir, ip.Results.sessionFolder), ...
                        'snumber',     T4ResolveBuilder.scanNumber(     ip.Results.tracerFolder), ...
                        'tracer',      T4ResolveBuilder.tracerPrefix(   ip.Results.tracerFolder), ...
                        'vnumber',     T4ResolveBuilder.visitNumber(    ip.Results.visitFolder));
                    this = T4ResolveBuilder('sessionData', sessd, 'frames', ip.Results.frames, 'NRevisions', ip.Results.NRevisions);
                    this = this.t4ResolveConvertedNAC;
                catch ME
                    handwarning(ME);
                end
            end            
        end
        function this  = triggeringOnConvertedNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('t4ResolveConvertedNAC', varargin{:});          
        end
        function this  = triggeringStagingForNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('locallyStageFdg', varargin{:});                      
        end
        
        function tf = hasNACFolder(pth)
            visitPth = fileparts(pth);
            [~,visit] = fileparts(visitPth);
            tf = isdir(fullfile(visitPth, ['FDG_' visit '-NAC'], ''));
        end
        function tf = hasOP(pth, lastFrame)
            lastFrame = lastFrame - 1; % Siemens tags frames starting with 09
            visitPth = fileparts(pth);
            [~,visit] = fileparts(visitPth);
            tf = lexist(fullfile(visitPth, ...
                                 ['FDG_' visit '-Converted'],...
                                 ['FDG_' visit '-LM-00'], ...
                                 sprintf('FDG_%s-LM-00-OP_%03i_000.v', visit, lastFrame)), 'file');
        end
        function tf = isConverted(pth)
            [~,fldr] = fileparts(pth);
            tf = ~isempty(regexp(fldr, '-Converted', 'once'));
        end
        function tf = isEmpty(pth)
            dt = mlsystem.DirTool(pth);
            tf = isempty(dt.dns) && isempty(dt.fqfns);
        end
        function tf = isNAC(pth)
            [~,fldr] = fileparts(pth);
            tf = ~isempty(regexp(fldr, '-NAC', 'once'));
        end
        function tf = isVisit(fldr)
            tf = ~isempty(regexp(fldr, 'V[0-9]', 'once'));
        end
        function tf = isTracer(varargin)
            ip = inputParser;
            addRequired(ip, 'path', @isdir);
            addOptional(ip, 'tracers', 'FDG', @ischar);
            parse(ip, varargin{:});
            
            import mlraichle.*;
            [~,fldr] = fileparts(ip.Results.path);
            tf = lstrfind(fldr, ip.Results.tracers);
        end
        function tf = matchesTag(sess, tag)
            assert(ischar(sess));
            assert(ischar(tag));
            
            if (isempty(tag))
                tf = true;
                return
            end
            tf = lstrfind(sess, tag);
        end      
        function revertToLM00(nacPth)
            if (~isdir(nacPth))
                return
            end
            vPth = fileparts(nacPth);
            [~,vFold] = fileparts(vPth);
            tracerFold = ['FDG_' vFold];
            lm00Pth = fullfile(vPth, [tracerFold '-Converted'], [tracerFold '-LM-00'], '');
            if (lexist(fullfile(nacPth, ['fdg' lower(vFold) 'r2_resolved.4dfp.img'])))
                return
            end
            if (~isdir(lm00Pth))
                movefile(nacPth, lm00Pth);
            end
        end  
        function scp(sessFold, visit, files)
            assert(ischar(sessFold));
            if (isnumeric(visit))
                visit = sprintf('V%i', visit);
            end
            if (~iscell(files))
                files = {files};
            end
            
            import mlraichle.*;
            for f = 1:length(files)                
                try
                    [~,r] = mlbash(sprintf('scp -qr %s %s:%s', ...
                        fullfile(getenv('PPG'), 'jjlee', sessFold, visit, files{f}), ...
                        T4ResolveBuilder.cluster, ...
                        fullfile(T4ResolveBuilder.clusterSubjectsDir, sessFold, visit, '')));
                    fprintf('mlraichle.T4ResolveBuilder.scp:  %s\n', r);
                catch ME
                    handwarning(ME);
                end
            end
        end
        function scp_2016oct16
            import mlraichle.*;
            T4ResolveBuilder.scp('HYGLY25', 1, 'FDG*NAC');
            %T4ResolveBuilder.scp('HYGLY25', 1, 'mpr.4dfp.*');
            T4ResolveBuilder.scp('HYGLY25', 1, '*t4');
        end
        function s  = scanNumber(fldr)
            idx = regexp(fldr, 'FDG|HO|OO|OC', 'end');
            s = str2double(fldr(idx+1));
        end
        function t  = tracerPrefix(varargin)
            ip = inputParser;
            addRequired( ip, 'folder', @ischar);
            addOptional( ip, 'tracers', {'FDG' 'HO' 'OO' 'OC'}, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'prefixRegexp', 'FDG|HO|OO|OC', @ischar);
            parse(ip, varargin{:});
            
            import mlraichle.*;
            t = 'unknownTracer';
            if (lstrfind(ip.Results.folder, ip.Results.tracers))
                idx = regexp(ip.Results.folder, ip.Results.prefixRegexp, 'end');
                t = ip.Results.folder(1:idx);
            end
        end
        function v  = visitNumber(str)
            v = str2double(str(2:end));            
        end
        
        function this = runRaichle(sessPth, v, s)
            studyd = mlpipeline.StudyDataSingletons.instance('raichle');
            sessd = mlraichle.SessionData( ...
                'studyData', studyd, ...
                'sessionPath', sessPth, ...
                'vnumber', v, ...
                'snumber', s);
            this = mlraichle.T4ResolveBuilder('sessionData', sessd);            
            cd(this.sessionData.fdgNAC);
            if (~lexist(this.sessionData.fdgNAC('typ', 'mhdr'), 'file'))
                this.buildVisitor.sif_4dfp([this.sessionData.fdgNAC('typ', 'fqfp') '.mhdr']);
            end
            this = this.t4ResolvePET3;
        end
        function this = testCompiler
            studyd = mlpipeline.StudyDataSingletons.instance('raichle');            
            sessd = mlraichle.SessionData( ...
                'studyData', studyd, ...
                'sessionPath', fullfile(studyd.subjectsDir, 'HYGLY24', ''));            
            this = mlraichle.T4ResolveBuilder('sessionData', sessd);
            cd(fullfile(sessd.sessionPath, 'V1', ''));
            this = this.t4ResolvePET3;
        end
    end
    
	methods
        function this = buildFdgNAC(this)
            %% BUILD4DFP builds 4dfp formatted fdg NAC images; use to prep data before conveying to clusters.
            
            ori = this.sessionData.fdgLMFrame(this.Nframes-1, 'typ', 'fqfn');
            lm  = this.sessionData.fdgLM( 'typ', 'fqfp');
            nac = this.sessionData.fdgNAC('typ', 'fqfp');
            
            if (this.buildVisitor.lexist_4dfp(nac))
                return
            end
            if (~this.buildVisitor.lexist_4dfp(ori))
                error('mlfourdfp:processingStreamFailure', 'T4ResolveBuilder.buildFdgNAC could not find %s', ori);
            end
            if (~this.buildVisitor.lexist_4dfp(lm))
                fprintf('mlraichle.T4ResolveBuilder.buildFdgNAC:  building %s\n', lm);
                cd(fileparts(lm));
                this.buildVisitor.sif_4dfp(lm);
            end
            assert(isdir(this.sessionData.fdgNACLocation));
            movefile([lm '.4dfp.*'], this.sessionData.fdgNACLocation);
        end
        function this = excludeFrames(this, toExclude)
            if (isempty(toExclude))
                return
            end
            
            this.frames_ = this.frames; % read Nframes from data
            for ie = 1:length(toExclude)
                this.frames_(toExclude(ie)) = 0;
            end
        end
        function        ensureFdgSymlinks(this)
            sessd = this.sessionData;
            mprAtlT4 = [sessd.mpr('typ', 'fp') '_to_' sessd.atlas('typ', 'fp') '_t4'];
            fqMprAtlT4 = fullfile(sessd.mpr('typ', 'path'), mprAtlT4);
            
            assert(lexist(fqMprAtlT4, 'file'));
            assert(this.buildVisitor.lexist_4dfp(sessd.mpr('typ', 'fqfp')));
            assert(this.buildVisitor.lexist_4dfp(sessd.ct( 'typ', 'fqfp')));
            assert(isdir(sessd.fdgNACLocation));
            
            cd(sessd.fdgNACLocation);
            if (~lexist(mprAtlT4))
                this.buildVisitor.lns(fqMprAtlT4);
            end
            if (~lexist(sessd.mpr('typ', 'fn')))
                this.buildVisitor.lns_4dfp(sessd.mpr('typ', 'fqfp'));
            end
            if (~lexist(sessd.ct('typ', 'fn')))
                this.buildVisitor.lns_4dfp(sessd.ct('typ', 'fqfp'));
            end
        end
        function this = locallyStageFdg(this)
            this.prepareFdgNACLocation;         
            this.buildFdgNAC;
            this.prepareMR;
            this.scpFdg;
        end
        function        prepareFdgNACLocation(this)
            %% PREPAREFDGNACLOCATION recovers the NAC location from backup or creates it de novo.
            
            if (this.recoverNACFolder)
                movefile([this.sessionData.fdgNACLocation '-Backup'], this.sessionData.fdgNACLocation);
                return
            end            
            if (~isdir(this.sessionData.fdgNACLocation))
                mkdir(this.sessionData.fdgNACLocation);
            end            
        end
        function        prepareMR(this)
            %% PREPAREMR runs msktgenMprage as needed for use by resolve.
            
            sessd      = this.sessionData;
            mpr        = sessd.mprage('typ', 'fp');
            atl        = sessd.atlas('typ', 'fp');
            mprToAtlT4 = [mpr '_to_' atl '_t4'];            
            if (~lexist(fullfile(sessd.mprage('typ', 'path'), mprToAtlT4)))
                cd(sessd.mprage('typ', 'path'));
                this.msktgenMprage(mpr, atl);
            end
        end
        function        scpFdg(this)
            cd(fullfile(this.sessionData.sessionPath));
            lists = {'ct.4dfp.*'};
            for ils = 1:length(lists)
                try
                    mlbash(sprintf('scp -qr %s %s:%s', ...
                        lists{ils}, this.cluster, fullfile(this.clusterSubjectsDir, this.sessionData.sessionFolder, '')));
                catch ME
                    handwarning(ME);
                end
            end
            
            visits = {'V1' 'V2'};
            for iv = 1:length(visits)                
                cd(fullfile(this.sessionData.sessionPath, visits{iv}, ''));
                listv = {'mpr.4dfp.*' '*_t4' 'FDG_*-NAC'};
                for ilv = 1:length(listv)
                    try
                        mlbash(sprintf('scp -qr %s %s:%s', ...
                            listv{ilv}, ...
                            this.cluster, ...
                            fullfile(this.clusterSubjectsDir, this.sessionData.sessionFolder, visits{iv}, '')));
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function this = t4ResolveConvertedNAC(this)
            %% T4RESOLVECONVERTEDNAC is the principle caller of resolve.
            
            cd(this.sessionData.fdgNAC('typ', 'path'));
            this.ensureFdgSymlinks;
            this = this.resolve( ...
                'dest', sprintf('fdgv%i', this.sessionData.vnumber), ...
                'source', this.sessionData.fdgNAC('typ', 'fp'), ...
                'firstCrop', this.firstCrop, ...
                'frames', this.frames);
        end
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
            if (lstrfind(this.sessionData.sessionFolder, 'HYGLY25') && ...
                         this.sessionData.vnumber == 1)
                this.Nframes = 64;
            end
        end
    end
    
    %% PRIVATE
    
    methods (Static, Access = private)        
        function this = triggering(varargin)
            
            studyd = mlraichle.StudyDataSingleton.instance;
            
            ip = inputParser;
            addRequired( ip, 'methodName', @ischar);
            addParameter(ip, 'excludeFrames', 1, @isnumeric);
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            if (~strcmp(ip.Results.subjectsDir, studyd.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end
            
            import mlsystem.* mlraichle.* ;
            eSess = DirTool(ip.Results.subjectsDir);
            for iSess = 1:length(eSess.fqdns)
                
                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                    
                    if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))
                        
                        eTracer = DirTool(eVisit.fqdns{iVisit});
                        for iTracer = 1:length(eTracer.fqdns)

                            pth = eTracer.fqdns{iTracer};
                            if (T4ResolveBuilder.isTracer(pth) && ...
                                T4ResolveBuilder.isConverted(pth) && ...
                               ~T4ResolveBuilder.isEmpty(pth) && ...
                                T4ResolveBuilder.hasOP(pth, length(mlraichle.T4ResolveBuilder.MinFrames)) && ...
                                T4ResolveBuilder.matchesTag(eSess.fqdns{iSess}, ip.Results.tag))
                                try
                                    sessd = SessionData( ...
                                        'studyData',   studyd, ...
                                        'sessionPath', eSess.fqdns{iSess}, ...
                                        'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    this = this.excludeFrames(ip.Results.excludeFrames); 
                                    this.(ip.Results.methodName);   
                                catch ME
                                    handwarning(ME);
                                end
                            end
                        end
                    end
                end                
            end            
        end
    end
    
    %% HIDDEN & DEPRECATED
    
    methods (Hidden)
        function this = t4ResolvePET3(this)

            mprDir  = this.sessionData.vLocation;
            nacDir  = this.sessionData.fdgListmodeLocation;
            workDir = this.sessionData.vLocation;

            cd(this.sessionData.vLocation);
            
            assert(lexist(this.sessionData.mprage('fqfn'), 'file'));
            mpr_ = this.sessionData.mprage('fp');
            if (~lexist([mpr_ '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(this.sessionData.mprage('fp'), this.atlasTag);
            end

            tracer_ = 'fdg';
            tracerdir = fullfile(workDir, sprintf('%s_V%i-Resolved', upper(tracer_), this.sessionData.vnumber));
            if (~isdir(tracerdir))
                mkdir(tracerdir);
            end
            cd(tracerdir);
            fdfp0 = this.sessionData.fdgNAC('typ', 'fp');
            fdfp1 = sprintf('%sv%i', tracer_, this.sessionData.vnumber);
            this.buildVisitor.lns(     fullfile(workDir, [mpr_ '_to_' this.atlasTag '_t4']));
            this.buildVisitor.lns_4dfp(fullfile(mprDir,  mpr_));
            this.buildVisitor.lns_4dfp(fullfile(nacDir, fdfp0));
            this.t4ResolveIterative(fdfp0, fdfp1, mpr_);
        end
        function this = t4ResolvePET2(this)
            subject = 'NP995_09';
            convdir = fullfile(getenv('PPG'), 'converted', subject, '');
            workdir = fullfile(getenv('PPG'), 'jjlee', subject, 'V2', '');
            mpr     = [subject '_mpr'];

            mprImg = [mpr '.4dfp.img'];
            if (~lexist(mprImg, 'file'))
                if (lexist(fullfile(convdir, mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, mpr));
                elseif (lexist(fullfile(workdir, 'V1', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(workdir, 'V1', mpr));
                elseif (lexist(fullfile(workdir, 'V2', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(workdir, 'V2', mpr));
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mprImg);
                end
            end
            if (~lexist([mpr '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(mpr, this.atlasTag);
            end

            tracer = 'fdg';
            for visit = 2:2
                tracerdir = fullfile(workdir, sprintf('%s_v%i', upper(tracer), visit));
                if (~isdir(tracerdir))
                    mkdir(tracerdir);
                end
                cd(tracerdir);
                this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
                this.buildVisitor.lns_4dfp(fullfile(workdir,  mpr));
                fdfp0 = sprintf('%s%s_v%i', subject, tracer, visit);
                this.buildVisitor.lns_4dfp(fullfile(workdir, fdfp0));
                fdfp1 = sprintf('%sv%i', tracer, visit);
                this.t4ResolveIterative(fdfp0, fdfp1, mpr);
            end
        end
        function this = t4ResolvePET(this)

            subject = 'HYGLY09';
            convdir = fullfile(getenv('PPG'), 'converted', subject, 'V1', '');
            nacdir  = fullfile(convdir, '');
            workdir = fullfile(getenv('PPG'), 'jjlee', subject, '');
            mpr     = [subject '_mpr'];

            mprImg = [mpr '.4dfp.img'];
            if (~lexist(mprImg, 'file'))
                if (lexist(fullfile(convdir, mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, mpr));
                elseif (lexist(fullfile(convdir, 'V1', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V1', mpr));
                elseif (lexist(fullfile(convdir, 'V2', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V2', mpr));
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mprImg);
                end
            end
            if (~lexist([mpr '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(mpr, this.atlasTag);
            end

            tracer = 'fdg';
            for visit = 1:1 %2
                tracerdir = fullfile(workdir, sprintf('%s_v%i', upper(tracer), visit));
                cd(tracerdir);
                this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
                this.buildVisitor.lns_4dfp(fullfile(convdir,  mpr));
                this.buildVisitor.lns_4dfp(fullfile(nacdir, sprintf('%s%s_v%i_AC', subject, tracer, visit)));
                fdfp0 = sprintf('%s%s_v%i_AC', subject, tracer, visit);
                fdfp1 = sprintf('%sv%i', tracer, visit);
                this.t4ResolveIterative(fdfp0, fdfp1, mpr);
            end
            
%             tracers = {'ho' 'oo'};
%             for t = 1:1 %length(tracers)
%                 for visit = 1:1 %2
%                     for scan = 2:2
%                         tracerdir = fullfile(workdir, sprintf('%s%i_v%i', upper(tracers{t}), scan, visit));
%                         this.buildVisitor.mkdir(tracerdir);
%                         cd(tracerdir);
%                         this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
%                         this.buildVisitor.lns_4dfp(fullfile(workdir,  mpr));
%                         this.buildVisitor.lns_4dfp(fullfile(nacdir, sprintf('%s%s%i_v%i', subject, tracers{t}, scan, visit)));
%                         fdfp0 = sprintf('%s%s%i_v%i', subject, tracers{t}, scan, visit);
%                         fdfp1 = sprintf('%s%iv%i', tracers{t}, scan, visit);
%                         this.t4ResolveIterative(fdfp0, fdfp1, mpr);
%                     end
%                 end
%             end
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

