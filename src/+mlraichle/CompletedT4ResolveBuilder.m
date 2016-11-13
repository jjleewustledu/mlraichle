classdef CompletedT4ResolveBuilder < mlfourdfp.MMRResolveBuilder
	%% COMPLETEDT4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 10-Nov-2016 17:48:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    methods (Static)        
        function serialCompletedT4s(varargin)
            
            import mlraichle.*;
            setenv('PRINTV', '1');

            ip = inputParser;
            addParameter(ip, 'sessionPath', @isdir);
            addParameter(ip, 'iVisit', 1, @isnumeric);
            parse(ip, varargin{:});
            iVisit = ip.Results.iVisit;
            cd(ip.Results.sessionPath);
            T4ResolveBuilder.diaryv('serialCompletedT4s');
            T4ResolveBuilder.printv('serialCompletedT4s.ip.Results.sessionPath->%s\n', ip.Results.sessionPath);

            eVisit = mlsystem.DirTool(ip.Results.sessionPath);              
            if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveBuilder.printv('serialCompletedT4s.pth:  %s\n', pth);
                    if ( mlraichle.T4ResolveUtilities.isTracer(pth) && ...
                         mlraichle.T4ResolveUtilities.isNAC(pth) && ...
                        ~mlraichle.T4ResolveUtilities.isEmpty(pth) && ...
                         mlraichle.T4ResolveUtilities.hasOP(pth))

                        try
                            T4ResolveBuilder.printv('serialCompletedT4s:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessionPath, ...
                                'snumber',     mlraichle.T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      mlfourdfp.T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     iVisit);
                            this = CompletedT4ResolveBuilder('sessionData', sessd);
                            this = this.excludeFrames([1 2 3]);
                            this = this.t4ResolveCompletedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_T4ResolveBuilder_serialCompletedT4s_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
    end
    
	methods        
        function this = resolve(this, varargin)
            %% RESOLVE
            %  @param dest       is a f.q. fileprefix.
            %  @param destMask   "
            %  @param source     "
            %  @param sourceMask "
            %  @param destBlur   is the fwhm blur applied by imgblur_4dfp to dest.            
            %  @param sourceBlur is the fwhm blur applied by imgblur_4dfp to source.
            %  @param t40        is the initial t4-file for the transformation:  transverse is default.
            %  @param t4         is the cumulative t4-file for the transformation.
            %  @param log        is the f.q. filename of the log file.
            %  @param useMetricGradient:  cf. ${TRANSFER}/cross_modal_intro.pdf
            %  @returns t4       is the t4-file for the transformation.
            %  @returns fqfp     is the f.q. fileprefix of the co-registered output.
            
            import mlfourdfp.*;
            ip = inputParser;
            addParameter(ip, 'dest',       '',              @ischar);
            addParameter(ip, 'source',     '',              @FourdfpVisitor.lexist_4dfp);
            addParameter(ip, 'destMask',   'none',          @ischar);
            addParameter(ip, 'sourceMask', 'none',          @ischar);
            addParameter(ip, 'framesMask', 'maskOrdFrames', @ischar);
            addParameter(ip, 'destBlur',   this.coulombPrecision, @isnumeric); % fwhh/mm
            addParameter(ip, 'sourceBlur', this.coulombPrecision, @isnumeric); % fwhh/mm            
            addParameter(ip, 'NRevisions', this.NRevisions, @isnumeric);
            addParameter(ip, 'atlas',      this.atlas,      @ischar);
            addParameter(ip, 'firstCrop',  this.firstCrop,  @isnumeric); % [0 1]
            addParameter(ip, 'frames',     this.frames,     @isnumeric); % 1 to keep; 0 to skip
            addParameter(ip, 'log',        '/dev/null',     @ischar);
            addParameter(ip, 'mprage',     this.mprage,     @ischar);
            addParameter(ip, 'rnumber',    this.NRevisions, @isnumeric);
            addParameter(ip, 't40',        this.buildVisitor.transverse_t4, @(x) ischar(x) || iscell(x));
            parse(ip, varargin{:});
            this.inputCache_ = ip.Results;
            ipr = this.inputCache_;       
            ipr = this.expandFrames(ipr); 
            ipr = this.boundFrames(ipr);      
            ipr = this.expandBlurs(ipr);
            ipr.mprage = '';            
            
            this.t4ResolveAndPasteLog_ = this.loggerFilename('T4ResolveBuilder_resolve', ipr.dest, 'path', this.sessionData.vLocation);
            ipr.dest     = sprintf('%sr%i', ipr.dest, ip.Results.NRevisions);            
            ipr          = this.contractBlurs(ipr);
            ipr          = this.contractFrames(ipr);
            extractedFps = this.extractFrames(ipr);
                           this.lazyBlurredFrames(extractedFps, ipr);
            ipr          = this.t4ResolveAndPaste(ipr); 
            ipr          = this.teardownIterate(ipr);            
            
            this.buildVisitor.imgblur_4dfp(ipr.resolved, this.blurArg);
            this.product_ = this.fileprefixBlurred(ipr.resolved);
        end
        function        recoverTorndown(this)
            copyfile(fullfile(this.t4Path, '*_t4'), this.sessionData.fdgNACLocation);
        end
        function this = t4ResolveCompletedNAC(this)
            %% T4RESOLVECONVERTEDNAC is the principle caller of resolve.
            
            cd(this.sessionData.fdgNAC('typ', 'path'));
            this.recoverTorndown;
            mlraichle.T4ResolveBuilder.printv('t4ResolveCompletedNAC.pwd:  %s\n', pwd);
            this = this.resolve( ...
                'dest', sprintf('%sv%i', lower(this.sessionData.tracer), this.sessionData.vnumber), ...
                'source', this.sessionData.fdgNAC('typ', 'fp'), ...
                'firstCrop', this.firstCrop, ...
                'frames', this.frames);
        end
		  
 		function this = CompletedT4ResolveBuilder(varargin)
 			%% COMPLETEDT4RESOLVEBUILDER
 			%  Usage:  this = CompletedT4ResolveBuilder()

 			this = this@mlfourdfp.MMRResolveBuilder(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
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
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

