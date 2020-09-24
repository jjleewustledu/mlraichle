classdef AerobicGlycolysisKit < handle & mlpet.AerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 10:54:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
    
	methods (Static)
        function msk       = buildTrainingMask(nmae)
            assert(contains(nmae.fileprefix, 'NMAE'))
            msk = nmae.numlt(0.95);
            msk.fileprefix = strrep(nmae.fileprefix, 'fdg', 'mask');
        end
        function [cbf,msk] = constructCbfAndSupportInfo(varargin)
            %% CONSTRUCTCBFSUPPORTINFO
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbf in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            
            this = mlraichle.AerobicGlycolysisKit.createFromSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            raichle = this.loadImagingRaichle();
            pred = raichle.buildPrediction(); 
            pred.save(); 
            resid = raichle.buildResidual(); 
            resid.save(); 
            [mae,nmae] = raichle.buildMeanAbsError(); 
            mae.save(); 
            nmae.save();
            cbf = this.metric2cbf(raichle.fs); 
            cbf.save(); 
            msk = this.buildTrainingMask(raichle.sessionData, nmae);
            msk.save();
            popd(pwd0)
        end
        function cbf       = constructCbfByQuadModel(varargin)
            %% CONSTRUCTCBFBYQUADMODEL
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbf in mL/min/hg as mlfourd.ImagingContext2.
                      
            this = mlraichle.AerobicGlycolysisKit.createFromSession(varargin{:});            
            sesd = this.sessionData;
            pwd0 = pushd(sesd.subjectPath);             
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            cbf = this.buildCbfByQuadModel();
            cbf.save()
            cbf = cbf.blurred(4.3);
            cbf.save()                      
            popd(pwd0)
        end
        function [cmrglc,Ks,msk] = constructCmrglcAndSupportInfo(varargin)
            %% CONSTRUCTCMRGLCANDSUPPORTINFO
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param lastKsTag is char and used by this.ksOnAtlas, e.g., '', '_b43'
            %  @return cmrglc in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return Ks in (s^{-1}) as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            %  @return pred as mlfourd.ImagingContext2.
            %  @return resid as mlfourd.ImagingContext2.
            %  @return mae as mlfourd.ImagingContext2.
            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));            
            huang = this.loadImagingHuang();
            pred = huang.buildPrediction(); 
            pred.save(); 
            resid = huang.buildResidual(); 
            resid.save(); 
            [mae,nmae] = huang.buildMeanAbsError(); 
            mae.save(); 
            nmae.save();
            Ks = this.k1_to_K1(huang.ks, huang.v1 ./ 0.0105);
            Ks.save()
            chi = this.ks2chi(huang.ks); 
            chi.save(); 
            cmrglc = this.ks2cmrglc(huang.ks, huang.v1 ./ 0.0105, this.devkit_.radMeasurements); 
            cmrglc.save();
            msk = this.buildTrainingMask(nmae);
            msk.save();
            popd(pwd0)
        end
        function [fs,msk]  = constructFsByRegion(varargin)
            %% CONSTRUCTFBYREGION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param region is char:  'wmparc', 'wbrain'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Ks and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = AerobicGlycolysisKit.createFromSession(sesd);
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            fs = this.(['buildFsBy' Region])(); 
            fs.save()
            fs = fs.blurred(4.3);
            fs.save()             
            msk = this.ensureTailoredMask();            
            popd(pwd0)
        end  
        function [kss,msk] = constructKsByRegion(varargin)
            %% CONSTRUCTKSBYREGION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param region is char:  'wmparc', 'wbrain'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'region', '', @(x) ischar(x) && ~isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            Region = [upper(ipr.region(1)) ipr.region(2:end)];
            
            % build Ks and their masks
            ss = strsplit(ipr.foldersExpr, '/');           
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            msk = {};
            kss = {};
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true, ...
                    'region', ipr.region); 
                this = AerobicGlycolysisKit.createFromSession(sesd);
                sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
                this.constructWmparc1OnAtlas(sesd)
                
                fdgstr = split(sesd.tracerOnAtlas('typ', 'fqfn'), ['Singularity' filesep]);
                kss_ = this.(['buildKsBy' Region])('filesExpr', fdgstr{2}); 
                kss_.save()
                kss_ = kss_.blurred(4.3);
                kss_.save()
                kss = [kss kss_]; %#ok<AGROW>                
                msk_ = this.ensureTailoredMask();
                msk = [msk msk_]; %#ok<AGROW>
            end
            popd(pwd0)
        end  
        function [kss,msk] = constructKsByWbrain(varargin)
            %% CONSTRUCTKSWBRAIN
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            [kss,msk] = mlraichle.AerobicGlycolysisKit.constructKsByRegion( ...
                varargin{:}, 'region', 'wbrain');
        end    
        function [kss,msk] = constructKsByWmparc1(varargin)
            %% CONSTRUCTKSBYWMPARC1
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            [kss,msk] = mlraichle.AerobicGlycolysisKit.constructKsByRegion( ...
                varargin{:}, 'region', 'wmparc1');
        end
        function             constructKsByVoxels(varargin)
            %% CONSTRUCTKSBYVOXELS 
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param useParfor is logical with default := ~ifdeployed().
            %  @param assemble is logical with default := false.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addRequired(ip, 'cpuIndex', @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'roisExpr', 'brain', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelTime', 180, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'wallClockLimit', 168*3600, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'useParfor', ~isdeployed(), @islogical)
            addParameter(ip, 'assemble', false, @islogical)
            addParameter(ip, 'doStaging', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if ischar(ipr.cpuIndex)
                ipr.cpuIndex = str2double(ipr.cpuIndex);
            end
            if ischar(ipr.voxelTime)
                ipr.voxelTims = str2double(ipr.voxelTime);
            end
            if ischar(ipr.wallClockLimit)
                ipr.wallClockLimit = str2double(ipr.wallClockLimit);
            end            
    
            % update registry with passed parameters
            registry = mlraichle.StudyRegistry.instance();
            registry.voxelTime = ipr.voxelTime;
            registry.wallClockLimit = ipr.wallClockLimit;   
            registry.useParfor = ipr.useParfor || ipr.assemble;
            
            % estimate num nodes or build Ks  
            ss = strsplit(ipr.foldersExpr, '/');          
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true); 
                kit = AerobicGlycolysisKit.createFromSession(sesd);
                sstr = split(sesd.tracerOnAtlas('typ', 'fqfn'), ['Singularity' filesep]);
                kit.estimateNumNodes(sstr{2}, ipr.roisExpr)
                
                if ipr.doStaging
                    sesd.jitOn222(sesd.tracerOnAtlas());
                    continue
                end
                if ipr.assemble
                    kit.ensureCompleteSubjectsStudy(varargin{:})
                    kit.assembleSubjectsStudy(varargin{:})
                else
                    kit.buildKsByVoxels( ...
                        'filesExpr', sstr{2}, ...
                        'cpuIndex', ipr.cpuIndex, ...
                        'roisExpr', ipr.roisExpr, ...
                        'averageVoxels', false)
                end
            end
            popd(pwd0)
        end   
        function ic        = constructRegularizedSolution(varargin)
            %% CONSTRUCTSOLUTIONCHOICE
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return mlfourd.ImagingContext2 contains lowest mean abs error solutions drawn from
            %          ksdt*_222_b43_brain and ksdt*_222_b43_wmparc.
            
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            
            % expand choice to [128 128 75 4]
            choice = this.constructSolutionChoice(varargin{:});
            choice = choice.fourdfp;
            img = choice.img;
            for ik = 1:4
                choice.img(:,:,:,ik) = img;
            end
            
            % construct regularized ks & save
            ksbrain = ImagingFormatContext([this.sessionData.ksOnAtlas('typ', 'fqfp') '_b43_brain.4dfp.hdr']);
            kswmparc1 = ImagingFormatContext([this.sessionData.ksOnAtlas('typ', 'fqfp') '_b43_wmparc1_b43.4dfp.hdr']);            
            ks = copy(ksbrain);
            ks.fileprefix = strrep(ks.fileprefix, 'brain', 'regular');
            ks.img(logical(choice.img)) = kswmparc1.img(logical(choice.img));
            ks.save() % 4dfp
            sz = size(ks);
            img = reshape(ks.img, [sz(1) sz(2) sz(3) 4]);
            save([ks.fileprefix '.mat'], 'img') % Patrick's mat
            
            % construct chi & save
            chi = this.ks2chi(ks);
            chi.save()
            chi = chi.blurred(4.3);
            chi.save()
            
            % return ImagingContext2
            ic = ImagingContext2(ks);
        end
        function ic        = constructSolutionChoice(varargin)
            %% CONSTRUCTSOLUTIONCHOICE
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return mlfourd.ImagingContext2 chooses the solution that has lower mean abs error:
            %          0 -> brain has lower error;
            %          1 -> wmparc1 has lower error.
            
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            
            brainMAE = ImagingFormatContext([this.sessionData.fdgOnAtlas('typ', 'fqfp') '_b43_brain_meanAbsError.4dfp.hdr']);
            wmparc1MAE = ImagingFormatContext([this.sessionData.fdgOnAtlas('typ', 'fqfp') '_b43_wmparc1_meanAbsError.4dfp.hdr']);
            wmparc1MAE.img(wmparc1MAE.img == 0) = inf;
            choice = copy(brainMAE);
            choice.fileprefix = strrep(choice.fileprefix, 'brain_meanAbsError', 'choice');
            choice.img = single(wmparc1MAE.img < brainMAE.img);
            ic = ImagingContext2(choice);
            ic.save()
            
            popd(pwd0)
        end        
        function             constructSubjectByRegion(varargin)
            %% CONSTRUCTSUBJECTBYREGION constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            %  @param region is char:  'wmparc', 'wbrain'.
            
            import mlraichle.*
            import mlraichle.AerobicGlycolysisKit.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'region', 'wmparc1', @(x) ischar(x) && ~isempty(x))
            addParameter(ip, 'saveMat', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Region = [upper(ipr.region(1)) ipr.region(2:end)];
            
            ss = strsplit(ipr.foldersExpr, '/');           
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = mlraichle.SubjectData('subjectFolder', ss{2});             
            sesfs = subd.subFolder2sesFolders(ss{2});
            foldersExpr = ipr.foldersExpr;
            
            for sesf = sesfs(contains(sesfs, ipr.sessionsExpr))
                try
                    sesd = SessionData( ...
                        'studyData', StudyData(), ...
                        'projectData', ProjectData('sessionStr', sesf{1}), ...
                        'subjectData', subd, ...
                        'sessionFolder', sesf{1}, ...
                        'tracer', 'FDG', ...
                        'ac', true, ...
                        'region', ipr.region); 
                    if sesd.datetime < mlraichle.StudyRegistry.instance.earliestCalibrationDatetime
                        continue
                    end
                    if ipr.saveMat
                        fdg = sesd.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
                        AerobicGlycolysisKit.ic2mat(fdg)
                    end
                    
                    AerobicGlycolysisKit.(['constructKsBy' Region])( ...
                        foldersExpr, [], 'sessionsExpr', sesf{1}); % memory ~ 5.5 GB
                    
                    [cmrglc,Ks,msk] = AerobicGlycolysisKit.constructCmrglcAndSupportInfo( ...
                        foldersExpr, [], 'sessionsExpr', sesf{1});
                catch ME
                    handwarning(ME)
                end
            end            
            popd(pwd0)            
        end
        function             constructSubjectByWbrain(varargin)
            %% CONSTRUCTSUBJECTBYWBRAIN constructs the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            
            mlraichle.AerobicGlycolysisKit.constructSubjectByRegion(varargin{:}, 'region', 'wbrain')            
        end
        function             constructSubjectByWmparc1(varargin)   
            %% CONSTRUCTSUBJECTBYWMPARC1 constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            
            mlraichle.AerobicGlycolysisKit.constructSubjectByRegion(varargin{:}, 'region', 'wmparc1')               
        end
        function this      = createFromSession(varargin)
            this = mlraichle.AerobicGlycolysisKit('sessionData', varargin{:});
        end
        function these     = createFromSubjectSession(varargin)
            %% CREATEFROMSUBJECTSESSION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return these is {mlraichle.AerobicGlycolysisKit, ...}
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ss = strsplit(ipr.foldersExpr, '/');         
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, ''));            
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            these = {};
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true, ...
                    'region', ipr.region); 
                this = AerobicGlycolysisKit.createFromSession(sesd);
                these = [these this]; %#ok<AGROW>
            end
            popd(pwd0)
        end    
        function             plotDxDTimes(varargin)
            %% PLOTDXDTIMES plots diagnosstics for \Delta t shifts of AIF.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.AerobicGlycolysisKit.buildKsByWmparc1().    
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            addParameter(ip, 'Delta', 0.05, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results; 
            DELTA = ipr.Delta;
            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
            sesd = this.sessionData;
            pwd0 = pushd(sesd.tracerOnAtlas('typ', 'filepath'));            
            
            % select ROI
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            roi = copy(wmparc1);
            roi.img = single(wmparc1.img == ipr.voxelIndex);
            fprintf('plotDxPrediction:  #roi = %g\n', dipsum(roi.img))
            if dipsum(roi.img) == 0
                return
            end
            roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, ipr.voxelIndex); 
            
            % select data
            cbv = sesd.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
            cbv = cbv.volumeAveraged(roi);
            cbv = cbv .* 0.0105;
            devkit = mlpet.ScannerKit.createFromSession(sesd);            
            counting = devkit.buildCountingDevice();
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(4.3);
            scanner = scanner.volumeAveraged(roi);
            Dt = mlglucose.NumericHuang1980.DTimeToShift(counting, scanner);
            timesInterp = 0:scanner.times(end);
            aif0 = cbv.fourdfp.img * pchip(counting.times, counting.activityDensity(), timesInterp);     
            aif1 = cbv.fourdfp.img * pchip(counting.times + Dt, counting.activityDensity(), timesInterp);    
            aif2 = conv(aif1, DELTA*exp(-DELTA*timesInterp));
            aif2 = aif2(1:length(timesInterp));
            tac = scanner.activityDensity(); 
            
            % plot
            figure
            plot(scanner.times, tac, ':o', ...
                 timesInterp, aif0, '--', ...
                 timesInterp, aif1, '-', ...
                 timesInterp, aif2, '-.')
            legend('TAC', 'AIF_{Dt=0}', sprintf('AIF_{Dt=%g}', Dt), sprintf('AIF_{Dt=%g, Delta=%g}', Dt, 1/DELTA))
            xlim([0 360])
            xlabel('time frames')
            ylabel('activity (Bq/mL)')
            title(sprintf('plotDxTimes: index = %g', ipr.voxelIndex))
            
            popd(pwd0)
        end 
        function             plotDxPrediction(varargin)
            %% PLOTDXPREDICTION plots diagnosstics for model predictions.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.AerobicGlycolysisKit.buildKsByWmparc1().   
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
            sesd = this.sessionData;
            pwd0 = pushd(sesd.tracerOnAtlas('typ', 'filepath')); 
            
            % select ROI
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            roi = copy(wmparc1);
            roi.img = single(wmparc1.img == ipr.voxelIndex);
            fprintf('plotDxPrediction:  #roi = %g\n', dipsum(roi.img))
            if dipsum(roi.img) == 0
                return
            end
            roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, ipr.voxelIndex); 
            
            % select data
            fdg = sesd.tracerOnAtlas('typ', 'ImagingContext2');
            fdg1d = fdg.volumeAveraged(roi);
            fdg1d = fdg1d.fourdfp.img;
            pred = sesd.tracerOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1_predicted');
            pred1d = pred.volumeAveraged(roi);
            pred1d = pred1d.fourdfp.img;
            times = cumsum(sesd.taus);
            times = [0 times(1:end-1)];
            
            % plot
            figure
            plot(times, fdg1d, ':o', times, pred1d, '-')
            xlabel('time frames')
            ylabel('activity (Bq/mL)')
            title(sprintf('plotDxPrediction: index = %g', ipr.voxelIndex))
            
            %timesInterp = 0:times(end);
            %predInterp = pchip(times, pred1d, timesInterp);
            %plot(times, fdg1d, ':o', timesInterp, predInterp, '-')             
            
            popd(pwd0)
        end
    end

	methods
        function       assembleSubjectsStudy(this, varargin)
            %% ASSEMBLESUBJECTSSTUDY 
            
            % create union of inferences   
            
            sesd = this.sessionData;
            fqfp1 = sesd.ksOnAtlas('typ', 'fqfp', 'tags', [this.blurTag '_brain_part1']);
            ifc1 = mlfourd.ImagingFormatContext([fqfp1 '.4dfp.hdr']);
            assert(~isempty(ifc1))
            ifc1.img = zeros(size(ifc1.img));
            ifc1.fileprefix = sesd.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag '_brain']);
            N = this.sessionData.registry.numberNodes;
            for n = 1:N
                fqfp = sesd.ksOnAtlas('typ', 'fqfp', 'tags', sprintf('%s_brain_part%i', this.blurTag, n));
                try
                    ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                    assert(dipisfinite(ic))
                    assert(dipsum(ic) > 0)
                    patch = ic.fourdfp.img ~= 0;
                    if dipsum(ifc1.img(patch)) == 0
                        ifc1.img(patch) = ic.fourdfp.img(patch);
                    end
                catch ME
                    handwarning(ME)
                end                
            end
            ifc1.save()
            
            % write mat-files of inferences for use in training deep models
            
            sz1 = size(ifc1.img);
            img = reshape(ifc1.img, [sz1(1)*sz1(2)*sz1(3) sz1(4)]);
            save([ifc1.fqfileprefix '.mat'], 'img', '-v7.3');
            
            fdg = mlfourd.ImagingFormatContext(sesd.fdgOnAtlas('typ', 'fqfn'));
            sz1 = size(fdg.img);
            img = reshape(fdg.img, [sz1(1)*sz1(2)*sz1(3) sz1(4)]);
            save([fdg.fqfileprefix '.mat'], 'img', '-v7.3');   
            
            cbv = mlfourd.ImagingFormatContext(sesd.cbvOnAtlas('typ', 'fqfn', 'dateonly', true));
            sz1 = size(cbv.img);
            img = reshape(cbv.img, [sz1(1)*sz1(2)*sz1(3) 1]);
            save([cbv.fqfileprefix '.mat'], 'img', '-v7.3');
            
            % create mask of reasonable model inferences
            
            img = ifc1.img;
            img = img ~= 0;
            img = img(:,:,:,1) | img(:,:,:,2) | img(:,:,:,3) | img(:,:,:,4);
            sz1 = size(img);
            img = reshape(img, [sz1(1)*sz1(2)*sz1(3) 1]);
            save(fullfile(ifc1.filepath, [strrep(ifc1.fileprefix, 'ks', 'mask') '.mat']), 'img', '-v7.3');
        end
        function       ensureCompleteSubjectsStudy(this, varargin)
            %% ENSURECOMPLETESUBJECTSSTUDY
            
            import mlraichle.*
            sesd = this.sessionData;
            N = this.sessionData.registry.numberNodes;
            for n = 1:N
                fqfp = sesd.ksOnAtlas('typ', 'fqfp', 'tags', sprintf('%s_brain_part%i', this.blurTag, n));
                try
                    ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                    assert(dipisfinite(ic))
                    assert(dipsum(ic) > 0)
                catch ME
                    handwarning(ME)
                    
                    % param assemble := false
                    vararg2pass = varargin;
                    for vi = 1:length(vararg2pass)
                        if ischar(vararg2pass{vi}) && strcmp(vararg2pass{vi}, 'assemble')
                            if vi < length(vararg2pass)
                                vararg2pass{vi+1} = false;
                            end
                        end
                    end
                    AerobicGlycolysisKit.constructKsByVoxels(vararg2pass{:})
                end
            end
        end   
        function msk = ensureTailoredMask(this)
            msk = this.sessionData.wmparc1OnAtlas('typ', 'ImagingContext2');
            fqfn = [msk.fqfileprefix '_binarized_b43_binarized.4dfp.hdr'];
            if isfile(fqfn)
                msk = mlfourd.ImagingContext2(fqfn);
                return
            end            
            msk = msk.binarized();
            msk = msk.blurred(4.3);
            msk = msk.binarized();
            msk.save()
        end   
        function sess = filesExpr2sessions(this, fexp)
            % @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            % @return instance from this.sessionData_.create()
            
            assert(ischar(fexp))
            sess = {};
            ss = strsplit(fexp, filesep);
            assert(strcmp(ss{1}, 'subjects'))
            assert(strcmp(ss{3}, 'resampling_restricted'))
            this.jitOnT1001(fexp)

            pwd0 = pushd(fullfile(getenv('SINGULARITY_HOME'), ss{1}, ss{2}, ''));
            re = regexp(ss{4}, '(?<tracer>[a-z]{2,3})dt(?<datetime>\d{14})\w+', 'names');            
            for globTracer = globFoldersT( ...
                    fullfile('ses-E*', sprintf('%s_DT%s.000000-Converted-AC', upper(re.tracer), re.datetime)))
                for ccir = {'CCIR_00559' 'CCIR_00754'}
                    sesf = fullfile(ccir{1}, globTracer{1});
                    if isfolder(fullfile(getenv('SINGULARITY_HOME'), sesf))
                        sess = [sess {this.sessionData_.create(sesf)}]; %#ok<AGROW>
                    end
                end
            end            
            popd(pwd0)
        end  
    end
		
    %% PROTECTED
    
    methods (Access = protected)
 		function this = AerobicGlycolysisKit(varargin)
 			this = this@mlpet.AerobicGlycolysisKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
