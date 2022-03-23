classdef Fung2013 < handle & mlaif.MMRFung2013
    %% FUNG2013 implements
    %  Edward K Fung and Richard E Carson.  Cerebral blood flow with [15O]water PET studies using 
    %  an image-derived input function and MR-defined carotid centerlines.  
    %  Phys. Med. Biol. 58 (2013) 1903–1923.  doi:10.1088/0031-9155/58/6/1903
    %  See also:  mlvg.Registration, mlvg.Reregistration
    
    %  $Revision$
 	%  was created 22-Mar-2021 22:11:00 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.

    methods (Static)
        function createPetOnT1001()
            for sub = globFoldersT('sub-S*')
                pwd0 = pushd(fullfile(sub{1}, 'resampling_restricted'));

                for gt4 = globT('*dt*_to_T1001_t4')
                    re = regexp(gt4{1}, '(?<pet>\w{2,3}dt\d{14})', 'names');
                    pet = re.pet;
                    if ~isfile([pet '_on_T1001.4dfp.hdr'])
                        try
                            mlbash(sprintf('t4img_4dfp %s %s %s_on_T1001 -OT1001', gt4{1}, pet, pet))
                        catch ME
                            handwarning(ME)
                        end
                    end
                end

                popd(pwd0)
            end
        end
        function call_on_project(range, varargin)
            %% CALL_ON_PROJECT performs essential computations needed to create tables of IDIFs.
            %  @param required range is numeric, specifying subjects ordinally, e.g., 1:13.

            assert(isnumeric(range))
            deriv = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'derivatives', 'resolve', '');
            cd(deriv)
            subfolders = globFoldersT('sub-S*');
            if isempty(range)
                range = 1:length(subfolders);
            end
            for s = range
                try
                    pwd0 = pushd(fullfile(deriv, subfolders{s}, 'pet', ''));
                    mlraichle.Fung2013.call_on_subject(varargin{:}); 
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

            this = mlraichle.Fung2013(varargin{:});
            tbls_idif = call(this);
        end
        function niis1 = petSorted(niis)
            tracer = cell(size(niis));
            tracerNum = nan(size(niis));
            dts = NaT(size(niis));
            for i = 1:length(niis)
                [~,fp] = myfileparts(niis{i});
                re = regexp(fp, ...
                    "(?<tracer>\w+)dt(?<yyyy>\d{4})(?<mm>\d{2})(?<dd>\d{2})(?<HH>\d{2})(?<MM>\d{2})(?<SS>\d{2})_\w+", "names");
                tracer{i} = re.tracer;
                tracerNum(i) = mlraichle.Fung2013.tracerCode(fp);
                fields_ = asrow(fields(re));
                for ff = fields_(2:end)
                    re.(ff{1}) = str2double(re.(ff{1}));
                end
                dts(i) = datetime(re.yyyy, re.mm, re.dd, 0, 0, 0);
            end
            tbl = table(dts, tracer, tracerNum, niis, 'VariableNames', {'dts', 'tracer', 'tracerNum', 'filename'});
            tbl = sortrows(tbl, [1 3]);
            niis1 = tbl.filename;
        end
        function [c,tr] = tracerCode(filename)
            %  Returns:
            %      c: numeric 1 for ho, 2 for oc, 3 for fdg, 4 for oo, in order of suitability for IDIF
            %      tr: strings ho, oc, fdg, and oo.

            [~,fp] = myfileparts(filename);
            tr = lower(strtok(fp, 'd'));
            switch lower(tr)
                case 'oc'
                    c = 2;
                case 'ho'
                    c = 1;
                case 'f'
                    c = 3;
                case 'oo'
                    c = 4;
            end
        end
    end

    properties
        alg % prefer 'fung'; try 'cpd'
        it10
        it25
        it50
        it75
        registration % struct
            % tform
            % centerlineOnTarget
            % rmse 
            % target_ics are averages of frames containing 10-25 pcnt, 10-50 pcnt, 10-75 pcnt of max emissions
    end

    properties (Dependent)
        bbBufferMax
        N_centerline_samples
    end

    methods

        %% GET

        function g = get.bbBufferMax(this)
            g = round([16/this.dx 16/this.dy 3/this.dz]);
        end
        function g = get.N_centerline_samples(this)
            g = ceil(max(this.bbRange{3}) - min(this.bbRange{3}));
        end

        %%

        function this = Fung2013(varargin)
            %% FUNG2013
            %  @param destinationPath is the path for writing outputs.  Default is Ccir559754Bids.destinationPath.  
            %         Must specify project ID & subject ID.
            %  @param corners from fsleyes NIfTI [ x y z; ... ], [ [RS]; [LS]; [RI]; [LI] ].
            %  @param bbBuffer is the bounding box buffer ~ [x y z].
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

            this = this@mlaif.MMRFung2013(varargin{:});

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'alg', 'fung', @(x) strcmpi(x, 'ndt') || strcmpi(x, 'icp') || strcmpi(x, 'cpd') || strcmpi(x, 'fung'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.buildAnatomy();
            this.buildCorners(this.coords);
            this.alg = lower(ipr.alg);
        end
        
        function this = buildAnatomy(this)
            this.anatomy_ = this.bids.t1w_ic;
            this.anatomy_.selectNiftiTool;
            this.anatomy_mask_ = this.bids.wmparc_ic;
            this.anatomy_mask_.selectNiftiTool;
        end
        function this = buildCenterlines(this)
            %% builds left and right centerlines, calling this.buildCenterline() for each.
            %  Requires this.petStatic to contain time-averaged PET which delimits spatial extent of centerlines.
            %  @return this.centerlines_pcs are the pointCloud representation of the centerlines.
            %  @return this.Cs are {L,R} points of the B-spline curve.
            %  @return this.Ps are {L,R} matrices of B-spline control points.

            tic

            img = logical(this.segmentation_ic) .* logical(this.petStatic.thresh(0.125*dipmax(this.petStatic)));
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

            fprintf("Fun2013.buildCenterlines: ")
            toc
        end
        function this = buildCORegistrationTargets(this, dyn_ic)
            %% builds CO registration targets comprising time-averaged emissions.
            %  Registration targets are R^3 images.
            
            timeAveraged = dyn_ic.timeAveraged();
            timeAveraged = timeAveraged.blurred(2.5); % 2.5 mm blurring specified by Fung & Carson
            for i = 1:3
                this.registration.target_ics{i} = timeAveraged; % handles
            end
            this.registration.target_ics{1}.save();
        end
        function this = buildCorners(this, varargin)
            %% BUILDCORNERS builds representations of the bounding box as images and coord ranges.
            %  As needed, it launches fsleyes for manual selection of bounding box corners.
            %  @param coords is [x y z; x2 y2 z2; x3 y3 z3; x4 y4 z4] | empty.
            %         coords is [ [RS]; [LS]; [RI]; [LI] ] for end points of arterial segmentation.
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
            
            % build ImagingContexts with enlarged corners
            cc = num2cell(this.coords);
            coords_ic = this.anatomy.zeros;
            coords_ic.fileprefix = 'corners_on_T1w';            
            nii = coords_ic.nifti;
                nii.img(cc{1,:}) = 1;
                nii.img(cc{2,:}) = 1;
                nii.img(cc{3,:}) = 1;
                nii.img(cc{4,:}) = 1;
            coords_ic = mlfourd.ImagingContext2(nii);
            assert(4 == dipsum(coords_ic))            
            this.coords_b1_ic = coords_ic.blurred(1);
            this.coords_b1_ic = this.coords_b1_ic.numgt(0.001);
            this.coords_b1_ic.fileprefix = 'corners_on_t1w_spheres';
            this.coords_b1_ic.save();

            % build bbRange
            for m = 1:3
                this.bbRange{m} = (min(this.coords(:,m)) - this.bbBuffer(m)):(max(this.coords(:,m)) + this.bbBuffer(m) + 1);
            end
            this.bbRange = this.ensureBoxInFieldOfView(this.bbRange);
        end
        function this = buildRegistrationTargets(this, dyn_ic_)
            %% Builds registration targets comprising time-averaged emissions for times
            %  sampled at {0.1:0.25,0.25:0.5,0.5:0.75} of maximal whole-brain emissions.
            %  Viz., whole-brain emissions determine the sampling intervals, but registration targets are R^3 images.

            if contains(dyn_ic_.fileprefix, 'CO') || contains(dyn_ic_.fileprefix, 'OC')
                this = this.buildCORegistrationTargets(dyn_ic_);
                return
            end

            dyn_avgxyz = dyn_ic_.volumeAveraged(logical(this.anatomy_mask));
            dyn_max = dipmax(dyn_avgxyz);
            img = dyn_avgxyz.nifti.img;
            [~,this.it10] = max(img > 0.1*dyn_max);
            [~,this.it25] = max(img > 0.25*dyn_max);
            [~,this.it50] = max(img > 0.5*dyn_max);
            [~,this.it75] = max(img > 0.75*dyn_max);            
            this.registration.target_ics{1} = dyn_ic_.timeAveraged(this.it10:this.it25);
            this.registration.target_ics{2} = dyn_ic_.timeAveraged(this.it10:this.it50);
            this.registration.target_ics{3} = dyn_ic_.timeAveraged(this.it10:this.it75);
            for i = 1:3
                this.registration.target_ics{i} = this.registration.target_ics{i}.blurred(2.5); % 2.5 mm blurring specified by Fung & Carson
                this.registration.target_ics{i}.save();
            end
        end
        function this = buildSegmentation(this, varargin)
            %% segments the arterial path using activecontour() with the 'Chan-Vese' method.
            %  @param optional iterations ~ 100.
            %  @param smoothFactor ~ 0.
            %  @return this.segmentation_ic.
            
            ip = inputParser;
            addParameter(ip, 'iterations', this.iterations, @isscalar)
            addParameter(ip, 'contractBias', this.contractBias, @isscalar)
            addParameter(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;

            if ~isempty(this.segmentation_ic)
                return
            end
                        
            blurred = this.anatomy.blurred(this.segmentation_blur);
            anatomyb_img = blurred.nifti.img(this.bbRange{:});
            threshed_ic = this.anatomy.thresh(this.segmentationThresh);
            %imfilled_ic = threshed_ic.imfill(26, 'holes'); % 6, 18, 26
            if this.plotdebug
                %figure
                %pcshow(imfilled_ic.pointCloud('useMmppix', true))
                figure
                pcshow(threshed_ic.pointCloud('useMmppix', true))
                %threshed_ic.fsleyes
            end
            %imfilled_img = logical(imfilled_ic.nifti.img(this.bbRange{:}));
            coords_bb_img = logical(this.coords_b1_ic.nifti.img(this.bbRange{:}));
            
            % call snakes, viz., iterate
            ac = activecontour(anatomyb_img, coords_bb_img, ipr.iterations, 'Chan-Vese', ...
                'ContractionBias', ipr.contractBias, 'SmoothFactor', ipr.smoothFactor);
            this.plotSegmentation(ac, ipr.iterations, ipr.smoothFactor);

            % fit back into anatomy
            ic = this.anatomy.zeros;
            ic.filepath = this.destinationPath;
            ic.fileprefix = [ic.fileprefix '_Fung2013_segmentation'];
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
            this.buildSegmentation('iterations', ipr.iterations, 'smoothFactor', ipr.smoothFactor);
            if this.segmentation_only
                tbl_idif = [];
                return
            end

            % build intermediate objects
            niis = this.petGlobbed('isdynamic', false);
            niis = this.petSorted(niis);
            niifqfn = cell(1, length(niis));
            tracer = cell(1, length(niis));
            IDIF = cell(1, length(niis));

            for ni = 1:length(niis)

                % sample input function from dynamic PET
                this.petStatic = mlfourd.ImagingContext2(niis{ni});
                this.petDynamic = mlfourd.ImagingContext2(strrep(niis{ni}, '_avgt', ''));
                this.buildCenterlines()
                this.buildRegistrationTargets(this.petDynamic)
                
                if this.tracerCode(niis{ni}) < 4
                    % register co, ho only
                    this.registerCenterlines('alg', this.alg)
                end
                this.idifmask_ic = this.pointCloudsToIC(); % single ImagingContext
                this.idifmask_ic.filepath = this.petDynamic.filepath;
                this.idifmask_ic.fileprefix = [this.petDynamic.fileprefix '_idifmask'];
                this.idifmask_ic.save()
                idif = this.petDynamic.volumeAveraged(this.idifmask_ic);

                % construct table variables
                niifqfn{ni} = this.idifmask_ic.fqfilename;
                tracer_ = this.bids.obj2tracer(this.petStatic);
                tracer{ni} = tracer_;
                IDIF_ = asrow(this.decay_uncorrected(idif));
                IDIF{ni} = IDIF_;
                this.writetable(this.timesMid(tracer_), IDIF_, this.petDynamic.fileprefix)
            end

            % construct table and write
            tbl_idif = table(niifqfn', tracer', IDIF', 'VariableNames', {'niifqfn', 'tracer', 'IDIF'});
            tbl_idif.Properties.Description = fullfile(this.destinationPath, sprintf('Fung2013_tbl_idif_%s.mat', this.subjectFolder));
            tbl_idif.Properties.VariableUnits = {'', '', 'Bq/mL'};
            save(tbl_idif.Properties.Description, 'tbl_idif')

            % plot and save
            this.plotIdif(tbl_idif);
        end
        function g = petGlobbed(this, varargin)
            ip = inputParser;
            addOptional(ip, 'isdynamic', true, @islogical)
            parse(ip, varargin{:})

            anat = 'T1001';
            g = glob(fullfile(this.petPath, sprintf('*dt*_on_%s.4dfp.hdr', anat)));
            if ip.Results.isdynamic
                g = g(~contains(g, '_avgt'));
            else
                g = g(contains(g, '_avgt'));
            end
        end
        function [h,h1] = plotRegistered(this, varargin)
            %% As requested by plotqc and plotdebug, plots then saves centerline registered to bounding-blox PET in green, 
            %  centerline reregistered to PET in magenta.  Clobbers previously saved.
            %  As requested by plotclose, closes figures.
            %  @param required target, pointCloud.
            %  @param required centerlineOnTarget, pointCloud.
            %  @param required centerline, pointCloud.
            %  @param required laterality, in {'' 'l' 'L' 'r' 'R'}.
            %  @return handle(s) for figure(s).       
            
            ip = inputParser;
            addRequired(ip, 'target', @(x) isa(x, 'pointCloud'))
            addRequired(ip, 'centerlineOnTarget', @(x) isa(x, 'pointCloud'))
            addRequired(ip, 'centerline', @(x) isa(x, 'pointCloud'))
            addRequired(ip, 'laterality', @(x) ismember(x, {'', 'l', 'L', 'r', 'R'}))
            parse(ip, varargin{:})
            ipr = ip.Results;
            Laterality = upper(ipr.laterality);        

            if this.plotqc
                fp = fullfile(this.petPath, sprintf('%s_%s_centerline_target', this.petDynamic.fileprefix, Laterality));
                h = figure;
                pcshow(ipr.target)
                hold on; 
                pcshow(ipr.centerline.Location, '*g', 'MarkerSize', 12); 
                pcshow(ipr.centerlineOnTarget.Location, '*m', 'MarkerSize', 12); 
                hold off;
                title(sprintf('centerline (green -> magenta) on target %s %s', upper(ipr.laterality), this.petBasename))
                saveas(h, [fp '.fig'])
                set(h, 'InvertHardCopy', 'off');
                set(h,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
                saveas(h, [fp '.png'])
                if this.plotclose
                    close(h)
                end
            end
            if this.plotdebug
                fp1 = fullfile(this.petPath, sprintf('%s_%s_centerline_target_pair', this.petDynamic.fileprefix, Laterality));
                h1 = figure;
                pcshowpair(ipr.target, ipr.centerlineOnTarget, 'VerticalAxis', 'Z') % only magenta & green available in R2021b
                title(sprintf('centerline (green) on target (magenta) %s %s', upper(ipr.laterality), this.petBasename))
                saveas(h1, [fp1 '.fig'])
                set(h1, 'InvertHardCopy', 'off');
                set(h1,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
                saveas(h1, [fp1 '.png'])
                if this.plotclose
                    close(h1)
                end
            end
        end
        function ic = pointCloudsToIC(this, varargin)
            %% converts point clouds for both hemispheres into ImagingContext objects.
        
            icL = this.pointCloudToIC(this.registration.centerlineOnTarget{1}, varargin{:});
            icR = this.pointCloudToIC(this.registration.centerlineOnTarget{2}, varargin{:});
            
            icLo = icL.imdilate(strel('sphere', this.outerRadius));
            icRo = icR.imdilate(strel('sphere', this.outerRadius));
            ic = icLo + icRo;
            ic = ic.binarized();
            if this.innerRadius > 0
                icLi = icL.imdilate(strel('sphere', this.innerRadius));
                icRi = icR.imdilate(strel('sphere', this.innerRadius));
                ic = ic - icLi - icRi;
                ic = ic.numgt(0);
            end
        end
        function this = registerCenterlines(this, varargin)
            %  @param thresh applies to ic3d.  Default is 25000.
            %  @param alg is from {'ndt', 'icp', 'cpd'}.
            %  @param gridStep preprocesses pcregister* methods.
            
            assert(~isempty(this.centerlines_pcs))
            this.centerlines_pcs{1} = ...
                this.registerCenterline(this.centerlines_pcs{1}, varargin{:}, 'laterality', 'L');
            this.centerlines_pcs{2} = ...
                this.registerCenterline(this.centerlines_pcs{2}, varargin{:}, 'laterality', 'R');
        end
        function centerlineOnTarget = registerCenterline(this, varargin)
            %  @param required centerline is a pointCloud.
            %  @param optional ic3d is an ImagingContext2 for PET averaged over early times for bolus arrival.
            %         Default is this.registration.target_ics{3}.
            %  @param thresh applies to ic3d.  Default is 25000.
            %  @param alg is from {'ndt', 'icp', 'cpd'}.
            %  @param gridStep preprocesses pcregister* methods.
            %  @param laterality is in {'R' 'L'}.
            %  @return centerlineOnTarget is a pointCloud.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'centerline', @(x) isa(x, 'pointCloud'))
            addOptional(ip, 'ic3d', this.registration.target_ics{3}, @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'thresh', [], @isnumeric)
            addParameter(ip, 'alg', this.alg, @(x) ismember(x, {'ndt', 'icp', 'cpd', 'fung'}))
            addParameter(ip, 'gridStep', 1, @isscalar)
            addParameter(ip, 'laterality', '', @(x) ismember(x, {'', 'l', 'L', 'r', 'R'})) % L has indices < Nx/2
            parse(ip, varargin{:})
            ipr = ip.Results;
            ipr.ic3d = this.maskInBoundingBox2(ipr.ic3d, ipr.laterality);
            if isempty(ipr.thresh)
                img = ipr.ic3d.nifti.img;
                img = img(img > 0);
                ipr.thresh = dipmedian(img);
            end
            target = pointCloud(ipr.ic3d, 'thresh', ipr.thresh); 
            centerlineOri = copy(ipr.centerline);
            
            idx = strcmpi(ipr.laterality, 'R') + 1; % idx == 1 <-> left            
            switch ipr.alg
                case 'ndt'
                    cmatrix = uint8(centerlineOri.Intensity*255/max(centerlineOri.Intensity)); 
                    centerlineOri_ = centerlineOri;
                    centerlineOri_.Color = cmatrix;
                    target_ = target;
                    target_.Color = cmatrix;
                    [tform,centerlineOnTarget,rmse] = pcregisterndt(centerlineOri_, target_, 6, ...
                        'Tolerance', [0.01 0.5], 'Verbose', true);
                case 'icp'
                    if ipr.gridStep ~= 1
                        centerlineOri = pcdownsample(centerlineOri, 'gridAverage', ipr.gridStep);
                    end
                    [tform,centerlineOnTarget,rmse] = pcregistericp(centerlineOri, target);
                case 'cpd'
                    if ipr.gridStep ~= 1
                        centerlineOri = pcdownsample(centerlineOri, 'gridAverage', ipr.gridStep);
                    end
                    [tform,centerlineOnTarget,rmse] = pcregistercpd(centerlineOri, target, ...
                        'Transform', 'Rigid', 'MaxIterations', 100, 'Tolerance', 1e-7); % 'InteractionSigma', 2
                case 'fung'                    
                    try
                        tform = this.registration.tform{idx};
                    catch ME
                        handwarning(ME)                        
                        tform = rigid3d(eye(4));
                    end
                    rr = mlvg.Reregistration(this.anatomy);
                    [tform,centerlineOnTarget,rmse] = rr.pcregistermax(tform, centerlineOri, target);
                otherwise
                    error('mlraichle:ValueError', ...
                        'Fung2013.registerCenterlines.ipr.alg == %s', ipr.alg)
            end
            this.registration.centerlineOnTarget{idx} = copy(centerlineOnTarget);
            this.registration.tform{idx} = tform;
            this.registration.rmse{idx} = rmse;
            this.plotRegistered(target, centerlineOnTarget, centerlineOri, ipr.laterality)
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function ic = maskInBoundingBox2(this, ic, laterality)
            ifc = ic.nifti;
            bb2 = cell(1,3);
            for m = 1:3
                bb2_m_ = (min(this.coords(:,m)) - this.bbBufferMax(m)): ...
                         (max(this.coords(:,m)) + this.bbBufferMax(m) + 1);
                bb2{m} = bb2_m_(1 <= bb2_m_ & bb2_m_ <= ifc.size(m)); % bounding box 2 must not exceed size of ifc
            end

            % select bounding box 2 from ifc.img
            img = zeros(size(ifc));
            img(bb2{1},bb2{2},bb2{3}) = ifc.img(bb2{1},bb2{2},bb2{3});
            if ~isempty(laterality)
                if strcmpi(laterality, 'L') % L has indices < Nx/2
                    img(ceil(this.Nx/2)+1:end,:,:) = zeros(ceil(this.Nx/2),this.Ny,this.Nz); % clobber left
                else 
                    img(1:ceil(this.Nx/2),:,:) = zeros(ceil(this.Nx/2),this.Ny,this.Nz); % clobber right
                end
            end
            ifc.img = img;
            ifc.fileprefix = [ifc.fileprefix '_maskInBoundingBox'];
            ic = mlfourd.ImagingContext2(ifc);
        end
    end
end




