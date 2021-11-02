classdef QuadraticAerobicGlycolysisKit < handle & mlpet.AbstractAerobicGlycolysisKit
	%% QUADRATICAEROBICGLYCOLYSISKIT implements quadratic parameterization of kinetic rates using
    %  emissions.  See also papers by Videen, Herscovitch.

	%  $Revision$
 	%  was created 12-Jun-2021 17:50:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.10.0.1669831 (R2021a) Update 2 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties 
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
            %  e.g.:  construct('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 1, 'region', 'wholebrain')
            %  e.g.:  construct('cbv', 'debug', true)
            %  @param required physiolog is char, e.g., cbv, cbf, cmro2, cmrglc.
            %  @param subjectsExpr is char, e.g., 'sub-S58163*'.
            %  @param region is char, e.g., wholebrain, voxels.
            %  @param debug is logical.
            %  @param Nthreads is numeric|char.
            
            import mlraichle.*
            import mlraichle.QuadraticAerobicGlycolysisKit.*

            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            setenv('DEBUG', '')
            setenv('NOPLOT', '1')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            
            ip = inputParser;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'voxels', @ischar)
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
                    construction = @QuadraticAerobicGlycolysisKit.constructCbvByRegion;                            
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    region = ipr.region;
                    construction = @QuadraticAerobicGlycolysisKit.constructCbfByRegion;
                case 'cmro2'
                    tracer = 'oo';
                    metric = 'os';
                    region = ipr.region;
                    construction = @QuadraticAerobicGlycolysisKit.constructCmro2ByRegion;
                otherwise
                    error('mlpet:RuntimeError', 'QuadraticAerobicGlycolysisKit.construct.ipr.physiology->%s', ipr.physiology)
            end
            
            % construct            
            pwd1 = pushd(subjectsDir);
            QuadraticAerobicGlycolysisKit.initialize()
            theSessionData = QuadraticAerobicGlycolysisKit.constructSessionData( ...
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
            %  @return cbf on filesystem.
            
            this = mlraichle.QuadraticAerobicGlycolysisKit(varargin{:});            
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            fs_ = this.(['buildFsBy' Region])();             
            cbf_ = this.fs2cbf(fs_);
            
            % save ImagingContext2
            cbf_.save()
            
            popd(pwd0);
        end
        function constructCbvByRegion(varargin)
            %% CONSTRUCTCBVBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbv on filesystem.
            
            this = mlraichle.QuadraticAerobicGlycolysisKit(varargin{:});
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            vs_ = this.(['buildVsBy' Region])(); 
            cbv_ = this.vs2cbv(vs_);

            % save ImagingContext2
            cbv_.save()
            
            popd(pwd0);
        end 
        function constructCmro2ByRegion(varargin)
            %% CONSTRUCTCMRO2BYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cmro2 on filesystem.
            %  @return oef on filesystem.
            
            this = mlraichle.QuadraticAerobicGlycolysisKit(varargin{:});            
            this.constructPhysiologyDateOnly('cbf', ...
                'subjectFolder', this.sessionData.subjectFolder, ...
                'region', this.sessionData.region)
            this.constructPhysiologyDateOnly('cbv', ...
                'subjectFolder', this.sessionData.subjectFolder, ...
                'region', this.sessionData.region)
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
             
            os_ = this.(['buildOsBy' Region])();   
            cbf_ = this.sessionData.cbfOnAtlas( ...
                'typ', 'mlfourd.ImagingContext2', ...
                'dateonly', true, ...
                'tags', [this.blurTag this.sessionData.regionTag]);
            [cmro2_,oef_] = this.os2cmro2(os_, cbf_, this.model);
            
            % save ImagingContext2
            cmro2_.save()
            oef_.save()
            
            popd(pwd0);
        end    
        function constructQC(varargin)
            %% CONSTRUCTQC
            %  e.g.:  constructQC('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 1, 'region', 'wholebrain')
            %  e.g.:  constructQC('cbv', 'debug', true)
            %  @param required physiolog is char, e.g., cbv, cbf, cmro2, cmrglc.
            %  @param subjectsExpr is char, e.g., 'sub-S58163*'.
            %  @param region is char, e.g., wholebrain, voxels.
            %  @param debug is logical.
            %  @param Nthreads is numeric|char.
            
            import mlraichle.*
            import mlraichle.QuadraticAerobicGlycolysisKit.*

            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            setenv('DEBUG', '')
            setenv('NOPLOT', '1')
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            
            ip = inputParser;
            addRequired( ip, 'physiology', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S58163', @ischar)
            addParameter(ip, 'region', 'voxels', @ischar)
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
                    averaging = 'wholebrain';
                    construction = @QuadraticAerobicGlycolysisKit.construct_qc_wholebrain;                            
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    region = ipr.region;
                    averaging = 'wholebrain';
                    construction = @QuadraticAerobicGlycolysisKit.construct_qc_wholebrain;
                case {'oef' 'cmro2'}
                    tracer = 'oo';
                    metric = 'os';
                    region = ipr.region;
                    averaging = 'wholebrain';
                    construction = @QuadraticAerobicGlycolysisKit.construct_qc_wholebrain;
                otherwise
                    error('mlpet:RuntimeError', 'QuadraticAerobicGlycolysisKit.construct.ipr.physiology->%s', ipr.physiology)
            end
            
            % construct
            pwd1 = pushd(subjectsDir);
            QuadraticAerobicGlycolysisKit.initialize()
            theSessionData = QuadraticAerobicGlycolysisKit.constructSessionData( ...
                metric, ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', tracer, ...
                'debug', ipr.debug, ...
                'region', region); % length(theSessionData) ~ 60
            qc_ = cell(1, length(theSessionData));
            if ipr.Nthreads > 1                
                parfor (p = 1:length(theSessionData), ipr.Nthreads)
                    try
                        qc_{p} = construction(ipr.physiology, theSessionData(p)); %#ok<PFBNS>
                    catch ME
                        handwarning(ME)
                    end
                end
            elseif ipr.Nthreads == 1
                for p = length(theSessionData):-1:1
                    try
                        qc_{p} = construction(ipr.physiology, theSessionData(p)); % RAM ~ 3.3 GB
                    catch ME
                        handwarning(ME)
                    end
                end
            end
            p_ = 1;
            for p = 1:length(theSessionData)
                try
                    qc(p_) = qc_{p}; %#ok<AGROW>
                    p_ = p_ + 1;
                catch ME
                    handwarning(ME)
                end
            end
            QuadraticAerobicGlycolysisKit.writeqc(ipr.physiology, qc, averaging)            
            popd(pwd1);
        end 
        function qc = construct_qc_wholebrain(physio, varargin)
            %% CONSTRUCT_QC_WHOLEBRAIN
            %  @param required physio is char:  'cbv', 'cbf', 'oef', cmro2', ...
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return qc as struct('subject', [], 'filename', [], 'datetime_', [], 'wholebrain', []).
            
            assert(ischar(physio))
            this = mlraichle.QuadraticAerobicGlycolysisKit(varargin{:});
            sd = this.sessionData;
            pwd0 = pushd(sd.subjectPath);
            
            qc.subject = sd.subjectFolder;
            qc.filename = sd.([physio 'OnAtlas'])('tags', sd.regionTag);
            qc.datetime_ = datetime(sd);
            
            wm1 = mlfourd.ImagingFormatContext(sd.wmparc1OnAtlas);
            wm1.img(wm1.img == 40) = 0;
            wm1 = mlfourd.ImagingContext2(wm1);
            wm1 = wm1.binarized();            
            ic = mlfourd.ImagingContext2(qc.filename);
            ic = ic.volumeAveraged(wm1);
            wb = ic.fourdfp.img;
            assert(isscalar(wb))
            qc.wholebrain = wb;
            
            popd(pwd0);
        end
        function writeqc(physio, qc, averaging)
            physiology = repmat({physio}, [length(qc) 1]);            
            tbl = table( ...
                physiology, {qc.subject}', {qc.filename}', {qc.datetime_}', {qc.(averaging)}', ...
                'VariableNames', ...
                {'Physiology', 'Subject', 'Filename', 'DateTime', averaging});
            writetable(tbl, ['qc_' physio '_wholebrain.xlsx'])
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
        
        function fs_ = buildFsByVoxels(this, varargin)
            %% BUILDFSBYVOXELS
            %  @return fs in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            
            import mlpet.AbstractAerobicGlycolysisKit
            import mloxygen.QuadraticNumericRaichle1983
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            brain = this.sessionData.brainOnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);             
            scanner = devkit.buildScannerDevice();
            scannerBrain = scanner.volumeAveraged(brain.binarized());           
            arterial = devkit.buildArterialSamplingDevice(scannerBrain, ...
                                                          'sameWorldline', false, ...
                                                          'indexCliff', this.indexCliff);
            h = plot(arterial.radialArteryKit);
            this.savefig(h, 0, 'tags', 'HO radial artery')
            
            fs_ = copy(brain.fourdfp);
            fs_.filepath = this.dataPath;
            fs_.fileprefix = this.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);

            % solve Raichle
            fprintf('%s\n', datestr(now))
            fprintf('starting mlraichle.QuadraticAerobicGlycolysisKit.buildFsByVoxels\n')
            raichle = QuadraticNumericRaichle1983.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', brain.binarized());  
            raichle = raichle.solve();
            this.model = raichle;

            % insert Raichle solutions into fs
            fs_.img = raichle.fs('typ', 'single');
                
            fs_ = mlfourd.ImagingContext2(fs_);
            popd(pwd0);
        end 
        function os_ = buildOsByVoxels(this, varargin)
            %% BUILDOSBYVOXELS
            %  @return os in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
                    
            import mloxygen.QuadraticNumericMintun1984
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            brain = this.sessionData.brainOnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);            
            scanner = devkit.buildScannerDevice(); 
            scannerBrain = scanner.volumeAveraged(brain.binarized());         
            arterial = devkit.buildArterialSamplingDevice(scannerBrain, ...
                                                          'sameWorldline', false, ...
                                                          'indexCliff', this.indexCliff);
            h = plot(arterial.radialArteryKit);
            this.savefig(h, 0, 'tags', 'OO radial artery')
            
            os_ = copy(brain.fourdfp);
            os_.filepath = this.dataPath;
            os_.fileprefix = this.osOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);

            % solve Mintun
            fprintf('%s\n', datestr(now))
            fprintf('starting mlraichle.QuadraticAerobicGlycolysisKit.buildOsByVoxels\n')
            mintun = QuadraticNumericMintun1984.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', brain.binarized());  
            mintun = mintun.solve();
            this.model = mintun;

            % insert Raichle solutions into fs
            os_.img = mintun.os('typ', 'single');

            os_ = mlfourd.ImagingContext2(os_);
            popd(pwd0);
        end
        function vs_ = buildVsByVoxels(this, varargin)
            %% BUILDVSBYVOXELS
            %  @return v1_ in R^ as mlfourd.ImagingContext2, without saving to filesystems.  
            %  @return cbv_ in R^3, without saving.
            
            import mloxygen.QuadraticNumericMartin1987
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);                                    
            
            brain = this.sessionData.brainOnAtlas('typ', 'mlfourd.ImagingContext2');
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);             
            scanner = devkit.buildScannerDevice();
            scannerBrain = scanner.volumeAveraged(brain.binarized());            
            arterial = devkit.buildArterialSamplingDevice(scannerBrain, ...
                                                          'sameWorldline', false); 
            h = plot(arterial.radialArteryKit);
            this.savefig(h, 0, 'tags', 'CO radial artery') 
            
            vs_ = copy(brain.fourdfp);
            vs_.filepath = this.dataPath;
            vs_.fileprefix = this.vsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);

            % solve Martin
            fprintf('%s\n', datestr(now))
            fprintf('starting mlraiche.QuadraticAerobicGlycolysisKit.buildVsByVoxels\n')
            martin = QuadraticNumericMartin1987.createFromDeviceKit( ...
                devkit, ...
                'scanner', scanner, ...
                'arterial', arterial, ...
                'roi', brain.binarized());
            martin = martin.solve();  
            this.model = martin;

            % insert Martin solutions into fs
            vs_.img = martin.vs('typ', 'single');

            vs_ = mlfourd.ImagingContext2(vs_);
            popd(pwd0);
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
    
    methods (Access = protected)
 		function this = QuadraticAerobicGlycolysisKit(varargin)
 			this = this@mlpet.AbstractAerobicGlycolysisKit(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indexCliff', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;
            this.indexCliff = ipr.indexCliff;
            
            this.dataFolder = 'resampling_restricted';
            this.resetModelSampler()
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

