classdef T4ResolveRepair < mlfourdfp.T4ResolveBuilder
	%% T4RESOLVEREPAIR was written, ad hoc, for defective runs of mlraichle.T4ResolveBuilder for which calls to 
    %  mlfourdfp.T4ResolveBuilder.revise succeeded but calls to .resolveAndPaste needed adjusting.  N.B. differences
    %  noted below for methods .resolve and .t4ResolveCompletedNAC.

	%  $Revision$
 	%  was created 10-Jan-2017 23:10:42
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

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
            T4ResolveRepair.diaryv('serialCompletedT4s');
            T4ResolveRepair.printv('serialCompletedT4s.ip.Results.sessionPath->%s\n', ip.Results.sessionPath);

            eVisit = mlsystem.DirTool(ip.Results.sessionPath);              
            if (mlraichle.T4ResolveUtilities.isVisit(eVisit.fqdns{iVisit}))
                eTracer = mlsystem.DirTool(eVisit.fqdns{iVisit});
                for iTracer = 1:length(eTracer.fqdns)
                    pth = eTracer.fqdns{iTracer};
                    T4ResolveRepair.printv('serialCompletedT4s.pth:  %s\n', pth);
                    if ( T4ResolveUtilities.isTracer(pth) && ...
                         T4ResolveUtilities.isNAC(pth) && ...
                        ~T4ResolveUtilities.isEmpty(pth) && ...
                         T4ResolveUtilities.hasOP(pth))

                        try
                            T4ResolveRepair.printv('serialCompletedT4s:  inner try pwd->%s\n', pwd);
                            sessd = SessionData( ...
                                'studyData',   mlraichle.StudyData, ...
                                'sessionPath', ip.Results.sessionPath, ...
                                'snumber',     T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                'tracer',      T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                'vnumber',     iVisit);
                            this = T4ResolveRepair('sessionData', sessd);
                            this = this.t4ResolveCompletedNAC; %#ok<NASGU>                                    
                            save(sprintf('mlraichle_CompletedT4ResolveBuilder_serialCompletedT4s_this_%s.mat', datestr(now, 30)), 'this');
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function triggeringMoveLogs
            mlraichle.T4ResolveRepair.triggering('moveLogs___', ...
                'conditions', {'isVisit' 'isAnyTracer' 'isNAC' 'isNotEmpty'});
        end
    end
    
	methods 
		  
 		function this = T4ResolveRepair(varargin)
 			%% T4RESOLVEREPAIR
 			%  Usage:  this = T4ResolveRepair()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
            this.mmrBuilder_ = mlfourdfp.MMRBuilder('sessionData', this.sessionData);
        end
        
        function ipr  = imageRegSingle(this, ipr)
            try
                extractedFp1 = sprintf('%s_frame%i', ipr.dest, ipr.frame1st);
                extractedFp2 = sprintf('%s_frame%i', ipr.dest, ipr.frame2nd);
                blurredFp1   = this.buildVisitor.fileprefixBlurred(extractedFp1, this.blurArg);
                blurredFp2   = this.buildVisitor.fileprefixBlurred(extractedFp2, this.blurArg);
                mlbash(sprintf('rm -rf %s', this.buildVisitor.filenameT4(extractedFp1, extractedFp2)));
                maskFp = this.lazyMaskForImages( ...
                    ipr.maskForImages, extractedFp2, extractedFp1, ipr.frame2nd, ipr.frame1st);
                this.buildVisitor.align_2051( ...
                    'dest',       blurredFp2, ...
                    'source',     blurredFp1, ...
                    'destMask',   maskFp, ...
                    'sourceMask', maskFp, ...
                    't4',         this.buildVisitor.filenameT4(extractedFp1, extractedFp2), ...
                    't4img_4dfp', false);
                % t4_resolve requires an idiomatic naming convention for t4 files,
                % based on the names of frame files
                % e. g., fdgv1r1_frame13_to_fdgv1r1_frame72_t4
                
                this.deleteTrash;
                
            catch ME
                copyfile( ...
                    this.buildVisitor.transverse_t4, ...
                    this.buildVisitor.filenameT4(extractedFp1, extractedFp2), 'f');
                handwarning(ME);
            end
        end 
        function        recoverTorndown(this)
            copyfile(fullfile(this.t4Path, '*_t4'), this.sessionData.fdgNACLocation);
        end
        function this = repairConvertedNAC(this, frame1st, frame2nd)
            %% REPAIRCONVERTEDNAC
            %  @param frame1st is numeric.
            %  @param frame2nd is numeric.            
            %  See also:  mlraichle.T4ResolveBuilder.repairSingle
            
            sessd = this.sessionData;
            pwd0 = pushd(sessd.tracerNAC('typ', 'path'));
            this.printv('repairConvertedNAC.pwd -> %s\n', pwd);
            this.mmrBuilder_.ensureTracerSymlinks;
            this = this.repairSingle( ...
                frame1st, frame2nd, ...
                'dest', sprintf('%sv%ir%i', lower(sessd.tracer), sessd.vnumber, sessd.rnumber));
            popd(pwd0);
        end
        function ipr  = repairSingle(this, varargin)
            
            import mlfourdfp.*;
            ip = inputParser;
            addRequired( ip, 'frame1st', @isnumeric);
            addRequired( ip, 'frame2nd', @isnumeric);
            addParameter(ip, 'dest', '', @(x) ischar(x) && ~isempty(x));
            addParameter(ip, 'maskForImages', 'maskForImages', @ischar);
            parse(ip, varargin{:});
            
            ipr = this.imageReg(ip.Results);
        end
        function this = resolve(this, varargin)
            %% RESOLVE differs from mlfourdfp.T4ResolveBuilder.resolve in that no while-loop calls .revise; 
            %  key calls are to .lazyStageImages, .lazyBlurImages, .resolveAndPaste and .teardownRevision.
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
            addParameter(ip, 'destBlur',   this.blurArg,    @isnumeric); % fwhh/mm
            addParameter(ip, 'sourceBlur', this.blurArg,    @isnumeric); % fwhh/mm
            addParameter(ip, 'maskForImages', 'maskForImages', @ischar);
            addParameter(ip, 'indicesLogical', this.indicesLogical, @isnumeric); % 1 to keep; 0 to skip
            addParameter(ip, 'rnumber',    this.NRevisions, @isnumeric);
            addParameter(ip, 't40',        this.buildVisitor.transverse_t4, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'atlas',      this.atlas('typ', 'fp'), @ischar);
            addParameter(ip, 'log',        '/dev/null',     @ischar);
            parse(ip, varargin{:});
            ipr = ip.Results;       
            this = this.expandFrames;
            ipr = this.expandBlurs(ipr);
            
            this.resolveLog = this.loggerFilename( ...
                ipr.dest, 'func', 'T4ResolveBuilder_resolve', 'path', this.sessionData.vLocation);
            ipr.dest     = sprintf('%sr%i', ipr.dest, ip.Results.NRevisions);
                           this.lazyBlurImages(ipr);
            ipr          = this.resolveAndPaste(ipr); 
            ipr          = this.teardownRevision(ipr);            
            
            this.buildVisitor.imgblur_4dfp(ipr.resolved, this.blurArg);
            this.product_ = this.fileprefixBlurred(ipr.resolved);
        end
        function this = t4ResolveCompletedNAC(this)
            %% T4RESOLVECONVERTEDNAC is the principle caller of resolve.
            %  It differs from mlfourdp.T4ResolveBuilder.t4ResolveCompletedNAC by calling .recoverTorndown
            %  and not calling .ensureTracerSymLinks.
            
            cd(this.sessionData.fdgNAC('typ', 'path'));
            this.recoverTorndown;
            mlraichle.T4ResolveRepair.printv('t4ResolveCompletedNAC.pwd:  %s\n', pwd);
            this = this.resolve( ...
                'dest', sprintf('%sv%i', lower(this.sessionData.tracer), this.sessionData.vnumber), ...
                'source', this.sessionData.fdgNAC('typ', 'fp'), ...
                'indicesLogical', this.indicesLogical);
        end
 	end 

    %% PRIVATE
    
    properties (Access = private)
        mmrBuilder_
    end
    
    methods (Static, Access = private)
        function this = triggering(varargin)
            
            studyd = mlraichle.StudyData;
            
            ip = inputParser;
            addRequired( ip, 'method', @ischar);
            addOptional( ip, 'args', {});
            addParameter(ip, 'subjectsDir', studyd.subjectsDir, @isdir);
            addParameter(ip, 'conditions', {}, @iscell);
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            if (~strcmp(ip.Results.subjectsDir, studyd.subjectsDir))
                studyd.subjectsDir = ip.Results.subjectsDir;
            end
            
            import mlsystem.* mlfourdfp.* ;           
            eSess = DirTool(ip.Results.subjectsDir);
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    eTracer = DirTool(eVisit.fqdns{iVisit});
                    for iTracer = 1:length(eTracer.fqdns)

                        pth___ = eTracer.fqdns{iTracer};
                        if (T4ResolveUtilities.matchesTag(pth___, ip.Results.tag) && ...
                            T4ResolveUtilities.pathConditions(pth___, ip.Results.conditions))
                            try
                                sessd = mlraichle.SessionData( ...
                                    'studyData',   studyd, ...
                                    'sessionPath', eSess.fqdns{iSess}, ...
                                    'snumber',     T4ResolveUtilities.scanNumber(eTracer.dns{iTracer}), ...
                                    'tracer',      T4ResolveUtilities.tracerPrefix(eTracer.dns{iTracer}), ...
                                    'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                                this = T4ResolveRepair('sessionData', sessd);
                                this.(ip.Results.method)(ip.Results.args{:});   
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end                
            end            
        end
    end
    
    methods (Access = private) 
        function moveLogs___(this, varargin)
            pwd0 = pushd(this.sessionData.tracerNACLocation);
            movefiles('*.log', this.logPath);
            movefiles('*.txt', this.logPath);
            popd(pwd0);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

