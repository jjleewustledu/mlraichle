classdef DispersedAerobicGlycolysisKit < handle & mlpet.AbstractAerobicGlycolysisKit
	%% DISPERSEDAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 11-Aug-2020 23:14:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraihcle/src/+mlraihcle.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	  
    properties
        aifMethods
        dataFolder
        indexCliff
        model
        sessionData
    end
    
    properties (Dependent)
        blurTag
        dataPath
        regionTag
        subjectPath
    end
    
	methods (Static)  
        function construct(varargin)
            %% CONSTRUCT
            %  e.g.:  construct('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 1, 'region', 'wholebrain', 'aifMethods', 'idif')
            %  e.g.:  construct('cbv', 'debug', true)
            %  @param required physiolog is char, e.g., cbv, cbf, cmro2, cmrglc.
            %  @param subjectsExpr is char, e.g., 'sub-S58163*'.
            %  @param region is char, e.g., wholebrain, wmparc1.
            %  @param debug is logical.
            %  @param Nthreads is numeric|char.
            
            import mlraichle.*
            import mlraichle.DispersedAerobicGlycolysisKit.*

            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            setenv('DEBUG', '1')
            setenv('NOPLOT', '1')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'debug', ~isempty(getenv('DEBUG')), @islogical)
            addParameter(ip, 'indexCliff', [], @isnumeric)
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
                    metric = 'vs';
                    region = ipr.region;
                    construction = @DispersedAerobicGlycolysisKit.constructCbvByRegion;
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    region = ipr.region;
                    construction = @DispersedAerobicGlycolysisKit.constructCbfByRegion;
                case 'cmro2'
                    tracer = 'oo';
                    metric = 'os';
                    region = ipr.region;
                    construction = @DispersedAerobicGlycolysisKit.constructCmro2ByRegion;
                case 'cmrglc'
                    tracer = 'fdg';
                    metric = 'ks';
                    region = ipr.region;
                    construction = @DispersedAerobicGlycolysisKit.constructCmrglcByRegion;
                otherwise
                    error('mlpet:RuntimeError', 'DispersedAerobicGlycolysisKit.construct.ipr.physiology->%s', ipr.physiology)
            end
            
            % construct            
            pwd1 = pushd(subjectsDir);
            DispersedAerobicGlycolysisKit.initialize()
            theSessionData = DispersedAerobicGlycolysisKit.constructSessionData( ...
                metric, ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', tracer, ...
                'debug', ipr.debug, ...
                'region', region); % length(theSessionData) ~ 60
            if ipr.Nthreads > 1                
                parfor (p = 1:length(theSessionData), ipr.Nthreads)
                    try
                        construction(theSessionData(p), ...
                            'indexCliff', ipr.indexCliff); %#ok<PFBNS>
                    catch ME
                        handwarning(ME)
                    end
                end
            elseif ipr.Nthreads == 1
                for p = length(theSessionData):-1:1
                    try
                        construction(theSessionData(p), ...
                            'indexCliff', ipr.indexCliff); % RAM ~ 3.3 GB
                    catch ME
                        handwarning(ME)
                    end
                end
            end
            
            popd(pwd1);
        end
        function constructCbfByRegion(varargin)
            %% CONSTRUCTCBFBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return fs on filesystem.
            %  @return aifs on filesystem.
            %  @return cbf on filesystem.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});            
            %this.constructPhysiologyDateOnly('cbv', 'subjectFolder', this.sessionData.subjectFolder)
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [fs_,aifs_] = this.(['buildFsBy' Region])();             
            cbf_ = this.fs2cbf(fs_);
            
            % save ImagingContext2
            fs_.save()
            aifs_.save()
            cbf_.save()
            
            popd(pwd0);
        end        
        function constructCbvByRegion(varargin)
            %% CONSTRUCTCBVBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return vs on filesystem.
            %  @return aifs on filesystem.
            %  @return cbv on filesystem.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [vs_,aifs_] = this.(['buildVsBy' Region])(); 
            cbv_ = this.vs2cbv(vs_);

            % save ImagingContext2
            vs_.save()
            aifs_.save()
            cbv_.save()
            
            popd(pwd0);
        end 
        function constructCmrglcByRegion(varargin)
            %% CONSTRUCTCMRGLCBYREGION
            %  @param required sessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return ks on filesystem.
            %  @return aifs on filesystem.
            %  @return cmrglc on filesystem.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);  
            
            % build Ks and their masks           
            [ks_,cbv_,aifs_] = this.(['buildKsBy' Region])();
            cmrglc_ = this.ks2cmrglc(ks_, cbv_, this.model);
            
            % save ImagingContext2
            ks_.save()
            aifs_.save()
            cmrglc_.save()
            
            popd(pwd0);
        end
        function constructCmro2ByRegion(varargin)
            %% CONSTRUCTCMRO2BYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param required another sessionData for augmentation by averaging.
            %  @return os on filesystem.
            %  @return aifs on filesystem.
            %  @return cmro2 on filesystem.
            %  @return oef on filesystem.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});            
            this.constructPhysiologyDateOnly('cbf', 'subjectFolder', this.sessionData.subjectFolder)            
            this.constructPhysiologyDateOnly('cbv', 'subjectFolder', this.sessionData.subjectFolder)
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [os_,aifs_] = this.(['buildOsBy' Region])();   
            cbf_ = this.sessionData.cbfOnAtlas( ...
                'typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, ...
                'tags', [this.blurTag this.sessionData.regionTag]);
            [cmro2_,oef_] = this.os2cmro2(os_, cbf_, this.model);
            
            % save ImagingContext2
            os_.save()
            aifs_.save()
            cmro2_.save()
            oef_.save()
            
            popd(pwd0);
        end     
        function cohortMetric = constructCohortMetric(varargin)
            %% CONSTRUCTCOHORTMETRIC
            %  @param subjectsExpr is char, e.g., 'sub-S*'.
            %  @return cohortCbv on the filesystem contains the entire cohort in R^{3+1}.
            
            import mlraichle.*
            import mlraichle.DispersedAerobicGlycolysisKit.*

            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            warning('off', 'mlnipet:ValueError:getScanFolder')
            
            ip = inputParser;
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'metric', 'cbv', @ischar)
            addParameter(ip, 'Nthreads', 15, @(x) isnumeric(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;  
            ipr.metric = lower(ipr.metric);
            metricOnAtlas = [ipr.metric 'OnAtlas'];
            
            switch ipr.metric
                case 'cbv'
                    tracer = 'oc';
                    tracerPath = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC';
                case 'cbf'
                    tracer = 'ho';
                    tracerPath = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC';
                case 'oef'
                    tracer = 'oo';
                    tracerPath = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC';
                case 'cmro2'
                    tracer = 'oo';
                    tracerPath = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC';
                case 'cmrglc'
                    tracer = 'fdg';
                    tracerPath = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC';
                otherwise
                    error('mlraichle:ValueError', ...
                        'DispersedAerobicGlycolysisKit.constructCohortMetric does not support metric %s', ...
                        ipr.metric)
            end
            
            % reference            
            refSessionData = mlraichle.SessionData.create(tracerPath);
            refWmparc1 = refSessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                        
            % subjects, sessions            
            pwd0 = pushd(subjectsDir);
            theSessionData = DispersedAerobicGlycolysisKit.constructSessionData( ...
                ipr.metric, ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', tracer); % length(theSessionData) ~ 60
            
            % 1st session
            pwd1 = pushd(theSessionData(1).dataPath);
            cohortMetric = reshapeOnWmparc1( ...
                theSessionData(1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                theSessionData(1).(metricOnAtlas)('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                refWmparc1);
            cohortMetric.filepath = subjectsDir;
            cohortMetric.fileprefix = [ipr.metric '_cohort_222_b43_wmparc1'];
            cohortMetric = cohortMetric.fourdfp;
            popd(pwd1)
            
            % remaining sessions
            
            if ipr.Nthreads > 1
                img_ = cohortMetric.img;
                parfor (p = 1:length(theSessionData)-1, ipr.Nthreads)
                    try
                        pwd2 = pushd(theSessionData(p+1).dataPath);
                        metric_ = reshapeOnWmparc1( ...
                            theSessionData(p+1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                            theSessionData(p+1).(metricOnAtlas)('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                            refWmparc1);
                        img_(:,:,:,p+1) = metric_.fourdfp.img;
                        popd(pwd2)
                    catch ME
                        handwarning(ME)
                    end
                end 
                cohortMetric.img = img_;
            else
                for p = 1:length(theSessionData)-1
                    try
                        pwd2 = pushd(theSessionData(p+1).dataPath);
                        metric_ = reshapeOnWmparc1( ...
                            theSessionData(p+1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                            theSessionData(p+1).(metricOnAtlas)('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                            refWmparc1);
                        cohortMetric.img(:,:,:,p+1) = metric_.fourdfp.img;                    
                        popd(pwd2)
                    catch ME
                        handwarning(ME)
                    end
                end 
            end
            
            popd(pwd0);  
            
            % finalize returns
            cohortMetric = mlfourd.ImagingContext2(cohortMetric);
            cohortMetric.save()
        end     
    end
    
    methods
        
        %% GET
        
        function g = get.blurTag(~)
            g = mlraichle.StudyRegistry.instance.blurTag;
            %g = this.sessionData.petPointSpreadTag;
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
            
            import mlpet.AbstractAerobicGlycolysisKit
            import mloxygen.DispersedNumericRaichle1983
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);             
            scanner = devkit.buildScannerDevice();
            %scanner = scanner.blurred(this.sessionData.petPointSpread);
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());
            arterial = this.buildAif(devkit, scanner, scannerWmparc1);
            
            cbv_ = this.sessionData.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, 'tags', [this.blurTag this.sessionData.regionTag]);
            
            fs_ = copy(wmparc1.fourdfp);
            fs_.filepath = this.dataPath;
            fs_.fileprefix = this.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.DispersedNumericRaichle1983.LENK;
            fs_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(fs_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlraichle.DispersedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                if 0 == dipsum(roi)
                    continue
                end

                % solve Raichle
                raichle = DispersedNumericRaichle1983.createFromDeviceKit( ...
                    devkit, ...
                    'scanner', scanner, ...
                    'arterial', arterial, ...
                    'cbv', cbv_, ...
                    'roi', roi, ...
                    'histology', AbstractAerobicGlycolysisKit.index2histology(idx));  
                raichle = raichle.solve(@mloxygen.DispersedRaichle1983Model.loss_function);
                this.model = raichle.model;
                
                % insert Raichle solutions into fs
                fs_.img = fs_.img + raichle.fs('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + raichle.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = raichle.plot();
                    this.savefig(h, idx)
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
            
            import mlglucose.DispersedNumericHuang1980
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            this.checkFdgIntegrity(devkit)            
            scanner = devkit.buildScannerDevice();
            %scanner = scanner.blurred(this.sessionData.petPointSpread);   
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());          
            arterial = devkit.buildCountingDevice(scannerWmparc1);
            
            cbv_ = this.sessionData.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, 'tags', [this.blurTag this.sessionData.regionTag]);
                        
            ks_ = copy(wmparc1.fourdfp);
            ks_.filepath = this.dataPath;
            ks_.fileprefix = this.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mlglucose.DispersedNumericHuang1980.LENK;
            ks_.img = zeros([size(wmparc1) lenKs], 'single');              
            aifs_ = copy(ks_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]); 
            aifs_.img = 0;         

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlraichle.DispersedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                if 0 == dipsum(roi)
                    continue
                end

                % solve Huang
                huang = DispersedNumericHuang1980.createFromDeviceKit( ...
                    devkit, ...
                    'scanner', scanner, ...
                    'arterial', arterial, ...
                    'cbv', cbv_, ...
                    'roi', roi);
                huang = huang.solve(@mlglucose.DispersedHuang1980Model.loss_function);
                this.model = huang.model;

                % insert Huang solutions into ks
                ks_.img = ks_.img + huang.ks('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + huang.artery_local('typ', 'single');

                % Dx
                
                if any(idx == this.indicesToCheck)  
                    h = huang.plot();
                    this.savefig(h, idx)
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
                    
            import mloxygen.DispersedNumericMintun1984
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);            
            scanner = devkit.buildScannerDevice();
            %scanner = scanner.blurred(this.sessionData.petPointSpread);  
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());
            arterial = this.buildAif(devkit, scanner, scannerWmparc1);
            
            os_ = copy(wmparc1.fourdfp);
            os_.filepath = this.dataPath;
            os_.fileprefix = this.osOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.DispersedNumericMintun1984.LENK;
            os_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(os_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlraichle.DispersedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                if 0 == dipsum(roi) 
                    continue
                end

                % solve Mintun
                mintun = DispersedNumericMintun1984.createFromDeviceKit( ...
                    devkit, ...
                    'scanner', scanner, ...
                    'arterial', arterial, ...
                    'roi', roi);  
                mintun = mintun.solve(@mloxygen.DispersedMintun1984Model.loss_function);
                this.model = mintun.model;
                
                % insert Raichle solutions into fs
                os_.img = os_.img + mintun.os('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + mintun.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = mintun.plot();
                    this.savefig(h, idx)
                end                    
            end
            os_ = mlfourd.ImagingContext2(os_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end
        function [vs_,aifs_] = buildVsByWmparc1(this, varargin)
            %% BUILDVSBYWMPARC1
            %  @return v1_ in R^ as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3, without saving.
            %  @return aifs_ in R, without saving.
            
            import mloxygen.DispersedNumericMartin1987
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);                                    
            
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);             
            scanner = devkit.buildScannerDevice();
            %scanner = scanner.blurred(this.sessionData.petPointSpread);
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());  
            arterial = this.buildAif(devkit, scanner, scannerWmparc1); 
            
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
                fprintf('starting mlraichle.DispersedAerobicGlycolysisKit.buildVsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                if 0 == dipsum(roi) 
                    continue
                end
                
                martin = DispersedNumericMartin1987.createFromDeviceKit( ...
                    devkit, ...
                    'scanner', scanner, ...
                    'arterial', arterial, ...
                    'roi', roi, ...
                    'T0', 120, ...
                    'Tf', 240);
                martin = martin.solve();                
                
                % insert Martin solutions into fs
                vs_.img = vs_.img + martin.vs('typ', 'single');
                
                % collect delay & dipsersion adjusted aifs
                aifs_.img = aifs_.img + martin.artery_local('typ', 'single');

                % Dx
                if any(idx == this.indicesToCheck)  
                    h = martin.plot();
                    this.savefig(h, idx)
                end  
            end
            vs_ = mlfourd.ImagingContext2(vs_);
            aifs_ = mlfourd.ImagingContext2(aifs_);
            popd(pwd0);
        end 
        function checkFdgIntegrity(~, devkit)
            
            import mlglucose.Huang1980
            
            scanner = devkit.buildScannerDevice();
            if rank(scanner.imagingContext) < 4 
                error('mlraichle:RuntimeError', ...
                    'DispersedAerobicGlycolysisKit.checkFdgIntegrity found no dynamic data in %s', ...
                    scanner.imagingContext.fileprefix)
            end
        end
        function obj = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonly is logical.
            %  @param tags is char, e.g., 'b43_wmparc1', default ''.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.sessionData.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;
            
            if ~isempty(ipr.tags)
                ipr.tags = strcat("_", strip(ipr.tags, "_"));
            end   
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s%s_%s%s%s', ...
                        lower(ipr.metric), ...
                        adatestr, ...
                        this.sessionData.registry.atlasTag, ...
                        ipr.tags, ...
                        this.sessionData.filetypeExt));
            obj  = this.sessionData.fqfilenameObject(fqfn, varargin{:});
        end
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = DispersedAerobicGlycolysisKit(varargin)
 			this = this@mlpet.AbstractAerobicGlycolysisKit(varargin{:});
            
            am = containers.Map;
            am('CO') = 'twilite';
            am('OC') = 'twilite';
            am('OO') = 'twilite';
            am('HO') = 'twilite';
            am('FDG') = 'caprac';

            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indexCliff', [], @isnumeric)
            addParameter(ip, 'aifMethods', am, @(x) isa(x, 'containers.Map'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;
            this.indexCliff = ipr.indexCliff;
            this.aifMethods = ipr.aifMethods;
            
            this.dataFolder = 'resampling_restricted';
            this.resetModelSampler()
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

