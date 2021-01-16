classdef AugmentedAerobicGlycolysisKit < handle
	%% AUGMENTEDAEROBICGLYCOLYSISKIT implements data augmentations that support machine learning inference.

	%  $Revision$
 	%  was created 04-Jan-2021 16:19:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.9.0.1538559 (R2020b) Update 3 for MACI64.  Copyright 2021 John Joowon Lee.
    
    properties 
        dataFolder = 'data_augmentation'
        Dt_aif
        fracMixing
        model
        sessionData
        sessionData2
    end
    
    properties (Dependent)
        blurTag
        blurTag2
        dataPath
        indices
        indicesToCheck
        regionTag
        subjectPath
    end
    
	methods (Static)        
        function construct(varargin)
            %% CONSTRUCT
            %  e.g.:  construct('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 1, 'region', 'wholebrain')
            %  e.g.:  construct('cbv', 'debug', true)
            %  @param required physiolog is char, e.g., cbv, cbf, cmro2, cmrglc.
            %  @param subjectsExpr is char, e.g., 'sub-S58163*'.
            %  @param region is char, e.g., wholebrain, wmparc1.
            %  @param debug is logical.
            %  @param Nthreads is numeric|char.
            
            import mlraichle.*
            import mlraichle.AugmentedAerobicGlycolysisKit.*

            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            setenv('DEBUG', '1')
            setenv('NOPLOT', '')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            warning('off', 'mlnipet:ValueError:getScanFolder')
            
            ip = inputParser;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'debug', false, @islogical)
            addParameter(ip, 'Nthreads', 1, @(x) isnumeric(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            if ischar(ipr.Nthreads)
                ipr.Nthreads = str2double(ipr.Nthreads);
            end 
            
            % switch strategy
            switch ipr.physiology
                case 'cbv'
                    tracer = 'oc';
                    metric = '';
                    construction = @AugmentedAerobicGlycolysisKit.constructCbvByRegion;
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    construction = @AugmentedAerobicGlycolysisKit.constructCbfByRegion;
                case 'cmro2'
                    tracer = 'oo';
                    metric = 'os';
                    construction = @AugmentedAerobicGlycolysisKit.constructCmro2ByRegion;
                case 'cmrglc'
                    tracer = 'fdg';
                    metric = 'ks';
                    construction = @AugmentedAerobicGlycolysisKit.constructCmrglcByRegion;
                otherwise
                    error('mlpet:RuntimeError', 'AugmentedAerobicGlycolysisKit.construct.ipr.physiology->%s', ipr.physiology)
            end
            
            % construct
            pwd1 = pushd(subjectsDir);           
            theSessionData = AugmentedAerobicGlycolysisKit.constructSessionData( ...
                metric, ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', tracer, ...
                'debug', ipr.debug, ...
                'region', ipr.region);
            if ipr.Nthreads > 1
                parfor (p = 1:length(theSessionData), ipr.Nthreads)
                    for q = 1:length(theSessionData)
                        if p ~= q
                            try
                                construction(theSessionData(p), theSessionData(q)); %#ok<PFBNS>
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
            else
                for p = 5 % 1:length(theSessionData)
                    for q = 3 % 1:length(theSessionData)
                        if p ~= q
                            try
                                construction(theSessionData(p), theSessionData(q)); % RAM ~ 3 GB
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
            end
            
            popd(pwd1)
        end
        function constructCmrglcByRegion(varargin)
            %% CONSTRUCTCMRGLCBYREGION
            %  @param required sessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.AugmentedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);  
            
            % build Ks and their masks           
            [ks_,cbv_,aifs_] = this.(['buildKsBy' Region])();
            cmrglc_ = this.ks2cmrglc(ks_, cbv_, this.model);
            fdg_ = this.fdgMixed();  
            
            % save ImagingContext2
            ks_.save()
            cbv_.save()
            aifs_.save()
            cmrglc_.save()
            fdg_.save()
            
            % save mat files for physiology
            this.ic2mat(ks_)
            this.ic2mat(cbv_)
            this.ic2mat(aifs_)
            this.ic2mat(cmrglc_)
            this.ic2mat(fdg_)
            
            %this.constructCmrglcSupport(varargin{:});
            
            popd(pwd0)
        end
        function constructCmrglcSupport(varargin)
            %% CONSTRUCTCMRGLCSUPPORT
            %  @param required sessionData is mlpipeline.ISessionData.
            
            this = mlraichle.AugmentedAerobicGlycolysisKit(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            huang = this.loadImagingHuang();
            pred = huang.buildPrediction();
            pred.save();
            resid = huang.buildResidual(); 
            resid.save(); 
            [mae,nmae] = huang.buildMeanAbsError(); 
            mae.save(); 
            nmae.save(); 
            %msk = this.buildTrainingMask(huang.sessionData, nmae);
            %msk.save();
            popd(pwd0)
        end 
        function ic = constructPhysiologyDateOnly(varargin)
            
            import mlraichle.AugmentedAerobicGlycolysisKit.physiologyObjToDatetimeStr
            
            ip = inputParser;
            addRequired(ip, 'physiology', @ischar)
            addParameter(ip, 'subjectFolder', '', @ischar)
            addParameter(ip, 'atlTag', '_222', @ischar)
            addParameter(ip, 'blurTag', '_b43', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            pwd0 = pushd(fullfile(getenv('SINGULARITY_HOME'), 'subjects', ipr.subjectFolder, 'resampling_restricted')); 
            fnPatt = sprintf('%sdt*%s%s_%s.4dfp.hdr', ipr.physiology, ipr.atlTag, ipr.blurTag, ipr.region);
            g = globT(fnPatt);
            if isempty(g); return; end
            
            %% segregate by dates
            
            m = containers.Map;            
            for ig = 1:length(g)
                dstr = physiologyObjToDatetimeStr(g{ig}, 'dateonly', true);
                if ~lstrfind(m.keys, dstr)
                    m(dstr) = g(ig); % cell
                else
                    m(dstr) = [m(dstr) g{ig}];
                end
            end 
            
            %% average scans by dates
            
            for k = asrow(m.keys)
                fns = m(k{1});
                ic = mlfourd.ImagingContext2(fns{1});
                ic = ic.zeros();
                icfp = strrep(ic.fileprefix, physiologyObjToDatetimeStr(fns{1}), physiologyObjToDatetimeStr(fns{1}, 'dateonly', true));
                for fn = fns
                    incr = mlfourd.ImagingContext2(fn{1});
                    ic = ic + incr;
                end
                ic = ic / length(fns);
                ic.fileprefix = icfp;
                ic.save()
            end
            
            %%
            
            popd(pwd0)
        end
        function theSD = constructSessionData(varargin)
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'metric', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S*', @ischar)
            addParameter(ip, 'tracer', '', @ischar)
            addParameter(ip, 'debug', false, @islogical)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'scanIndex', 1:4, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            idx = 1;
            subPath = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            pwd1 = pushd(subPath);
            subjects = globFoldersT(ipr.subjectsExpr); % e.g., 'sub-S3*'
            for sub = subjects
                pwd0 = pushd(fullfile(subPath, sub{1}));
                subd = SubjectData('subjectFolder', sub{1});
                sesfs = subd.subFolder2sesFolders(sub{1});

                for ses = sesfs
                    if ~ipr.debug || strcmp(ses{1}, sesfs{3})
                        for scan_idx = ipr.scanIndex
                            try
                                sesd = SessionData( ...
                                    'studyData', StudyData(), ...
                                    'projectData', ProjectData('sessionStr', ses{1}), ...
                                    'subjectData', subd, ...
                                    'sessionFolder', ses{1}, ...
                                    'scanIndex', scan_idx, ...
                                    'tracer', upper(ipr.tracer), ...
                                    'ac', true, ...
                                    'region', ipr.region, ...
                                    'metric', ipr.metric);            
                                if sesd.datetime < mlraichle.StudyRegistry.instance.earliestCalibrationDatetime
                                    continue
                                end
                                theSD(idx) = sesd; %#ok<AGROW>
                                idx = idx + 1;
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
                popd(pwd0)
            end
            popd(pwd1)
        end
        function matfn = ic2mat(ic)
            %% creates mat files with img(binary_msk) with multi-arrays always flipped on 2
            %  for consistency with luckett_to_4dfp, luckett_to_nii.
            
            msk = mlfourd.ImagingContext2(fullfile(getenv('REFDIR'), '711-2B_222_brain.4dfp.hdr'));
            msk = msk.binarized();
            bin = msk.fourdfp.img > 0;
            bin = flip(bin, 2);
            
            sz = size(ic);
            img = ic.fourdfp.img;
            img = flip(img, 2);
            if 4 == length(sz)
                dat = zeros(dipsum(msk), sz(4));
                for t = 1:sz(4)
                    img_ = img(:,:,:,t);
                    dat(:,t) = img_(bin);
                end
                matfn = [ic.fqfileprefix '.mat'];
                save(matfn, 'dat')
                return
            end
            if 3 == length(sz)
                dat = img(bin);
                matfn = [ic.fqfileprefix '.mat'];
                save(matfn, 'dat')
                return
            end
            error('mlraichle:ValueError', 'AugmentedAerobicGlycolysisKit.ic2mat.sz of %g is not supported', sz)
        end  
        function chi = ks2chi(ks)
            %  @param ks is ImagingContext2.
            %  @return chi := k1 k3/(k2 + k3) in 1/s, without v1.
            
            ks = ks.fourdfp;            
            img = ks.img(:,:,:,1).*ks.img(:,:,:,3)./(ks.img(:,:,:,2) + ks.img(:,:,:,3)); % 1/s
            img(isnan(img)) = 0;
            
            chi = copy(ks);            
            chi.fileprefix = strrep(ks.fileprefix, 'ks', 'chi');
            chi.img = img;
            chi = mlfourd.ImagingContext2(chi);
        end
        function cmrglc = ks2cmrglc(ks, cbv, model)   
            %  @param ks is ImagingContext2.
            %  @param cbv is ImagingContext2.
            %  @param model is mlglucose.Huang1980Model.
            %  @return cmrglc is ImagingContext2.
            
            import mlraichle.AugmentedAerobicGlycolysisKit.ks2chi
            
            chi = ks2chi(ks); % 1/s
            chi = chi * 60; % 1/min
            v1 = cbv * 0.0105;
            glc = mlglucose.Huang1980.glcConversion(model.glc, 'mg/dL', 'umol/hg');
            
            cmrglc = v1 .* chi .* (glc/mlpet.AerobicGlycolysisKit.LC);
            cmrglc.fileprefix = strrep(ks.fileprefix, 'ks', 'cmrglc');
        end
        function dt = physiologyObjToDatetime(obj)
            ic = mlfourd.ImagingContext2(obj);            
            ss = split(ic.fileprefix, '_');
            re = regexp(ss{1}, '\w+dt(?<datetime>\d{14})\w*', 'names');
            dt = datetime(re.datetime, 'InputFormat', 'yyyyMMddHHmmss');
        end
        function dtstr = physiologyObjToDatetimeStr(varargin)
            ip = inputParser;
            addRequired(ip, 'obj', @(x) ~isempty(x))
            addParameter(ip, 'dateonly', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            import mlraichle.AugmentedAerobicGlycolysisKit.physiologyObjToDatetime   
            if ipr.dateonly
                dtstr = [datestr(physiologyObjToDatetime(ipr.obj), 'yyyymmdd') '000000'];
            else
                dtstr = datestr(physiologyObjToDatetime(ipr.obj), 'yyyymmddHHMMSS') ;
            end
        end
    end
    
    methods
        
        %% GET
        
        function g = get.blurTag(this)
            g = this.sessionData.petPointSpreadTag;
        end
        function g = get.blurTag2(this)
            g = this.sessionData2.petPointSpreadTag;
        end
        function g = get.dataPath(this)
            g = fullfile(this.sessionData.subjectPath, this.dataFolder, '');
        end
        function g = get.indices(this)
            g = this.dagk_.indices;
        end
        function g = get.indicesToCheck(this)
            g = this.dagk_.indicesToCheck;
        end   
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end
        function g = get.subjectPath(this)
            g = this.sessionData.subjectPath;
        end
        
        %%
        
        function obj = aifsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('aif', varargin{:});
        end
        function [ks_,cbv_,aifs_] = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @return ks_ in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3.
            %  @return aifs_ in R^4.
            
            import mlglucose.AugmentedNumericHuang1980.mix
            
            ensuredir(this.dataPath)
            pwd0 = pushd(this.dataPath);  
            
            this.sessionData.region = 'wmparc1';
            this.sessionData2.region = 'wmparc1';                         
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            this.checkFdgIntegrity(devkit, devkit2)
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            counter = devkit.buildCountingDevice();
            counter2 = devkit2.buildCountingDevice();            
            this.Dt_aif = mlglucose.AugmentedNumericHuang1980.DTimeToShiftAifs(counter, counter2)*rand();
            this.resetModelSampler()
            
            cbv = this.sessionData.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, 'tags', [this.blurTag this.sessionData.regionTag]);
            cbv2 = this.sessionData2.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, 'tags', [this.blurTag2 this.sessionData2.regionTag]);
            cbv_ = mix(cbv, cbv2, this.fracMixing);
            cbv_.filepath = this.dataPath;
            cbv_.fileprefix = this.cbvOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc12 = this.sessionData2.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            
            ks_ = copy(wmparc1.fourdfp);
            ks_.filepath = this.dataPath;
            ks_.fileprefix = this.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mlglucose.AugmentedNumericHuang1980.LENK + 1;
            ks_.img = zeros([size(wmparc1) lenKs]);  
            ksmat_ = reshape(ks_.img, [numel(wmparc1) lenKs]);
            
            aifs_ = copy(ks_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp');
            aifsmat_ = [];            

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single                    
                fprintf('starting mlpet.AugmentedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
                tic
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                roivec_ = reshape(logical(roi.fourdfp.img), [numel(roi) 1]);
                N_roivec_ = sum(roivec_);
                roi2 = mlfourd.ImagingContext2(wmparc12);
                roi2.fileprefix = sprintf('%s_index%i', roi2.fileprefix, idx);
                roi2 = roi2.numeq(idx);
                if 0 == dipsum(roi) || 0 == dipsum(roi2)
                    continue
                end

                % solve Huang
                huang = mlglucose.AugmentedNumericHuang1980.createFromDeviceKit( ...
                    devkit, devkit2, ...
                    'scanner', scanner, ...
                    'scanner2', scanner2, ...
                    'counter', counter, ...
                    'counter2', counter2, ...
                    'cbv', cbv, 'cbv2', cbv2, ...
                    'roi', roi, 'roi2', roi2, ...
                    'Dt_aif', this.Dt_aif, ...
                    'fracMixing', this.fracMixing);
                huang = huang.solve();
                this.model = huang.model;
                toc

                % insert Huang solutions on roibin(idx) into ks
                kscache = huang.ks();
                kscache(lenKs) = huang.Dt;                
                ksmat_(roivec_, :) = repmat(kscache, N_roivec_, 1);
                
                % collect delay & dipsersion adjusted aifs
                if isempty(aifsmat_)
                    aifsmat_ = zeros([numel(wmparc1) length(huang.artery_sampled)]);
                end
                aifsmat_(roivec_, :) = repmat(huang.artery_sampled, N_roivec_, 1); %#ok<AGROW>

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = huang.plot();
                    dtStr = [datestr(this.sessionData.datetime) ', ' datestr(this.sessionData2.datetime)];
                    title(sprintf('AugmentedAerobicGlycolysisKit.buildKsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = [lower(this.sessionData.doseAdminDatetimeTag) ...
                                 lower(this.sessionData2.doseAdminDatetimeTag)];
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end
            ks_.img = reshape(ksmat_, [size(wmparc1) lenKs]);
            ks_ = mlfourd.ImagingContext2(ks_);
            aifs_.img = reshape(aifsmat_, [size(wmparc1) size(aifsmat_,2)]);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0)
        end
        function checkFdgIntegrity(~, devkit, devkit2)
            
            import mlglucose.Huang1980
            
            scanner = devkit.buildScannerDevice();
            scanner2 = devkit2.buildScannerDevice();
            if rank(scanner.imagingContext) < 4 
                error('mlraichle:RuntimeError', ...
                    'AugmentedNumericHuang1980.checkFdgIntegrity found no dynamic data in %s', ...
                    scanner.imagingContext.fileprefix)
            end
            if rank(scanner2.imagingContext) < 4
                error('mlraichle:RuntimeError', ...
                    'AugmentedNumericHuang1980.checkFdgIntegrity found no dynamic data in %s', ...
                    scanner2.imagingContext.fileprefix)
            end
            counting = devkit.buildCountingDevice();
            counting2 = devkit2.buildCountingDevice();
            glc = Huang1980.glcFromRadMeasurements(counting.radMeasurements);
            glc2 = Huang1980.glcFromRadMeasurements(counting2.radMeasurements);
            if abs(glc - glc2) > min(glc, glc2)
                error('mlglucose:RuntimeError', ...
                    'AugmentedNumericHuang1980.checkFdgIntegrity:  glc (%g) and glc2 (%g) are too discrepant', ...
                    glc, glc2)
            end
        end
        function fdg_ = fdgMixed(this)
            fdg = this.sessionData.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
            fdg2 = this.sessionData2.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
            times = this.sessionData.times;
            times2 = this.sessionData2.times;
            if this.Dt_aif > 10
                fdg2 = fdg2.makima(times2 - this.Dt_aif, times);
            end
            if this.Dt_aif < -10                
                fdg = fdg.makima(times + this.Dt_aif, times2);
            end
            fdg_ = mlglucose.AugmentedNumericHuang1980.mix(fdg, fdg2, this.fracMixing);
            fdg_.filepath = this.dataPath;
        end
        function obj = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function r = loadImagingHuang(this, varargin)
            %%
            %  @return mlglucose.DispersedImagingHuang1980  
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.cbvOnAtlas('dateonly', true));
            mask = this.maskOnAtlasTagged();
            m = this.metricOnAtlasTagged();
            r = mlglucose.DispersedImagingHuang1980.createFromDeviceKit(this.devkit_, 'cbv', cbv, 'roi', mask);
            r.ks = m;
        end
        function ic = maskOnAtlasTagged(this, varargin)
            fqfp = this.sessionData.wmparc1OnAtlas('typ', 'fqfp');
            fqfp_bin = [fqfp '_binarized'];
            
            % 4dfp exists
            if isfile([fqfp_bin '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp_bin '.4dfp.hdr']);
                return
            end
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                ic = ic.binarized();
                ic.save()
                return
            end
        end
        function obj = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param datetime2 is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonly is logical.
            %  @param tags is char, e.g., '_b43_wmparc1'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.sessionData.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'datetime2', this.sessionData2.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;
            
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if ischar(ipr.datetime2)
                adatestr2 = ipr.datetime2;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            if isdatetime(ipr.datetime2)
                if ipr.dateonly
                    adatestr2 = ['dt' datestr(ipr.datetime2, 'yyyymmdd') '000000'];
                else
                    adatestr2 = ['dt' datestr(ipr.datetime2, 'yyyymmddHHMMSS')];
                end
            end
            fracstr = sprintf('mix%s', strrep(num2str(this.fracMixing, 4), '.', 'p'));
            assert(~isempty(this.Dt_aif))
            daifstr = sprintf('daif%s', strrep(num2str(this.Dt_aif, 4), '.', 'p'));
            
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s%s%s%s%s%s%s%s', ...
                        lower(ipr.metric), ...
                        adatestr, ...
                        adatestr2, ...
                        fracstr, ...
                        daifstr, ...
                        this.sessionData.registry.atlasTag, ...
                        ipr.tags, ...
                        this.sessionData.filetypeExt));
            obj  = this.sessionData.fqfilenameObject(fqfn, varargin{:});
        end
        function resetModelSampler(~)
            mlpet.TracerKineticsModel.sampleOnScannerFrames([], [])
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        dagk_
    end
    
	methods (Access = protected)
 		function this = AugmentedAerobicGlycolysisKit(varargin)
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addRequired(ip, 'sessionData2', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;
            this.sessionData2 = ipr.sessionData2;
 			this.dagk_ = mlraichle.DispersedAerobicGlycolysisKit.createFromSession(ipr.sessionData);
            this.fracMixing = 0.9*rand() + 0.05;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

