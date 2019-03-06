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
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            tag    = ip.Results.tag;

            eSess = mlsystem.DirTool('/scratch/jjlee/raichle/PPGdata/jjlee');
            eSessFqdns = eSess.fqdns;
            T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
            these = cell(length(eSessFqdns), 2);
            parfor iSess = 1:length(eSessFqdns)

                try
                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eTracer = mlsystem.DirTool(eSessFqdns{iSess});
                    for iTracer = 1:length(eTracer.fqdns)
                        T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                        pth = eTracer.fqdns{iTracer};
                        if (isdir(pth))
                            T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.pth:  %s\n', pth);
                            these{iSess} = [pth ' was skipped'];
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
                                        'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    this = this.resolveConvertedNAC;   
                                    these{iSess} = this;
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
                    eTracer = mlsystem.DirTool(eSessFqdns{iSess});
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
                                    'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));
                                this = T4ResolveBuilder('sessionData', sessd);
                                this = this.resolveConvertedNAC; %#ok<NASGU>
                                %these{iSess,iVisit} = this;
                            catch ME
                                handwarning(ME);
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
            addParameter(ip, 'tracer', 'FDG', @ischar);
            addParameter(ip, 'snumber', [],   @isnumeric);
            parse(ip, varargin{:});
            tracer  = ip.Results.tracer;
            snumber = ip.Results.snumber;
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialConvertedNAC');
            T4ResolveBuilder.printv('serialConvertedNAC.ip.Results.sessPath->%s\n', ip.Results.sessPath);
            
            import mlraichle.*;
            eTracer = mlsystem.DirTool(ip.Results.sessPath);
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
                            'tracer',      tracer);
                        this = T4ResolveBuilder('sessionData', sessd);
                        this = this.resolveConvertedNAC;
                        save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC_this_%s.mat', datestr(now, 30)), 'this');
                    catch ME
                        handwarning(ME);
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
            eTracer = mlsystem.DirTool(ip.Results.sessPath);
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
                            'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));
                        this = T4ResolveBuilder('sessionData', sessd);
                        this = this.resolveConvertedNAC;                                     
                        save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC2_this_%s.mat', datestr(now, 30)), 'this');
                    catch ME
                        handwarning(ME);
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
            tag    = ip.Results.tag;

             eSess = mlsystem.DirTool(mlraichle.RaichleRegistry.instance.subjectsDir);
             cd(mlraichle.RaichleRegistry.instance.subjectsDir);
             eSessFqdns = eSess.fqdns;
             T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
             these = cell(length(eSessFqdns), 2);
             for iSess = 1:length(eSessFqdns)

                try
                    T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eTracer = mlsystem.DirTool(eSessFqdns{iSess});
                    for iTracer = 1:length(eTracer.fqdns)
                        T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                        pth = eTracer.fqdns{iTracer};
                        T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.pth:  %s\n', pth);
                        these{iSess} = [pth ' was skipped'];
                        if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                             mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                             mlraichle.T4ResolveUtilities.hasOP(pth) && ...
                             mlraichle.T4ResolveUtilities.matchesTag(eSessFqdns{iSess}, tag))

                            try
                                sessd = SessionData( ...
                                    'studyData',   mlraichle.StudyData, ...
                                    'sessionPath', eSessFqdns{iSess}, ...
                                    'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                    'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));
                                this = T4ResolveBuilder('sessionData', sessd);
                                this = this.resolveConvertedNAC;   
                                these{iSess} = this;
                            catch ME
                                handwarning(ME);
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
            tag    = ip.Results.tag;

            eSess = mlsystem.DirTool(mlraichle.RaichleRegistry.instance.subjectsDir);
            eSessFqdns = eSess.fqdns;
            T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eSessFqdns->\n%s\n', cell2str(eSessFqdns));
            for iSess = 1:length(eSessFqdns)

                try
                    T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eTracer = mlsystem.DirTool(eSessFqdns{iSess});
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
                                    'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));
                                this = T4ResolveBuilder('sessionData', sessd);
                                this = this.repairConvertedNAC( ...
                                    ip.Results.frame1st, ip.Results.frame2nd);
                            catch ME
                                handwarning(ME);
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
                        fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, sessFold, visit, files{f}), ...
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
        
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
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

                eTracer = DirTool(eSess.fqdns{iSess}));
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
                                'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}));                                    
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
    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

