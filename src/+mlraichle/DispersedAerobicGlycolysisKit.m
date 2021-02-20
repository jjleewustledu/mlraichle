classdef DispersedAerobicGlycolysisKit < handle & mlpet.AbstractAerobicGlycolysisKit
	%% DISPERSEDAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 11-Aug-2020 23:14:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraihcle/src/+mlraihcle.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	  
    properties 
        dataFolder
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
            %  e.g.:  construct('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 1, 'region', 'wholebrain')
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
            setenv('NOPLOT', '')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            warning('off', 'mlnipet:ValueError:getScanFolder')
            
            ip = inputParser;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'debug', ~isempty(getenv('DEBUG')), @islogical)
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
                        construction(theSessionData(p)); %#ok<PFBNS>
                    catch ME
                        handwarning(ME)
                    end
                end
            elseif ipr.Nthreads == 1
                for p = length(theSessionData):-1:1
                    try
                        construction(theSessionData(p)); % RAM ~ 3.3 GB
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
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});
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
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
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
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
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
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            this = mlraichle.DispersedAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            [os_,aifs_] = this.(['buildOsBy' Region])();   
            cbf_ = this.sessionData.cbfOnAtlas( ...
                'typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, ...
                'tags', [this.sessionData.petPointSpreadTag this.sessionData.regionTag]);
            cmro2_ = this.os2cmro2(os_, cbf_, this.model);
            
            % save ImagingContext2
            os_.save()
            aifs_.save()
            cmro2_.save()
            
            popd(pwd0);
        end     
        function cohortCbv = constructCohortCbv(varargin)
            %% CONSTRUCTCOHORTCBV
            %  @param subjectsExpr is char.
            %  @return cohortCbv is mlfourd.ImagingContext2.
            
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
            addParameter(ip, 'Nthreads', 15, @(x) isnumeric(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;  
            
            % reference            
            refSessionData = mlraichle.SessionData.create( ...
                'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC');
            refWmparc1 = refSessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                        
            % subjects, sessions            
            pwd0 = pushd(subjectsDir);
            theSessionData = DispersedAerobicGlycolysisKit.constructSessionData( ...
                'cbv', ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', 'oc'); % length(theSessionData) ~ 60
            
            % 1st session
            pwd1 = pushd(fullfile(theSessionData(1).subjectPath, 'resampling_restricted'));
            cohortCbv = reshapeOnWmparc1( ...
                theSessionData(1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                theSessionData(1).cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                refWmparc1);
            cohortCbv.filepath = subjectsDir;
            cohortCbv.fileprefix = 'cbv_cohort_222_b43_wmparc1';
            cohortCbv = cohortCbv.fourdfp;
            popd(pwd1)
            
            % remaining sessions
            
            if ipr.Nthreads > 1
                img_ = cohortCbv.img;
                parfor (p = 1:length(theSessionData)-1, ipr.Nthreads)
                    try
                        pwd2 = pushd(fullfile(theSessionData(p+1).subjectPath, 'resampling_restricted'));
                        cbv_ = reshapeOnWmparc1( ...
                            theSessionData(p+1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                            theSessionData(p+1).cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                            refWmparc1);
                        img_(:,:,:,p+1) = cbv_.fourdfp.img;
                        popd(pwd2)
                    catch ME
                        handwarning(ME)
                    end
                end 
                cohortCbv.img = img_;
            else
                for p = 1:length(theSessionData)-1
                    try
                        pwd2 = pushd(fullfile(theSessionData(p+1).subjectPath, 'resampling_restricted'));
                        cbv_ = reshapeOnWmparc1( ...
                            theSessionData(p+1).wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'), ...
                            theSessionData(p+1).cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1'), ...
                            refWmparc1);
                        cohortCbv.img(:,:,:,p+1) = cbv_.fourdfp.img;                    
                        popd(pwd2)
                    catch ME
                        handwarning(ME)
                    end
                end 
            end
            
            popd(pwd0);  
            
            % finalize returns
            cohortCbv = mlfourd.ImagingContext2(cohortCbv);
            cohortCbv.save()
        end     
        function ic = constructPhysiologyDateOnly(varargin)
            
            import mlraichle.DispersedAerobicGlycolysisKit
            
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
                dstr = DispersedAerobicGlycolysisKit.physiologyObjToDatetimeStr(g{ig}, 'dateonly', true);
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
                icfp = strrep(ic.fileprefix, ...
                    DispersedAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}), ...
                    DispersedAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}, 'dateonly', true));
                for fn = fns
                    incr = mlfourd.ImagingContext2(fn{1});
                    ic = ic + incr;
                end
                ic = ic / length(fns);
                ic.fileprefix = icfp;
                ic.save()
            end
            
            %%
            
            popd(pwd0);
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
            ven = ven.thresh(10.29); % mean + 10 sigmas (mL/hg) per Ito 2004
            ven = ven.binarized();
            ven.fqfilename = sesd.venousOnAtlas();
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            selected = logical(ven.fourdfp.img) & wmparc1.img < 2;
            wmparc1.img(selected) = 6000;
            
            % construct wmparc1
            ic = ImagingContext2(wmparc1);
            ic.save()
        end        
        function dt = physiologyObjToDatetime(obj)
            ic = mlfourd.ImagingContext2(obj);            
            ss = split(ic.fileprefix, '_');
            re = regexp(ss{1}, '\w+dt(?<datetime>\d{14})\w*', 'names');
            dt = datetime(re.datetime, 'InputFormat', 'yyyyMMddHHmmss');
        end
        function dtstr = physiologyObjToDatetimeStr(varargin)
            import mlraichle.DispersedAerobicGlycolysisKit 
            ip = inputParser;
            addRequired(ip, 'obj', @(x) ~isempty(x))
            addParameter(ip, 'dateonly', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;  
            if ipr.dateonly
                dtstr = [datestr(DispersedAerobicGlycolysisKit.physiologyObjToDatetime(ipr.obj), 'yyyymmdd') '000000'];
            else
                dtstr = datestr(DispersedAerobicGlycolysisKit.physiologyObjToDatetime(ipr.obj), 'yyyymmddHHMMSS') ;
            end
        end
        function metricOut = reshapeOnWmparc1(wmparc1, metric, wmparc1Out)
            %% Cf. semantics of pchip or makima.
            
            wmparc1 = mlfourd.ImagingContext2(wmparc1);
            wmparc1 = wmparc1.fourdfp;
            metric = mlfourd.ImagingContext2(metric);
            metric = metric.fourdfp;
            wmparc1Out = mlfourd.ImagingContext2(wmparc1Out);
            wmparc1Out = wmparc1Out.fourdfp;
            metricOut = copy(metric);
            metricOut.img = zeros(size(metric));
            
            for idx = mlraichle.DispersedAerobicGlycolysisKit.indices % parcs
                if 6000 == idx % venous structures
                    continue
                end
                roibin = wmparc1.img == idx;
                if 0 == dipsum(roibin) 
                    continue
                end
                m = dipsum(metric.img(roibin))/dipsum(roibin);
                roibinOut = wmparc1Out.img == idx;
                metricOut.img(roibinOut) = m;
            end
            metricOut = mlfourd.ImagingContext2(metricOut);
        end
    end
    
    methods
        
        %% GET
        
        function g = get.blurTag(this)
            g = this.sessionData.petPointSpreadTag;
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
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());           
            arterial = devkit.buildArterialSamplingDevice(scannerWmparc1, 'sameWorldline', false);
            
            fs_ = copy(wmparc1.fourdfp);
            fs_.filepath = this.dataPath;
            fs_.fileprefix = this.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.DispersedNumericRaichle1983.LENK + 1;
            fs_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(fs_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
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
                    dtStr = datestr(this.sessionData.datetime);
                    title(sprintf('DispersedAerobicGlycolysisKit.buildFsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = lower(this.sessionData.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.png', idx, dtTag)))
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
            
            import mlglucose.DispersedNumericHuang1980
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData); 
            this.checkFdgIntegrity(devkit)            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);   
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());          
            arterial = devkit.buildCountingDevice(scannerWmparc1);
            
            cbv = this.sessionData.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, 'tags', [this.blurTag this.sessionData.regionTag]);
            cbv_.filepath = this.dataPath;
            cbv_.fileprefix = this.cbvOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
                        
            ks_ = copy(wmparc1.fourdfp);
            ks_.filepath = this.dataPath;
            ks_.fileprefix = this.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mlglucose.DispersedNumericHuang1980.LENK + 1;
            ks_.img = zeros([size(wmparc1) lenKs], 'single');              
            aifs_ = copy(ks_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]); 
            aifs_.img = 0;         

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
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
                    'cbv', cbv, ...
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
                    dtStr = datestr(this.sessionData.datetime);
                    title(sprintf('DispersedAerobicGlycolysisKit.buildKsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = lower(this.sessionData.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.png', idx, dtTag)))
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
                    
            import mloxygen.DispersedNumericMintun1984
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            wmparc1 = this.sessionData.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);            
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(this.sessionData.petPointSpread);  
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());         
            arterial = devkit.buildArterialSamplingDevice(scannerWmparc1, 'sameWorldline', false); 
            
            os_ = copy(wmparc1.fourdfp);
            os_.filepath = this.dataPath;
            os_.fileprefix = this.osOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            lenKs = mloxygen.DispersedNumericMintun1984.LENK + 1;
            os_.img = zeros([size(wmparc1) lenKs], 'single'); 
            aifs_ = copy(os_);
            aifs_.fileprefix = this.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            aifs_.img = 0;

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single 
                fprintf('%s\n', datestr(now))
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                roi = mlfourd.ImagingContext2(wmparc1);
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                roi = roi.numeq(idx);
                if 0 == dipsum(roi) 
                    continue
                end

                % solve Raichle
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
                    dtStr = datestr(this.sessionData.datetime);
                    title(sprintf('DispersedAerobicGlycolysisKit.buildOsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = lower(this.sessionData.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildOsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildOsByWmparc1_idx%i_%s.png', idx, dtTag)))
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
            scanner = scanner.blurred(this.sessionData.petPointSpread);
            scannerWmparc1 = scanner.volumeAveraged(wmparc1.binarized());            
            arterial = devkit.buildArterialSamplingDevice(scannerWmparc1, 'sameWorldline', false); 
                                                                        % 'deconvCatheter', false); 
            % empirical normalization
            this.setNormalizationFactor(scanner)   
            
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
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildVsByWmparc1.idx -> %i\n', idx)
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
                    dtStr = datestr(this.sessionData.datetime);
                    title(sprintf('DispersedAerobicGlycolysisKit.buildVsByWmparc1:  idx == %i\n%s', idx, dtStr))
                    try
                        dtTag = lower(this.sessionData.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildVsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(this.dataPath, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildVsByWmparc1_idx%i_%s.png', idx, dtTag)))
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
        function checkFdgIntegrity(~, devkit)
            
            import mlglucose.Huang1980
            
            scanner = devkit.buildScannerDevice();
            if rank(scanner.imagingContext) < 4 
                error('mlraichle:RuntimeError', ...
                    'AugmentedNumericHuang1980.checkFdgIntegrity found no dynamic data in %s', ...
                    scanner.imagingContext.fileprefix)
            end
        end
        function obj = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonly is logical.
            %  @param tags is char, e.g., '_b43_wmparc1'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.sessionData.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;
            
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
                sprintf('%s%s%s%s%s', ...
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
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;
            
            this.dataFolder = 'resampling_restricted';
            this.resetModelSampler()
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

