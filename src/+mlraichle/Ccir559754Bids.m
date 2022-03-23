classdef Ccir559754Bids < handle & mlpipeline.IBids
	%% CCIR559754BIDS  

	%  $Revision$
 	%  was created 13-Nov-2021 15:03:32 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
    methods (Static)
        function [s,r] = dcm2niix(varargin)
            [s,r] = mlpipeline.Bids.dcm2niix(varargin{:});
        end
        function tf = isdynamic(obj)
            tf = ~mlraichle.Ccir559754Bids.isstatic(obj);
        end
        function tf = isnac(obj)
            ic = mlfourd.ImagingContext2(obj);
            re = regexp(ic.filepath, '\w+(dt|DT)\d{14}(?<tags>\S*)', 'names');
            tf = contains(re.tags, 'nac', 'IgnoreCase', true);
        end
        function tf = isstatic(obj)
            ic = mlfourd.ImagingContext2(obj);
            re = regexp(ic.fileprefix, '\w+(dt|DT)\d{14}(?<tags>\S*)', 'names');
            tf = contains(re.tags, '_avgt') || contains(re.tags, '_sumt');
        end
        function movefiles(varargin)
            %% Move files on filesystem specifying source using glob().  Dereference valid symbolic links in the source directory.
            %  Args:
            %      source (required text)
            %      dest (required text)

            ip = inputParser;
            addRequired(ip, 'source', @istext)
            addRequired(ip, 'dest', @istext)
            parse(ip, varargin{:});
            ipr = ip.Results;
            assert(~contains(ipr.dest, '*'))

            for g = globT(ipr.source)
                if isfile(fullfile(ipr.dest, basename(g{1})))
                    continue
                end
                try
                    r = '';
                    if unix(sprintf('test -L %s', g{1}))
                        % not sym. link
                        [~,r] = mlbash(sprintf('mv %s %s', g{1}, ipr.dest));
                    else
                        [~,r] = mlbash(sprintf('rsync -aL %s %s', g{1}, ipr.dest));
                    end
                catch ME
                    handexcept(ME, r)
                end
            end
        end
        function move_pet(varargin)
            %% Move large files for pet on filesystem specifying source using glob().  
            %  For symbolic links, look up location of original file and create new link the destination folder.
            %  Args:
            %      source (required text)
            %      dest (required text)
            %      sub (required text): e.g., sub-S12345

            ip = inputParser;
            addRequired(ip, 'source', @istext)
            addRequired(ip, 'dest', @istext)
            addRequired(ip, 'sub', @istext)
            parse(ip, varargin{:});
            ipr = ip.Results;
            assert(~contains(ipr.dest, '*'))

            for g = globT(ipr.source)
                if isfile(fullfile(ipr.dest, basename(g{1})))
                    continue
                end
                mlraichle.Ccir559754Bids.relink_pet(ipr.sub, g{1}, ipr.dest);
            end
        end
        function move_resampling_restricted(varargin)
            import mlraichle.Ccir559754Bids.movefiles;
            import mlraichle.Ccir559754Bids.move_pet;

            ip = inputParser;
            addRequired(ip, 'source', @isfolder)
            parse(ip, varargin{:});
            ipr = ip.Results;
            assert(endsWith(ipr.source, 'resampling_restricted'))

            pwd0 = pushd(ipr.source);

            ss = strsplit(ipr.source, filesep);
            sub = ss{contains(ss, 'sub-')};
            dest = fullfile(getenv('PPG'), ...
                'jjlee', 'Singularity', 'CCIR_00559_00754', 'derivatives', 'resolve', sub, 'resampling_restricted', '');
            if ~isfolder(dest)
                mkdir(dest)
            end

            % FreeSurfer objects
            movefiles('{brain,wmparc,T1001}.4dfp.*', dest);

            % json
            movefiles('{OC,OO,HO,FDG}_DT*.json', dest);

            % pet t4
            movefiles('{oc,oo,ho,fdg}dt*_to_*_t4', dest);

            % pet dynamic, static
            for g = globT('{oc,oo,ho,fdg}dt*.4dfp.*')
                % {oc, oo, ho, fdg}dtyyyymmddHHMMss.4dfp.*
                idx = regexp(g{1}, '[a-z]+dt\d{14}.4dfp.\S+', 'once'); % starting index
                if ~isempty(idx)
                    move_pet(g{1}, dest, sub);
                    continue
                end

                % {oc, oo, ho, fdg}dtyyyymmddHHMMss_avgt.4dfp.*
                idx_ = regexp(g{1}, '[a-z]+dt\d{14}_avgt.4dfp.\S+', 'once'); % starting index
                if ~isempty(idx_)
                    move_pet(g{1}, dest, sub);
                    continue
                end
            end

            popd(pwd0);
        end
        function tr = obj2tracer(obj)
            ic = mlfourd.ImagingContext2(obj);
            try
                re = regexp(ic.fileprefix, '(?<tr>\w+)(dt|DT)\d{14}\S*', 'names');
                tr = upper(re.tr);
            catch
                re = regexp(ic.fileprefix, '(?<tr>[a-z]+)r\d{1}\S*', 'names');
                tr = upper(re.tr);
            end
        end
        function relink_pet(sub, fn, dest)
            assert(istext(sub), sub)
            assert(isfile(fn), fn)
            assert(isfolder(dest), dest)
            fn = basename(fn);

            j = mlraichle.Ccir559754Json();
            ses = j.tradt_to_sessionFolder(fn);
            converted_folder = fn2converted(fn);
            referent_patt = fn2patt(fn);
            toglob = fullfile(getenv('PPG'), ...
                'jjlee', 'Singularity', 'CCIR_00559_00754', 'derivatives', 'nipet', ses, converted_folder, ...
                referent_patt);
            referents = glob(toglob);
            assert(~isempty(referents),  '%s not found', toglob)
            assert(isfile(referents{1}), '%s not found', toglob);
            link = fullfile(dest, fn);
            mlbash(sprintf('ln -s %s %s', referents{1}, link));

            function c_ = fn2converted(f_)
                re = regexp(f_, '(?<tra>[a-z]+)(?<dt>dt\d{14})(|_avgt).4dfp.\w+', 'names');
                c_ = sprintf('%s_%s.000000-Converted-AC', upper(re.tra), upper(re.dt));
            end
            function p_ = fn2patt(f_)
                re = regexp(f_, '(?<tra>[a-z]+)(?<dt>dt\d{14})(?<tag>(|_avgt))(?<ext>.4dfp.\S+)', 'names');
                p_ = sprintf('%sr2_op_%sr1_frame*%s%s', re.tra, re.tra, re.tag, re.ext);
            end
        end
    end

    properties (Constant)
        PROJECT_FOLDER = 'CCIR_00559_00754'
        SURFER_VERSION = '5.3-patch'
    end

	properties (Dependent)
        anatPath
        derivAnatPath
        derivativesPath
        derivPetPath
        destinationPath
        mriPath
        petPath
        projectPath
        rawdataPath
        sourcedataPath
        sourceAnatPath
        sourcePetPath
        subjectFolder

        tof_ic
        tof_mask_ic
        t1w_ic
        wmparc_ic
    end

	methods

        %% GET

        function g = get.anatPath(this)
            g = this.derivAnatPath;
        end
        function g = get.derivAnatPath(this)
            g = fullfile(this.derivativesPath, this.subjectFolder, 'anat', '');
        end
        function g = get.derivativesPath(this)
            g = this.registry_.subjectsDir;
        end
        function g = get.derivPetPath(this)
            g = fullfile(this.derivativesPath, this.subjectFolder, 'pet', '');
        end
        function g = get.destinationPath(this)
            g = this.destinationPath_;
        end
        function g = get.mriPath(this)
            g = fullfile(this.registry_.sessionsDir, ...
                this.registry_.sub2ses(this.subjectFolder), 'mri', '');
        end
        function g = get.petPath(this)
            g = this.derivPetPath;
        end
        function g = get.projectPath(this)
            g = this.projectPath_;
        end
        function g = get.rawdataPath(this)
            g = fullfile(this.projectPath, 'rawdata', '');
        end
        function g = get.sourcedataPath(this)
            g = fullfile(this.projectPath, 'sourcedata', '');
        end
        function g = get.sourceAnatPath(this)
            g = fullfile(this.sourcedataPath, this.subjectFolder, 'anat', '');
        end
        function g = get.sourcePetPath(this)
            g = fullfile(this.sourcedataPath, this.subjectFolder, 'pet', '');
        end
        function g = get.subjectFolder(this)
            g = this.subjectFolder_;
        end

        function g = get.tof_ic(this)
            if ~isempty(this.tof_ic_)
                g = copy(this.tof_ic_);
                return
            end
            g = globT(fullfile(this.anatPath, '*TOF*.nii.gz'));
            assert(~isempty(g))
            fn = g{end};
            assert(isfile(fn))
            this.tof_ic_ = mlfourd.ImagingContext2(fn);
            this.tof_ic_.selectNiftiTool();
            this.tof_ic_.filepath = this.anatPath;
            this.tof_ic_.fileprefix = 'tof';
            this.tof_ic_.save();
            g = copy(this.tof_ic_);
        end
        function g = get.tof_mask_ic(this)
            if ~isempty(this.tof_mask_ic_)
                g = copy(this.tof_mask_ic_);
                return
            end
            tmp_ = this.tof_ic.blurred(6);
            tmp_ = tmp_.thresh(30);
            tmp_ = tmp_.binarized();
            this.tof_mask_ic_ = tmp_;
            g = copy(this.tof_mask_ic_);
        end
        function g = get.t1w_ic(this)
            if ~isempty(this.t1w_ic_)
                g = copy(this.t1w_ic_);
                return
            end
            fn = fullfile(this.anatPath, 'T1001.nii.gz');
            assert(isfile(fn))
            this.t1w_ic_ = mlfourd.ImagingContext2(fn);
            this.t1w_ic_.selectNiftiTool();
            this.t1w_ic_.filepath = this.anatPath;
            this.t1w_ic_.save();
            g = copy(this.t1w_ic_);
        end
        function g = get.wmparc_ic(this)
            if ~isempty(this.wmparc_ic_)
                g = copy(this.wmparc_ic_);
                return
            end
            fn = fullfile(this.anatPath, 'wmparc.nii.gz');
            assert(isfile(fn))
            this.wmparc_ic_ = mlfourd.ImagingContext2(fn);
            this.wmparc_ic_.selectNiftiTool();
            this.wmparc_ic_.filepath = this.anatPath;
            this.wmparc_ic_.save();
            g = copy(this.wmparc_ic_);
        end

        %%

 		function this = Ccir559754Bids(varargin)
            %  @param destinationPath will receive outputs.
            %  @projectPath belongs to a CCIR project.
            %  @subjectFolder is the BIDS-adherent string for subject identity.

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'destinationPath', pwd, @isfolder)
            addParameter(ip, 'projectPath', fullfile(getenv('SINGULARITY_HOME'), this.PROJECT_FOLDER), @istext)
            addParameter(ip, 'subjectFolder', '', @istext)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.destinationPath_ = ipr.destinationPath;
            this.projectPath_ = ipr.projectPath;
            this.subjectFolder_ = ipr.subjectFolder;
            if isempty(this.subjectFolder_)
                this.parseDestinationPath(this.destinationPath_)
            end
            this.json_ = mlraichle.Ccir559754Json();
            this.registry_ = mlraichle.StudyRegistry.instance();
        end
        
        function s = pet_toglob(~, varargin)
            s = fullfile(this.petPath, '*dt*_on_T1001.4dfp.hdr');
        end
        function selectNiftiTool(this)
            this.tof_ic_.selectNiftiTool();
            this.tof_mask_ic_.selectNiftiTool();
            this.t1w_ic_.selectNiftiTool();
            this.wmparc_ic_.selectNiftiTool();
        end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        destinationPath_
        json_
        projectPath_
        registry_
        subjectFolder_

        tof_ic_
        tof_mask_ic_
        t1w_ic_
        wmparc_ic_
    end

    methods (Access = protected)
        function parseDestinationPath(this, dpath)
            if contains(dpath, 'sub-')
                ss = strsplit(dpath, filesep);
                this.subjectFolder_ = ss{contains(ss, 'sub-')}; % picks first occurance
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

