classdef Ccir559754Json
    %% CCIR559754JSON manages *.json and *.mat data repositories for CNDA-related data such as subjects, experiments, aliases,
    %  ct, unique subject-ID...
    
    %  $Revision$
    %  was created 11-May-2019 15:04:39 by jjlee,
    %  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
    %% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
    
    methods (Static)
        
        function S = loadConstructed()
            import mlraichle.Ccir559754Json;
            S = jsondecode(fileread(fullfile(Ccir559754Json.datapath, mlraichle.Ccir559754Json.filenameConstructed)));
        end
        
        function saveConstructed(S)
            assert(isstruct(S))
            
            datapath = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'data', '');
            fid = fopen(fullfile(datapath, mlraichle.Ccir559754Json.filenameConstructed), 'w');
            fprintf(fid, jsonencode(S));
            fclose(fid);            
        end
        
        function [j559,j754] = hand_curated()
            %load(fullfile(this.datapath, 'j559.mat'), 'j559')
            %load(fullfile(this.datapath, 'j754.mat'), 'j754')            
            
            import mlraichle.Ccir559754Json;
            j559 = jsondecode(fileread(fullfile(Ccir559754Json.datapath, 'CCIR_00559.json')));
            j754 = jsondecode(fileread(fullfile(Ccir559754Json.datapath, 'CCIR_00754.json')));
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
            
            S = jsondecode(fileread(mlraichle.Ccir559754Json.filenameConstructed));
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
    
    properties (Constant)
        filenameConstructed = 'constructed_20190725.json'      
        datapath = fullfile(getenv('SINGULARITY_HOME'), 'subjects', '')
    end
    
    
    methods
        function prjf = tradt_to_projectFolder(this, tradt)
            re = regexp(tradt, '^[a-z]+dt(?<datetime>\d+)\S*', 'names');
            date = re.datetime(1:8);
            exp = this.date2experimentMap_(date);
            prjf = this.experiment2projectMap_(exp);
        end
        function sesf = tradt_to_sessionFolder(this, tradt)   
            re = regexp(tradt, '^[a-z]+dt(?<datetime>\d+)\S*', 'names');
            date = re.datetime(1:8);
            exp = this.date2experimentMap_(date);         
            exp = strsplit(exp, '_');
            sesf = ['ses-' exp{2}];
        end
        
        function this = Ccir559754Json(varargin)
            %% JSON
            %  @param .
            
            this.S_ = mlraichle.Ccir559754Json.loadConstructed();            
            [this.S559_,this.S754_] = this.hand_curated();
            this.experiment2projectMap_ = containers.Map;
            this.date2experimentMap_ = containers.Map;
            this = this.buildExperiment2projectMap();
            this = this.buildDate2experimentMap(this.S_);            
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        S_
        S559_
        S754_    
        date2experimentMap_
        experiment2projectMap_
    end
    
    methods (Access = protected)
        function this = buildExperiment2projectMap(this)
            for sub = asrow(fields(this.S559_))
               for exp = asrow(this.S559_.(sub{1}).experiments)
                   this.experiment2projectMap_(exp{1}) = 'CCIR_00559';
               end
            end
            for sub = asrow(fields(this.S754_))
               for exp = asrow(this.S754_.(sub{1}).experiments)
                   this.experiment2projectMap_(exp{1}) = 'CCIR_00754';
               end
            end
        end
        function this = buildDate2experimentMap(this, node)
            for sub = asrow(fields(node))
                dates = node.(sub{1}).dates;
                for exp = asrow(fields(dates))
                    if isfield(node.(sub{1}), 'ct_experiment') && ...
                            this.isct(node.(sub{1}).ct_experiment, exp{1})
                        continue
                    end
                    date = node.(sub{1}).dates.(exp{1});
                    this.date2experimentMap_(date) = exp{1};
                end
                
                if isfield(node.(sub{1}), 'aliases')
                    this = this.buildDate2experimentMap(node.(sub{1}).aliases);
                end
            end
        end
        function tf = isct(this, ct_exp, exp1)
            if iscell(ct_exp)
                tf = false;
                for ct = asrow(ct_exp)
                    tf = tf || this.isct(ct{1}, exp1);
                end
                return
            end
            
            % base case
            tf = strcmp(ct_exp, exp1);
        end
    end
    
    %  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

