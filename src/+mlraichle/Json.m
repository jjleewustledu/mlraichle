classdef Json
    %% JSON manages *.json and *.mat data repositories for CNDA-related data such as subjects, experiments, aliases,
    %  ct, unique subject-ID...
    
    %  $Revision$
    %  was created 11-May-2019 15:04:39 by jjlee,
    %  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
    %% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
    
    properties (Constant)
        filenameConstructed = 'constructed_20190725.json'
    end
    
    methods (Static)
        
        function S = loadConstructed()
            datapath = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'data', '');
            S = jsondecode(fileread(fullfile(datapath, mlraichle.Json.filenameConstructed)));
        end
        function saveConstructed(S)
            assert(isstruct(S))
            
            datapath = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'data', '');
            fid = fopen(fullfile(datapath, mlraichle.Json.filenameConstructed), 'w');
            fprintf(fid, jsonencode(S));
            fclose(fid);            
        end
        function [j559,j754] = hand_curated()
            datapath = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'data', '');
            load(fullfile(datapath, 'j559.mat'), 'j559')
            load(fullfile(datapath, 'j754.mat'), 'j754')
        end
        
        function S = json_for_construct_ct(j754, j559)
            % @param j754 is a hand-curated struct
            % @param j559 is a hand-curated struct
            
            % accumulate subjects with ct
            S = struct();
            j7_subjs = fields(j754);
            for s = 1:length(j7_subjs)
                j7_subj = j7_subjs{s};
                if isfield(j754.(j7_subj), 'ct') && isfield(j754.(j7_subj), 'sid')
                    S.(j7_subj) = j754.(j7_subj);
                end
            end
            j5_subjs = fields(j559);
            for s = 1:length(j5_subjs)
                j5_subj = j5_subjs{s};
                if isfield(j559.(j5_subj), 'ct') && isfield(j559.(j5_subj), 'sid')
                    S.(j5_subj) = j559.(j5_subj);
                end
            end
            
            % accumulate subject aliases
            S_subjs = fields(S);
            for ss = 1:length(S_subjs)
                sid = S.(S_subjs{ss}).sid;
                for j7 = 1:length(j7_subjs)
                    j7_subj = j7_subjs{j7};
                    if (isfield(j754.(j7_subj), 'sid'))
                        if strcmp(j754.(j7_subj).sid, sid) && ...
                                ~strcmp(j754.(j7_subj).id,  sid)
                            S.(S_subjs{ss}).aliases.(j7_subj) = j754.(j7_subj);
                        end
                    end
                end
                for j5 = 1:length(j5_subjs)
                    j5_subj = j5_subjs{j5};
                    if (isfield(j559.(j5_subj), 'sid'))
                        if strcmp(j559.(j5_subj).sid, sid) && ...
                                ~strcmp(j559.(j5_subj).id,  sid)
                            S.(S_subjs{ss}).aliases.(j5_subj) = j559.(j5_subj);
                        end
                    end
                end
            end
            
            fid = fopen('construct_ct.json', 'w');
            fprintf(fid, jsonencode(S));
            fclose(fid);
        end
        
        function jXXX_to_json(j559, j754)
            % @param j559 is a hand-curated struct
            % @param j754 is a hand-curated struct
            
            fid = fopen('CCIR_00559.json', 'w');
            fprintf(fid, jsonencode(j559));
            fclose(fid);
            
            fid = fopen('CCIR_00754.json', 'w');
            fprintf(fid, jsonencode(j754));
            fclose(fid);
        end
        
        function S = dispExperimentsForAllS()
            
            S = jsondecode(fileread(mlraichle.Json.filenameConstructed));
            fS = sort(fields(S));
            for s = 1:length(fS)
                if isfield(S.(fS{s}), 'sid')
                    fprintf('Subject:  %s %s\n', fS{s}, S.(fS{s}).sid);
                else
                    fprintf('Subject:  %s\n', fS{s});
                end
                expts = S.(fS{s}).experiments;
                for e = 1:length(expts)
                    fprintf('\t%s\n', expts{e});
                end
                
                if isfield(S.(fS{s}), 'aliases')
                    fA = fields(S.(fS{s}).aliases);
                    for a = 1:length(fA)
                        if isfield(S.(fS{s}).aliases.(fA{a}), 'id')
                            fprintf('\tSubject Alias:  %s %s\n', fA{a}, S.(fS{s}).aliases.(fA{a}).id);
                        else
                            fprintf('\tSubject Alias:  %s\n', fA{a});
                        end
                        expts1 = S.(fS{s}).aliases.(fA{a}).experiments;
                        for e1 = 1:length(expts1)
                            fprintf('\t\t%s\n', expts1{e1});
                        end
                    end
                end
            end
        end
        
        function [lbl,id] = exp2sbj(e, varargin)
            %% EXP2SBJ searches local file mlraichle.StudyRegistry.subjectsJson for
            %  @param experiment, char or cell array of char;
            %  @returns subject label, char, and
            %  @returns subject id, char or cell array of char.
            
            registry = mlraichle.StudyRegistry.instance;
            top_json = registry.subjectsJson;
            
            ip = inputParser;
            addRequired(ip, 'e', @ischar);
            addOptional(ip, 'top', from_json, @isstruct)
            parse(ip, e, varargin{:});
            
            % cell array case
            if iscell(e)
                lbl = cell(size(e));
                id  = cell(size(e));
                for ie = 1:length(e)
                    [lbl{ie},id{ie}] = exp2sbj(e{ie}, varargin{:});
                end
                return
            end
            
            % base case
            lbl = '';
            id = '';
            subject_names = fields(ip.Results.top);
            for iname = 1:length(subject_names)
                subject = ip.Results.top.(subject_names{iname}); % is struct
                assert(isfield(subject, 'experiments'))
                experiments = subject.experiments; % is cell
                for ie = 1:length(experiments)
                    if strcmp(e, experiments{ie})
                        lbl = subject_names{iname};
                        id  = subject.id;
                        return
                    end
                end
                
                % recursion for aliases
                if isfield(subject, 'aliases')
                    if lstrfind(subject_names{iname}, fields(subject.aliases))
                        [lbl,id] = exp2sbj(e, subject.aliases);
                        return
                    end
                end
            end
            
            %% INTERNAL
            
            function top = from_json()
                top = jsondecode(fileread(top_json));
            end
            
        end        
    end
    
    methods
        function this = Json(varargin)
            %% JSON
            %  @param .
            
            
        end
    end
    
    %  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

