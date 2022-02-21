classdef HyperglycemiaDirector < mlraichle.StudyDirector
	%% HYPERGLYCEMIADIRECTOR is a high-level, study-level director for other directors and builders.
    %  Construct methods must be called in coordination with invocations of JSRecon12 on Windows

	%  $Revision$
 	%  was created 26-Dec-2016 12:39:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	

    properties (Dependent)
        sessionData
    end
    
    methods (Static)   
        function those = alignCrossModal(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.alignCrossModal', varargin{:}, 'tracer', 'FDG');
        end
        function those = alignCrossModalSubset(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.alignCrossModalSubset', varargin{:}, 'tracer', 'FDG');
        end
        function those = alignCrossModalPar(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParSess( ...
                @mlraichle.TracerDirector.alignCrossModal, varargin{:}, 'tracer', 'FDG');
        end
        function those = alignCrossModalRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.alignCrossModal', varargin{:}, 'tracer', 'FDG');
        end
        
        function         cleanConverted(varargin)
            %% cleanConverted
            %  @param named verifyForDeletion must be set to the fully-qualified study directory to clean.
            %  @param works in the pwd which should point to the study directory.
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
            
            ip = inputParser;
            addParameter(ip, 'verifyForDeletion', ['notavalidedirectory_' datestr(now,30)], @isdir);
            parse(ip, varargin{:});            
            pwd0 = pushd(ip.Results.verifyForDeletion);
            fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd);
            import mlsystem.*;
            
            dtsess = DirTools({'HYGLY*' 'NP995*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd); 

                    dtconv = DirTool('*-Converted*');
                    for idtconv = 1:length(dtconv.fqdns)
                        try
                            mlbash(sprintf('rm -rf %s', dtconv.fqdns{idtconv}));
                        catch ME
                            handwarning(ME);
                        end
                    end
                    popd(pwdv);
                end
                popd(pwds);
            end   
            popd(pwd0);
        end
        function         cleanMore(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            tracers = {'OC' 'OO' 'HO' 'FDG'};
            %tracers = {'FDG'};
            import mlraichle.*;
            for t = 1:length(tracers)
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', false);
                %HyperglycemiaDirector.constructCellArrayOfObjects( ...
                %    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', true);
            end
        end
        function         cleanMoreRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            %tracers = {'OC' 'OO' 'HO' 'FDG'};
            tracers = {'FDG'};
            import mlraichle.*;
            for t = 1:length(tracers)
                HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', false, 'pushData', false);
                %HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                %    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', true,  'pushData', false);
            end
        end
        function chpc  = cleanSinograms(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            chpc = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanSinograms', varargin{:});
        end
        function chpc  = cleanSinogramsRemotely(varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return chpc, an instance of mlpet.CHPC4TracerDirector.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            try
                chpc = CHPC4TracerDirector([], 'distcompHost', ip.Results.distcompHost, 'wallTime', '2:00:00');
                chpc = chpc.runSerialProgram(@mlraichle.TracerDirector.cleanSinograms, {}, 1);
            catch ME
                handwarning(ME);
            end
        end
        function those = cleanSymlinks(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanSymlinks', varargin{:});
        end
        function those = cleanSymlinksRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.cleanSymlinks', varargin{:});
        end
        function         cleanTracer(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanTracer', varargin{:});
        end 
        function         cleanTracerRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanTracerRemotely', varargin{:});
        end
        
        function those = constructAifs(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructAifs', 'tracer', 'HO', 'scanList', 1:1, varargin{:}); % TracerDirector service will iterate tracer, scanList.
            % mlsiemens.Herscovitch1985.constructPhysiologicals will
            % iterate tracers and s-numbers.
        end
        function those = constructAnatomy(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructAnatomy', 'tracer', 'FDG', 'ac', true, varargin{:});            
        end
        function those = constructAnatomyPar(varargin)   
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            tracers = ensureCell(ipr.tracer);
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess}; %#ok<*PFBNS>
                pwds = pushd(sessp);
                    
                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = SessionData( ...
                                'studyData', StudyData, ...
                                'sessionPath', sessp, ...
                                'snumber', iscan, ...
                                'tracer', tracers{itrac}, ...
                                'ac', ipr.ac, ...
                                'supEpoch', ipr.supEpoch);

                            if (isdir(sessd.tracerRawdataLocation))
                                % there exist spurious tracerLocations; select those with corresponding raw data

                                mlraichle.TracerDirector.constructAnatomy( ...
                                    'sessionData', sessd, varargin{:});
                            end
                        catch ME
                            handwarning(ME);
                        end
                    end
                end                   
                popd(pwds);
            end        
        end
        function those = constructAnatomyRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructAnatomy', 'tracer', 'FDG', 'ac', true, varargin{:});            
        end  
        function those = constructHerscovitchOpAtlasRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructHerscovitchOpAtlas', ...
                'ac', true, ...
                'tracer', 'FDG', varargin{:});    
            %  KLUDGE:  choosing FDG limits iterations over tracers and
            %  anticipates error conditions for mlraichle.SessionData
        end
        function those = constructCompositeResolved(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructCompositeResolved', 'ac', true, 'tracer', 'FDG', varargin{:});   
            %  KLUDGE:  choosing FDG limits iterations over tracers         
        end     
        function those = constructCompositeResolvedPar(varargin)
            %% constructCompositeResolvedPar iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating constructCompositeResolved for each.
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            tracers = ensureCell(ipr.tracer);
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                    
                if (lstrfind(dtv.dns{idtv}, 'HYGLY25'))
                    continue
                end

                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = SessionData( ...
                                'studyData', StudyData, ...
                                'sessionPath', sessp, ...
                                'snumber', iscan, ...
                                'tracer', tracers{itrac}, ...
                                'ac', ipr.ac, ...
                                'supEpoch', ipr.supEpoch);

                            if (isdir(sessd.tracerRawdataLocation))
                                % there exist spurious tracerLocations; select those with corresponding raw data

                                mlraichle.TracerDirector.constructCompositeResolved( ...
                                    'sessionData', sessd, varargin{:});
                            end
                        catch ME
                            handwarning(ME);
                        end
                    end
                end                       
                popd(pwds);
            end
        end
        function those = constructCompositeResolvedRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructCompositeResolved', 'ac', true, 'tracer', 'FDG', varargin{:}); 
            %  KLUDGE:  choosing FDG limits iterations over tracers           
        end
        function those = constructExports(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructExports', 'ac', true, varargin{:});   
        end
        function those = constructFdgOpT1001(varargin)   
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'tracer', 'FDG', ...
                        'ac', true);

                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructFdgOpT1001( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end                       
                popd(pwds);
            end        
        end
        function those = constructFdgOpT1001Par(varargin)   
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'tracer', 'FDG', ...
                        'ac', true);

                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructFdgOpT1001( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end                      
                popd(pwds);
            end        
        end
        function those = constructFreesurfer6(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlsurfer.SurferDirector.constructFreesurfer6', 'wallTime', '47:59:59', varargin{:});
        end
        function those = constructNiftyPETy(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructNiftyPETy', [varargin{:} {'ac' true}]);
        end
        function those = constructPhysiologicalSingle(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects2( ...
                'mlraichle.HyperglycemiaDirector.constructPhysiologicalSingle__', varargin{:}); 
        end
        function those = constructPhysiologicalSingle__(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            those = mlraichle.Herscovitch1985.constructSingle(ip.Results.sessionData);
        end
        function those = constructPhysiologicals(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp);
                    mlraichle.Herscovitch1985.constructPhysiologicals(sessd);
                catch ME
                    handwarning(ME);
                end         
                popd(pwds);
            end
        end
        function those = constructPhysiologicals1(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'tracer', {'HO' 'OO' 'OC'});
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp);
                    mlraichle.Herscovitch1985.constructPhysiologicals1(sessd, ip.Results.tracer);
                catch ME
                    handwarning(ME);
                end                  
                popd(pwds);
            end
        end
        function those = constructPhysiologicals2(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'resamplerType', 'VoxelResampler');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'resamplerType', ipr.resamplerType);
                    mlsiemens.Herscovitch1985_FDG.constructPhysiologicals2(sessd);
                catch ME
                    handwarning(ME);
                end                     
                popd(pwds);
            end
        end
        function those = constructPhysiologicalsPar(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp);
                    mlraichle.Herscovitch1985.constructPhysiologicals(sessd);
                catch ME
                    handwarning(ME);
                end                      
                popd(pwds);
            end
        end
        function those = constructPhysiologicals1Par(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'tracer', {'HO' 'OO' 'OC'});
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp);
                    mlraichle.Herscovitch1985.constructPhysiologicals1(sessd, ip.Results.tracer);
                catch ME
                    handwarning(ME);
                end                     
                popd(pwds);
            end
        end
        function those = constructPhysiologicals2Par(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'resamplerType', 'VoxelResampler');
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            disp(dtsess);
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                if (strcmp(dtv.dns{idtv}, 'Vall'))
                    continue
                end
                try
                    sessd = mlraichle.HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'resamplerType', ipr.resamplerType);
                    mlsiemens.Herscovitch1985_FDG.constructPhysiologicals2(sessd);
                catch ME
                    handwarning(ME);
                end                    
                popd(pwds);
            end
        end
        function those = constructPhysiologicalsRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructPhysiologicals', 'tracer', 'HO', 'scanList', 1:1, varargin{:});
            % mlsiemens.Herscovitch1985.constructPhysiologicals will
            % iterate tracers and s-numbers.
        end
        function those = constructReferenceTracerToT1001T4(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructReferenceTracerToT1001T4', varargin{:}, 'tracer', 'FDG');            
        end
        function those = constructResolved(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolved', varargin{:}); 
        end
        function those = constructResolvedPar(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', mlraichle.StudyDirector.TRACERS, @(x) iscell(x) || ischar(x));
            parse(ip, varargin{:});
            
            if (iscell(ip.Results.tracer))
                those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParTrac( ...
                    @mlraichle.TracerDirector.constructResolved, varargin{:});
            else
                those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParSess( ...
                    @mlraichle.TracerDirector.constructResolved, varargin{:});
            end
        end 
        function those = constructResolvedRemotely(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pushMinimalToRemote', varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructResolved', 'wallTime', '47:59:59', varargin{:});
        end
        function those = constructResolveReports(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolveReports', varargin{:});
        end
        function those = constructSuvrPar1(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, sessExpr));
            dtsessFqdns = dtsess.fqdns;
            parfor idtsess = 1:length(dtsessFqdns)
                sessp = dtsessFqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'rnumber', 1, ...
                        'tracer', ipr.tracer, ...
                        'ac', ipr.ac);    
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructSuvr1( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end                     
                popd(pwds);
            end 
        end 
        function those = constructSuvrPar2(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, sessExpr));
            dtsessFqdns = dtsess.fqdns;
            parfor idtsess = 1:length(dtsessFqdns)
                sessp = dtsessFqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'rnumber', 1, ...
                        'tracer', ipr.tracer, ...
                        'ac', ipr.ac);    
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructSuvr2( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end                 
                popd(pwds);
            end 
        end 
        function those = constructSuvr2(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, sessExpr));
            dtsessFqdns = dtsess.fqdns;
            for idtsess = 1:length(dtsessFqdns)
                sessp = dtsessFqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'rnumber', 1, ...
                        'tracer', ipr.tracer, ...
                        'ac', ipr.ac);    
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructSuvr2( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end          
                popd(pwds);
            end 
        end 
        function those = constructSuvr2018jun17(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'tracer', 'FDG', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, sessExpr));
            dtsessFqdns = dtsess.fqdns;
            for idtsess = 1:length(dtsessFqdns)
                sessp = dtsessFqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = HerscovitchContext( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'rnumber', 1, ...
                        'tracer', ipr.tracer, ...
                        'ac', ipr.ac);    
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                        mlraichle.TracerDirector.constructSuvr2018jun17( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end                  
                popd(pwds);
            end 
        end 
        function those = constructT1001s(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.HyperglycemiaDirector.prepareFreesurferData', varargin{:});
        end    
        function umap = constructUmaps(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            umap = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.UmapDirector.constructUmaps', 'ac', false, varargin{:});
        end        
        function those = constructUmapsRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.UmapDirector.constructUmaps', varargin{:});
        end    
        
        function         createImgRec__(fqfp, cellContents)
            import mlfourdfp.*;
            irl = ImgRecLogger(fqfp);
            irl.cons(strjoin(cellContents));
            irl.save;
        end
        function compos = debugOnAtl(varargin)
            census = mlraichle.StudyCensus( ...
                fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'census 2018apr2.xlsx'));
            census = census.readtable;   
            tbl = census.censusTable;
            fv = mlfourdfp.FourdfpVisitor;
            compos = mlfourd.NumericalNIfTId.load(fullfile(getenv('REFDIR'), 'TRIO_Y_NDC_333.4dfp.hdr'));
            compos.fqfilename = fullfile(getenv('PPG'), 'jjlee2', 'atlasTest', 'fdgAll.4dfp.hdr');
            d_ = 0;
            for d = 1:length(tbl.date)
                if (isnan(tbl.ready(d)))
                    continue
                end    
                d_ = d_ + 1;          
                sid = tbl.subjectID(d);
                atlBldr = mlpet.AtlasBuilder( ...
                    'sessionData', ...
                    mlraichle.SessionData( ...
                        'studyData', mlraichle.StudyData, ...
                        'sessionFolder', sid{1}, ...
                        'ac', true));
                    
                pwd0 = pushd(atlBldr.sessionPath);
                assert(lexist(atlBldr.tracer_to_atl_t4));
                tracerOnAtl_fp = [atlBldr.sessionData.tracerResolvedFinalAvgt('typ','fp') '_on_TRIO_Y_NDC_333'];
                fv.t4img_4dfp( ...
                    atlBldr.tracer_to_atl_t4, ...
                    atlBldr.sessionData.tracerResolvedFinalAvgt('typ','fqfp'), ...
                    'out', tracerOnAtl_fp, ...
                    'options', '-O333');
                ele = mlfourd.NumericalNIfTId.load([tracerOnAtl_fp '.4dfp.hdr']);
                compos.img(:,:,:,d_) = ele.img;
                popd(pwd0);
                
            end
            compos.save;
            compos = compos.timeSummed / d_;
            compos.filename = 'fdgMean.4dfp.hdr';
            compos.save;            
        end 
        function         fetchOutputs(those, varargin)
            %  @param those is cell-array of mlraichle.TracerDirector
            %  objects. 
            %  @param varargin are indices for those.
            
            if (~isempty(varargin))
                that = those(varargin{:});
                if (~isempty(that))
                    fprintf('HyperglycemiaDirector.fetchOutputs.those(%i,%i,%i,%i):\n', varargin{:});
                    disp(that{1}.job.fetchOutputs{:})
                end
                return
            end
            
            for a = 1:size(those,1)
                for b = 1:size(those,2)
                    for c = 1:size(those,3)
                        for d = 1:size(those,4)
                            that = those(a,b,c,d);
                            if (~isempty(that))
                                try
                                    fprintf('HyperglycemiaDirector.fetchOutputs.those(%i,%i,%i,%i):\n', a,b,c,d);
                                    disp(that{1}.job.fetchOutputs{:})
                                catch ME
                                    dispwarning(ME);
                                end
                            end
                        end
                    end
                end
            end
        end
        function those = gatherSuvr(varargin)
            import mlsystem.* mlraichle.* mlfourd.*;
           
            ip = inputParser;
            addParameter(ip, 'mat', '', @ischar);
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.mat))
                load(ip.Results.mat);
            else            

                census = mlraichle.StudyCensus( ...
                    fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'census 2018apr2.xlsx'));
                census = census.readtable;   
                tbl    = census.censusTable;
                params = {'hoa' 'oca' 'fdg' 'cmro2' 'oef' 'ogi'};
                atl    = fullfile(getenv('PPG'), 'jjlee2/atlasTest/source', 'HYGLY_atlas_333.4dfp.hdr');
                atl    = NumericalNIfTId.load(atl);

                % init, set filenames, set content cells
                paramsNiisAll = cell(length(params), 1);
                paramsNiis    = cell(length(params), 3); % params \otimes conditions
                cellContents  = cell(length(params), 3);
                for ip = 1:length(params)
                    paramsNiisAll{ip} = atl;
                    paramsNiisAll{ip}.img = zeros(size(atl));
                    paramsNiisAll{ip}.fqfilename = ...
                        fullfile(getenv('PPG'), 'jjlee2', 'forTyler', sprintf('%s_333.4dfp.hdr', params{ip}));
                    for ic = 1:3
                        paramsNiis{ip,ic} = atl;
                        paramsNiis{ip,ic}.img = zeros(size(atl));
                        paramsNiis{ip,ic}.fqfilename = ...
                            fullfile(getenv('PPG'), 'jjlee2', 'forTyler', sprintf('%s_cond%i_333.4dfp.hdr', params{ip}, ic));
                    end
                end            

                % glob metabolic data
                i0 = 0;
                i1 = 0;
                i2 = 0;
                i3 = 0;
                contentStr = '\nvolume := %i\nstudy date (yyyy:mm:dd) := %g:%02g:%02g\nsubject := %s\nvisit := %i\nparam := %s\ncondition := %i\n';
                for r = 1:length(tbl.date)
                    
                    if (~isnan(tbl.ready(r)))
                        sid = tbl.subjectID(r); sid = sid{1};
                        dt_ = datetime(tbl.date(r));
                        theCond = HyperglycemiaDirector.condition__(tbl, r); 
                        switch (theCond)
                            case 1
                                i0 = i0 + 1;
                                i1 = i1 + 1; fprintf('gatherSuvr i1->%i\n', i1);
                                for ip = 1:length(params)      
                                    img = HyperglycemiaDirector.selectedImg__(tbl, r, params{ip});
                                    if (~isempty(img))                                        
                                        paramsNiisAll{ip}.img(:,:,:,i0) = img;
                                        paramsNiis{ip,theCond}.img(:,:,:,i1) = img;
                                        cellContents{ip,theCond} = [cellContents{ip,theCond}; ...
                                            string(sprintf(contentStr, i1, dt_.Year, dt_.Month, dt_.Day, sid, tbl.v_(r),  params{ip}, theCond))];
                                    end
                                end
                            case 2
                                i0 = i0 + 1;
                                i2 = i2 + 1; fprintf('gatherSuvr i2->%i\n', i2);
                                for ip = 1:length(params)      
                                    img = HyperglycemiaDirector.selectedImg__(tbl, r, params{ip});
                                    if (~isempty(img))
                                        paramsNiisAll{ip}.img(:,:,:,i0) = img;
                                        paramsNiis{ip,theCond}.img(:,:,:,i2) = img;
                                        cellContents{ip,theCond} = [cellContents{ip,theCond}; ...
                                            string(sprintf(contentStr, i2, dt_.Year, dt_.Month, dt_.Day, sid, tbl.v_(r),  params{ip}, theCond))];  
                                    end
                                end            
                            case 3
                                i0 = i0 + 1;
                                i3 = i3 + 1; fprintf('gatherSuvr i3->%i\n', i3);
                                for ip = 1:length(params)      
                                    img = HyperglycemiaDirector.selectedImg__(tbl, r, params{ip});
                                    if (~isempty(img))
                                        paramsNiisAll{ip}.img(:,:,:,i0) = img;
                                        paramsNiis{ip,theCond}.img(:,:,:,i3) = img;
                                        cellContents{ip,theCond} = [cellContents{ip,theCond}; ...
                                            string(sprintf(contentStr, i3, dt_.Year, dt_.Month, dt_.Day, sid, tbl.v_(r),  params{ip}, theCond))];  
                                    end
                                end       
                            otherwise
                                warning('mlraichle:unsupportedSwitchcase', ...
                                    'HyperglycemiaDirector.gatherSuvr.case->%s, tbl.date(%i)->%s', theCond, r, tbl.date(r));
                        end          
                    end
                    
                end      
                
                fprintf('Ncontrol  -> %g\n', i1); %19
                fprintf('Nhypergly -> %g\n', i2); %13
                fprintf('Nhyperins -> %g\n', i3); %6            
            end     
            
            % write the globbed
            for ip = 1:length(params)
                paramsNiisAll{ip}.save;
                for ic = 1:3
                    paramsNiis{ip,ic}.save; 
                    HyperglycemiaDirector.createImgRec__(paramsNiis{ip,ic}.fqfileprefix, cellContents{ip,ic});
                end
            end
            
            % write averages            
            for ip = 1:length(params)
                for ic = 1:3
                    times = paramsNiis{ip,ic}.volumeSummed;
                    timesImg = times.img;
                    timesImg = timesImg(timesImg > 0);
                    paramsNiis{ip,ic} = paramsNiis{ip,ic}.timeSummed / length(timesImg);
                    paramsNiis{ip,ic}.filename = sprintf('%s_cond%i_condMean_333.4dfp.hdr', params{ip}, ic);
                    paramsNiis{ip,ic}.save;
                end
            end            

            those = {};
        end 
        function gr    = graphUmapDefects(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listUmapDefects', varargin{:});
            gr = mlraichle.HyperglycemiaDirector.constructGraphOfObjects(those);
        end
        function         job(those, varargin)
            %  @param those is cell-array of mlraichle.TracerDirector
            %  objects. 
            %  @param varargin are indices for those.
            
            if (~isempty(varargin))
                that = those(varargin{:});
                if (~isempty(that))
                    fprintf('HyperglycemiaDirector.job.those(%i,%i,%i,%i):\n', varargin{:});
                    disp(that{1}.job)
                end
                return
            end
            
            for a = 1:size(those,1)
                for b = 1:size(those,2)
                    for c = 1:size(those,3)
                        for d = 1:size(those,4)
                            that = those(a,b,c,d);
                            if (~isempty(that))
                                try
                                    fprintf('HyperglycemiaDirector.job.those(%i,%i,%i,%i):\n', a,b,c,d);
                                    disp(that{1}.job)
                                catch ME
                                    dispwarning(ME);
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function lst   = listUmapDefects(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listUmapDefects', varargin{:});
        end
        function [tbl,lst] = listRawdataAndConverted(varargin)
            %% LISTRAWDATAANDCONVERTED lists:
            %  session identifier, visit number, scan date, tracer raw data listing, tracer converted data intact.
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listRawdataAndConverted', varargin{:});
            
            datetimes = [];
            rawdataLocs = {};
            mhdrs = {};
            for se = 1:size(lst,1)
                for vi = 1:size(lst,2)
                    for tr = 1:size(lst,3)
                        for sc = 1:size(lst,4)
                            lstEle = lst{se,vi,tr,sc};
                            if (~isempty(lstEle) && isdatetime(lstEle.datetime))                    
                                datetimes = [datetimes; lstEle.datetime]; %#ok<*AGROW>
                                rawdataLocs = [rawdataLocs; lstEle.rawdataLocation];
                                mhdrs = [mhdrs; lstEle.filenameMhdr];
                            else
                                nat = NaT; nat.TimeZone = 'America/Chicago';
                                datetimes = [datetimes; nat];
                                rawdataLocs = [rawdataLocs; sprintf('session->%i visit->%i tracer->%i scan->%i', se, vi, tr, sc)];
                                mhdrs = [mhdrs; ' '];
                            end
                        end
                    end
                end
            end
            
            tbl = table(datetimes, rawdataLocs, mhdrs, 'VariableNames', {'datetime' 'rawdata_location' 'mhdr'});
            tbl = sortrows(tbl, 1);
            writetable(tbl, 'listRawdataAndConverted.xlsx');
            save('listRawdataAndConverted.mat');
        end
        function tbl   = listT4ResolveErrTable(varargin)
            tbl = mlraichle.TracerDirector.listT4ResolveErrTable;
        end
        function tbl   = listT4ResolveErrTable2(varargin)
            tbl = mlraichle.TracerDirector.listT4ResolveErrTable2;
        end
        function lst   = listTracersConverted(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listTracersConverted', varargin{:});
        end
        function lst   = listTracersResolved(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listTracersResolved', varargin{:});
        end
        function lst   = listTracersResolvedRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            import mlraichle.*;
            cellArr = HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.listTracersResolved', varargin{:});
            lst = HyperglycemiaDirector.fetchOutputsCellArrayOfObjectsRemotely( ...
                cellArr);
        end    
        
        function those = prepareFreesurferData(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.prepareFreesurferData', varargin{:});
        end        
        function those = pullFromRemote(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullFromRemote', varargin{:});
        end     
        function those = pullPattern(varargin)
            %  @param named 'pattern' is given to rsync to match objects to pull
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', varargin{:});
        end     
        function those = pullResolved(varargin)
            %  @param named 'pattern' is given to rsync to match objects to pull
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ac', true, @islogical);
            parse(ip, varargin{:});
            
            import mlraichle.*;
            if (~ip.Results.ac)
                those = HyperglycemiaDirector.pullResolvedNAC(varargin{:});
            else
                those = HyperglycemiaDirector.pullResolvedAC(varargin{:});
            end
        end  
        function those = pullT4RE(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullT4RE', 'ac', true, varargin{:});
        end
        function those = pullVall(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullVall', 'ac', true, varargin{:});
        end
        function those = pushToRemote(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pushToRemote', varargin{:});
        end
        function those = pushToRemotePar(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParSess( ...
                @mlraichle.TracerDirector.pushToRemote, varargin{:});
        end   
        function those = reconAll(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconAll', 'wallTime', '23:59:59', varargin{:});            
        end
        function those = reconAllRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.reconAll', 'wallTime', '23:59:59', varargin{:});            
        end 
        function lst   = repairUmapDefects(varargin)
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.repairUmapDefects', varargin{:});
        end
        function those = reportResolved(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reportResolved', varargin{:});
        end
        function those = reviewUmaps(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reviewUmaps', 'ac', false, varargin{:});   
        end
        function those = reviewACAlignment(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reviewACAlignment', 'ac', true, varargin{:});   
        end          
        function those = reviewTracerAlignments(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reviewTracerAlignments', 'tracer', 'FDG', 'ac', true, varargin{:});   
        end  
        function this  = sortDownloads(downloadPath, sessionFolder, v, varargin)
            %% SORTDOWNLOADS installs data from rawdata into SUBJECTS_DIR; start here after downloading rawdata.  
            
            ip = inputParser;
            addRequired(ip, 'downloadPath', @isdir);
            addRequired(ip, 'sessionFolder', @ischar);
            addRequired(ip, 'v', @isnumeric);
            addOptional(ip, 'kind', '', @ischar);
            parse(ip, downloadPath, sessionFolder, v, varargin{:});

            pwd0 = pwd;
            import mlraichle.*;
            sessp = fullfile(StudyRegistry.instance.subjectsDir, sessionFolder, '');
            if (~isdir(sessp))
                mlfourdfp.FourdfpVisitor.mkdir(sessp);
            end
            sessd = SessionData('studyData', StudyData, 'sessionPath', sessp);
            this  = HyperglycemiaDirector('sessionData', sessd);
            switch (lower(ip.Results.kind))
                case 'ct'
                    this  = this.instanceSortDownloadCT(downloadPath);
                case 'freesurfer'
                    this  = this.instanceSortDownloadFreesurfer(downloadPath);
                otherwise
                    this  = this.instanceSortDownloads(downloadPath);
                    this  = this.instanceSortDownloadFreesurfer(downloadPath);
            end
            cd(pwd0);
        end     
        function those = avgTracerRevision1Par(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            tracers = ensureCell(ipr.tracer);
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                    
                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = SessionData( ...
                                'studyData', StudyData, ...
                                'sessionPath', sessp, ...
                                'snumber', iscan, ...
                                'tracer', tracers{itrac}, ...
                                'ac', ipr.ac, ...
                                'supEpoch', ipr.supEpoch, ...
                                'tauIndices', ipr.tauIndices);                                
                            if (isdir(sessd.tracerRawdataLocation))
                                % there exist spurious tracerLocations; select those with corresponding raw data
                                mlraichle.TracerDirector.avgTracerRevision1( ...
                                    'sessionData', sessd, varargin{:});
                            end
                        catch ME
                            handwarning(ME);
                        end
                    end
                end                  
                popd(pwds);
            end 
        end 
        function those = avgTracerResolvedFinalPar(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = ip.Results;
            tracers = ensureCell(ipr.tracer);
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = SessionData( ...
                                'studyData', StudyData, ...
                                'sessionPath', sessp, ...
                                'snumber', iscan, ...
                                'tracer', tracers{itrac}, ...
                                'ac', ipr.ac, ...
                                'supEpoch', ipr.supEpoch, ...
                                'tauIndices', ipr.tauIndices);                                
                            if (isdir(sessd.tracerRawdataLocation))
                                % there exist spurious tracerLocations; select those with corresponding raw data
                                mlraichle.TracerDirector.avgTracerResolvedFinal( ...
                                    'sessionData', sessd, varargin{:});
                            end
                        catch ME
                            handwarning(ME);
                        end
                    end
                end                  
                popd(pwds);
            end 
        end 
        function those = urgentCheckFdgOnOrigPar(varargin)
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', '');
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            those = {};
            dtsess = DirTools( ...
                fullfile(StudyRegistry.instance.subjectsDir, ipr.sessionsExpr));
            
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);

                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'tracer', 'FDG', ...
                        'ac', true);  
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data
                        mlraichle.TracerDirector.urgentCheckFdgOnAtl( ...
                            'sessionData', sessd, varargin{:});
                    end
                catch ME
                    handwarning(ME);
                end               
                popd(pwds);
            end             
            
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                try
                    sessd = SessionData( ...
                        'studyData', StudyData, ...
                        'sessionPath', sessp, ...
                        'tracer', 'FDG', ...
                        'ac', true);  
                    if (isdir(sessd.tracerRawdataLocation))
                        % there exist spurious tracerLocations; select those with corresponding raw data

                    end
                catch ME
                    handwarning(ME);
                end                      
                popd(pwds);
            end 
            
        end 
        function those = viewExports(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.viewExports', 'ac', true, varargin{:});   
        end  
    end
    
    methods 
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %% 
        
        function this = instanceSortDownloads(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData);
                %RawDataSorter.CreateSorted( ...
                %    'srcPath', downloadPath, ...
                %    'sessionData', this.sessionData_);            
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloads.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end
        function this = instanceSortDownloadCT(this, downloadPath)
            try
                mlfourdfp.DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData);
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloadCT.downloadPath->%s may be missing folder SCANS', downloadPath);
            end
        end
        function this = instanceSortDownloadFreesurfer(this, downloadPath)
            try
                [~,downloadFolder] = fileparts(downloadPath);
                dt = mlsystem.DirTool(fullfile(downloadPath, 'ASSESSORS', '*freesurfer*'));
                for idt = 1:length(dt.fqdns)
                    DATAdir = fullfile(dt.fqdns{idt}, 'DATA', '');
                    if (~isdir(this.sessionData.freesurferLocation))
                        if (isdir(fullfile(DATAdir, downloadFolder)))
                            DATAdir = fullfile(DATAdir, downloadFolder);
                        end
                        movefile(DATAdir, this.sessionData.freesurferLocation);
                    end
                end
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloadFreesurfer.downloadPath->%s may be missing folder ASSESSORS', ...
                    downloadPath);
            end
        end
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  @param parameter 'sessionData' is a 'mlpipeline.ISessionData'

            this = this@mlraichle.StudyDirector(varargin{:});
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;          
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end
    
    methods (Static, Access = private)   
        function cond  = condition__(tbl, r)
            if (~isnan(tbl.control(r)) &&  isnan(tbl.hypergly(r)) &&  isnan(tbl.hyperins(r)))
                cond = 1;
                return
            end
            if ( isnan(tbl.control(r)) && ~isnan(tbl.hypergly(r)) &&  isnan(tbl.hyperins(r)))
                cond = 2;
                return
            end
            if ( isnan(tbl.control(r)) &&  isnan(tbl.hypergly(r)) && ~isnan(tbl.hyperins(r)))
                cond = 3;
                return
            end
            cond = -1;
        end     
        function those = pullResolvedAC(varargin)
            %  @param named 'pattern' is given to rsync to match objects to pull
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', '*_op_*_frame*.4dfp.*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'T1001*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'wmparc*.*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'aparc*.*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', '*_t4', varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'Log', varargin{:});
        end
        function those = pullResolvedNAC(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            %% pattern matches fullfile(this.sessionData.tracerLocation, pattern);
            import mlraichle.*;
            those = {};
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', '*.v')];
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', 'umapSynth.*')];
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', 'umapSynth*_b40.*')];            
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', '*r1.4dfp.*')];           
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', '*r2.4dfp.*')];
            those = [those ...
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', false, varargin{:}, 'pattern', 'Log')];
        end
        function img   = selectedImg__(tbl, r, param)
            try
                sid = tbl.subjectID(r);
                sd = mlraichle.SessionData( ...
                    'studyData', mlraichle.StudyData, ...
                    'sessionFolder', sid{1}, ...
                    'ac', true, ...
                    'tracer', '', ...
                    'rnumber', 1, ...
                    'snumber', 1);
                nn  = mlfourd.NumericalNIfTId.load(sd.tracerSuvrNamed(param));
                img = nn.img;
                if (sum(sum(sum(img))) < eps)
                    img = [];
                end
            catch ME
                img = [];
                dispwarning(ME);
            end
        end
    end

    %% HIDDEN, DEPRECATED
    
    methods (Hidden, Static)        
        function those = reconstructE1toN(varargin)
            %% RECONSTRUCTE1TON is a bug-fix detailed in method T4ResolveBuilder.t4ForReconstituteFramesAC2.
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects  
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconstructE1toN', varargin{:});
        end
        function those = reconstructE1E1toN(varargin)
            %% RECONSTRUCTE1TON is a bug-fix detailed in method T4ResolveBuilder.t4ForReconstituteFramesAC2.
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects  
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconstructE1E1toN', varargin{:});
        end
        function those = reconstructE1toNPar(varargin)
            %% RECONSTRUCTE1TONPAR is a bug-fix detailed in method T4ResolveBuilder.t4ForReconstituteFramesAC2.
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects  
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParTrac( ...
                @mlraichle.TracerDirector.cleanE1toN, varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParTrac( ...
                @mlraichle.TracerDirector.constructResolved, varargin{:});
        end
        function those = reconstructE1toNRemotely(varargin)
            %% RECONSTRUCTE1TON is a bug-fix detailed in method T4ResolveBuilder.t4ForReconstituteFramesAC2.
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects  
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.reconstructE1toN', varargin{:});
        end
        function those = reconstructE1E1toNRemotely(varargin)
            %% RECONSTRUCTE1TON is a bug-fix detailed in method T4ResolveBuilder.t4ForReconstituteFramesAC2.
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects  
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.reconstructE1E1toN', varargin{:});
        end
        function those = reconstructErrMat(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconstructErrMat', varargin{:}, 'tracer', 'FDG');
        end
        function those = reconstructErrMatPar(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsParSess( ...
                @mlraichle.TracerDirector.reconstructErrMat, varargin{:}, 'tracer', 'FDG');
        end
        function those = reconstructUnresolvedRemotely(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pushMinimalToRemote', varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.reconstructUnresolved', 'wallTime', '23:59:59', varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
    
 end

