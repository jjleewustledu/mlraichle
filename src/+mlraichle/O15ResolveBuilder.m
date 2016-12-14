classdef O15ResolveBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% O15RESOLVEBUILDER  

	%  $Revision$
 	%  was created 27-Oct-2016 22:21:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

    methods (Static)
        function tf   = completed(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            this = mlraichle.O15ResolveBuilder('sessionData', sessd);
            tf = lexist(this.completedTouchFile, 'file');
        end
        function        parTriggering(varargin)           
            
            ip = inputParser;
            addRequired( ip, 'methodName', @ischar);
            addParameter(ip, 'ac', false, @islogical);
            addParameter(ip, 'studyd', mlraichle.StudyData, @(x) isa(x, 'mlpipeline.StudyDataHandle'));
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'tracerExpr', {'OC'}, @iscell);
            parse(ip, varargin{:});
            ipr = ip.Results;
            studyd = ipr.studyd;
            
            import mlsystem.* mlfourdfp.*;           
            eSess = DirTool(studyd.subjectsDir);
            eSessFqdns = eSess.fqdns;
            parfor iSess = 1:length(eSessFqdns)

                eVisit = DirTool(eSessFqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    eTracer = DirTool(eVisit.fqdns{iVisit});
                    for iTracer = 1:length(eTracer.fqdns)

                        pth___ = eTracer.fqdns{iTracer};
                        if (mlraichle.T4ResolveUtilities.matchesTag(pth___, ipr.tag) && ...
                            mlraichle.T4ResolveUtilities.isVisit(pth___) && ...
                            mlraichle.T4ResolveUtilities.isTracer(pth___, ipr.tracerExpr) && ...
                            mlraichle.T4ResolveUtilities.isConverted(pth___) && ...
                            mlraichle.T4ResolveUtilities.matchesAC(ipr.ac, pth___)) %#ok<PFBNS>
                            try
                                sessd = mlraichle.SessionData( ...
                                    'studyData',   ipr.studyd, ...
                                    'sessionPath', eSessFqdns{iSess}, ...
                                    'ac',          ipr.ac, ...
                                    'snumber',     mlraichle.T4ResolveUtilities.scanNumber(  eTracer.dns{iTracer}), ...
                                    'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                    'vnumber',     mlraichle.T4ResolveUtilities.visitNumber( eVisit.dns{iVisit}));
                                this = mlraichle.O15ResolveBuilder('sessionData', sessd);
                                mlraichle.O15ResolveBuilder.printv('O15ResolveBuilder.pth___ -> %s\n', pth___);
                                this.(ipr.methodName);
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end                
            end            
        end
        function this = triggering(varargin)
            
            ip = inputParser;
            addRequired( ip, 'methodName', @ischar);
            addParameter(ip, 'ac', false, @islogical);
            addParameter(ip, 'studyd', mlraichle.StudyData, @(x) isa(x, 'mlpipeline.StudyDataHandle'));
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'tracerExpr', {'OC'}, @iscell);
            parse(ip, varargin{:});
            studyd = ip.Results.studyd;
            
            import mlsystem.* mlfourdfp.*;           
            eSess = DirTool(studyd.subjectsDir);
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    eTracer = DirTool(eVisit.fqdns{iVisit});
                    for iTracer = 1:length(eTracer.fqdns)

                        pth___ = eTracer.fqdns{iTracer};
                        if (mlraichle.T4ResolveUtilities.matchesTag(pth___, ip.Results.tag) && ...
                            mlraichle.T4ResolveUtilities.isVisit(pth___) && ...
                            mlraichle.T4ResolveUtilities.isTracer(pth___, ip.Results.tracerExpr) && ...
                            mlraichle.T4ResolveUtilities.isConverted(pth___) && ...
                            mlraichle.T4ResolveUtilities.matchesAC(ip.Results.ac, pth___))
                            try
                                sessd = mlraichle.SessionData( ...
                                    'studyData',   ip.Results.studyd, ...
                                    'sessionPath', eSess.fqdns{iSess}, ...
                                    'ac',          ip.Results.ac, ...
                                    'snumber',     mlraichle.T4ResolveUtilities.scanNumber(  eTracer.dns{iTracer}), ...
                                    'tracer',      mlraichle.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                    'vnumber',     mlraichle.T4ResolveUtilities.visitNumber( eVisit.dns{iVisit}));
                                this = mlraichle.O15ResolveBuilder('sessionData', sessd);
                                mlraichle.O15ResolveBuilder.printv('O15ResolveBuilder.pth___ -> %s\n', pth___);
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
    
	methods		  
 		function this = O15ResolveBuilder(varargin)
 			%% O15RESOLVEBUILDER
 			%  Usage:  this = O15ResolveBuilder()

 			this = this@mlfourdfp.AbstractTracerResolveBuilder(varargin{:});
        end
        function printSessionData(this)
            mlraichle.O15ResolveBuilder.printv('O15ResolveBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
        function resolveLocally(this)
            this.mkdirTracerNACLocation;
            this.buildTracerNAC;
            this.ensureMsktgenMprage;  
            this.resolveConvertedNAC;
        end
        function prepareClusterResolve(this)
            this.mkdirTracerNACLocation;
            this.buildTracerNAC;
            this.ensureMsktgenMprage; 
            this.pushAncillary;
            this.pushTracerNAC;
        end
        function pullTracerNAC(this, varargin)
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
        function pushTracerNAC(this, varargin)
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
        function batchClusterResolve(this)
            c = parcluster;
            c.batch(@this.batchClusterResolve__, 1, {});
        end
    end 
    
    %% PRIVATE
    
    methods (Access = private)
        function batchClusterResolve__(this)
            this.resolveConvertedNAC;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

