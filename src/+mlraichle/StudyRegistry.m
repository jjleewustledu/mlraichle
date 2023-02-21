classdef (Sealed) StudyRegistry < handle & mlnipet.StudyRegistry
	%% STUDYREGISTRY 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64. 	
    
    properties
        atlasTag = '111'
        blurTag = ''
        comments = ''
        Ddatetime0 % seconds
        dicomExtension = '.dcm'
        ignoredExperiments = {'52823', '53317', '53343', '178378', '186470'}
        noclobber = true
        normalizationFactor = 1
        numberNodes
        projectFolder = 'CCIR_00559_00754'
        projectFolders = {'CCIR_00559', 'CCIR_00754'};
        referenceTracer = 'FDG'
        scatterFraction = 0
        T = 10 % sec at the start of artery_interpolated used for model but not described by scanner frames
        stableToInterpolation = true
        tracerList = {'oc' 'oo' 'ho' 'fdg'}
        umapType = 'ct'
        voxelTime = 60 % sec
        wallClockLimit = 168*3600 % sec
    end
    
    properties (Dependent)
        projectsDir
        rawdataDir
        sessionsDir
        subjectsDir
        subjectsJson
        tBuffer
    end 
    
    methods % GET        
        function g = get.projectsDir(~)
            g = getenv('SINGULARITY_HOME');
        end 
        function x = get.rawdataDir(~)
            x = fullfile(getenv('PPG'), 'rawdata', '');
        end
        function g = get.sessionsDir(this)
            g = fullfile(this.projectsDir, this.projectFolder, 'derivatives', 'nipet', '');
        end
        function g = get.subjectsDir(this)
            g = fullfile(this.projectsDir, this.projectFolder, 'derivatives', 'resolve', '');
        end 
        function g = get.subjectsJson(this)
            if isempty(this.subjectsJson_)
                this.subjectsJson_ = jsondecode( ...
                    fileread(fullfile(this.projectsDir, this.projectFolder, 'constructed_20190725.json')));
            end
            g = this.subjectsJson_;
        end
        function g = get.tBuffer(this)
            g = max(0, -this.Ddatetime0) + this.T;
        end
    end
    
    methods
        function dt = ses2dt(this, ses)
            ses = strsplit(ses, '-');
            ses = ses{2};
            j = this.subjectsJson;
            for f = asrow(fields(j))
                if any(contains(j.(f{1}).experiments, ses))
                    dfield = fields(j.(f{1}).dates);
                    dt = j.(f{1}).dates.(dfield{1});
                    dt = datetime(dt, 'InputFormat', 'yyyyMMdd');
                    return
                end
                if isfield(j.(f{1}), 'aliases')
                    J = j.(f{1}).aliases;
                    for F = asrow(fields(J))
                        if any(contains(J.(F{1}).experiments, ses))
                            dfield = fields(J.(F{1}).dates);
                            dt = J.(F{1}).dates.(dfield{1});
                            dt = datetime(dt, 'InputFormat', 'yyyyMMdd');
                            return
                        end
                    end
                end
            end
        end
        function ses = dt2ses(this, dt)
            ds = datestr(dt, 'yyyymmdd');
            j = this.subjectsJson;
            for f = asrow(fields(j))
                dfield = fields(j.(f{1}).dates);
                if strcmp(ds, j.(f{1}).dates.(dfield{1}))
                    ses = j.(f{1}).experiments;
                    ses = strsplit(ses{1}, '_');
                    ses = strcat('ses-', ses{2});
                    return
                end
                if isfield(j.(f{1}), 'aliases')
                    J = j.(f{1}).aliases;
                    for F = asrow(fields(J))
                        dfield = fields(J.(F{1}).dates);
                        if strcmp(ds, J.(F{1}).dates.(dfield{1}))
                            ses = J.(F{1}).experiments;
                            ses = strsplit(ses{1}, '_');
                            ses = strcat('ses-', ses{2});
                            return
                        end
                    end
                end
            end
        end
        function ses = sub2ses(this, sub)
            ses = {};
            sub = strsplit(sub, '-');
            sub = sub{2};
            j = this.subjectsJson;
            for f = asrow(fields(j))
                if contains(j.(f{1}).sid, sub)
                    for ses_ = asrow(j.(f{1}).experiments)
                        ses__ = strsplit(ses_{1}, '_');
                        ses = [ses strcat('ses-', ses__{2})]; %#ok<AGROW>
                    end
                end
                if isfield(j.(f{1}), 'aliases')
                    J = j.(f{1}).aliases;
                    for F = asrow(fields(J))
                        if contains(J.(F{1}).sid, sub)
                            for ses_ = asrow(J.(F{1}).experiments)
                                ses__ = strsplit(ses_{1}, '_');
                                ses = [ses strcat('ses-', ses__{2})]; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
        end
        function sub = ses2sub(this, ses)
            ses = strsplit(ses, '-');
            ses = ses{2};
            j = this.subjectsJson;
            for f = asrow(fields(j))
                if any(contains(j.(f{1}).experiments, ses))
                    sub = j.(f{1}).sid;
                    sub = strsplit(sub, '_');
                    sub = strcat('sub-', sub{2});
                    return
                end
                if isfield(j.(f{1}), 'aliases')
                    J = j.(f{1}).aliases;
                    for F = asrow(fields(J))
                        if any(contains(J.(F{1}).experiments, ses))
                            sub = J.(F{1}).sid;
                            sub = strsplit(sub, '_');
                            sub = strcat('sub-', sub{2});
                            return
                        end
                    end
                end
            end
        end
    end    
    
    methods (Static)
        function this = instance()
            persistent uniqueInstance  
            if (isempty(uniqueInstance))
                this = mlraichle.StudyRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 

    %% PRIVATE
    
    properties (Access = private)
        subjectsJson_
    end
    
	methods (Access = private)		  
 		function this = StudyRegistry(varargin)
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

