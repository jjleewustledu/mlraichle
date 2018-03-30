classdef O15DynamicBuilder < mlfourdfp.AbstractTracerResolveBuilder
	%% O15DYNAMICBUILDER  

	%  $Revision$
 	%  was created 27-Oct-2016 22:21:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

    methods (Static)
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
                                this = mlraichle.O15DynamicBuilder('sessionData', sessd);
                                mlraichle.O15DynamicBuilder.printv('O15DynamicBuilder.pth___ -> %s\n', pth___);
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
                                this = mlraichle.O15DynamicBuilder('sessionData', sessd);
                                mlraichle.O15DynamicBuilder.printv('O15DynamicBuilder.pth___ -> %s\n', pth___);
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
 		function this = O15DynamicBuilder(varargin)
 			%% O15DynamicBuilder
 			%  Usage:  this = O15DynamicBuilder()

 			this = this@mlfourdfp.AbstractTracerResolveBuilder(varargin{:});
            this.finished_ = mlpipeline.Finished(this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
        function printSessionData(this)
            mlraichle.O15DynamicBuilder.printv('O15DynamicBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

