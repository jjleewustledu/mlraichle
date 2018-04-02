classdef TracerDirector < mlpet.TracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 27-Sep-2017 02:38:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	methods (Static)
        
        %% factory methods        
        
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
        function out   = cleanSymlinks(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this.instanceCleanSymlinks;
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
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
        
        function those = constructAifs(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            
            those = mlsiemens.Herscovitch1985.constructAifs(ip.Results.sessionData);
        end 
        function this  = constructAnatomy(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'anatomy', 'brainmask', @ischar);
            addParameter(ip, 'noclobber', false, @islogical);
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            mlpet.TracerDirector.prepareFreesurferData(varargin{:})
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));    
            this.anatomy_ = ip.Results.anatomy;
            if (~ip.Results.noclobber)
                this.builder_.ignoreTouchfile = true;
            end
            this = this.instanceConstructAnatomy( ...
                'tag2', ['constructAnat_' this.anatomy_], ...
                'mask', this.anatomy_, ...
                'target', ip.Results.target);
        end 
        function out   = constructAtlasRepresentations(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
        
            sd = this.sessionData;
            fv = mlfourdfp.FourdfpVisitor;
            fv.mpr2atl_4dfp(sd.mprForReconall, 'options', sprintf('-T%s -S711-2B', sd.atlas('typ','fqfp')));
            fv.freesurfer2mpr_4dfp(sd.mprForReconall, sd.T1001, 'options', ['-T' sd.atlas('typ','fqfp')]);
            maps = {sd.cbfOpFdg('typ','fqfp') ...
                    sd.cbvOpFdg('typ','fqfp') ...
                    sd.oefOpFdg('typ','fqfp') ...
                    sd.cmro2OpFdg('typ','fqfp') ...
                    sd.cmrglcOpFdg('typ','fqfp') ...
                    sd.ogiOpFdg('typ','fqfp') ...
                    sd.agiOpFdg('typ','fqfp')};
            onatl = {sd.cbfOnAtl('typ','fqfp') ...
                     sd.cbvOnAtl('typ','fqfp') ...
                     sd.oefOnAtl('typ','fqfp') ...
                     sd.cmro2OnAtl('typ','fqfp') ...
                     sd.cmrglcOnAtl('typ','fqfp') ...
                     sd.ogiOnAtl('typ','fqfp') ...
                     sd.agiOnAtl('typ','fqfp')};
                 
            sdFdg = sd;
            sdFdg.tracer = 'FDG';
            sdFdg.rnumber = 1;
            sdFdg.attentuationCorrected = true;
            fdg_to_T1_t4  = fullfile(sdFdg.vLocation, sprintf('%s_to_%s_t4', sdFdg.tracerRevision('typ','fp'), sdFdg.T1001('typ','fp')));
            T1_to_atl_t4  = fullfile(sdFdg.vLocation, sprintf('%s_to_%s_t4', sdFdg.T1001('typ','fp'), sdFdg.atlas('typ','fp')));
            fdg_to_atl_t4 = fullfile(sdFdg.vLocation, sprintf('%s_to_%s_t4', sdFdg.tracerRevision('typ','fp'), sdFdg.atlas('typ','fp')));
            T1_to_fdg_t4  = fullfile(sdFdg.tracerLocation, sprintf('brainmaskr1r2_to_op_%s_t4', sdFdg.tracerRevision('typ','fp')));
            
            fv.t4_mul( ...
                fullfile(sdFdg.tracerLocation, sprintf('brainmaskr1_to_op_%s_t4', sdFdg.tracerRevision('typ','fp'))), ...
                fullfile(sdFdg.tracerLocation, sprintf('brainmaskr2_to_op_%s_t4', sdFdg.tracerRevision('typ','fp'))), ...
                T1_to_fdg_t4); 
            fv.t4_inv(T1_to_fdg_t4, 'out', fdg_to_T1_t4);
            fv.t4_mul(fdg_to_T1_t4, T1_to_atl_t4, fdg_to_atl_t4);
            out = [];
            for m = 1:length(maps)
                out = [out fv.t4img_4dfp(fdg_to_atl_t4, maps{m}, 'out', onatl{m}, 'options', '-O333')]; %#ok<AGROW>
            end
        end
        function this  = constructCompositeResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            import mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'anatomy', 'T1001', @ischar);
            addParameter(ip, 'noclobber', true, @islogical);
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            mlpet.TracerDirector.prepareFreesurferData(varargin{:})
            
            this = TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:})); 
            this.anatomy_ = ip.Results.anatomy;
            if (~ip.Results.noclobber)
                this.builder_.ignoreTouchfile = true;
            end
            this = this.instanceConstructCompositeResolved( ...
                'tag2', 'constructCR_', ...
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
        function this  = constructKinetics(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlraichle.TracerKineticsBuilder(varargin{:}));              
            this = this.instanceConstructKinetics;
            
        end
        function this  = constructHerscovitchOpAtlas(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            import mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'noclobber', true, @islogical);
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            
            this = TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:})); 
            if (~ip.Results.noclobber)
                this.builder_.ignoreTouchfile = true;
            end
            sd = this.sessionData;
            sd.tracer = 'FDG';
            sources = { sd.cbfOpFdg sd.cbvOpFdg sd.oefOpFdg sd.cmro2OpFdg sd.cmrglcOpFdg sd.ogiOpFdg sd.agiOpFdg };
            if (~lexist(sd.tracerResolvedFinalSumt, 'file'))
                this.builder_ = this.builder_.packageProduct(sd.tracerResolvedFinal);
                this.builder_ = this.builder_.sumProduct;
            end
            this = this.instanceConstructHerscovitchOpAtlas( ...
                'sources', sources, ...
                'intermediary', sd.tracerResolvedFinalSumt);
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
        function those = constructGlcOnly(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            
            labs.glc = 308;
            labs.hct = 37.55;
            those = mlsiemens.Herscovitch1985.constructGlcOnly(ip.Results.sessionData, labs);
        end 
        function those = constructOxygenOnly(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            
            [thisHO,thisOC,thisOO] = mlsiemens.Herscovitch1985.constructOxygenOnly(ip.Results.sessionData);
            those.thisHO = thisHO;
            those.thisOC = thisOC;
            those.thisOO = thisOO;
        end 
        function those = constructPhysiologicals(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            
            those = mlsiemens.Herscovitch1985.constructPhysiologicals(ip.Results.sessionData);
        end 
        function this  = constructResolved(varargin)
            this = mlraichle.TracerDirector.reconstructResolved(varargin{:});
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
        function this  = constructUmapSynthForDynamicFrames(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;
            mlpet.TracerDirector.prepareFreesurferData(varargin{:})
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));             
            this = this.instanceConstructUmapSynthForDynamicFrames;
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
        function this  = pushMinimalToRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instancePushMinimalToRemote;
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
        function this  = reconstructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;  
            mlpet.TracerDirector.prepareFreesurferData(varargin{:});          
            
            %mlraichle.UmapDirector.constructUmaps('sessionData', ip.Results.sessionData);
            
            tr = ip.Results.sessionData.tracer;
            if (~ip.Results.sessionData.attenuationCorrected && (strcmpi('OC', tr) || strcmpi('OO', tr)))
                varargin = [varargin {'f2rep', 1, 'fsrc', 2}]; % first frame has breathing tube which confuses T4ResolveBuilder.
            end
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));   
            this = this.instanceReconstructResolved;
        end 
        function this  = reconstructUnresolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            mlpet.TracerDirector.assertenv;  
            mlpet.TracerDirector.prepareFreesurferData(varargin{:})          
            
            mlraichle.UmapDirector.constructUmaps('sessionData', ip.Results.sessionData);
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));   
            this = this.instanceReconstructUnresolved;
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
        function this  = reportResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            import mlraichle.*;
            sessd = ip.Results.sessionData;
            if (~sessd.attenuationCorrected)
                this = TracerDirector.reportResolvedNAC(varargin{:});
            else
                this = TracerDirector.reportResolvedAC(varargin{:});
            end
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
                mlbash(sprintf('fslview_deprecated %s -b 0,20000 umapSynth.4dfp.img -b 0.07,0.15 -t 0.15 -l Cool', sd0.tracerRevision('typ', '.4dfp.img')));
            catch ME
                handwarning(ME);
            end
            popd(pwd0);
        end 
        function this  = reviewACAlignment(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            
            sd = this.sessionData;          
            if (strcmp(sd.tracer, 'HO'))
                bval = 100000;
            else
                bval = 50000;
            end
            if (strcmp(sd.tracer, 'FDG'))
                tval = 0.15;
            else
                tval = 0.6;
            end
            
            try                
                pwd0 = pushd(fullfile(sd.tracerLocation, ''));
                while (~lexist(sd.tracerResolvedFinal('typ','fn'), 'file') && ...
                    sd.supEpoch > 0)
                    sd.supEpoch = sd.supEpoch - 1;                 
                end
                assert(lexist(sd.tracerResolvedFinal('typ','fn'), 'file'), ...
                    'mlraichle.TracerDirector.reviewACAlignment.fatalError');
                if (~lexist(sd.tracerResolvedFinalSumt, 'file'))
                    this.builder_ = this.builder_.packageProduct(sd.tracerResolvedFinal);
                    this.builder_ = this.builder_.sumProduct;
                end
                mlbash(sprintf('fslview_deprecated %s.4dfp.img -b 0,%g %s.4dfp.img -t %g -l Cool', ...
                    sd.tracerResolvedFinal('typ','fp'), ...
                    bval, ...
                    sd.tracerResolvedFinalSumt('typ','fp'), ...
                    tval));
                popd(pwd0);
            catch ME                
                handexcept(ME);
            end
        end
        function this  = sumTracerResolvedFinal(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            sd = this.sessionData;
            pwd0 = pushd(fullfile(sd.tracerLocation, ''));
            try
                if (~lexist(sd.tracerResolvedFinalSumt, 'file'))
                    this.builder_ = this.builder_.packageProduct(sd.tracerResolvedFinal);
                    this.builder_ = this.builder_.sumProduct;
                end
            catch ME
                handwarning(ME);
            end
            popd(pwd0);
        end
        function this  = sumTracerRevision1(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            sd = this.sessionData;
            sd.rnumber = 1;
            pwd0 = pushd(fullfile(sd.tracerLocation, ''));
            try
                if (~lexist(sd.tracerRevisionSumt, 'file'))
                    this.builder_ = this.builder_.packageProduct(sd.tracerRevision);
                    this.builder_ = this.builder_.sumProduct;
                end
            catch ME
                handwarning(ME);
            end
            popd(pwd0);
        end
        function this  = testLaunchingRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instanceTestLaunching;
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
    end
    
    methods
        function this  = instanceConstructHerscovitchOpAtlas(this, varargin)
            %% INSTANCECONSTRUCTHERSCOVITCHOPATLAS
            %  @param named target is the filename of a target, recognizable by mlfourd.ImagingContext.ctor;
            %  the default target is this.tracerResolvedFinal('epoch', this.sessionData.epoch) for FDG;
            %  see also TracerDirector.tracerResolvedTarget.
            %  @param this.anatomy is char; it is the sessionData function-name for anatomy in the space of
            %  this.sessionData.T1; e.g., 'T1', 'T1001', 'brainmask'.
            %  @result ready-to-use t4 transformation files aligned to this.tracerResolvedTarget.
            
            bv = this.builder_.buildVisitor;
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sources', @iscell);
            addParameter(ip, 'intermediary', @ischar);
            parse(ip, varargin{:});  
            ss = ip.Results.sources;
            
            assert(~isempty(ss));
            pwd0 = pushd(myfileparts(ss{1}));
            bv.ensureLocalFourdfp(ip.Results.intermediary); 
            this.builder_ = this.builder_.packageProduct(ip.Results.intermediary); % build everything resolved to intermediary
            this.builder_ = this.builder_.resolveModalitiesToProduct( ...
                thus.sessionData.tracerResolvedFinalSumt, varargin{:});
            
            cRB = this.builder_.compositeResolveBuilder;
            for is = 1:length(ss)
                this.localResolvedOpAtlas(cRB, mlfourd.ImagingContext(ss{is}));
            end
            deleteExisting('*_b15.4dfp.*');
            popd(pwd0);
        end
        function         rerunConstructResolvedRemotely(this, varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                mlpet.TracerDirector.assertenv;
                mlpet.TracerDirector.prepareFreesurferData(varargin{:})
            
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
 		function this  = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector()

 			this = this@mlpet.TracerDirector(varargin{:});
 		end
    end 
    
    %% PRIVATE
    
    methods (Static, Access = private)   
        function obj  = replaceEmptyWithSessionDataImagingContext(sessd, obj, whichIC)
            assert(isa(sessd, 'mlpipeline.SessionData'));
            assert(ischar(whichIC))
            if (isempty(obj))   
                obj = sessd.(whichIC)('typ', 'mlfourd.ImagingContext');
            end
        end
        function this = reportResolvedAC(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});            
            
            try
                sessd = ip.Results.sessionData;
                ssh   = @mldistcomp.CHPC.ssh;
                sessd.subjectsDir = '/scratch/jjlee/raichle/PPGdata/jjlee2';
                [~,r] = ssh(sprintf('ls %s', sessd.tracerResolvedFinal));
            catch ME
                fprintf(ME.message);
                r = '';
            end
            this.char = r;
            this.string = splitlines(r);
            this.n = sum(this.string ~= '');
            this.complete = this.n == 1;
        end
        function this = reportResolvedNAC(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});            
            
            try
                sessd = ip.Results.sessionData;
                ssh   = @mldistcomp.CHPC.ssh;
                sessd.subjectsDir = '/scratch/jjlee/raichle/PPGdata/jjlee2';
                [~,r] = ssh(sprintf('ls %s/umapSynth_frame*.v', sessd.tracerLocation));            
            catch ME
                fprintf(ME.message);
                r = '';
            end
            this.char = r;
            this.string = splitlines(r);
            this.n = sum(this.string ~= '');
            this.complete = this.n == numel(sessd.taus);
        end
    end
    
    methods
        function c = localResolvedOpAtlas(this, cRB, ic)
            %  TODO:  refactor with localTracerResolvedFinalSumt
            
            assert(isa(cRB, 'mlfourdfp.CompositeT4ResolveBuilder'));
            assert(lexist_4dfp(ic.fileprefix));
            sd = this.sessionData;
            
            c = {};
            t4 = sprintf('%sr0_to_%s_t4', sd.tracerResolvedFinalSumt('typ','fp'), cRB.resolveTag);
            outfile = [ic.fileprefix 'op_TRIO_Y_NDC']; 
            if (lexist(strrep(t4,'r0','r2'), 'file') && ~lexist_4dfp(outfile))
                try
                    cRB.t4img_4dfp( ...
                        t4, ...
                        ic.fqfileprefix, ...
                        'out', outfile, ...
                        'options', sprintf('-n -O%s', sd.atlas('typ','fqfp')));
                    c{1} = outfile;
                catch ME
                    dispwarning(ME);
                end
            end
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

