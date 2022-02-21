classdef FieldAerobicGlycolysisKit < handle & mlpet.AbstractAerobicGlycolysisKit
	%% FIELDAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 23-Aug-2021 13:42:48 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.10.0.1710957 (R2021a) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties 
        model
        sessionData
    end
    
    properties (Dependent)
        blurTag
        dataFolder
        dataPath
        regionTag
        subjectFolder
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
            import mlraichle.FieldAerobicGlycolysisKit.*

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
            addParameter(ip, 'region', 'surferfields', @ischar)
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
                    construction = @FieldAerobicGlycolysisKit.constructCbvByRegion;                            
                case 'cbf'
                    tracer = 'ho';
                    metric = 'fs';
                    region = ipr.region;
                    construction = @FieldAerobicGlycolysisKit.constructCbfByRegion;
                case 'cmro2'
                    tracer = 'oo';
                    metric = 'os';
                    region = ipr.region;
                    construction = @FieldAerobicGlycolysisKit.constructCmro2ByRegion;
                otherwise
                    error('mlpet:RuntimeError', 'FieldAerobicGlycolysisKit.construct.ipr.physiology->%s', ipr.physiology)
            end
            
            % construct            
            pwd1 = pushd(subjectsDir);
            FieldAerobicGlycolysisKit.initialize()
            theSessionData = FieldAerobicGlycolysisKit.constructSessionData( ...
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
            %  @return cbf on filesystem.
            
            this = mlraichle.FieldAerobicGlycolysisKit(varargin{:});            
            Region = [upper(this.sessionData.region(1)) this.sessionData.region(2:end)];
            pwd0 = pushd(this.sessionData.subjectPath);            
            
            fs_ = this.(['buildFsBy' Region])();             
            cbf_ = this.fs2cbf(fs_);
            
            % save ImagingContext2
            cbf_.save()
            
            popd(pwd0);
        end
    end

	methods 
        
        %% GET
        
        function g = get.blurTag(~)
            g = mlraichle.StudyRegistry.instance.blurTag;
            %g = this.sessionData.petPointSpreadTag;
        end
        function g = get.dataFolder(this)
            g = this.sessionData.dataFolder;
        end  
        function g = get.dataPath(this)
            g = fullfile(this.sessionData.subjectPath, this.dataFolder, '');
        end  
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end
        function g = get.subjectFolder(this)
            g = this.sessionData.subjectFolder;
        end
        function g = get.subjectPath(this)
            g = this.sessionData.subjectPath;
        end
        
        %%
        
        function fs_ = buildFsBySurferfields(this, varargin)
            %% BUILDFSBYSURFERFIELDS
            %  @return fs in R^4 as mlfourd.ImagingContext2, without saving to filesystems.  
            
            import mlpet.AbstractAerobicGlycolysisKit
            import mloxygen.FieldNumericRaichle1983
            
            ensuredir(this.dataPath);
            pwd0 = pushd(this.dataPath);  
                                    
            brain = this.sessionData.brainOnAtlas('typ', 'mlfourd.ImagingContext2'); 
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);             
            scanner = devkit.buildScannerDevice();
            scannerBrain = scanner.volumeAveraged(brain.binarized());           
            arterial = devkit.buildArterialSamplingDevice(scannerBrain, ...
                                                          'sameWorldline', false);
            h = plot(arterial.radialArteryKit);
            this.savefig(h, 0, 'tags', 'HO radial artery')
            
            fs_ = copy(brain.fourdfp);
            fs_.filepath = this.dataPath;
            fs_.fileprefix = this.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);

            % solve Raichle
            fprintf('%s\n', datestr(now))
            fprintf('starting mlraichle.FieldAerobicGlycolysisKit.buildFsByVoxels\n')
            raichle = FieldNumericRaichle1983.createFromDeviceKit( ...
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
    end
    
	methods (Access = protected)
 		function this = FieldAerobicGlycolysisKit(varargin)
 			this = this@mlpet.AbstractAerobicGlycolysisKit(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.sessionData = ipr.sessionData;            
            this.dataFolder = 'resampling_restricted';
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

