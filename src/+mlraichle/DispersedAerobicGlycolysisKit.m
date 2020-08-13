classdef DispersedAerobicGlycolysisKit < handle & mlraichle.AerobicGlycolysisKit
	%% DISPERSEDAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 11-Aug-2020 23:14:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraihcle/src/+mlraihcle.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	methods (Static)  
        function msk = buildTrainingMask(nmae)
            assert(contains(nmae.fileprefix, 'NMAE'))
            msk = nmae.numlt(1);
            msk.fileprefix = strrep(nmae.fileprefix, 'fdg', 'mask');
        end
        function [cmrglc,Ks,msk] = constructCmrglc(varargin)
            %% CONSTRUCTCMRGLC
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param regionTag is char, e.g., '_brain' | '_wmparc1'
            %  @param lastKsTag is char and used by this.ksOnAtlas, e.g., '', '_b43'
            %  @return cmrglc in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return Ks in (s^{-1}) as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            %  @return pred as mlfourd.ImagingContext2.
            %  @return resid as mlfourd.ImagingContext2.
            %  @return mae as mlfourd.ImagingContext2.
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            
            this.ensureTailoredMask()
                    
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
                    'parcellation', ipr.region); 
                this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
                this.regionTag = ['_' ipr.region];
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
        function [kss,msk] = constructKsByWmparc1(varargin)
            %% CONSTRUCTKSBYWMPARC1
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            [kss,msk] = mlraichle.DispersedAerobicGlycolysisKit.constructKsByRegion( ...
                varargin{:}, 'region', 'wmparc1');
        end   
        function constructSubjectByRegion(varargin)   
            %% CONSTRUCTSUBJECTBYREGION constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            %  @param region is char:  'wmparc1', 'wbrain'.
            %  @param saveMat is logical.
            
            import mlraichle.*
            import mlraichle.DispersedAerobicGlycolysisKit.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'region', '', @(x) ischar(x) && ~isempty(x))
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
                        'parcellation', ipr.region); 
                    if sesd.datetime < mlraichle.StudyRegistry.instance.earliestCalibrationDatetime
                        continue
                    end
                    if ipr.saveMat
                        fdg = sesd.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
                        fdg = fdg.blurred(4.3);
                        DispersedAerobicGlycolysisKit.ic2mat(fdg)
                    end
                    
                    DispersedAerobicGlycolysisKit.(['constructKsBy' Region])( ...
                        foldersExpr, [], 'sessionsExpr', sesf{1}); % memory ~ 5.5 GB
                    
                    [cmrglc,Ks,msk] = DispersedAerobicGlycolysisKit.constructCmrglc( ...
                        foldersExpr, [], 'sessionsExpr', sesf{1}, 'regionTag', ['_' ipr.region]);
                    if ipr.saveMat
                        Ksc = DispersedAerobicGlycolysisKit.iccrop(Ks, 1:4);
                        DispersedAerobicGlycolysisKit.ic2mat(Ksc)
                        DispersedAerobicGlycolysisKit.ic2mat(cmrglc)
                        DispersedAerobicGlycolysisKit.ic2mat(msk)
                    end
                catch ME
                    handwarning(ME)
                end
            end            
            popd(pwd0)            
        end
        function constructSubjectByWmparc1(varargin)
            %% CONSTRUCTSUBJECTBYWMPARC1 constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            
            mlraichle.DispersedAerobicGlycolysisKit.constructSubjectByRegion(varargin{:}, 'region', 'wmparc1')               
        end
        function ic = constructWmparc1OnAtlas(sesd)
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            
            deleteExisting([sesd.wmparc1OnAtlas('typ', 'fqfileprefix') '.4dfp.*'])
            
            % define CSF
            wmparc = ImagingFormatContext(sesd.wmparcOnAtlas());
            wmparc1 = ImagingFormatContext(sesd.brainOnAtlas());
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1;
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);
            
            % define venous
            ven = sesd.cbvOnAtlas('typ', 'ImagingContext2', 'dateonly', true);
            ven = ven.blurred(4.3);
            ven = ven.thresh(10.8); % 10 sigmas per Ito 2004
            ven = ven.binarized();
            ven.fqfilename = sesd.venousOnAtlas();
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            wmparc1.img(logical(ven.fourdfp.img)) = 6000;
            
            % construct wmparc1
            ic = ImagingContext2(wmparc1);
            ic.save()
        end
        function this = createFromSession(varargin)
            this = mlraichle.DispersedAerobicGlycolysisKit('sessionData', varargin{:});
        end
        function these = createFromSubjectSession(varargin)
            %% CREATEFROMSUBJECTSESSION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param regionTag is char, e.g., '_brain' | '_wmparc'
            %  @return these is {mlraichle.DispersedAerobicGlycolysisKit, ...}
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'regionTag', '_wmparc1', @ischar)
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
                    'ac', true); 
                this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
                this.regionTag = ipr.regionTag;
                these = [these this]; %#ok<AGROW>
            end
            popd(pwd0)
        end
        function plotDxDTimes(varargin)
            %% PLOTDXDTIMES plots diagnosstics for \Delta t shifts of AIF.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1().    
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            addParameter(ip, 'regionTag', '_wmparc1', @ischar)
            addParameter(ip, 'Delta', 0.5, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results; 
            DELTA = ipr.Delta;
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
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
            Dt = mlglucose.DispersedNumericHuang1980.DTimeToShift(counting, scanner);
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
        function plotDxPrediction(varargin)
            %% PLOTDXPREDICTION plots diagnosstics for model predictions.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1().   
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            addParameter(ip, 'regionTag', '_wmparc1', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
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
            xlim([0 1000])
            xlabel('time frames')
            ylabel('activity (Bq/mL)')
            title(sprintf('plotDxPrediction: index = %g', ipr.voxelIndex))         
            
            popd(pwd0)
        end 		
    end
    
    methods
        function kss = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @param filesExpr
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return kss as mlfourd.ImagingContext2 or cell array, without saving to filesystems.
            
            indices = [6000 1:85 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002];
            if isdeployed()
                indicesToCheck = 0;
            else
                indicesToCheck = [6000 1 7:20 24 26:28];
            end
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filesExpr', '', @ischar)
            addParameter(ip, 'foldersExpr', '', @ischar)
            addParameter(ip, 'indicesToCheck', indicesToCheck, @(x) any(x == indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            kss = {};
            for sesd = this.filesExpr2sessions(ipr.filesExpr)
                sesd1 = sesd{1};
                sesd1.parcellation = 'wmparc1';
                workdir = sesd1.tracerResolvedOpSubject('typ', 'path');
                pwd0 = pushd(workdir);                
                devkit = mlpet.ScannerKit.createFromSession(sesd1);                
                cbv = sesd1.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
                cbv = cbv.fourdfp;
                wmparc1 = sesd1.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                wmparc1 = wmparc1.fourdfp;
                ks = copy(wmparc1);
                ks.fileprefix = sesd1.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
                lenKs = mlglucose.DispersedNumericHuang1980.LENK + 1;
                ks.img = zeros([size(wmparc1) lenKs]);   

                for idx = indices % parcs
                    
                    % for parcs, build roibin as logical, roi as single                    
                    fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
                    tic
                    roi = copy(wmparc1);
                    roibin = wmparc1.img == idx;
                    roi.img = single(roibin);  
                    roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                    if 0 == dipsum(roi.img)
                        continue
                    end

                    % solve Huang
                    roicbv = mean(cbv.img(roibin));
                    huang = mlglucose.DispersedNumericHuang1980.createFromDeviceKit( ...
                        devkit, 'cbv', roicbv, 'roi', mlfourd.ImagingContext2(roi));
                    huang = huang.solve();
                    toc

                    % insert Huang solutions on roibin(idx) into ks
                    kscache = huang.ks();
                    kscache(huang.LENK+1) = huang.Dt;
                    for ik = 1:huang.LENK+1
                        rate = ks.img(:,:,:,ik);
                        rate(roibin) = kscache(ik);
                        ks.img(:,:,:,ik) = rate;
                    end
                    
                    % Dx
                    if any(idx == ipr.indicesToCheck)                        
                        h = huang.plot('xlim', [-20 1800]);
                        title(sprintf('DispersedAerobicGlycolysisKit.buildKsByWmparc1:  idx == %i\n%s', idx, datestr(sesd1.datetime)))
                        try
                            dtTag = lower(sesd.doseAdminDatetimeTag);
                            savefig(h, ...
                                fullfile(workdir, ...
                                sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                            figs = get(0, 'children');
                            saveas(figs(1), ...
                                fullfile(workdir, ...
                                sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.png', idx, dtTag)))
                            close(figs(1))
                        catch ME
                            handwarning(ME)
                        end
                    end                    
                end                
                ks = mlfourd.ImagingContext2(ks);
                kss = [kss ks]; %#ok<AGROW>
                popd(pwd0)
            end
        end        
        function msk = ensureTailoredMask(this)
            msk = this.sessionData.wmparc1OnAtlas('typ', 'ImagingContext2');
            fqfn = [msk.fqfileprefix '_binarized.4dfp.hdr'];
            if isfile(fqfn)
                msk = mlfourd.ImagingContext2(fqfn);
                return
            end 
            % msk = msk.uthresh(5999); % exclude venous
            % msk = msk.binarized();
            % msk = msk.blurred(4.3);
            msk = msk.binarized();
            msk.save()
        end 
        function h = loadImagingHuang(this, varargin)
            %%
            %  @return mlglucose.DispersedImagingHuang1980  
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mask = this.maskOnAtlasTagged();
            ks = this.ksOnAtlasTagged();
            h = mlglucose.DispersedImagingHuang1980.createFromDeviceKit( ...
                this.devkit_, 'cbv', cbv, 'roi', mask, 'regionTag', this.regionTag);
            h.ks = ks;
        end
        function h = loadNumericHuang(this, roi, varargin)
            %%
            %  @param required roi is understood by mlfourd.ImagingContext2
            %  @return mlglucose.NumericHuang1980
            
            roi = mlfourd.ImagingContext2(roi);
            roi = roi.binarized();
            roibin = logical(roi.fourdfp.img);
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mean_cbv = cbv.fourdfp.img(roibin);            
            h = mlglucose.DispersedNumericHuang1980.createFromDeviceKit( ...
                this.devkit_, 'cbv', mean_cbv, 'roi', roi, 'regionTag', this.regionTag);
        end
        function ic = maskOnAtlasTagged(this, varargin)
            fqfp = [this.sessionData.wmparc1OnAtlas('typ', 'fqfp') '_binarized'];
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                msk = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(msk.img), [128 128 75]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.maskOnAtlasTagged')
        end
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = DispersedAerobicGlycolysisKit(varargin)
 			this = this@mlraichle.AerobicGlycolysisKit(varargin{:});
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
