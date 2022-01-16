classdef TofInputFunction < handle & mlraichle.AbstractFung2013
	%% TOFINPUTFUNCTION retains the methodology of mlraichle.Fung2013, but replaces data from the
    %  cervical carotid artery with data from TOF MRA.

	%  $Revision$
 	%  was created 22-Nov-2021 20:34:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.11.0.1809720 (R2021b) Update 1 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    methods (Static)
        function call_on_project(range, varargin)
            %% CALL_ON_PROJECT performs essential computations needed to create tables of IDIFs.
            %  @param required range is numeric, specifying subjects ordinally, e.g., 1:13.

            assert(isnumeric(range))
            deriv = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'derivatives', '');
            cd(deriv)
            subfolders = globFoldersT('sub-S*');
            if isempty(range)
                range = 1:length(subfolders);
            end
            for s = range
                try
                    pwd0 = pushd(fullfile(deriv, subfolders{s}, 'pet', ''));
                    mlraichle.TofInputFunction.call_on_subject(varargin{:}); 
                    popd(pwd0)
                catch ME
                    handwarning(ME)
                end
            end
        end
        function tbls_idif = call_on_subject(varargin)
            %% CALL_ON_SUBJECT performs essential computations needed to create tables of IDIFs.
            %  @param for ctor.
            %  @return tables for idif.

            this = mlraichle.TofInputFunction(varargin{:});
            tbls_idif = call(this);
        end
    end

	properties
        alg % prefer 'fung'; try 'cpd'
        basilar_blur
        basilar_thresh
        bboxes
        it10
        it25
        it50
        it75
        registration % struct
            % tform
            % centerlineOnTarget
            % rmse 
            % target_ics are averages of frames containing 10-25 pcnt, 10-50 pcnt, 10-75 pcnt of max emissions 
        tof_mask
        T1w_mask
        Wmparc
    end

	properties (Dependent)
        NCenterlineSamples
    end

	methods 

        %% GET

        function g = get.NCenterlineSamples(this)
            g = [max(this.bbRange{1}) - min(this.bbRange{1})/2 ...
                 max(this.bbRange{2}) - min(this.bbRange{2})...
                 max(this.bbRange{3}) - min(this.bbRange{3})];
            g = ceil(max(g));
        end

        %%
		  
        function this = TofInputFunction(varargin)
            %  @param destinationPath is the path for writing outputs.  Default is MMRBids.destinationPath.  
            %         Must specify project ID & subject ID.
            %  @param corners from fsleyes NIfTI [ x y z; ... ], [ [RS]; [LS]; [RI]; [LI] ].
            %  @param bbBuffer is the bounding box buffer ~ [x y z] in voxels.
            %  @param iterations ~ 80:130.
            %  @param smoothFactor ~ 0.
            %  @param contractBias is the contraction bias for activecontour():  ~[-1 1], bias > 0 contracting.
            %  @param segmentationOnly is logical.
            %  @param segmentationBlur is scalar.
            %  @param segmentationThresh is scalar.
            %  @param alg is 'cpd' or 'fung', used by registerCenterline(). 
            %  @param ploton is bool for showing IDIFs.
            %  @param plotqc is bool for showing QC.
            %  @param plotdebug is bool for showing information for debugging.
            %  @param plotclose closes plots after saving them.
            %  @param basilar_blur determines mask for excluding basilar artery.
            %  @param basilar_thresh determines mask for excluding basilar artery.

            this = this@mlraichle.AbstractFung2013(varargin{:});

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'basilar_blur', 30, @isscalar)
            addParameter(ip, 'basilar_thresh', 0.13, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.basilar_blur = ipr.basilar_blur;
            this.basilar_thresh = ipr.basilar_thresh;

            % adjustments to superclass

            this.segmentation_blur = 1;
            this.k = 5;
            this.threshqc = 0.5;

            % gather requirements
            this.buildMasks();
            this.flirtT1wOnTof(); % also builds wmparc_on_tof
            this.Wmparc = mlsurfer.Wmparc( ...
                fullfile(this.bids_.anatPath, strcat(this.bids_.wmparc_ic.fileprefix, '_on_tof.nii.gz')));
        end

        function this = buildAnatomy(this)
            this.anatomy_ = this.bids_.tof_ic;
            this.anatomy_.selectNiftiTool;
            this.anatomy_mask_ = this.bids_.tof_mask_ic;
            this.anatomy_mask_.selectNiftiTool;
        end
        function this = buildCenterlines(this)
            %% builds left and right centerlines, calling this.buildCenterline() for each.
            %  Requires this.petStatic to contain time-averaged PET which delimits spatial extent of centerlines.
            %  @return this.centerlines_pcs are the pointCloud representation of the centerlines.
            %  @return this.Cs are {L,R} points of the B-spline curve.
            %  @return this.Ps are {L,R} matrices of B-spline control points.

            tic

            img = logical(this.segmentation_ic);% .* logical(this.petStatic.thresh(dipmax(this.petStatic)/8));
            img = imfill(img, 26, 'holes');
            coox = this.coords(:,1);
            midx = ceil(min(coox(1), coox(2)) + abs(coox(1) - coox(2))/2);
            imgL = img(1:midx,:,:);
            imgR = zeros(size(img));
            imgR(midx+1:end,:,:) = img(midx+1:end,:,:);
            [pcL,CL,PL] = this.buildCenterline(imgL, 'L');
            [pcR,CR,PR] = this.buildCenterline(imgR, 'R');
            this.centerlines_pcs = {pcL pcR};
            this.Cs = {CL CR};
            this.Ps = {PL PR};

            fprintf("TofInputFunction.buildCenterlines: ")
            toc
        end
        function this = buildCorners(this, varargin)
            %% BUILDCORNERS builds representations of the bounding box as images and coord ranges.
            %  As needed, it launches fsleyes for manual selection of bounding box corners.
            %  @param coords is [x y z; x2 y2 z2; x3 y3 z3; x4 y4 z4] | empty.
            %         coords is [ [RS medial]; [LS medial]; [RI lateral]; [LI lateral] ] for end points of arterial segmentation.
            %  @return this.corners*_ic, which represent corners of the bounding box with unit voxels in arrays of zeros.
            %  @return this.bbRange, which are row arrays for bases [x y z] that describe the range of bounding box voxels.
            %
            %  e.g.:
            %  f = mlraichle.Fung2013
            %  f.buildCorners([158 122 85; 96 126 88; 156 116 27; 101 113 28])
            %  158, 122, 85
            %  96, 126, 88
            %  156, 116, 27
            %  101, 113, 28

            ip = inputParser;
            addOptional(ip, 'coords', this.coords, @isnumeric)
            addOptional(ip, 'bbBuffer', this.bbBuffer, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.coords = ipr.coords;
            this.bbBuffer = ipr.bbBuffer;
            
            if isempty(this.coords) % pick corners
                disp('No coords for carotids are available.  Please find coords in the T1w and provide to the constructor.')
                assert(~isempty(this.anatomy), 'Oops:  No anatomy is available.  Please provide information for anatomy to the constructor.')
                this.anatomy.fsleyes
                error('mlraichle:AbstractFung2013', ...
                    'No coords for carotids were available.  Please provide carotid coords to the constructor.')
            else                
                assert(all(size(this.coords) == [4 3]))
            end
            
            % build bboxes, usually left and right hemispheres
            % [ x y z; ... ]; [ [RS medial]; [LS medial]; [RI lateral]; [LI lateral] ]
            coo = this.coords; % 4 x 3
            for h = 1:2
                for m = 2:3
                    this.bboxes{h}{m} = min(coo(:, m)):max(coo(:, m));
                end
            end
            this.bboxes{1}{1} = coo(4, 1):coo(2, 1);
            this.bboxes{2}{1} = coo(1, 1):coo(3, 1);

            % build bbRange, the single box that encloses all bounding boxes
            for m = 1:3
                this.bbRange{m} = (min(this.coords(:,m)) - this.bbBuffer(m)):(max(this.coords(:,m)) + this.bbBuffer(m) + 1);
            end
            this.bbRange = this.ensureBoxInFieldOfView(this.bbRange);
        end
        function [tof_mask_,T1w_mask_] = buildMasks(this)
            %% helpful for flirt to TOF.  Ensures creation of {tof,T1001}.nii.gz.
            %  @returns tof_mask as an ImagingContext2 after saving.
            %  @returns T1w_mask as an ImagingContext2 after saving.

            bids = this.bids_;
            pwd0 = pushd(bids.anatPath);

            if ~isfile(bids.tof_ic.nifti.fqfn) % ensure tof.nii.gz
                bids.tof_ic.nifti.save()
            end
            fn = strcat(bids.tof_ic.fqfp, '_b60_thr30_binarized.nii.gz');
            if isfile(fn)
                tof_mask_ = mlfourd.ImagingContext2(fn);
            else
                tof_mask_ = bids.tof_ic.blurred(6);
                tof_mask_ = tof_mask_.thresh(30);
                tof_mask_ = tof_mask_.binarized();
                tof_mask_.nifti.save()
            end
            this.tof_mask = tof_mask_;

            if ~isfile(bids.T1w_ic.nifti.fqfn) % ensure T1001.nii.gz
                bids.T1w_ic.nifti.save()
            end
            fn = strcat(bids.T1w_ic.fqfp, '_b60_thr10_binarized.nii.gz');
            if isfile(fn)
                T1w_mask_ = mlfourd.ImagingContext2(fn);
            else
                T1w_mask_ = bids.T1w_ic.blurred(6);
                T1w_mask_ = T1w_mask_.thresh(10);
                T1w_mask_ = T1w_mask_.binarized();
                T1w_mask_.nifti.save()
            end
            this.T1w_mask = T1w_mask_;

            popd(pwd0)
        end
        function petic = buildPetOnTof(this, petfile)
            %% builds T1w and pet_avgt and pet on TOF.
            %  @param petfile is text for dynamic on T1w, 4dfp.
            %  @param petic for dynamic on tof, nifti.

            bids = this.bids_;
            pwd0 = pushd(bids.petPath);

            f = this.flirtT1wOnTof();
            petOnTof = strrep(petfile, '.4dfp.hdr', '.nii.gz');
            petOnTof = strrep(petOnTof, '_on_T1001', '_on_tof');
            if ~isfile(petOnTof)
                this.applyxfmToPet(petfile, f);
            end
            petic = mlfourd.ImagingContext2(petOnTof);

            popd(pwd0)
        end
        function this = buildSegmentation(this, varargin)
            %% segments the arterial path using activecontour() with the 'Chan-Vese' method.            
            %  @param optional iterations ~ 100.
            %  @param smoothFactor ~ 0.
            %  @return this.segmentation_ic.
            
            ip = inputParser;
            addOptional(ip, 'iterations', this.iterations, @isscalar)
            addParameter(ip, 'contractBias', this.contractBias, @isscalar)
            addParameter(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;

            if ~isempty(this.segmentation_ic)
                return
            end
                        
            blurred = this.anatomy.blurred(this.segmentation_blur);
            anatomyb_img = blurred.nifti.img(this.bbRange{:});
            basilar_mask = this.Wmparc.select_roi('brainstem+'); % mask out basilar artery
            basilar_mask = basilar_mask.blurred(this.basilar_blur);
            basilar_mask = basilar_mask.thresh(this.basilar_thresh);
            basilar_mask = basilar_mask.binarized();
            threshed = blurred.thresh(this.segmentationThresh) .* ~basilar_mask;
            if this.plotdebug
                figure
                pcshow(threshed.pointCloud('useMmppix', true))
                %threshed_ic.fsleyes
            end
            threshed_img = zeros(size(this.anatomy));
            for h = 1:2
                threshed_img(this.bboxes{h}{:}) = threshed.nifti.img(this.bboxes{h}{:}); % mask in boundary boxes
            end
            threshed_img = threshed_img(this.bbRange{:}); % reduce image size for contouring
            threshed_img = logical(threshed_img);
            
            %threshed_img = threshed_ic.nifti.img(this.bbRange{:});
            %threshed_img = logical(threshed_img);

            % call snakes, viz., iterate
            ac = activecontour(anatomyb_img, threshed_img, ipr.iterations, 'Chan-Vese', ...
                'ContractionBias', ipr.contractBias, 'SmoothFactor', ipr.smoothFactor);
            this.plotSegmentation(ac, ipr.iterations, ipr.smoothFactor);

            % fit back into anatomy
            ic = this.anatomy.zeros;
            ic.filepath = this.destinationPath;
            ic.fileprefix = [ic.fileprefix '_TofInputFunction_segmentation'];
            nii = ic.nifti;
            nii.img(this.bbRange{:}) = ac;
            nii.save()
            this.segmentation_ic = mlfourd.ImagingContext2(nii);
        end
        function tbl_idif = call(this, varargin)
            %% CALL
            %  @param iterations for Chan-Vese snakes.
            %  @param smoothFactor for Chan-Vese snakes.
            %  @return table of IDIFs; write table to text file.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'iterations', this.iterations, @isscalar)
            addParameter(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;

            % build segmentation
            this.buildSegmentation(ipr.iterations, 'smoothFactor', ipr.smoothFactor);
            if this.segmentation_only
                this.segmentation_ic.view(this.anatomy)
                tbl_idif = [];
                return
            end
            this.buildCenterlines()

            % build intermediate objects
            niis = this.petGlobbed('isdynamic', false);
            if ~isempty(getenv('DEBUG'))
                niis = niis(contains(niis, 'hodt20190523120249'));
            end
            niifqfn = cell(1, length(niis));
            tracer = cell(1, length(niis));
            IDIF = cell(1, length(niis));

            for ni = 1:length(niis)

                % sample input function from dynamic PET
                this.buildPetOnTof(niis{ni});
                niis{ni} = this.petOnTofFilename(niis{ni});
                this.petStatic = mlfourd.ImagingContext2(niis{ni});
                this.petDynamic = mlfourd.ImagingContext2(strrep(niis{ni}, '_avgt', ''));
                this.idifmask_ic = this.pointCloudsToIC(); % single ImagingContext
                this.idifmask_ic.filepath = this.petDynamic.filepath;
                this.idifmask_ic.fileprefix = [this.petDynamic.fileprefix '_idifmask'];
                this.idifmask_ic.save()
                idif = this.petDynamic.volumeAveraged(this.idifmask_ic);

                % construct table variables
                niifqfn{ni} = this.idifmask_ic.fqfilename;
                tracer_ = this.tracername();
                tracer{ni} = tracer_;
                IDIF_ = asrow(this.decay_uncorrected(idif));
                IDIF{ni} = IDIF_;
                this.writetable(this.timesMid(tracer_), IDIF_, this.petDynamic.fileprefix)
            end

            % construct table and write
            tbl_idif = table(niifqfn', tracer', IDIF', 'VariableNames', {'niifqfn', 'tracer', 'IDIF'});
            tbl_idif.Properties.Description = fullfile(this.destinationPath, sprintf('TofInputFunction_tbl_idif_%s.mat', this.subFolder));
            tbl_idif.Properties.VariableUnits = {'', '', 'Bq/mL'};
            save(tbl_idif.Properties.Description, 'tbl_idif')

            % plot and save
            this.plotIdif(tbl_idif);
        end
        function fn = petOnTofFilename(this, fn)
            fn = strrep(fn, 'T1001', this.anatomy.fileprefix);
            fn = strrep(fn, '.4dfp.hdr', '.nii.gz');
        end
        function ic = pointCloudsToIC(this, varargin)
            %% converts point clouds for both hemispheres into ImagingContext objects.
        
            icL = this.pointCloudToIC(this.centerlines_pcs{1}, varargin{:});
            icL = icL.imdilate(strel('sphere', this.dilationRadius));
            icR = this.pointCloudToIC(this.centerlines_pcs{2}, varargin{:});
            icR = icR.imdilate(strel('sphere', this.dilationRadius));
            ic = icL + icR;
            ic = ic.binarized();
        end

        %% FSL UTILITIES

        function [f1,f] = applyxfmToPet(this, pet_obj, f)
            %% requires files for <pet_obv>_avgt_on_T1001 and <pet_obj>_on_T1001. It generates nii.gz as needed.
            %  @param pet_obj is an ImagingContext2, char or string containing a basename, e.g., "hodt20211122000000".
            %  @param f is an mlfsl.Flirt.
            %  @returns f1, pet_obj on tof, also on filesystem pet_obj_avgt_on_tof.nii.gz.
            %  @returns f, pet_obj on tof, also on filesystem pet_obj_on_tof.nii.gz.

            switch class(pet_obj)
                case 'mlfourd.ImagingContext2'
                    pet_fileprefix = pet_obj.fileprefix;
                case 'char'
                    pet_fileprefix = pet_obj;
                case 'string'
                    pet_fileprefix = char(pet_obj);
                otherwise
                    error('mlraichle:TypeError', 'TofInputFunction.applyxfmToPet');
            end
            assert(isa(f, 'mlfsl.Flirt'))
            bids = this.bids_;
            pwd0 = pushd(bids.petPath);

            re = regexp(pet_fileprefix, '(?<basename>[a-z]+dt\d{14})', 'names');            
            f1 = copy(f);
            f1.in = [re.basename '_avgt_on_T1001.4dfp.hdr'];
            % implicitly: f1.in.selectNiftiTool(); 
            f1.out = [re.basename '_avgt_on_tof.nii.gz'];
            f1.interp = 'trilinear';
            f.in = [re.basename '_on_T1001.4dfp.hdr'];
            % implicitly: f.in.selectNiftiTool();
            f.out = [re.basename '_on_tof.nii.gz'];
            f.interp = 'trilinear';
            
            if ~isfile(f1.out.fqfn)
                [~,r] = f1.applyXfm();
                if ~isempty(r); error('mlraichle:RuntimeError', r); end
            end
            if ~isfile(f.out.fqfn)
                [~,r] = f.applyXfm();
                if ~isempty(r); error('mlraichle:RuntimeError', r); end
            end

            popd(pwd0)
        end
        function f = flirtT1wOnTof(this, varargin)
            %% requires T1001 and tof to require < 5 degrees of angular search.
            %  @param option tof_mask is an ImagingContext2.
            %  @param option T1w_mask is an ImagingContext2.
            %  @retruns f as mlfsl.Flirt; also builds wmparc_on_tof as needed.

            ip = inputParser;
            addOptional(ip, 'tof_mask', this.tof_mask, @(x) isa(x, 'mlfourd.ImagingContext2'))
            addOptional(ip, 'T1w_mask', this.T1w_mask, @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, varargin{:})
            ipr = ip.Results;

            bids = this.bids_;
            pwd0 = pushd(bids.anatPath);

            f = mlfsl.Flirt( ...
                'in', bids.T1w_ic, ...
                'ref', bids.tof_ic, ...
                'cost', 'normmi', 'searchrx', 5, 'interp', 'spline', ...
                'refweight', ipr.tof_mask, 'inweight', ipr.T1w_mask);

            tform_mat = fullfile(bids.tof_ic.filepath, [bids.T1w_ic.fileprefix '_on_' bids.tof_ic.fileprefix '.mat']);
            if ~isfile(tform_mat)
                [~,r] = f.flirt();
                if ~isempty(r); error('mlraichle:RuntimeError', r); end
            end

            % aslo build wmparc_on_tof
            wmparc_on_tof = fullfile(bids.tof_ic.filepath, [bids.wmparc_ic.fileprefix '_on_' bids.tof_ic.fileprefix '.nii.gz']);
            if ~isfile(wmparc_on_tof)
                f_ = copy(f);
                f_.in = bids.wmparc_ic.fqfn;
                f_.out = wmparc_on_tof;
                f_.interp = 'nearestneighbour';
                [~,r] = f_.applyXfm();
                if ~isempty(r); error('mlraichle:RuntimeError', r); end
            end

            popd(pwd0)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

