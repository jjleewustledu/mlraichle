classdef MMRBids < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable  
	%% MMRBIDS  

	%  $Revision$
 	%  was created 13-Nov-2021 15:03:32 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties (Dependent)
        anatPath
        projPath
        derivativesPath
        destinationPath 		
        mriPath
        petPath
        sourcedataPath
        sourceAnatPath
        sourcePetPath
        subFolder
        tof_ic
        tof_mask_ic
        T1w_ic
        wmparc_ic
    end

	methods

        %% GET

        function g = get.anatPath(this)
            g = fullfile(this.derivativesPath, this.subFolder, 'anat');
            assert(isfolder(g))
        end
        function g = get.projPath(this)
            g = this.projPath_;
            assert(isfolder(g))
        end
        function g = get.derivativesPath(this)
            g = fullfile(this.projPath, 'derivatives', '');
            assert(isfolder(g))
        end
        function g = get.destinationPath(this)
            g = this.destPath_;
            assert(isfolder(g))
        end
        function g = get.mriPath(this)
            g = fullfile(this.derivativesPath, this.subFolder, 'mri', '');
            assert(isfolder(g))
        end
        function g = get.petPath(this)
            g = fullfile(this.derivativesPath, this.subFolder, 'pet', '');
            assert(isfolder(g))
        end
        function g = get.sourcedataPath(this)
            g = fullfile(this.projPath, 'sourcedata', '');
            assert(isfolder(g))
        end
        function g = get.sourceAnatPath(this)
            g = fullfile(this.sourcedataPath, this.subFolder, 'anat', '');
            assert(isfolder(g))
        end
        function g = get.sourcePetPath(this)
            g = fullfile(this.sourcedataPath, this.subFolder, 'pet', '');
            assert(isfolder(g))
        end
        function g = get.subFolder(this)
            g = this.subFolder_;
        end
        function g = get.tof_ic(this)
            if ~isempty(this.tof_ic_)
                g = copy(this.tof_ic_);
                return
            end
            g = globT(fullfile(this.anatPath, '*TOF*.nii.gz'));
            assert(~isempty(g))
            fn = g{end};

            this.tof_ic_ = mlfourd.ImagingContext2(fn);
            this.tof_ic_.selectNiftiTool();
            this.tof_ic_.fileprefix = 'tof';
            g = copy(this.tof_ic_);

%             fn = fullfile(this.sourceAnatPath, 'tof.4dfp.hdr');
%             if ~isfile(fn)
%                 fn_sourcedata = glob(fullfile(this.sourcedataPath, this.subFolder, 'scans', '*TOF*', '*TOF*.4dfp.hdr'));
%                 if iscell(fn_sourcedata)
%                     fn_sourcedata = fn_sourcedata{end};
%                 end
%                 v = mlfourdfp.FourdfpVisitor();
%                 v.lns_4dfp(fn_sourcedata, fn);
%             end
%             assert(isfile(fn))
%             this.tof_ic_ = mlfourd.ImagingContext2(fn);
%             this.tof_ic_.filepath = this.anatPath;
%             g = copy(this.tof_ic_);
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
        function g = get.T1w_ic(this)
            if ~isempty(this.T1w_ic_)
                g = copy(this.T1w_ic_);
                return
            end
            fn = fullfile(this.anatPath, 'T1001.nii.gz');
            assert(isfile(fn))
            this.T1w_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.T1w_ic_);
        end
        function g = get.wmparc_ic(this)
            if ~isempty(this.wmparc_ic_)
                g = copy(this.wmparc_ic_);
                return
            end
            fn = fullfile(this.anatPath, 'wmparc.nii.gz');
            assert(isfile(fn))
            this.wmparc_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.wmparc_ic_);
        end

        %%

 		function this = MMRBids(varargin)
            %  @param destPath will receive outputs.
            %  @projPath belongs to a CCIR project.
            %  @subFolder is the BIDS-adherent string for subject identity.

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'destPath', pwd, @isfolder)
            addParameter(ip, 'projPath', fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', ''), @isfolder)
            addParameter(ip, 'subFolder', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.destPath_ = ipr.destPath;
            this.projPath_ = ipr.projPath;
            this.subFolder_ = ipr.subFolder;
            if isempty(this.subFolder_)
                this.parseDestinationPath(this.destPath_)
            end
        end
        
        function parseDestinationPath(this, dpath)
            assert(contains(dpath, 'CCIR_00559_00754'), 'mlraichle.MMRBids: destination path must include a project identifier')
            assert(contains(dpath, 'sub-'), 'mlraichle.MMRBids: destination path must include a subject identifier')

            this.destPath_ = dpath;
            ss = strsplit(dpath, filesep);
            [~,idxProjFold] = max(contains(ss, 'CCIR_'));
            this.projPath_ = [filesep fullfile(ss{1:idxProjFold})];
            this.subFolder_ = ss{contains(ss, 'sub-')}; % picks first occurance
        end
        function s = pet_toglob(~, varargin)
            s = fullfile(this.petPath, '*dt*_on_T1001.4dfp.hdr');
        end
        function selectNiftiTool(this)
            this.tof_ic_.selectNiftiTool();
            this.tof_mask_ic_.selectNiftiTool();
            this.T1w_ic_.selectNiftiTool();
            this.wmparc_ic_.selectNiftiTool();
        end
        function n = tracername(~, str)
            if contains(str, 'co', 'IgnoreCase', true) || contains(str, 'oc', 'IgnoreCase', true)
                n = 'CO';
                return
            end
            if contains(str, 'oo', 'IgnoreCase', true)
                n = 'OO';
                return
            end
            if contains(str, 'ho', 'IgnoreCase', true)
                n = 'HO';
                return
            end
            if contains(str, 'fdg', 'IgnoreCase', true)
                n = 'FDG';
                return
            end
            error('mlraichle:ValeError', 'MMRBids.tracername() did not recognize %s', str)
        end
 	end 
    
    %% PRIVATE
    
    properties (Access = private)
        destPath_
        projPath_
        subFolder_
        tof_ic_
        tof_mask_ic_
        T1w_ic_
        wmparc_ic_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

