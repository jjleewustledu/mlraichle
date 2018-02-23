classdef TracerDirector < mlpet.TracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 27-Sep-2017 02:38:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	methods (Static)
        
        %% factory methods        
        
        function out   = cleanTracerRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this.instanceCleanTracerRemotely('distcompHost', ip.Results.distcompHost);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        function out   = cleanSinograms(varargin)
            %% cleanSinograms
            %  @param works in mlraichle.RaichleRegistry.instance.subjectsDir
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
                      
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            sessd = ip.Results.sessionData;
                    
            import mlsystem.*;
            pwdv = pushd(sessd.vLocation);
            fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 
            dtconv = DirTool('*-Converted*');
            for idtconv = 1:length(dtconv.fqdns)
                pwdc = pushd(dtconv.fqdns{idtconv});
                fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 
                tracer = strtok(sessd.tracerLocation('typ','folder'), '-');
                try
                    mlbash(sprintf('rm -r %s-00',    tracer));
                    mlbash(sprintf('rm -r %s-WB',    tracer));
                    mlbash(sprintf('rm -r %s-WB-LM', tracer));
                    mlbash(        'rm -r UMapSeries');
                catch  %#ok<CTCH>
                end

                dt00 = DirTool('*-00');
                for idt00 = 1:length(dt00.fqdns)
                    pwd00 = pushd(dt00.fqdns{idt00});
                    fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd);   
                    deleteExisting('*-00-sino*');  
                    popd(pwd00);
                end
                popd(pwdc);

            end
            popd(pwdv);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        function out   = cleanMore(varargin)
            %% cleanMore
            %  @param works in mlraichle.RaichleRegistry.instance.subjectsDir
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
                      
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            sessd = ip.Results.sessionData;
            sessd1 = sessd; sessd1.rnumber = 1;
            sessd2 = sessd; sessd2.rnumber = 2;
                    
            import mlsystem.*;
            pwdv = pushd(sessd.vLocation);
            fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd); 
            
            deleteExisting('umapSynth_op_T1001_b40_b40.4dfp.*');
            deleteExisting('ctRescaledv*');
            %deleteExisting('T1001_*.4dfp.*');
            %deleteExisting('T1001r*.4dfp.*');
            deleteExisting('*_b15.4dfp.*');
            if (isdir('UmapResolveSequencev1'))
                mlbash(sprintf('rm -r UmapResolveSequencev1'));
            end

            pwdt = pushd(sessd.tracerLocation);
            fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd); 
            try

                deleteExisting('*_g0_1.4dfp.*');
                deleteExisting('*_g0.1.4dfp.*');
                deleteExisting('*_b43.4dfp.*');
                deleteExisting('umapSynth_frame*.4dfp.*');
                deleteExisting('umapSynth*.log');
                deleteExisting([sessd.tracerVisit('typ','fp') 'r*_b4*.4dfp.*']);
                deleteExisting('*-LM-00-umap.4dfp.*');
                deleteExisting('*-LM-00-umap_f1.4dfp.*');
                deleteExisting('*-LM-00-umapfz.4dfp.*');
                deleteExisting([sessd1.tracerRevision('typ','fp') '_frame*.4dfp.*']);
                
                dtE = DirTool('E*');
                for idtE = 1:length(dtE.fqdns)
                    if (length(epochDir2Numeric(dtE.dns{idtE})) > 1)
                        pwdE = pushd(dtE.dns{idtE});                            
                        deleteExisting('*_g0_1.4dfp.*');
                        deleteExisting('*_g0.1.4dfp.*');
                        deleteExisting('*_b15.4dfp.*');
                        deleteExisting('*_b55.4dfp.*');
                        deleteExisting('ctMasked*.4dfp.*');
                        %deleteExisting('T1001*.4dfp.*'); % no!
                        %deleteExisting('t2*.4dfp.*');
                        popd(pwdE);
                        continue
                    end
                    pwdE = pushd(dtE.fqdns{idtE});
                    sessd1.epoch = epochDir2Numeric(dtE.dns{idtE});
                    sessd2.epoch = epochDir2Numeric(dtE.dns{idtE});
                    deleteExisting('maskForImages*');
                    deleteExisting([sessd1.tracerRevision('typ','fp') '*.4dfp.*']);
                    deleteExisting([sessd2.tracerRevision('typ','fp') '*.4dfp.*']);
                    deleteExisting('*_g0_1.4dfp.*');
                    deleteExisting('*_g0.1.4dfp.*');
                    deleteExisting('*_b15.4dfp.*');
                    deleteExisting('*_b55.4dfp.*');
                    deleteExisting('ctMasked*.4dfp.*');
                    %deleteExisting('T1001*.4dfp.*'); % no!
                    %deleteExisting('t2*.4dfp.*');
                    popd(pwdE);
                end  

            catch ME
                handwarning(ME);
            end
            popd(pwdt);
                
            popd(pwdv);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        
        function this  = constructNiftyPETy(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.NiftyPETyBuilder(varargin{:}));              
            this = this.instanceConstructNiftyPETy;
        end 
        function this  = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            tr = ip.Results.sessionData.tracer;
            if (~ip.Results.sessionData.attenuationCorrected && (strcmpi('OC', tr) || strcmpi('OO', tr)))
                varargin = [varargin {'f2rep', 1, 'fsrc', 2}]; % first frame has breathing tube which confuses T4ResolveBuilder.
            end
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));              
            this = this.instanceConstructResolved;
        end 
        function this  = constructUmapSynthFull(varargin)
            %  @deprecated
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));             
            this = this.instanceConstructUmapSynthFull;
        end
        function this  = constructResolvedRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instanceConstructResolvedRemotely( ...
                @mlraichle.SessionData, @mlraichle.TracerDirector.constructResolved);
        end 
        function rpts  = constructResolveReports(varargin)
            %  @param  varargin for mlfourdfp.T4ResolveReporter.
            %  @return saved *.fig, *.png, *.mat.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerReportsBuilder(varargin{:}));          
            rpts = this.instanceMakeReports;
        end
        function this  = constructKinetics(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlraichle.TracerKineticsBuilder(varargin{:}));              
            this = this.instanceConstructKinetics;
            
        end
        function this  = constructAnatomy(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'anatomy', 'brainmask', @ischar);
            addParameter(ip, 'noclobber', true, @islogical);
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));    
            this.anatomy_ = ip.Results.anatomy;
            if (~ip.Results.noclobber)
                this.builder_.ignoreTouchfile = true;
            end
            this = this.instanceConstructAnatomy( ...
                'tag2', ['constructAnatomy_' ip.Results.anatomy], ...
                'mask', ip.Results.anatomy, ...
                'target', ip.Results.target);
        end 
        function this  = constructExports(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));    
            this = this.instanceConstructExports;
        end 
        function this  = viewExports(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            sd = this.sessionData;
            pwd0 = pushd(fullfile(sd.vLocation, 'export', ''));
            try
                mlbash(sprintf('fslview_deprecated %s.4dfp.img %s_%s.4dfp.img', ...
                    sd.tracerResolvedFinal('typ','fp'), sd.T1001('typ','fp'), sd.resolveTag));
            catch ME
                handwarning(ME);
            end
            popd(pwd0);
        end 
        function bldr  = reconstituteImgRec(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            bldr =  mlpet.TracerBuilder(varargin{:});    
            bldr.product_ = mlfourd.ImagingContext(bldr.tracerResolvedFinal);
            bldr.reconstituteImgRec();
        end
        function this  = reconAll(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerSurferBuilder(varargin{:}));
            
            this = this.builder.findLegacySurfer001;
            if (isdir(this.builder.legacySessionPath))
                this.builder.linkLegacySurfer001;
                this.builder.reconAllSurferObjects;
                return
            end
            this.builder.linkRawdataMPR;
            this.builder.reconAllSurferObjects;
        end 
        
        function this  = reviewUmaps(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            sd0 = this.sessionData;
            sd0.attenuationCorrected = false;
            sd1 = this.sessionData;
            sd1.attenuationCorrected = true;
            pwd0 = pushd(sd0.tracerLocation);
            try
                mlbash(sprintf('fslview_deprecated umapSynth.4dfp.img %s', sd0.tracerRevision('typ', '.4dfp.img')));
            catch ME
                handwarning(ME);
            end
            popd(pwd0);
        end 
        function list  = listUmapDefects(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            sessd = ip.Results.sessionData;
            
            import mlraichle.*;
            list = '';
            sessd.attenuationCorrected = false;
            dtumap = mlsystem.DirTool(sessd.umap('frame*.v', 'typ', 'fqfp')); % abuse of umap args
            if (isdir(sessd.tracerRawdataLocation)) 
                % there exist spurious tracerLocations; select those with corresponding raw data
                
                msg = sprintf('%s, V%i, %s%i, length->%i', ...
                    sessd.sessionFolder, sessd.vnumber, sessd.tracer, sessd.snumber, length(dtumap.fqfns));
                switch(sessd.tracer)
                    case {'OO' 'HO'}
                        if (isempty(dtumap.fqfns) || 10 ~= length(dtumap.fqfns))
                            list = msg;
                        end
                    case  'OC'
                        if (isempty(dtumap.fqfns) || 14 ~= length(dtumap.fqfns))
                            list = msg;
                        end
                    case  'FDG'
                        if (isempty(dtumap.fqfns) || length(dtumap.fqfns) < 65)
                            list = msg;
                        end
                    otherwise
                        warning('mlraichle:unsupportedSwitchcase', ...
                            'TracerDirector.listUmapDefects.sessd.tracer->%s', sessd.tracer);
                end
            end
        end
        function list  = repairUmapDefects(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            sessd = ip.Results.sessionData;            
            
            import mlraichle.*;
            list = '';
            sessd.attenuationCorrected = false;
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));  
            dtumap = mlsystem.DirTool(sessd.umap('frame*.v', 'typ', 'fqfp')); % abuse of umap args
            if (isdir(sessd.tracerRawdataLocation)) 
                % there exist spurious tracerLocations; select those with corresponding raw data
                
                msg = sprintf('%s, V%i, %s%i, length->%i', ...
                    sessd.sessionFolder, sessd.vnumber, sessd.tracer, sessd.snumber, length(dtumap.fqfns));
                switch(sessd.tracer)
                    case {'OO' 'HO'}
                        if (isempty(dtumap.fqfns) || 10 ~= length(dtumap.fqfns))
                            list = msg;
                            this.rerunConstructResolvedRemotely(varargin{:});
                        end
                    case  'OC'
                        if (isempty(dtumap.fqfns) || 14 ~= length(dtumap.fqfns))
                            list = msg;
                            this.rerunConstructResolvedRemotely(varargin{:});
                        end
                    case  'FDG'
                        if (isempty(dtumap.fqfns) || length(dtumap.fqfns) < 65)
                            list = msg;
                            this.rerunConstructResolvedRemotely(varargin{:});
                        end
                    otherwise
                        warning('mlraichle:unsupportedSwitchcase', ...
                            'TracerDirector.listUmapDefects.sessd.tracer->%s', sessd.tracer);
                end
            end
        end
        function list  = listRawdataAndConverted(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            sessd = ip.Results.sessionData;
            sessd.attenuationCorrected = false;
            sessd.frame = nan;

            datet = NaT;
            datet.TimeZone = 'America/Chicago';
            fnMhdr = 'NO MHDR FOUND';
            try
                dirt  = mlsystem.DirTool([sessd.tracerListmodeMhdr '*']);
                if (~isempty(dirt.fqfns))
                    fnMhdr = cell2str(dirt.fqfns, 'AsRow', true);
                end      
                datet = sessd.readDatetime0;      
                list  = struct( ...
                    'datetime', datet, ...
                    'rawdataLocation', sessd.tracerRawdataLocation, ...
                    'filenameMhdr', fnMhdr);
            catch ME
                dispwarning(ME);
                list = struct( ...
                    'datetime', datet, ...
                    'rawdataLocation', sessd.tracerRawdataLocation, ...
                    'filenameMhdr', ME.message);
            end
        end
        function lst   = listTracersConverted(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});

            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            lst = this.instanceListTracersConverted;
        end
        function lst   = listTracersResolved(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});

            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            lst = this.instanceListTracersResolved;      
        end
        function this  = pullFromRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instancePullFromRemote;
        end 
        function this  = pullPattern(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            addParameter(ip, 'pattern', '', @ischar);
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));              
            this = this.instancePullPattern('pattern', ip.Results.pattern);
        end 
        function this  = pushToRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instancePushToRemote;
        end 
    end
    
    methods
        
        %%
        
        function         rerunConstructResolvedRemotely(this, varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                sessd = this.sessionData;
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData); 
                fprintf('WARNING: rerunConstructResolvedRemotely will delete %s/E*\n', ...
                    chpc.chpcSessionData.tracerLocation);
                try
                    chpc.cleanEpochs;
                catch 
                end
                mlraichle.HyperglycemiaDirector.constructResolvedRemotely( ...
                                'sessionsExpr', [sessd.sessionFolder '*'], ...
                                'visitsExpr', sprintf('V%i*', sessd.vnumber), ...
                                'tracer', sessd.tracer, ...
                                'ac', sessd.attenuationCorrected, ...
                                'scanList', sessd.snumber, ...
                                'wallTime', '12:00:00');
            catch ME
                handwarning(ME);
            end
        end
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector()

 			this = this@mlpet.TracerDirector(varargin{:});
 		end
    end 
    
    %% PRIVATE
    
    methods (Access = private)        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

