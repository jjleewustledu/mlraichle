classdef (Sealed) Ccir559754Registry < handle & mlnipet.StudyRegistry
    %% CCIR559754REGISTRY
    %  
    %  Created 22-Feb-2023 23:34:44 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
    %  Developed on Matlab 9.13.0.2126072 (R2022b) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        projectsDir
        projectFolder
        projectFolders = {'CCIR_00559', 'CCIR_00754'}
        rawdataDir
    end
    
    properties (Dependent)        
        subjectsJson
    end 
    
    methods % GET 
        function g = get.subjectsJson(this)
            if isempty(this.subjectsJson_)
                this.subjectsJson_ = jsondecode( ...
                    fileread(fullfile(this.projectsDir, this.projectFolder, 'constructed_20190725.json')));
            end
            g = this.subjectsJson_;
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
    
	methods (Access = private)		  
 		function this = StudyRegistry(varargin)
            this.atlasTag = '111';
            this.ignoredExperiments = {'52823', '53317', '53343', '178378', '186470'};
            this.projectsDir = getenv('SINGULARITY_HOME');
            this.projectFolder = 'CCIR_00559_00754';
            this.rawdataDir = fullfile(getenv('PPG'), 'rawdata', '');
            this.reconstructionMethod = 'NiftyPET';
            this.referenceTracer = 'FDG';
            this.T = 10; % sec at the start of artery_interpolated used for model but not described by scanner frames
            this.tracerList = {'oc' 'oo' 'ho' 'fdg'};
            this.umapType = 'ct';
 		end
    end 
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
