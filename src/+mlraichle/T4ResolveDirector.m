classdef T4ResolveDirector 
	%% T4RESOLVEDIRECTOR  

	%  $Revision$
 	%  was created 11-Nov-2016 13:50:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
    end
    
    methods (Static)
        function forTracer(varargin)
            
            import mlraichle.* ;          
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'innerMethod', 'unknown', @ischar);
            addParameter(ip, 'studyData', StudyData,   @isdir);
            addParameter(ip, 'subjectTag', '',         @ischar);
            addParameter(ip, 'tracer', 'OC',           @ischar);
            parse(ip, varargin{:});            
            fprintf('T4ResolveDirector.forTracer.ip.Results:  %s\n', struct2str(ip.Results));
            
            import mlsystem.*;
            eSess = DirTool(ip.Results.studyData.subjectsDir);
            for iSess = 1:length(eSess.fqdns)                
                if (T4ResolveUtilities.matchesTag(eSess.fqdns{iSess}, ip.Results.subjectTag))
                    eVisit = DirTool(eSess.fqdns{iSess});
                    for iVisit = 1:length(eVisit.fqdns)                        
                        if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))
                            eTracer = DirTool(eVisit.fqdns{iVisit});
                            for iTracer = 1:length(eTracer.fqdns)                                
                                tracerp = eTracer.fqdns{iTracer};
                                if ( T4ResolveUtilities.isTracer(tracerp, ip.Results.tracer) && ...
                                    ~T4ResolveUtilities.isEmpty(tracerp))
                                    try
                                        ip.Results.innerMethod('tracerPath', tracerp, varargin{:});
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
        function ifConverted(varargin)
            
            import mlraichle.* ;         
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracerPath', pwd, @isdir);
            addParameter(ip, 'innerMethod2',    @ischar);
            parse(ip, varargin{:});            
            fprintf('T4ResolveDirector.forTracer.ip.Results:  %s\n', struct2str(ip.Results)); 
            
            tracerp = ip.Results.tracerPath;
            if (T4ResolveUtilities.isConverted(tracerp) && ...
                T4ResolveUtilities.hasOP(tracerp))
                %%T4ResolveUtilities.isNAC(sessPth) && ...
                try
                    sessd = SessionData( ...
                        'studyData',   ip.Results.studyData, ...
                        'sessionPath', tracerp, ...
                        'snumber',     T4ResolveUtilities.scanNumber(  tracerp), ...
                        'tracer',      T4ResolveUtilities.tracerPrefix(tracerp), ...
                        'vnumber',     T4ResolveUtilities.visitNumber( tracerp));                                    
                    disp(sessd);
                    this = T4ResolveBuilder('sessionData', sessd);
                    disp(this);
                    this.(ip.Results.innerMethod2);
                catch ME
                    handwarning(ME);
                end
            end
        end
        function ifNAC(varargin)
            
            import mlraichle.* ;         
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracerPath', pwd, @isdir);
            addParameter(ip, 'innerMethod2',    @ischar);
            parse(ip, varargin{:});            
            fprintf('T4ResolveDirector.forTracer.ip.Results:  %s\n', struct2str(ip.Results)); 
            
            tracerp = ip.Results.tracerPath;
            if (T4ResolveUtilities.isNAC(tracerp))
                try
                    sessd = SessionData( ...
                        'studyData',   ip.Results.studyData, ...
                        'sessionPath', tracerp, ...
                        'snumber',     T4ResolveUtilities.scanNumber(  tracerp), ...
                        'tracer',      T4ResolveUtilities.tracerPrefix(tracerp), ...
                        'vnumber',     T4ResolveUtilities.visitNumber( tracerp));                                    
                    disp(sessd);
                    this = T4ResolveBuilder('sessionData', sessd);
                    disp(this);
                    this.(ip.Results.innerMethod2);
                catch ME
                    handwarning(ME);
                end
            end
        end
        function parBuildUmaps
            import mlsystem.*;
            cd(mlraichle.StudyRegistry.instance.subjectsDir);
            dt = DirTool('*');
            dtFqdns = dt.fqdns;
            parfor idt = 1:length(dtFqdns)
                for v = 1:2
                    
                    %% testing
                    %studyd = mlraichle.StudyData;
                    %sessd = mlraichle.SessionData('studyData', studyd,'sessionPath', pwd);
                    %a = mlfourdfp.UmapResolveBuilder('sessionData', sessd); % ctor test
                    %b = mlfourdfp.O15UmapResolveBuilder('sessionData', sessd); % "

                    cd(dtFqdns{idt});
                    mlfourdfp.UmapResolveBuilder.serialBuildUmaps(pwd, 'iVisit', v);
                    cd(dtFqdns{idt});
                    mlfourdfp.O15UmapResolveBuilder.buildAllO15Umaps(pwd, 'iVisit', v);
                end
            end
        end
    end

	methods 
		  
 		function this = T4ResolveDirector(it4rb)
 			%% T4RESOLVEDIRECTOR
 			%  Usage:  this = T4ResolveDirector(IT4ResolveBuilder_object)

            assert(isa(it4rb, 'mlfourdfp.IT4ResolveBuilder'));
            this.iT4ResolveBuilder_ = it4rb;
 		end
    end 

    properties (Access = private)
        iT4ResolveBuilder_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

