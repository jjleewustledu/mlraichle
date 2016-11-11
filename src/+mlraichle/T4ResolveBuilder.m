classdef T4ResolveBuilder < mlfourdfp.MMRResolveBuilder
	%% T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 18-Apr-2016 19:22:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	
        
    properties (Constant)
        MinFrames = 64
    end
    
	properties
        Nframes = 72
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
%                     fprintf('iSess->%i, iVisit->%i\n', iSess, iVisit);
%                     these{iSess,iVisit} = sprintf('eSessFqdns{iSess}->%s, iVisit->%i, tag ->%s\n', eSessFqdns{iSess}, iVisit, tag);
%                 end

                try
                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eSessFqdns{iSess}:  %s\n', eSessFqdns{iSess});

                    import mlraichle.*;
                    eVisit = mlsystem.DirTool(eSessFqdns{iSess});
                    if (iVisit <= length(eVisit.fqdns) && isdir(eVisit.fqdns{iVisit}))
                        if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                if (isdir(pth))
                                    T4ResolveBuilder.printv('parTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                    these{iSess,iVisit} = [pth ' was skipped'];
                                    if ( T4ResolveBuilder.isTracer(pth) && ...
                                         T4ResolveBuilder.isNAC(pth) && ...
                                        ~T4ResolveBuilder.isEmpty(pth) && ...
                                         T4ResolveBuilder.hasOP(pth) && ...
                                         T4ResolveBuilder.matchesTag(eSessFqdns{iSess}, tag))

                                        try
                                            fprintf('pwd->%s\n', pwd);
                                            sessd = SessionData( ...
                                                'studyData',   mlraichle.StudyData, ...
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
                            if ( T4ResolveBuilder.isTracer(pth) && ...
                                    T4ResolveBuilder.isNAC(pth) && ...
                                    ~T4ResolveBuilder.isEmpty(pth) && ...
                                    T4ResolveBuilder.hasOP(pth) && ...
                                    T4ResolveBuilder.matchesTag(eSessFqdns{iSess}, tag))
                                
                                try
                                    fprintf('pwd->%s\n', pwd);
                                    sessd = SessionData( ...
                                        'studyData',   mlraichle.StudyData, ...
                                        'sessionPath', eSessFqdns{iSess}, ...
                                        'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    this = this.excludeFrames(1);
                                    this = this.t4ResolveConvertedNAC; %#ok<NASGU>
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
            save(sprintf('mlraichle_T4ResolveBuilder_parTriggerOnConvertedNAC_these_%s.mat', datestr(now, 30)), 'these');
        end
        function jobs  = serialize(c)
            
            assert(isa(c, 'parallel.cluster.Generic'));
            
            hyglys = { 'HYGLY05' 'HYGLY08' 'HYGLY11' 'HYGLY24' 'HYGLY25' };
            jobs   = cell(1, length(hyglys));
            jjlee  = '/scratch/jjlee/raichle/PPGdata/jjlee';
            eSessFqdns = cellfun(@(x) fullfile(jjlee, x), hyglys, 'UniformOutput', false);
            
            for iSess = 1:length(eSessFqdns)                
                try
                    jobs{iSess} = c.batch(@mlraichle.T4ResolveBuilder.serialCompletedT4s2, 0, {eSessFqdns{iSess}});                    
                catch ME
                    handwarning(ME);
                end
            end
        end
        function         serialConvertedNAC(varargin)
            
            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'sessPath', @isdir);
            addParameter(ip, 'iVisit', @isnumeric);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialConvertedNAC');
            T4ResolveBuilder.printv('serialConvertedNAC.ip.Results.sessPath->%s\n', ip.Results.sessPath);

            import mlraichle.*;
            eVisit = mlsystem.DirTool(ip.Results.sessPath);              
            if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialConvertedNAC.pth:  %s\n', pth);
                    if ( T4ResolveBuilder.isTracer(pth) && ...
                            T4ResolveBuilder.isNAC(pth) && ...
                            ~T4ResolveBuilder.isEmpty(pth) && ...
                            T4ResolveBuilder.hasOP(pth))

                        try
                            T4ResolveBuilder.printv('serialConvertedNAC:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     iVisit);
                            this = T4ResolveBuilder('sessionData', sessd);
                            this = this.excludeFrames(1);
                            this = this.t4ResolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function         serialConvertedNAC2(varargin)
            
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
                    if ( T4ResolveBuilder.isTracer(pth) && ...
                            T4ResolveBuilder.isNAC(pth) && ...
                            ~T4ResolveBuilder.isEmpty(pth) && ...
                            T4ResolveBuilder.hasOP(pth) && ...
                            T4ResolveBuilder.matchesTag(ip.Results.sessPath, ip.Results.tag))

                        try
                            T4ResolveBuilder.printv('serialConvertedNAC2:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                            this = T4ResolveBuilder('sessionData', sessd);
                            this = this.excludeFrames(1);
                            this = this.t4ResolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialConvertedNAC2_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end        
        function         serialCompletedT4s(varargin)
            
            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'sessPath', @isdir);
            addParameter(ip, 'iVisit', 1, @isnumeric);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialCompletedT4s');
            T4ResolveBuilder.printv('serialCompletedT4s.ip.Results.sessPath->%s\n', ip.Results.sessPath);

            import mlraichle.*;
            eVisit = mlsystem.DirTool(ip.Results.sessPath);              
            if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialCompletedT4s.pth:  %s\n', pth);
                    if ( T4ResolveBuilder.isTracer(pth) && ...
                            T4ResolveBuilder.isNAC(pth) && ...
                            ~T4ResolveBuilder.isEmpty(pth) && ...
                            T4ResolveBuilder.hasOP(pth))

                        try
                            T4ResolveBuilder.printv('serialCompletedT4s:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     iVisit);
                            this = T4ResolveBuilder('sessionData', sessd);
                            this.completedT4s = true;
                            this = this.excludeFrames([1 2 3]);
                            this = this.t4ResolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialCompletedT4s_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function         serialCompletedT4s2(varargin)
            
            import mlraichle.*;
            setenv('PRINTV', '1');

            ip = inputParser;
            addRequired( ip, 'sessPath', @isdir);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            cd(ip.Results.sessPath);
            T4ResolveBuilder.diaryv('serialCompletedT4s2');
            T4ResolveBuilder.printv('serialCompletedT4s2.ip.Results.sessPath->%s\n', ip.Results.sessPath);

            eVisit = mlsystem.DirTool(ip.Results.sessPath);
            for iVisit = 1:length(eVisit.fqdns)
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialCompletedT4s2.pth:  %s\n', pth);
                    if ( T4ResolveBuilder.isTracer(pth) && ...
                         T4ResolveBuilder.isNAC(pth) && ...
                        ~T4ResolveBuilder.isEmpty(pth) && ...
                         T4ResolveBuilder.hasOP(pth) && ...
                         T4ResolveBuilder.matchesTag(ip.Results.sessPath, ip.Results.tag))

                        try
                            T4ResolveBuilder.printv('serialCompletedT4s2:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessPath, ...
                                'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                            this = T4ResolveBuilder('sessionData', sessd);
                            this.completedT4s = true;
                            this = this.excludeFrames([1 2 3]);
                            this = this.t4ResolveConvertedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialCompletedT4s2_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function         serialValidateForT4Resolve(topPth)
            
            import mlraichle.*;
            
            cd(topPth);
            eVisit = mlsystem.DirTool(topPth);
            for iVisit = 1:length(eVisit.fqdns)
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)

                    pth = eTracer.fqdns{iTracer};
                    if ( T4ResolveBuilder.isTracer(pth) && ...
                         T4ResolveBuilder.isNAC(pth) && ...
                        ~T4ResolveBuilder.isEmpty(pth) && ...
                         T4ResolveBuilder.hasOP(pth))

                        try
                            cd(pth);
                            delete('T4ResolveBuilder.validateForT4Resolve.*');
                            if (strcmp(eVisit.dns{iVisit}, 'V2'))
                                mlraichle.T4ResolveBuilder.validateForT4Resolve('dest', 'fdgv2r1');
                            else
                                mlraichle.T4ResolveBuilder.validateForT4Resolve;
                            end
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
                        if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                T4ResolveBuilder.printv('serialTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                these{iSess,iVisit} = [pth ' was skipped'];
                                if ( T4ResolveBuilder.isTracer(pth) && ...
                                     T4ResolveBuilder.isNAC(pth) && ...
                                     T4ResolveBuilder.hasOP(pth) && ...
                                     T4ResolveBuilder.matchesTag(eSessFqdns{iSess}, tag))

                                    try
                                        sessd = SessionData( ...
                                            'studyData',   mlraichle.StudyData, ...
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
                catch ME
                    handwarning(ME);
                end
            end
            save(sprintf('mlraichle_T4ResolveBuilder_parTriggerOnConvertedNAC_these_%s.mat', datestr(now, 30)), 'these');
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
                        if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))

                            eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)
                                T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.eTracer{iTracer}:  %s\n', eTracer.fqdns{iTracer});

                                pth = eTracer.fqdns{iTracer};
                                T4ResolveBuilder.printv('repairTriggeringOnConvertedNAC.pth:  %s\n', pth);
                                if ( T4ResolveBuilder.isTracer(pth) && ...
                                     T4ResolveBuilder.isNAC(pth) && ...
                                    ~T4ResolveBuilder.isEmpty(pth) && ...
                                     T4ResolveBuilder.hasOP(pth) && ...
                                     T4ResolveBuilder.matchesTag(eSessFqdns{iSess}, tag))

                                    try
                                        sessd = SessionData( ...
                                            'studyData',   mlraichle.StudyData, ...
                                            'sessionPath', eSessFqdns{iSess}, ...
                                            'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                            'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                            'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));
                                        this = T4ResolveBuilder('sessionData', sessd);
                                        this = this.excludeFrames(1); 
                                        this = this.t4RepairConvertedNAC( ...
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
            %save(sprintf('mlraichle_T4ResolveBuilder_parTriggerOnConvertedNAC_these_%s.mat', datestr(now, 30)), 'this');
        end
        function this  = runSingleOnConvertedNAC(varargin)
            
            studyd = mlraichle.StudyData;

            ip = inputParser;
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'studyData', studyd, @(x) isa(x, 'mlpipeline.StudyData'));
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
                    this = this.excludeFrames(1);
                    this = this.t4ResolveConvertedNAC;
                catch ME
                    handwarning(ME);
                end
            end            
        end
        function this  = triggeringOnConvertedNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('t4ResolveConvertedNAC', varargin{:});          
        end
        function this  = triggeringRetrievalForNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('retrieveFdg', varargin{:});                      
        end
        function this  = triggeringStagingForNAC(varargin)
            this = mlraichle.T4ResolveBuilder.triggering('locallyStageFdg', varargin{:});                      
        end
          
        function revertToLM00(nacPth)
            if (~isdir(nacPth))
                return
            end
            vPth = fileparts(nacPth);
            [~,vFold] = fileparts(vPth);
            tracerFold = [upper(this.tracer) '_' vFold];
            lm00Pth = fullfile(vPth, [tracerFold '-Converted'], [tracerFold '-LM-00'], '');
            if (lexist(fullfile(nacPth, [lower(this.tracer) lower(vFold) 'r2_resolved.4dfp.img'])))
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
        function scp_example
            import mlraichle.*;
            T4ResolveBuilder.scp('HYGLY25', 1, 'FDG*NAC');
            %T4ResolveBuilder.scp('HYGLY25', 1, 'mpr.4dfp.*');
            T4ResolveBuilder.scp('HYGLY25', 1, '*t4');
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
            %% BUILDFDGNAC builds 4dfp formatted fdg NAC images; use to prep data before conveying to clusters.
            %  See also:  mlfourdfp.FourdfpVisitor.sif_4dfp.
            
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
        function        retrieveFdg(this, varargin)
            ip = inputParser;
            addParameter(ip, 'visits', {'V1' 'V2'}, @iscell);
            parse(ip, varargin{:});
            
            cd(fullfile(this.sessionData.sessionPath));
            
            for iv = 1:length(ip.Results.visits)
                cd(fullfile(this.sessionData.sessionPath, ip.Results.visits{iv}, ...
                    sprintf('FDG_%s-NAC', ip.Results.visits{iv}), ''));
                listv = {'*'}; %{'fdgv*' 'Log' 'T4'};
                for ilv = 1:length(listv)
                    try
                        mlbash(sprintf('scp -qr %s:%s .', ...
                            this.cluster, ...
                            fullfile( ...
                            this.clusterSubjectsDir, this.sessionData.sessionFolder, ip.Results.visits{iv}, ...
                            sprintf('FDG_%s-NAC', ip.Results.visits{iv}), listv{ilv})));                        
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function        retrieveNAC(this, varargin)
            ip = inputParser;
            addParameter(ip, 'visits', {'V1' 'V2'}, @iscell);
            parse(ip, varargin{:});
            
            cd(fullfile(this.sessionData.sessionPath));
            
            for iv = 1:length(ip.Results.visits)
                cd(fullfile(this.sessionData.sessionPath, ip.Results.visits{iv}, ''));
                try
                    mlbash(sprintf('scp -qr %s:%s .', ...
                        this.cluster, ...
                        fullfile( ...
                            this.clusterSubjectsDir, this.sessionData.sessionFolder, ip.Results.visits{iv}, ...
                            sprintf('FDG_%s-NAC', ip.Results.visits{iv}))));                        
                catch ME
                    handwarning(ME);
                end
            end
        end
        function        pushNAC(this, varargin)
            ip = inputParser;
            addParameter(ip, 'visits', {'V1' 'V2'}, @iscell);
            parse(ip, varargin{:});
            
            cd(fullfile(this.sessionData.sessionPath));
            
            for iv = 1:length(ip.Results.visits)
                cd(fullfile(this.sessionData.sessionPath, ip.Results.visits{iv}, ...
                    sprintf('FDG_%s-NAC', ip.Results.visits{iv}), ''));
                try
                    mlbash(sprintf('scp -qr %s %s:%s', ...
                        fullfile( ...
                            this.sessionData.sessionPath, ip.Results.visits{iv}, ...
                            sprintf('FDG_%s-NAC', ip.Results.visits{iv})), ...
                        this.cluster, ...
                        fullfile( ...
                            this.clusterSubjectsDir, this.sessionData.sessionFolder, ip.Results.visits{iv}, '') )); 
                catch ME
                    handwarning(ME);
                end
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
        function this = t4RepairConvertedNAC(this, frame1st, frame2nd)
            
            cd(this.sessionData.tracerNAC('typ', 'path'));
            mlraichle.T4ResolveBuilder.printv('t4RepairConvertedNAC.pwd:  %s\n', pwd);
            this.ensureFdgSymlinks;
            this = this.repairSingle( ...
                frame1st, frame2nd, ...
                'dest', sprintf('%sv%ir%i', lower(this.tracer), this.sessionData.vnumber, this.sessionData.rnumber));
        end
        function this = t4ResolveConvertedNAC(this)
            %% T4RESOLVECONVERTEDNAC is the principle caller of resolve.
            
            cd(this.sessionData.fdgNAC('typ', 'path'));
            mlraichle.T4ResolveBuilder.printv('t4ResolveConvertedNAC.pwd:  %s\n', pwd);
            this.ensureFdgSymlinks;
            if (~this.completedT4s)
                this = this.resolve( ...
                    'dest', sprintf('%sv%i', lower(this.sessionData.tracer), this.sessionData.vnumber), ...
                    'source', this.sessionData.fdgNAC('typ', 'fp'), ...
                    'firstCrop', this.firstCrop, ...
                    'frames', this.frames);
            else
                this = this.resolveCompletedT4s( ...
                    'dest', sprintf('%sv%i', lower(this.sessionData.tracer), this.sessionData.vnumber), ...
                    'source', this.sessionData.fdgNAC('typ', 'fp'), ...
                    'firstCrop', this.firstCrop, ...
                    'frames', this.frames);
            end
        end
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.MMRResolveBuilder(varargin{:});
            if (lstrfind(this.sessionData.sessionFolder, 'HYGLY25') && ...
                         this.sessionData.vnumber == 1)
                this.Nframes = 64;
            end
        end
    end
    
    %% PRIVATE
    
    methods (Static, Access = private)
        function this = triggering(varargin)
            
            studyd = mlraichle.StudyData;
            
            ip = inputParser;
            addRequired( ip, 'methodName', @ischar);
            addParameter(ip, 'excludeFrames', 1, @isnumeric);
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'tag', '', @ischar);
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
                    
                    if (T4ResolveBuilder.isVisit(eVisit.fqdns{iVisit}))
                        
                        eTracer = DirTool(eVisit.fqdns{iVisit});
                        T4ResolveBuilder.printv('triggering.eTracer:  %s\n', cell2str(eTracer.dns));
                        for iTracer = 1:length(eTracer.fqdns)

                            pth = eTracer.fqdns{iTracer};
                            T4ResolveBuilder.printv('triggering.pth:  %s\n', pth);
                            if (T4ResolveBuilder.isTracer(pth) && ...
                                T4ResolveBuilder.isNAC(pth) && ...
                               ~T4ResolveBuilder.isEmpty(pth) && ...
                                T4ResolveBuilder.hasOP(pth) && ...
                                T4ResolveBuilder.matchesTag(eSess.fqdns{iSess}, ip.Results.tag))
                                try
                                    sessd = SessionData( ...
                                        'studyData',   studyd, ...
                                        'sessionPath', eSess.fqdns{iSess}, ...
                                        'snumber',     T4ResolveBuilder.scanNumber(eTracer.dns{iTracer}), ...
                                        'tracer',      T4ResolveBuilder.tracerPrefix(eTracer.dns{iTracer}), ...
                                        'vnumber',     T4ResolveBuilder.visitNumber(eVisit.dns{iVisit}));                                    
                                    disp(sessd);
                                    this = T4ResolveBuilder('sessionData', sessd);
                                    disp(this);
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

