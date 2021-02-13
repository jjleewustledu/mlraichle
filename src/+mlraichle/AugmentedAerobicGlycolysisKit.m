classdef AugmentedAerobicGlycolysisKit < handle & mlpet.AbstractAerobicGlycolysisKit
	%% AUGMENTEDAEROBICGLYCOLYSISKIT implements data augmentations that support machine learning inference.

	%  $Revision$
 	%  was created 04-Jan-2021 16:19:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.9.0.1538559 (R2020b) Update 3 for MACI64.  Copyright 2021 John Joowon Lee.
    
    properties 
        dataFolder
        Dt_aif
        fracMixing
        model
        sessionData
        sessionData2
        similarGlycemias = false
    end
    
    properties (Dependent)
        blurTag
        blurTag2
        dataPath
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
            setenv('NOPLOT', '1')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            warning('off', 'mlnipet:ValueError:getScanFolder')
            
            ip = inputParser;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'debug', ~isempty(getenv('DEBUG')), @islogical)
            addParameter(ip, 'Nthreads', 1, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'augment', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if ischar(ipr.Nthreads)
                ipr.Nthreads = str2double(ipr.Nthreads);
            end 
            
            % switch strategy
            switch ipr.physiology
                case 'cbv'
                    tracer = 'oc';
                    metric = 'vs';
                    region = ipr.region;
                    construction = @AugmentedAerobicGlycolysisKit.constructCbvByRegion;
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    region = ipr.region;
                    construction = @AugmentedAerobicGlycolysisKit.constructCbfByRegion;
                case 'cmro2'
                    tracer = 'oo';
                    metric = 'os';
                    region = ipr.region;
                    construction = @AugmentedAerobicGlycolysisKit.constructCmro2ByRegion;
                case 'cmrglc'
                    tracer = 'fdg';
                    metric = 'ks';
                    region = ipr.region;
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
                'region', region); % length(theSessionData) ~ 60
            if ipr.Nthreads > 1
                parfor (p = 1:length(theSessionData), ipr.Nthreads)
                    for q = 1:length(theSessionData)
                        if (p ~= q) && ...
                                strcmp(theSessionData(p).subjectFolder, theSessionData(q).subjectFolder)
                            try
                                construction(theSessionData(p), theSessionData(q), 'augment', ipr.augment); %#ok<PFBNS>
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
            elseif ipr.Nthreads == 1
                for p = 1:length(theSessionData)
                    for q = 1:length(theSessionData)
                        if (p ~= q) && ...
                                strcmp(theSessionData(p).subjectFolder, theSessionData(q).subjectFolder)
                            try
                                construction(theSessionData(p), theSessionData(q), 'augment', ipr.augment); % RAM ~ 3.3 GB
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
            end
            
            popd(pwd1);
        end
        function constructCbfByRegion(varargin)
            %% CONSTRUCTCBFBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.AugmentedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [fs_,aifs_] = this.(['buildFsBy' Region])();             
            cbf_ = this.fs2cbf(fs_);
            ho_ = this.tracerMixed();
            
            % save ImagingContext2
            fs_.nifti.save()
            aifs_.nifti.save()
            cbf_.nifti.save()
            ho_.nifti.save()
            
            popd(pwd0);
        end  
        function constructCbvByRegion(varargin)
            %% CONSTRUCTCBVBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.AugmentedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [vs_,aifs_] = this.(['buildVsBy' Region])(); 
            cbv_ = this.vs2cbv(vs_);
            oc_ = this.tracerMixed();
            
            % save ImagingContext2
            vs_.nifti.save()
            aifs_.nifti.save()
            cbv_.nifti.save()
            oc_.nifti.save()
            
            popd(pwd0);
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
            fdg_ = this.tracerMixed();  
            
            % save ImagingContext2
            ks_.nifti.save()
            cbv_.nifti.save()
            aifs_.nifti.save()
            cmrglc_.nifti.save()
            fdg_.nifti.save()
            
            popd(pwd0);
        end
        function constructCmro2ByRegion(varargin)
            %% CONSTRUCTCMRO2BYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.AugmentedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [os_,aifs_] = this.(['buildOsBy' Region])();             
            cbf_ = this.sessionData.cbfOnAtlas( ...
                'typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, ...
                'tags', [this.sessionData.petPointSpreadTag this.sessionData.regionTag]);
            cmro2_ = this.os2cmro2(os_, cbf_, this.model);
            oo_ = this.tracerMixed();
            
            % save ImagingContext2
            os_.nifti.save()
            aifs_.nifti.save()
            cmro2_.nifti.save()
            oo_.nifti.save()
            
            popd(pwd0);
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
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end
        function g = get.subjectPath(this)
            g = this.sessionData.subjectPath;
        end
        
        %%
        
        function [fs_,aifs_] = buildFsByWmparc1(this, varargin)
            %% BUILDFSBYWMPARC1
            %  @return fs in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return aifs in R^4, without saving.
            
            import mlpet.AugmentedData.mix            
            import mlpet.AbstractAerobicGlycolysisKit
            import mloxygen.AugmentedNumericRaichle1983
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            arterial = devkit.buildArterialSamplingDevice(scanner);
            arterial2 = devkit2.buildArterialSamplingDevice(scanner2);  
            taus = this.sessionData.alternativeTaus();
            this.Dt_aif = taus(1)*abs(randn());
            this.resetModelSampler()
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            wmparc12 = this.sessionData2.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');            
            
            fs_ = copy(wmparc1);
            fs_.filepath = this.dataPath;
            fs_.fileprefix = this.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.AugmentedNumericRaichle1983.LENK + 1;
            fs_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(fs_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.AugmentedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                roi2 = mlfourd.ImagingContext2(wmparc12);
                roi2.fileprefix = sprintf('%s_index%i', roi2.fileprefix, idx);
                roi2 = roi2.numeq(idx);
                if 0 == dipsum(roi) || 0 == dipsum(roi2)
                    continue
                end

                % solve Raichle
                raichle = AugmentedNumericRaichle1983.createFromDeviceKit( ...
                    devkit, ...
                    devkit2, ...
                    'scanner', scanner, ...
                    'scanner2', scanner2, ...
                    'arterial', arterial, ...
                    'arterial2', arterial2, ...
                    'roi', roi, ...
                    'roi2', roi2, ...
                    'histology', AbstractAerobicGlycolysisKit.index2histology(idx), ...
                    'T', AugmentedNumericRaichle1983.T, ...
                    'Dt_aif', this.Dt_aif, ...
                    'fracMixing', this.fracMixing);  
                raichle = raichle.solve(@mloxygen.DispersedRaichle1983Model.loss_function);
                this.model = raichle.model;
                
                % insert Raichle solutions into fs
                fs_.img = fs_.img + raichle.fs('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + raichle.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = raichle.plot();
                    dtStr = [datestr(this.sessionData.datetime) ', ' datestr(this.sessionData2.datetime)];
                    title(sprintf('AugmentedAerobicGlycolysisKit.buildFsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = [lower(this.sessionData.doseAdminDatetimeTag) ...
                                 lower(this.sessionData2.doseAdminDatetimeTag)];
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end
            fs_ = mlfourd.ImagingContext2(fs_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end 
        function [ks_,cbv_,aifs_] = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @return ks_ in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3, without saving.
            %  @return aifs_ in R^4, without saving.
            
            import mlglucose.AugmentedNumericHuang1980
            import mlglucose.AugmentedNumericHuang1980.mix
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            this.checkFdgIntegrity(devkit, devkit2)
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            arterial = devkit.buildCountingDevice(scanner);
            arterial2 = devkit2.buildCountingDevice(scanner2);            
            taus = this.sessionData.alternativeTaus();
            this.Dt_aif = taus(1)*abs(randn());
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
            ks_.img = zeros([size(wmparc1) lenKs], 'single');              
            aifs_ = copy(ks_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]); 
            aifs_.img = 0;         

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.AugmentedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                roi2 = mlfourd.ImagingContext2(wmparc12);
                roi2.fileprefix = sprintf('%s_index%i', roi2.fileprefix, idx);
                roi2 = roi2.numeq(idx);
                if 0 == dipsum(roi) || 0 == dipsum(roi2)
                    continue
                end

                % solve Huang
                huang = AugmentedNumericHuang1980.createFromDeviceKit( ...
                    devkit, ...
                    devkit2, ...
                    'scanner', scanner, ...
                    'scanner2', scanner2, ...
                    'arterial', arterial, ...
                    'arterial2', arterial2, ...
                    'cbv', cbv, ...
                    'cbv2', cbv2, ...
                    'roi', roi, ...
                    'roi2', roi2, ...
                    'T', AugmentedNumericHuang1980.T, ...
                    'Dt_aif', this.Dt_aif, ...
                    'fracMixing', this.fracMixing);
                huang = huang.solve(@mlglucose.DispersedHuang1980Model.loss_function);
                this.model = huang.model;

                % insert Huang solutions into ks
                ks_.img = ks_.img + huang.ks('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + huang.artery_local('typ', 'single');

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
            ks_ = mlfourd.ImagingContext2(ks_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end
        function [os_,aifs_] = buildOsByWmparc1(this, varargin)
            %% BUILDOSBYWMPARC1
            %  @return os in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return aifs in R^4, without saving.
            
            import mlpet.AugmentedData.mix            
            import mloxygen.AugmentedNumericMintun1984
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            arterial = devkit.buildArterialSamplingDevice(scanner);
            arterial2 = devkit2.buildArterialSamplingDevice(scanner2);  
            taus = this.sessionData.alternativeTaus();
            this.Dt_aif = taus(1)*abs(randn());
            this.resetModelSampler()
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            wmparc12 = this.sessionData2.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');            
            
            os_ = copy(wmparc1);
            os_.filepath = this.dataPath;
            os_.fileprefix = this.osOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.AugmentedNumericMintun1984.LENK + 1;
            os_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(os_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.AugmentedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                roi2 = mlfourd.ImagingContext2(wmparc12);
                roi2.fileprefix = sprintf('%s_index%i', roi2.fileprefix, idx);
                roi2 = roi2.numeq(idx);
                if 0 == dipsum(roi) || 0 == dipsum(roi2)
                    continue
                end

                % solve Raichle
                mintun = AugmentedNumericMintun1984.createFromDeviceKit( ...
                    devkit, ...
                    devkit2, ...
                    'scanner', scanner, ...
                    'scanner2', scanner2, ...
                    'arterial', arterial, ...
                    'arterial2', arterial2, ...
                    'roi', roi, ...
                    'roi2', roi2, ...
                    'T', AugmentedNumericMintun1984.T, ...
                    'Dt_aif', this.Dt_aif, ...
                    'fracMixing', this.fracMixing);  
                mintun = mintun.solve(@mloxygen.DispersedMintun1984Model.loss_function);
                this.model = mintun.model;
                
                % insert Raichle solutions into fs
                os_.img = os_.img + mintun.os('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + mintun.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = mintun.plot();
                    dtStr = [datestr(this.sessionData.datetime) ', ' datestr(this.sessionData2.datetime)];
                    title(sprintf('AugmentedAerobicGlycolysisKit.buildOsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = [lower(this.sessionData.doseAdminDatetimeTag) ...
                                 lower(this.sessionData2.doseAdminDatetimeTag)];
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildOsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildOsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end
            os_ = mlfourd.ImagingContext2(os_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end
        function [v1_,cbv_,aifs_] = buildV1ByVoxel(this, varargin)
            %% BUILDVSBYVOXEL
            %  @return v1_ in R^ as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3, without saving.
            %  @return aifs_ in R, without saving.
            
            import mloxygen.AugmentedNumericMartin1987
            import mloxygen.AugmentedNumericMartin1987.mix
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                   
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            arterial = devkit.buildArterialSamplingDevice(scanner);
            arterial2 = devkit2.buildArterialSamplingDevice(scanner2);  
            taus = this.sessionData.alternativeTaus();
            this.Dt_aif = taus(1)*abs(randn());
            %this.resetModelSampler()
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.binarized();
            
            v1_ = copy(wmparc1.fourdfp);
            v1_.filepath = this.dataPath;
            v1_.fileprefix = this.v1OnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenV1 = 1;
            v1mat_ = reshape(v1_.img, [numel(wmparc1) lenV1]);
            v1found_ = find(v1mat_);

            martin = AugmentedImagingMartin1987.createFromDeviceKit( ...
                devkit, devkit2, ...
                'scanner', scanner, ...
                'scanner2', scanner2, ...
                'arterial', arterial, ...
                'arterial2', arterial2, ...
                'roi', wmparc1, ...
                'roi2', wmparc1, ...
                'T', AugmentedNumericMartin1987.T, ...
                'Dt_aif', this.Dt_aif, ...
                'fracMixing', this.fracMixing);
            
            aifs_ = copy(v1_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp');
            aifs_.img = martin.mixAifs( ...
                'scanner', scanner, ...
                'scanner2', scanner2, ...
                'arterial', arterial, ...
                'arterial2', arterial2, ...
                'roi', wmparc1, ...
                'Dt_aif', this.Dt_aif, ...
                'fracMixing', this.fracMixing);
            atimes = 0:numel(aifs_.img)-1;
            if this.Dt_aif < 0 % interpolate aifs_ to scanner
                aifs_.img = makima(atimes, aifs_.img, scanner.times);
            else % interpolate aifs_ to scanner2
                aifs_.img = makima(atimes, aifs_.img, scanner2.times);
            end

            for v1index = v1found_' % voxels

                % fprintf('starting mlraichle.AugmentedAerobicGlycolysisKit.buildV1ByVoxel.idx -> %i\n', idx)
                
                roivecbin_ = false(size(v1mat_, 1), 1);
                roivecbin_(v1index) = true;

                % solve Martin model
                martin = martin.solve(roivecbin_);

                % insert Martin solutions on into v1mat_
                v1mat_(roivecbin_) = martin.v1();
            end
            v1_.img = reshape(v1mat_, [size(wmparc1) lenV1]);
            v1_ = mlfourd.ImagingContext2(v1_);
            cbv_ = mlpet.TracerKinetics.v1ToCbv(v1_);
            cbv_.fileprefix = strrep(v1_.fileprefix, 'v1', 'cbv');
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end
        function [vs_,aifs_] = buildVsByWmparc1(this, varargin)
            %% BUILDVSBYVOXEL
            %  @return v1_ in R^ as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3, without saving.
            %  @return aifs_ in R, without saving.
            
            import mloxygen.AugmentedNumericMartin1987
            import mloxygen.AugmentedNumericMartin1987.mix
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                   
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            devkit2 = mlpet.ScannerKit.createFromSession(this.sessionData2); 
            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scanner2 = devkit2.buildScannerDevice();
            scanner2 = scanner2.blurred(this.sessionData.petPointSpread);
            
            arterial = devkit.buildArterialSamplingDevice(scanner);
            arterial2 = devkit2.buildArterialSamplingDevice(scanner2);  
            taus = this.sessionData.alternativeTaus();
            this.Dt_aif = taus(1)*abs(randn());
            %this.resetModelSampler()
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc12 = this.sessionData2.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext'); 
            
            vs_ = copy(wmparc1.fourdfp);
            vs_.filepath = this.dataPath;
            vs_.fileprefix = this.vsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = 1;
            vs_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(vs_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;            
            
            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.AugmentedAerobicGlycolysisKit.buildVsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                roi2 = mlfourd.ImagingContext2(wmparc12);
                roi2.fileprefix = sprintf('%s_index%i', roi2.fileprefix, idx);
                roi2 = roi2.numeq(idx);
                if 0 == dipsum(roi) || 0 == dipsum(roi2)
                    continue
                end
                
                martin = AugmentedNumericMartin1987.createFromDeviceKit( ...
                    devkit, ...
                    devkit2, ...
                    'scanner', scanner, ...
                    'scanner2', scanner2, ...
                    'arterial', arterial, ...
                    'arterial2', arterial2, ...
                    'roi', roi, ...
                    'roi2', roi2, ...
                    'T', AugmentedNumericMartin1987.T, ...
                    'Dt_aif', this.Dt_aif, ...
                    'fracMixing', this.fracMixing);
                martin = martin.solve();                
                
                % insert Martin solutions into fs
                vs_.img = vs_.img + martin.vs('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + martin.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = martin.plot();
                    dtStr = [datestr(this.sessionData.datetime) ', ' datestr(this.sessionData2.datetime)];
                    title(sprintf('AugmentedAerobicGlycolysisKit.buildVsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = [lower(this.sessionData.doseAdminDatetimeTag) ...
                                 lower(this.sessionData2.doseAdminDatetimeTag)];
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildVsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('AugmentedAerobicGlycolysisKit_buildVsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end  
            end
            vs_ = mlfourd.ImagingContext2(vs_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end       
        function checkFdgIntegrity(this, devkit, devkit2)
            
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
            if this.similarGlycemias                
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
            fracstr = sprintf('_mix%s', strrep(num2str(this.fracMixing, 4), '.', 'p'));
            assert(~isempty(this.Dt_aif))
            daifstr = sprintf('_daif%s', strrep(num2str(this.Dt_aif, 4), '.', 'p'));
            
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
        function tr_ = tracerMixed(this)
            tr = this.sessionData.tracerOnAtlas('typ', 'mlfourd.ImagingContext2');
            tr2 = this.sessionData2.tracerOnAtlas('typ', 'mlfourd.ImagingContext2');
            times = this.sessionData.times;
            times2 = this.sessionData2.times;
            taus = this.sessionData.alternativeTaus();
            annotate_Dt_aif = nan;
            if this.Dt_aif < -taus(1) % shift oc2 to left
                tr2 = tr2.makima(times2 + this.Dt_aif, times);
                annotate_Dt_aif = this.Dt_aif;
            end
            if this.Dt_aif > taus(1) % shift oc to left
                tr = tr.makima(times - this.Dt_aif, times2);
                annotate_Dt_aif = this.Dt_aif;
            end
            tr_ = mlpet.AugmentedData.mix(tr, tr2, this.fracMixing, annotate_Dt_aif);
            ifc = tr_.fourdfp;
            ifc.img(ifc.img < 0) = 0;
            ifc.filepath = this.dataPath;
            tr_ = mlfourd.ImagingContext2(ifc);
        end
    end

    %% PROTECTED
    
	methods (Access = protected)
 		function this = AugmentedAerobicGlycolysisKit(varargin)
            this = this@mlpet.AbstractAerobicGlycolysisKit(varargin{:});  
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addRequired(ip, 'sessionData2', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;
            this.sessionData2 = ipr.sessionData2;
            
            this.dataFolder = 'data_augmentation';
            this.fracMixing = 0.49*rand() + 0.5;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

