classdef T4ResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 18-Apr-2016 19:22:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	
        
	properties 
        recoverNACFolder = false 
    end

    methods (Static)
        function s = hello()
            s = cell(7,2);
            parfor j = 1:7
                for k = 1:2
                    s{j,k} = sprintf('hello world!  This is mlraichle.T4ResolveBuilder.hello: %i %i!\n', j, k);
                end
            end
        end
        function these = parTriggeringOnConvertedNAC(varargin)

            studyd = mlraichle.StudyDataSingleton.instance;

            ip = inputParser;
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'iVisit', 2, @isnumeric);
            parse(ip, varargin{:});
            if (~strcmp(ip.Results.subjectsDir, studyd.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end
            iVisit = ip.Results.iVisit; 

            import mlsystem.* mlraichle.*;
            eSess = DirTool(ip.Results.subjectsDir);
            eSessFqdns = eSess.fqdns;
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
                             T4ResolveBuilder.isNAC(pth) && ...
                            ~T4ResolveBuilder.isEmpty(pth))

                            try
                                sessd = SessionData( ...
                                    'studyData',   studyd, ...
                                    'sessionPath', eSessFqdns{iSess}, ...
                                    'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                    'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                    'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                this = T4ResolveBuilder('sessionData', sessd);
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
        function this = runSingleOnConvertedNAC(varargin)
            
            studyd = mlraichle.StudyDataSingleton.instance;

            ip = inputParser;
            addParameter(ip, 'NRevisions', 2, @isnumeric);
            addParameter(ip, 'studyData', studyd, @(x) isa(x, 'mlpipeline.StudyDataSingleton'));
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'sessionFolder', '', @ischar);
            addParameter(ip, 'visitFolder', '', @ischar);
            addParameter(ip, 'tracerFolder', 'FDG_V1-NAC', @ischar); 
            addParameter(ip, 'frames', [], @isnumeric);
            parse(ip, varargin{:});
            studyd = ip.Results.studyData;
            studyd.subjectsDir = ip.Results.subjectsDir;

            pth = fullfile(ip.Results.subjectsDir, ip.Results.sessionFolder, ip.Results.visitFolder, ip.Results.tracerFolder);
            this = [pth ' was skipped'];
            import mlraichle.*;
            if ( T4ResolveBuilder.isVisit(pth) && ...
                 T4ResolveBuilder.isTracer(pth) && ...
                 T4ResolveBuilder.isNAC(pth) && ...
                ~T4ResolveBuilder.isEmpty(pth))

                try
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
        function this = triggeringOnConvertedNAC(varargin)
            
            studyd = mlraichle.StudyDataSingleton.instance;
            
            ip = inputParser;
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
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
                               ~T4ResolveBuilder.isEmpty(pth))
                                try
                                    sessd = SessionData( ...
                                        'studyData',   studyd, ...
                                        'sessionPath', eSess.fqdns{iSess}, ...
                                        'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    this = this.t4ResolveConvertedNAC;   
                                catch ME
                                    handwarning(ME);
                                end
                            end
                        end
                    end
                end                
            end            
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
        function tf = isTracer(pth)
            import mlraichle.*;
            [~,fldr] = fileparts(pth);
            tf = lstrfind(fldr, StudyDataSingleton.instance.tracerPrefixes);
        end
        function s = scanNumber(fldr)
            idx = regexp(fldr, 'FDG|HO|OO|OC', 'end');
            s = str2double(fldr(idx+1));
        end
        function t = tracerPrefix(fldr)
            import mlraichle.*;
            t = 'unknownTracer';
            if (lstrfind(fldr, StudyDataSingleton.instance.tracerPrefixes))
                idx = regexp(fldr, 'FDG|HO|OO|OC', 'end');
                t = fldr(1:idx);
            end
        end
        function v = visitNumber(str)
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
            cd(this.sessionData.fdgNAC('path'));
            if (~lexist([this.sessionData.fdgNAC('fqfp') '.mhdr'], 'file'))
                this.buildVisitor.sif_4dfp([this.sessionData.fdgNAC('fqfp') '.mhdr']);
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
        function this = arrangeNACFolder(this)
            if (this.recoverNACFolder)
                movefile([this.sessionData.fdgNACLocation('path') '-Backup'], this.sessionData.fdgNACLocation('path'));
            else
                if (isdir(this.sessionData.fdgListmodeLocation('path')))
                    this.safeMovefile(this.sessionData.fdgListmodeLocation('path'), this.sessionData.fdgNACLocation('path'));
                else
                    assert(isdir(this.sessionData.fdgNACLocation('path')));
                end
            end
            if (~lexist(this.sessionData.fdgNAC('fqfn'), 'file'))
                cd(this.sessionData.fdgNAC('path'));
                this.buildVisitor.sif_4dfp(this.sessionData.fdgNAC('fqfp'));
            end
        end
        function this = arrangeMR(this)
            assert(lexist(this.sessionData.mprage('fqfn'), 'file'));
            assert(lexist(this.sessionData.atlas('fqfn'), 'file'));
            mprFp = this.sessionData.mprage('fp');
            atlFp = this.sessionData.atlas('fp');
            mprToAtlT4 = [mprFp '_to_' atlFp '_t4'];
            
            if (~lexist(fullfile(this.sessionData.mprage('path'), mprToAtlT4)))
                cd(this.sessionData.mprage('path'));
                this.msktgenMprage(mprFp, atlFp);
            end

            cd(this.sessionData.fdgNAC('path'));
            this.buildVisitor.lns(fullfile(this.sessionData.vLocation('path'), mprToAtlT4));
            this.buildVisitor.lns_4dfp(this.sessionData.mprage('fqfp'));
        end
        function this = t4ResolveConvertedNAC(this)
            this = this.arrangeNACFolder;
            this = this.arrangeMR;
            
            cd(this.sessionData.fdgNAC('path'));
            this = this.resolve( ...
                'dest', sprintf('fdgv%i', this.sessionData.vnumber), ...
                'source', this.sessionData.fdgNAC('fp'), ...
                'firstCrop', this.firstCrop, ...
                'frames', this.frames);
        end
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
        end
    end
    
    %% HIDDEN & DEPRECATED
    
    methods (Hidden)
        function this = t4ResolvePET3(this)

            mprDir  = this.sessionData.vLocation('path');
            nacDir  = this.sessionData.fdgListmodeLocation('path');
            workDir = this.sessionData.vLocation('path');

            cd(this.sessionData.vLocation('path'));
            
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
            fdfp0 = this.sessionData.fdgNAC('fp');
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

