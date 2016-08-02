classdef UmapResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% UMAPRESOLVEBUILDER  

	%  $Revision$
 	%  was created 20-Jul-2016 18:14:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		
    end

    methods (Static)
        function these = parTriggeringOnResolvedNAC(varargin)

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
                                this = UmapResolveBuilder('sessionData', sessd);
                                this = this.arrangeMR;
                                this = this.buildUmaps;   
                                these{iSess,iVisit} = this;
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end          
            end
        end
        function this = runSingleOnResolvedNAC(varargin)
            
            studyd = mlraichle.StudyDataSingleton.instance;

            ip = inputParser;
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'sessionFolder', 'HYGLY05', @ischar);
            addParameter(ip, 'visitFolder', 'V1', @ischar);
            addParameter(ip, 'tracerFolder', 'FDG_V1-NAC', @ischar);            
            parse(ip, varargin{:});
            studyd.subjectsDir = ip.Results.subjectsDir;

            pth = fullfile(ip.Results.subjectsDir, ip.Results.sessionFolder, ip.Results. visitFolder, ip.Results.tracerFolder);
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
                    this = UmapResolveBuilder('sessionData', sessd);
                    this = this.arrangeMR;
                    this = this.buildUmaps;
                catch ME
                    handwarning(ME);
                end
            end            
        end
    end
    
	methods 
		  
 		function this = UmapResolveBuilder(varargin)
 			%% UMAPRESOLVEBUILDER
 			%  Usage:  this = UmapResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

