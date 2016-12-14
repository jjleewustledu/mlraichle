classdef T4ResolveBuilder < mlfourdfp.MMRResolveBuilder
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
        function tf    = completed(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            this = mlraichle.T4ResolveBuilder('sessionData', sessd);
            tf = lexist(this.completedTouchFile, 'file');
        end
        function s     = hello(N)
            if (~exist('N', 'var'))
                N = 2;
            end
            assert(isnumeric(N));
            s = cell(1,N);
            for j = 1:N
                s{j} = mlraichle.StudyData;
                fprintf('s{%i} -> \n', j);
                disp(s{j});
                fprintf('\n');
            end
        end
        function s     = parHello(N)
            if (~exist('N', 'var'))
                N = 2;
            end
            assert(isnumeric(N));
            s = cell(1,N);
            parfor j = 1:N
                s{j} = mlraichle.StudyData;
                fprintf('s{%i} -> \n', j);
                disp(s{j});
                fprintf('\n');
            end
            save(sprintf('mlraichle_T4ResolveBuilder_parHello_s_%s.mat', datestr(now, 30)), 's');
        end
        function these = parTriggeringOnConvertedNAC(varargin)

            setenv('PRINTV', '1');

            ip = inputParser;
            addParameter(ip, 'iVisit', 1, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            tag    = ip.Results.tag;

             eSess = mlsystem.DirTool('/scratch/jjlee/raichle/PPGdata/jjlee');
             eSessFqdns = eSess.fqdns;
             T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
             these = cell(length(eSessFqdns), 2);
             parfor iSess = 1:length(eSessFqdns)
%                fprintf('iSess->%i, iVisit->%i\n', iSess, iVisit);
%                these{iSess,iVisit} = sprintf('eSessFqdns{iSess}->%s, iVisit->%i, tag ->%s\n', eSessFqdns{iSess}, iVisit, tag);
%            end

                try
                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eVisit = mlsystem.DirTool(eSessFqdns{iSess});
                    if (iVisit <= length(eVisit.fqdns) && isdir(eVisit.fqdns{iVisit}))
                        if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                if (isdir(pth))
                                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                    these{iSess,iVisit} = [pth ' was skipped'];
                                    if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                                         mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                                        ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                                         mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                                         mlraichle.T4ResolveUtilities.matchesTag(eSessFqdns{iSess}, tag))

                                        try
                                            fprintf('pwd->%s\n', pwd);
                                            sessd = SessionData( ...
                                                'studyData',   mlraichle.StudyData, ...
                                                'sessionPath', eSessFqdns{iSess}, ...
                                                'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                                'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                                'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                                            this = T4ResolveBuilder('sessionData', sessd);
                                            this = this.resolveConvertedNAC;   
                                            these{iSess,iVisit} = this;
                                        catch ME
                                            handwarning(ME);
                                        end
                                    end
                                end
                            end

                        end    
                    end
                catch ME
                    handwarning(ME);
                end
            end
            save(sprintf('mlraichle_T4ResolveBuilder_parTriggerOnConvertedNAC_these_%s.mat', datestr(now, 30)), 'these');
        end
        function these = parTriggeringOnConvertedNAC2(varargin)
            
            setenv('PRINTV', '1');
            
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            tag = ip.Results.tag;
            
            cd('/scratch/jjlee/raichle/PPGdata/jjlee');
            eSess = mlsystem.DirTool('/scratch/jjlee/raichle/PPGdata/jjlee');
            eSessFqdns = eSess.fqdns;
            T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
            these = cell(length(eSessFqdns), 2);
            parfor iSess = 1:length(eSessFqdns)
                
                try
                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});
                    
                    import mlraichle.*;
                    eVisit = mlsystem.DirTool(eSessFqdns{iSess});
                    for iVisit = 1:length(eVisit.fqdns)
                        eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                        for iTracer = 1:length(eTracer.fqdns)
                            T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});
                            
                            pth = eTracer.fqdns{iTracer};
                            T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.pth:  %s\n', pth);
                            %these{iSess,iVisit} = [pth ' was skipped'];
                            if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                                 mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                                ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                                 mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                                 mlraichle.T4ResolveUtilities.matchesTag(eSessFqdns{iSess}, tag))
                                
                                try
                                    fprintf('pwd->%s\n', pwd);
                                    sessd = SessionData( ...
                                        'studyData',   mlraichle.StudyData, ...
                                        'sessionPath', eSessFqdns{iSess}, ...
                                        'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    this = this.resolveConvertedNAC; %#ok<NASGU>
                                    %these{iSess,iVisit} = this;
                                catch ME
                                    handwarning(ME);
                                end
                            end
                        end
                    end
                catch ME
                    handwarning(ME);
                end
            end
            save(sprintf('mlraichle_T4ResolveBuilder_parTriggerOnConvertedNAC2_these_%s.mat', datestr(now, 30)), 'these');
        end
        function         serialT4ResolveConvertedNAC(varargin)
            
            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'sessPath',      @isdir);
            addParameter(ip, 'iVisit', 1,     @isnumeric);
            addParameter(ip, 'tracer', 'FDG', @ischar);
            addParameter(ip, 'snumber', [],   @isnumeric);
            parse(ip, varargin{:});
            iVisit  = ip.Results.iVisit;
            tracer  = ip.Results.tracer;
            snumber = ip.Results.snumber;
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialConvertedNAC');
            T4ResolveBuilder.printv('serialConvertedNAC.ip.Results.sessPath->%s\n', ip.Results.sessPath);

            import mlraichle.*;
            eVisit = mlsystem.DirTool(ip.Results.sessPath);              
            if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialConvertedNAC.pth:  %s\n', pth);
                    if ( T4ResolveUtilities.isTracer(pth, tracer) && ...
                         T4ResolveUtilities.isNAC(pth) && ...
                        ~T4ResolveUtilities.isEmpty(pth) && ...
                         T4ResolveUtilities.hasOP(pth))

                        try
                            T4ResolveBuilder.printv('serialConvertedNAC:  inner try pwd->%s\n', pwd);
                            if (isempty(snumber))
                                snumber = T4ResolveUtilities.scanNumber(eTracer.dns{iTracer});
                            end
                            sessd = SessionData( ...
                                'studyData',   StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     snumber, ...
                                'tracer',      tracer, ...
                                'vnumber',     iVisit);
                            this = T4ResolveBuilder('sessionData', sessd);
                            this = this.resolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function         serialT4ResolveConvertedNAC2(varargin)
            
            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'sessPath', @isdir);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialConvertedNAC2');
            T4ResolveBuilder.printv('serialConvertedNAC2.ip.Results.sessPath->%s\n', ip.Results.sessPath);

            import mlraichle.*;
            eVisit = mlsystem.DirTool(ip.Results.sessPath);
            for iVisit = 1:length(eVisit.fqdns)
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialConvertedNAC2.pth:  %s\n', pth);
                    if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                         mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                        ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                         mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                         mlraichle.T4ResolveUtilities.matchesTag(ip.Results.sessPath, ip.Results.tag))

                        try
                            T4ResolveBuilder.printv('serialConvertedNAC2:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                            this = T4ResolveBuilder('sessionData', sessd);
                            this = this.resolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC2_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function these = serialTriggeringOnConvertedNAC(varargin)

            setenv('PRINTV', '1');

            ip = inputParser;
            addParameter(ip, 'iVisit', 1, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            tag    = ip.Results.tag;

             eSess = mlsystem.DirTool(fullfile(getenv('PPG'), 'jjlee', ''));
             cd(fullfile(getenv('PPG'), 'jjlee', ''));
             eSessFqdns = eSess.fqdns;
             T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
             these = cell(length(eSessFqdns), 2);
             for iSess = 1:length(eSessFqdns)

                try
                    T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eVisit = mlsystem.DirTool(eSessFqdns{iSess});
                    if (iVisit <= length(eVisit.fqdns))
                        if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                these{iSess,iVisit} = [pth ' was skipped'];
                                if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                                     mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                                     mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                                     mlraichle.T4ResolveUtilities.matchesTag(eSessFqdns{iSess}, tag))

                                    try
                                        sessd = SessionData( ...
                                            'studyData',   mlraichle.StudyData, ...
                                            'sessionPath', eSessFqdns{iSess}, ...
                                            'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                            'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                            'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                                        this = T4ResolveBuilder('sessionData', sessd);
                                        this = this.resolveConvertedNAC;   
                                        these{iSess,iVisit} = this;
                                    catch ME
                                        handwarning(ME);
                                    end
                                end
                            end

                        end    
                    end
                catch ME
                    handwarning(ME);
                end
            end
            save(sprintf('mlraichle_T4ResolveBuilder_serialTriggeringOnConvertedNAC_these_%s.mat', datestr(now, 30)), 'these');
        end
        function this  = repairTriggeringOnConvertedNAC(varargin)

            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'frame1st', @(x) isnumeric(x) && ~isnan(x));
            addRequired( ip, 'frame2nd', @(x) isnumeric(x) && ~isnan(x));
            addParameter(ip, 'iVisit', 1, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            tag    = ip.Results.tag;

            eSess = mlsystem.DirTool(fullfile(getenv('PPG'), 'jjlee'));
            eSessFqdns = eSess.fqdns;
            T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
            for iSess = 1:length(eSessFqdns)

                try
                    T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eVisit = mlsystem.DirTool(eSessFqdns{iSess});
                    if (iVisit <= length(eVisit.fqdns))
                        if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                                     mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                                    ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                                     mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                                     mlraichle.T4ResolveUtilities.matchesTag(eSessFqdns{iSess}, tag))

                                    try
                                        sessd = SessionData( ...
                                            'studyData',   mlraichle.StudyData, ...
                                            'sessionPath', eSessFqdns{iSess}, ...
                                            'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                            'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                            'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                                        this = T4ResolveBuilder('sessionData', sessd);
                                        this = this.repairConvertedNAC( ...
                                            ip.Results.frame1st, ip.Results.frame2nd);
                                    catch ME
                                        handwarning(ME);
                                    end
                                end
                            end

                        end    
                    end
                catch ME
                    handwarning(ME);
                end
            end
        end
        function this  = triggeringT4ResolveConvertedNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('resolveConvertedNAC', varargin{:});          
        end
        function this  = triggeringPullTracerNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('pullTracerNAC', varargin{:});                      
        end
        function this  = triggeringLocallyStageTracer(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('locallyStageTracer', varargin{:});                      
        end
          
        function scp(sessFold, visit, files)
            assert(ischar(sessFold));
            if (isnumeric(visit))
                visit = sprintf('V%i', visit);
            end
            if (~iscell(files))
                files = {files};
            end
            
            import mlfourdfp.*;
            for f = 1:length(files)                
                try
                    [~,r] = mlbash(sprintf('scp -qr %s %s:%s', ...
                        fullfile(getenv('PPG'), 'jjlee', sessFold, visit, files{f}), ...
                        MMRResolveBuilder.CLUSTER_HOSTNAME, ...
                        fullfile(MMRResolveBuilder.CLUSTER_SUBJECTS_DIR, sessFold, visit, '')));
                    fprintf('mlfourdfp.MMRResolveBuilder.scp:  %s\n', r);
                catch ME
                    handwarning(ME);
                end
            end
        end
        function scp_example(varargin)
            ip = inputParser;
            addOptional(ip, 'subject',  'HYGLY00', @ischar);
            addOptional(ip, 'visit',    1,         @isnumeric);
            addOptional(ip, 'patterns', {'FDG*NAC' 'mpr.4dfp.*' '*t4'}, @iscell);
            parse(ip, varargin{:});
            
            for p = 1:length(ip.Results.patterns)
                mlraichle.T4ResolveBuilder.scp(ip.Results.subject, ip.Results.visit, ip.Results.patterns{p});
            end
        end        
        function this = compiler_example(varargin)
            ip = inputParser;
            addOptional(ip, 'subject', 'HYGLY00', @ischar);
            parse(ip, varargin{:});
            
            studyd = mlpipeline.StudyDataSingletons.instance('raichle');            
            sessd = mlraichle.SessionData( ...
                'studyData', studyd, ...
                'sessionPath', fullfile(studyd.subjectsDir, ip.Results.subject, ''));
            this = mlraichle.T4ResolveBuilder('sessionData', sessd);
            cd(fullfile(sessd.sessionPath, 'V1', ''));
            this = this.resolveConvertedNAC;
        end
    end
    
	methods
        function this = locallyStageTracer(this)
            this.prepareNACLocation;         
            this.buildTracerNAC;
            this.prepareMR;
            this.pushAncillary;
        end
        function        prepareNACLocation(this)
            %% PREPARENACLOCATION recovers the NAC location from backup or creates it de novo.
            
            sessd = this.sessionData;
            if (this.recoverNACFolder)
                movefile([sessd.tracerNACLocation '-Backup'], sessd.tracerNACLocation);
                return
            end            
            if (~isdir(sessd.tracerNACLocation))
                mkdir(sessd.tracerNACLocation);
            end            
        end
        function this = buildTracerNAC(this)
            %% BUILDTRACERNAC builds 4dfp-formatted tracer NAC images; use to prep data before conveying to clusters.
            %  See also:  mlfourdfp.FourdfpVisitor.sif_4dfp.
            
            sessd = this.sessionData;
            ori = sessd.tracerLMFrame('typ', 'fqfn', 'frame', length(this.frames)-1);
            lm  = sessd.tracerLM( 'typ', 'fqfp');
            nac = sessd.tracerNAC('typ', 'fqfp');
            
            if (this.buildVisitor.lexist_4dfp(nac))
                return
            end
            if (~this.buildVisitor.lexist_4dfp(ori))
                error('mlfourdfp:processingStreamFailure', 'T4ResolveBuilder.buildTracerNAC could not find %s', ori);
            end
            if (~this.buildVisitor.lexist_4dfp(lm))
                fprintf('mlraichle.T4ResolveBuilder.buildTracerNAC:  building %s\n', lm);
                cd(fileparts(lm));
                this.buildVisitor.sif_4dfp(lm);
            end
            if (~isdir(sessd.tracerNACLocation))
                mkdir(sessd.tracerNACLocation);
            end                
            movefile([lm '.4dfp.*'], sessd.tracerNACLocation);
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
        function        pullTracerNAC(this, varargin)
            %% PULLTRACERNAC calls scp to pull this.CLUSTER_HOSTNAME:this.CLUSTER_SUBJECTS_DIR/<TRACER>_<VISIT>-NAC*
            %  @param visits is a cell-array defaulting to {'V1' 'V2'}
            
            ip = inputParser;
            addParameter(ip, 'visits', {'V1' 'V2'}, @iscell);
            parse(ip, varargin{:});
            
            sessd = this.sessionData;
            cd(fullfile(sessd.sessionPath));
            
            for iv = 1:length(ip.Results.visits)
                cd(fullfile(sessd.sessionPath, ip.Results.visits{iv}, ...
                    sprintf('%s_%s-NAC', upper(sessd.tracer), ip.Results.visits{iv}), ''));
                listv = {'*'}; 
                for ilv = 1:length(listv)
                    try
                        mlbash(sprintf('scp -qr %s:%s .', ...
                            this.CLUSTER_HOSTNAME, ...
                            fullfile( ...
                                this.CLUSTER_SUBJECTS_DIR, sessd.sessionFolder, ip.Results.visits{iv}, ...
                                sprintf('%s_%s-NAC', upper(sessd.tracer), ip.Results.visits{iv}), listv{ilv})));                        
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function        pushTracerNAC(this, varargin)
            %% PUSHTRACERNAC calls scp to push <TRACER>_<VISIT>-NAC to this.CLUSTER_HOSTNAME:this.CLUSTER_SUBJECTS_DIR
            %  @param visits is a cell-array defaulting to {'V1' 'V2'}
            
            ip = inputParser;
            addParameter(ip, 'visits', {'V1' 'V2'}, @iscell);
            parse(ip, varargin{:});
            
            sessd = this.sessionData;
            cd(fullfile(sessd.sessionPath));
            
            for iv = 1:length(ip.Results.visits)
                cd(fullfile(sessd.sessionPath, ip.Results.visits{iv}, ...
                    sprintf('%s_%s-NAC', upper(sessd.tracer), ip.Results.visits{iv}), ''));
                try
                    mlbash(sprintf('scp -qr %s %s:%s', ...
                        fullfile( ...
                            sessd.sessionPath, ip.Results.visits{iv}, ...
                            sprintf('%s_%s-NAC', upper(sessd.tracer), ip.Results.visits{iv})), ...
                        this.CLUSTER_HOSTNAME, ...
                        fullfile( ...
                            this.CLUSTER_SUBJECTS_DIR, sessd.sessionFolder, ip.Results.visits{iv}, '') )); 
                catch ME
                    handwarning(ME);
                end
            end
        end
        function        pushAncillary(this)
            %% PUSHANCILLARY calls scp to push ct.4dfp.* to this.CLUSTER_HOSTNAME:this.CLUSTER_SUBJECTS_DIR
            
            sessd = this.sessionData;
            
            cd(fullfile(sessd.sessionPath));
            lists = {'ct.4dfp.*'};
            for ils = 1:length(lists)
                try
                    mlbash(sprintf('scp -qr %s %s:%s', ...
                        lists{ils}, this.CLUSTER_HOSTNAME, fullfile(this.CLUSTER_SUBJECTS_DIR, sessd.sessionFolder, '')));
                catch ME
                    handwarning(ME);
                end
            end
            
            visits = {'V1' 'V2'};
            for iv = 1:length(visits)                
                cd(fullfile(sessd.sessionPath, visits{iv}, ''));
                listv = {'mpr.4dfp.*' '*_t4' [upper(sessd.tracer) '_V*-NAC']};
                for ilv = 1:length(listv)
                    try
                        mlbash(sprintf('scp -qr %s %s:%s', ...
                            listv{ilv}, ...
                            this.CLUSTER_HOSTNAME, ...
                            fullfile(this.CLUSTER_SUBJECTS_DIR, sessd.sessionFolder, visits{iv}, '')));
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.MMRResolveBuilder(varargin{:});
        end
    end
    
    %% PRIVATE
    
    methods (Static, Access = private)
        function this = triggering(varargin)
            
            studyd = mlraichle.StudyData;
            
            ip = inputParser;
            addRequired( ip, 'methodName',                      @ischar);
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'tag', '',                         @ischar);
            parse(ip, varargin{:});
            
            import mlsystem.* mlraichle.* ;
            T4ResolveBuilder.printv('triggering.ip.Results:  %s\n', struct2str(ip.Results));
            if (~strcmp(ip.Results.subjectsDir, studyd.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end
            
            eSess = DirTool(ip.Results.subjectsDir);
            T4ResolveBuilder.printv('triggering.eSess:  %s\n', cell2str(eSess.dns));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                T4ResolveBuilder.printv('triggering.eVisit:  %s\n', cell2str(eVisit.dns));
                for iVisit = 1:length(eVisit.fqdns)
                    
                    if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))
                        
                        eTracer = DirTool(eVisit.fqdns{iVisit});
                        T4ResolveBuilder.printv('triggering.eTracer:  %s\n', cell2str(eTracer.dns));
                        for iTracer = 1:length(eTracer.fqdns)

                            pth = eTracer.fqdns{iTracer};
                            T4ResolveBuilder.printv('triggering.pth:  %s\n', pth);
                            if (mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                                mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                               ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                                mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                                mlraichle.T4ResolveUtilities.matchesTag(eSess.fqdns{iSess}, ip.Results.tag))
                                try
                                    sessd = SessionData( ...
                                        'studyData',   studyd, ...
                                        'sessionPath', eSess.fqdns{iSess}, ...
                                        'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     mlraichle.T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));                                    
                                    disp(sessd);
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    disp(this);
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
        function this = runRaichle(sessPth, v, s)
            studyd = mlpipeline.StudyDataSingletons.instance('raichle');
            sessd = mlraichle.SessionData( ...
                'studyData', studyd, ...
                'sessionPath', sessPth, ...
                'vnumber', v, ...
                'snumber', s);
            this = mlraichle.T4ResolveBuilder('sessionData', sessd);            
            cd(this.sessionData.tracerNAC);
            if (~lexist(this.sessionData.tracerNAC('typ', 'mhdr'), 'file'))
                this.buildVisitor.sif_4dfp([this.sessionData.tracerNAC('typ', 'fqfp') '.mhdr']);
            end
            this = this.t4ResolvePET3;
        end
        function this = t4ResolvePET3(this)

            mprDir  = this.sessionData.vLocation;
            nacDir  = this.sessionData.tracerListmodeLocation;
            workDir = this.sessionData.vLocation;

            cd(this.sessionData.vLocation);
            
            assert(lexist(this.sessionData.mprage('fqfn'), 'file'));
            mpr_ = this.sessionData.mprage('fp');
            if (~lexist([mpr_ '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(this.sessionData.mprage('fp'), this.atlasTag);
            end

            tracer_ = lower(this.sessionData.tracer);
            tracerdir = fullfile(workDir, sprintf('%s_V%i-Resolved', upper(tracer_), this.sessionData.vnumber));
            if (~isdir(tracerdir))
                mkdir(tracerdir);
            end
            cd(tracerdir);
            fdfp0 = this.sessionData.tracerNAC('typ', 'fp');
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

            tracer = this.sessionData.tracer;
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

            tracer = this.sessionData.tracer;
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
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

