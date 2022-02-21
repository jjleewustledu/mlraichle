classdef MMRBids < handle & mlpipeline.Bids
	%% MMRBIDS  

	%  $Revision$
 	%  was created 13-Nov-2021 15:03:32 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties (Constant)
        projectFolder = 'CCIR_00559_00754'
    end

	properties (Dependent)
        tof_ic
        tof_mask_ic
        T1w_ic
        wmparc_ic
    end

	methods

        %% GET

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
%                 fn_sourcedata = glob(fullfile(this.sourcedataPath, this.subjectFolder, 'scans', '*TOF*', '*TOF*.4dfp.hdr'));
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
            %  @projectPath belongs to a CCIR project.
            %  @subjectFolder is the BIDS-adherent string for subject identity.

            this = this@mlpipeline.Bids(varargin{:});
            if isempty(this.subjectFolder_)
                this.parseDestinationPath(this.destPath_)
            end
        end
        
        function parseDestinationPath(this, dpath)
            if contains(dpath, 'sub-')
                ss = strsplit(dpath, filesep);
                this.subjectFolder_ = ss{contains(ss, 'sub-')}; % picks first occurance
            end
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
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        tof_ic_
        tof_mask_ic_
        T1w_ic_
        wmparc_ic_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

