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
        T1w_ic
        wmparc_ic
    end

    properties
        pet_toglob
    end

	methods

        %% GET

        function g = get.anatPath(this)
            g = fullfile(this.derivativesPath, '');
            assert(isfolder(g))
        end
        function g = get.projPath(this)
            g = this.projPath_;
            assert(isfolder(g))
        end
        function g = get.derivativesPath(this)
            g = fullfile(this.projPath, this.subFolder, 'resampling_restricted', '');
            assert(isfolder(g))
        end
        function g = get.destinationPath(this)
            g = this.destPath_;
            assert(isfolder(g))
        end
        function g = get.mriPath(this)
            g = fullfile(this.derivativesPath, '');
            assert(isfolder(g))
        end
        function g = get.petPath(this)
            g = fullfile(this.derivativesPath, '');
            assert(isfolder(g))
        end
        function g = get.sourcedataPath(this)
            g = fullfile(this.projPath, this.subFolder, 'resampling_restricted', '');
            assert(isfolder(g))
        end
        function g = get.sourceAnatPath(this)
            g = fullfile(this.sourcedataPath, '');
            assert(isfolder(g))
        end
        function g = get.sourcePetPath(this)
            g = fullfile(this.sourcedataPath, '');
            assert(isfolder(g))
        end
        function g = get.subFolder(this)
            g = this.subFolder_;
        end
        function g = get.T1w_ic(this)
            if ~isempty(this.T1w_ic_)
                g = this.T1w_ic_;
                return
            end
            fn = fullfile(this.anatPath, 'T1001.4dfp.hdr');
            assert(isfile(fn))
            this.T1w_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.T1w_ic_);
        end
        function g = get.wmparc_ic(this)
            if ~isempty(this.wmparc_ic_)
                g = this.wmparc_ic_;
                return
            end
            fn = fullfile(this.anatPath, 'wmparc.4dfp.hdr');
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
            addParameter(ip, 'projPath', fullfile(getenv('SINGULARITY_HOME'), 'subjects', ''), @isfolder)
            addParameter(ip, 'subFolder', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.destPath_ = ipr.destPath;
            this.projPath_ = ipr.projPath;
            this.subFolder_ = ipr.subFolder;

            this.pet_toglob = fullfile(this.petPath, '*dt*_on_T1001.4dfp.hdr');
        end
        
        function parseDestinationPath(this, dpath)
            assert(contains(dpath, 'subjects'), 'mlraichle.MMRBids: destination path must include a project identifier')
            assert(contains(dpath, 'sub-'), 'mlraichle.MMRBids: destination path must include a subject identifier')

            this.destPath_ = dpath;
            ss = strsplit(dpath, filesep);
            [~,idxProjFold] = max(contains(ss, 'subjects'));
            this.projPath_ = [filesep fullfile(ss{1:idxProjFold})];
            this.subFolder_ = ss{contains(ss, 'sub-')}; % picks first occurance
        end
        function n = tracername(~, str)
            if contains(str, 'co', 'IgnoreCase', true)
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
        T1w_ic_
        wmparc_ic_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

