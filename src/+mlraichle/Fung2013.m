classdef Fung2013 < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable  
    %% FUNG2013 implements
    %  Edward K Fung and Richard E Carson.  Cerebral blood flow with [15O]water PET studies using 
    %  an image-derived input function and MR-defined carotid centerlines.  
    %  Phys. Med. Biol. 58 (2013) 1903–1923.  doi:10.1088/0031-9155/58/6/1903
    %  See also:  mlvg.Registration, mlvg.Reregistration
    
    %  $Revision$
 	%  was created 22-Mar-2021 22:11:00 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
    
    properties
        alg % prefer 'fung'; try 'cpd'
        BBBuf % extra voxels padded to coords to create convex bounding box for segmentation & centerline
        centerlines_ics % L, R in cell
        centerlines_pcs % L, R in cell
        contract_bias % used by activecontour
        coords % 4 coord points at corners
        coords_bb % coord ranges {x1:xN, y1:yN, z1:zN} for bounding box
        coords_bb2 % coord ranges {x1:xN, y1:yN, z1:zN} for bounding box 2
        coords_ic
        coords_bb_ic
        dilationRadius = 2 % Fung reported best results with radius ~ 2.5, but integers may be faster
        dyn_ic % contains dynamic PET as ImagingContext (LARGE)
        idifmask_ic % contains centerline expanded by dilationRadius as ImagingContext
        iterations
        it10
        it25
        it50
        it75
        plotclose % close plots after saving
        plotdebug % show debugging plots
        ploton % show final results
        plotqc % show more plots for QA
        registration % struct
            % tform
            % centerlineOnTarget
            % rmse 
            % target_ics are averages of frames containing 10-25 pcnt, 10-50 pcnt, 10-75 pcnt of max emissions
        segmentation_blur
        segmentation_only
        segmentation_ic % contains solid 3D volumes for carotids
        segmentation_thresh
        smoothFactor
        taus % containers.Map
        times % containers.Map
        timesMid % containers.Map
        
        % for B-splines in mlvg.Hunyadi2021
        k = 4
        t = [0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
        %t = [0 0 0 0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1 1 1]
        U % # samples for bspline_deboor()
        Cs % curves in cell, 3 x this.U
        Ps % control points in cell, 3 x M
    end
    
    properties (Dependent)
        anatPath
        BBBufMax % max voxels padded to coords to create convex bounding box for registration target by PET
        derivativesPath
        destinationPath
        dyn_label % label for PET, useful for figures
        NCenterlineSamples % 1 voxel/mm for coarse representation of b-splines
        Nx
        Ny
        Nz
        mriPath
        petPath
        pet_toglob
        projPath
        sourcedataPath
        sourceAnatPath
        sourcePetPath
        static_ic
        subFolder
        T1w_ic
        wmparc_ic
    end

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
            deriv = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'derivatives', '');
            cd(deriv)
            subfolders = globFoldersT('sub-S*');
            if isempty(range)
                range = 1:length(subfolders);
            end
            for s = range
                try
                    pwd0 = pushd(fullfile(deriv, subfolders{s}, 'pet', ''));
                    this = mlraichle.Fung2013(varargin{:}); %#ok<PFBNS> 
                    call(this)
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
    end

    methods
        
        %% GET
        
        function g = get.anatPath(this)
            g = this.bids_.anatPath;
        end
        function g = get.BBBufMax(this)
            g = round([16 16 5]);
        end
        function g = get.derivativesPath(this)
            g = this.bids_.derivativesPath;
        end
        function g = get.destinationPath(this)
            g = this.bids_.destinationPath;
        end
        function g = get.dyn_label(this)
            g = strrep(this.dyn_ic.fileprefix, '_', ' ');
        end
        function g = get.NCenterlineSamples(this)
            rngz = max(this.coords_bb{3}) - min(this.coords_bb{3});
            g = ceil(rngz/this.T1w_ic.nifti.mmppix(3)); % sample to 1 mm, or 1 voxels/mm
        end
        function g = get.Nx(this)
            g = size(this.T1w_ic, 1);
        end
        function g = get.Ny(this)
            g = size(this.T1w_ic, 2);
        end
        function g = get.Nz(this)
            g = size(this.T1w_ic, 3);
        end
        function g = get.mriPath(this)
            g = this.bids_.mriPath;
        end
        function g = get.petPath(this)
            g = this.bids_.petPath;
        end
        function g = get.pet_toglob(this)
            g = this.bids_.pet_toglob;
        end
        function g = get.projPath(this)
            g = this.bids_.projPath;
        end
        function g = get.sourcedataPath(this)
            g = this.bids_.sourcedataPath;
        end
        function g = get.sourceAnatPath(this)
            g = this.bids_.sourceAnatPath;
        end
        function g = get.sourcePetPath(this)
            g = this.bids_.sourcePetPath;
        end
        function g = get.static_ic(this)
            assert(~isempty(this.dyn_ic))
            static_fqfn = strrep(this.dyn_ic.fqfilename, '_on_T1001', '_avgt_on_T1001');
            if isfile(static_fqfn)
                g = mlfourd.ImagingContext2(static_fqfn);
                return
            end
            g = this.dyn_ic.timeAveraged();
        end
        function g = get.subFolder(this)
            g = this.bids_.subFolder;
        end
        function g = get.T1w_ic(this)
            g = this.bids_.T1w_ic;
        end
        function g = get.wmparc_ic(this)
            g = this.bids_.wmparc_ic;
        end
        
        %%
        
        function this = Fung2013(varargin)
            %% FUNG2013
            %  @param destPath is the path for writing outputs.  Default is MMRBids.destinationPath.  
            %         Must specify project ID & subject ID.
            %  @param subFolder is a folder name for the subject.
            %  @param ploton is bool for showing IDIFs.
            %  @param plotqc is bool for showing QC.
            %  @param plotdebug is bool for showing information for debugging.
            %  @param corners from fsleyes [ x y z; ... ], [ [RS]; [LS]; [RI]; [LI] ].
            %  @param BBBuff is the bounding box buffer ~ [x y z].
            %  @param iterations ~ 80:130.
            %  @param smoothFactor ~ 0.
            %  @param contractBias is the contraction bias for activecontour():  ~[-1 1], bias > 0 contracting.
            %  @param alg is 'cpd' or 'fung', used by registerCenterline(). 
            %  @param segmentationOnly is logical.
            %  @param segmentationBlur is scalar.
            %  @param segmentationThresh is scalar.
            
            this.bids_ = mlraichle.MMRBids(varargin{:}); % delegate uses subFolder

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'destPath', this.bids_.destinationPath, @isfolder)
            addParameter(ip, 'ploton', true, @islogical)
            addParameter(ip, 'plotqc', true, @islogical)
            addParameter(ip, 'plotdebug', false, @islogical)
            addParameter(ip, 'plotclose', true, @islogical)
            addParameter(ip, 'corners', [], @(x) ismatrix(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'BBBuf', [3 3 0], @(x) isvector(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'iterations', 70, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'smoothFactor', 0, @isscalar)
            addParameter(ip, 'contractBias', 0.02, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'alg', 'fung', @(x) strcmpi(x, 'ndt') || strcmpi(x, 'icp') || strcmpi(x, 'cpd') || strcmpi(x, 'fung'))
            addParameter(ip, 'segmentationOnly', false, @islogical)
            addParameter(ip, 'segmentationBlur', 0, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'segmentationThresh', 190, @(x) isscalar(x) || isa(x, 'containers.Map')) % tuned for PPG T1001
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.parseDestinationPath(ipr.destPath);
            if isa(ipr.corners, 'containers.Map')
                ipr.corners = ipr.corners(this.subFolder);
            end  
            if isa(ipr.BBBuf, 'containers.Map')
                ipr.BBBuf = ipr.BBBuf(this.subFolder);
            end  
            if isa(ipr.iterations, 'containers.Map')
                ipr.iterations = ipr.iterations(this.subFolder);
            end  
            if isa(ipr.contractBias, 'containers.Map')
                ipr.contractBias = ipr.contractBias(this.subFolder);
            end  
            if isa(ipr.segmentationBlur, 'containers.Map')
                ipr.segmentationBlur = ipr.segmentationBlur(this.subFolder);
            end  
            if isa(ipr.segmentationThresh, 'containers.Map')
                ipr.segmentationThresh = ipr.segmentationThresh(this.subFolder);
            end  
            this.ploton = ipr.ploton;
            this.plotqc = ipr.plotqc;
            this.plotdebug = ipr.plotdebug;
            this.plotclose = ipr.plotclose;          
            this.coords = ipr.corners;
            this.BBBuf = ipr.BBBuf;
            this.iterations = ipr.iterations;
            this.contract_bias = ipr.contractBias;
            this.smoothFactor = ipr.smoothFactor;
            this.alg = lower(ipr.alg);
            this.segmentation_only = ipr.segmentationOnly;
            this.segmentation_blur = ipr.segmentationBlur;
            this.segmentation_thresh = ipr.segmentationThresh;
            
            % gather requirements
            this.hunyadi_ = mlvg.Hunyadi2021();
            this.buildCorners(this.coords);
            this.buildTimings();
        end
        function this = buildTimings(this)
            %% builds taus, times, timesMid.

            this.taus = containers.Map;
            this.taus('CO') = [3,3,3,3,3,3,3,3,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,19,22,24,28,33,39,49,64,49];
            this.taus('OO') = [2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,15];
            this.taus('HO') = [3,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,20,22,25,29,34,41,51,52];
            this.taus('FDG') = [10,13,14,16,17,19,20,22,23,25,26,28,29,31,32,34,35,37,38,40,41,43,44,46,47,49,50,52,53,56,57,59,60,62,63,65,66,68,69,71,72,74,76,78,79,81,82,84,85,87,88,91,92,94,95,97,98,100,101,104,105,108];

            this.times = containers.Map;
            for key = this.taus.keys
                 this.times(key{1}) = [0 cumsum(this.taus(key{1}))];
            end

            this.timesMid = containers.Map;
            for key = this.taus.keys
                taus_ = this.taus(key{1});
                times_ = this.times(key{1});
                this.timesMid(key{1}) = times_(1:length(taus_)) + taus_/2;
            end
        end
        function this = buildCorners(this, varargin)
            %% BUILDCORNERS builds representations of the bounding box as images and coord ranges.
            %  As needed, it launches fsleyes for manual selection of bounding box corners.
            %  @param coords is [x y z; x2 y2 z2; x3 y3 z3; x4 y4 z4] | empty.
            %         coords is [ [RS]; [LS]; [RI]; [LI] ] for end points of arterial segmentation.
            %  @return this.corners*_ic, which represent corners of the bounding box with unit voxels in arrays of zeros.
            %  @return this.coords_bb, which are row arrays for bases [x y z] that describe the range of bounding box voxels.
            %  @return this.coords_bb2, which are row arrays for bases [x y z] that describe the range of bounding box 2 voxels.
            
            %  f = mlraichle.Fung2013
            %  f.buildCorners([158 122 85; 96 126 88; 156 116 27; 101 113 28])
            %  158, 122, 85
            %  96, 126, 88
            %  156, 116, 27
            %  101, 113, 28

            ip = inputParser;
            addOptional(ip, 'coords', this.coords, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.coords = ipr.coords;
            cc = num2cell(this.coords);
            
            % pick corners
            if isempty(this.coords)  
                disp('No coords for carotids are available.  Please find coords in the T1w and provide to the constructor.')
                assert(~isempty(this.T1w_ic), 'Oops:  No T1w is available.  Please provide information for T1w to the constructor.')
                this.T1w_ic.fsleyes
                error('mlraichle:Fung2013', ...
                    'No coords for carotids were available.  Please provide carotid coords to the constructor.')
            else                
                assert(all(size(this.coords) == [4 3]))
            end
            
            % build ImagingContexts with corners, and also with blurring, binarizing
            this.coords_ic = this.T1w_ic.zeros;
            this.coords_ic.fileprefix = 'corners_on_T1w';
            nii = this.coords_ic.nifti;
            nii.img(cc{1,:}) = 1;
            nii.img(cc{2,:}) = 1;
            nii.img(cc{3,:}) = 1;
            nii.img(cc{4,:}) = 1;
            this.coords_ic = mlfourd.ImagingContext2(nii);
            assert(4 == dipsum(this.coords_ic))
            
            this.coords_bb_ic = this.coords_ic.blurred(1);
            this.coords_bb_ic = this.coords_bb_ic.numgt(0.001);
            this.coords_bb_ic.fileprefix = 'corners_on_T1w_spheres';
            
            % build coords_bb, coords_bb2
            sz = size(this.T1w_ic);
            for m = 1:3
                this.coords_bb{m} = (min(ipr.coords(:,m)) - this.BBBuf(m)):(max(this.coords(:,m)) + this.BBBuf(m) + 1);
                bb = this.coords_bb{m};
                this.coords_bb{m} = bb(bb >=1 & bb <= sz(m));
            end
            for m = 1:3
                this.coords_bb2{m} = (min(ipr.coords(:,m)) - this.BBBufMax(m)):(max(this.coords(:,m)) + this.BBBufMax(m) + 1);
                bb2 = this.coords_bb2{m};
                this.coords_bb2{m} = bb2(bb2 >=1 & bb2 <= sz(m));
            end
        end
        function this = buildSegmentation(this, varargin)
            %% segments the arterial path using activecontour() with the 'Chan-Vese' method.            
            %  @param optional iterations ~ 100.
            %  @param smoothFactor ~ 0.
            %  @return this.segmentation_ic.
            
            ip = inputParser;
            addOptional(ip, 'iterations', this.iterations, @isscalar)
            addParameter(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;

            if ~isempty(this.segmentation_ic)
                return
            end
                        
            blurred = this.T1w_ic.blurred(this.segmentation_blur);
            T1wb_img = blurred.nifti.img(this.coords_bb{:});
            threshed_ic = this.T1w_ic.thresh(this.segmentation_thresh);
            imfilled_ic = threshed_ic.imfill(6, 'holes'); % 6, 18, 26
            if this.plotdebug
                figure
                pcshow(imfilled_ic.pointCloud)
                figure
                pcshow(threshed_ic.pointCloud)
                %threshed_ic.fsleyes
            end
            imfilled_img = logical(imfilled_ic.nifti.img(this.coords_bb{:}));
            coords_bb_img = logical(this.coords_bb_ic.nifti.img(this.coords_bb{:}));
            
            % call snakes, viz., iterate
            ac = activecontour(T1wb_img, imfilled_img .* coords_bb_img, ipr.iterations, 'Chan-Vese', ...
                'ContractionBias', this.contract_bias, 'SmoothFactor', ipr.smoothFactor);
            this.plotSegmentation(ac, ipr.iterations, ipr.smoothFactor);

            % fit back into T1w
            ic = this.T1w_ic.zeros;
            ic.filepath = this.destinationPath;
            ic.fileprefix = [ic.fileprefix '_segmentation'];
            nii = ic.nifti;
            nii.img(this.coords_bb{:}) = ac;
            %%nii.save()
            this.segmentation_ic = mlfourd.ImagingContext2(nii);
        end
        function this = buildCenterlines(this, static_ic)
            %% builds left and right centerlines, calling this.buildCenterline() for each.
            %  @param static_ic contains time-averaged PET used to delimit spatial extent of centerlines.
            %  @return this.centerlines_pcs are the pointCloud representation of the centerlines.
            %  @return this.Cs are {L,R} points of the B-spline curve.
            %  @return this.Ps are {L,R} matrices of B-spline control points.

            assert(isa(static_ic, 'mlfourd.ImagingContext2'))

            img = logical(this.segmentation_ic) .* logical(static_ic);
            imgL = img(1:ceil(this.Nx/2),:,:);
            imgR = zeros(size(img));
            imgR(ceil(this.Nx/2)+1:end,:,:) = img(ceil(this.Nx/2)+1:end,:,:);
            [pcL,CL,PL] = this.buildCenterline(imgL, 'L');
            [pcR,CR,PR] = this.buildCenterline(imgR, 'R');
            this.centerlines_pcs = {pcL pcR};
            this.Cs = {CL CR};
            this.Ps = {PL PR};
        end
        function [pc,C,P] = buildCenterline(this, img, tag)
            %% Builds a centerline using mlvg.Hunyadi2021.
            %  If not previously saved,
            %  as requested by plotqc and plotdebug, plots centerline with thresholded T1w and,
            %  as requested by plotclose, closes figures.
            %  @param img is the data upon which a centerline is built.
            %  @param tag is char.
            %  @return pc is the pointCloud representation of the centerline.
            %  @return C are points of the B-spline curve.
            %  @return P is the matrix of B-spline control points.

            assert(ischar(tag))
            idx = find(img);
            [X,Y,Z] = ind2sub(size(img), idx);             
            M(1,:) = X'; % M are ints cast as double
            M(2,:) = Y';
            M(3,:) = Z';
            this.U = this.NCenterlineSamples;             
            P = bspline_estimate(this.k, this.t, M); % double
            C = bspline_deboor(this.k, this.t, P, this.U); % double, ~2x oversampling for Z
            pc = pointCloud(C');
            
            fp = fullfile(this.destinationPath, sprintf('%s_centerline_in_%s', tag, this.T1w_ic.fileprefix));
            if ~isfile([fp '.fig']) && this.plotqc
                h = figure;
                pcshow(pointCloud(this.T1w_ic, 'thresh', 0.75*dipmax(this.T1w_ic)))
                hold on; pcshow(pc.Location, '*m', 'MarkerSize', 12); hold off;
                saveas(h, [fp '.fig'])
                set(h, 'InvertHardCopy', 'off');
                set(h,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
                saveas(h, [fp '.png'])
                if this.plotclose
                    close(h)
                end
            end
            fp1 = fullfile(this.destinationPath, sprintf('%s_centerline_in_segmentation', tag));
            if ~isfile(fp1) && this.plotdebug
                h1 = figure;
                hold all;
                plot3(M(1,:), M(2,:), M(3,:), 'k.');
                plot3(P(1,:), P(2,:), P(3,:), 'b');
                plot3(C(1,:), C(2,:), C(3,:), 'm');
                legend('segmentation', 'control points', 'curve', ...
                    'Location', 'Best');
                hold off;
                saveas(h1, [fp1 '.fig'])
                saveas(h1, [fp1 '.png'])
                if this.plotclose
                    close(h1)
                end
            end
        end
        function this = buildCORegistrationTargets(this, dyn_ic)
            %% builds CO registration targets comprising time-averaged emissions.
            %  Registration targets are R^3 images.
            
            timeAveraged = dyn_ic.timeAveraged();
            timeAveraged_b25 = timeAveraged.blurred(2.5); % 2.5 mm blurring specified by Fung & Carson
            for i = 1:3
                this.registration.target_ics{i} = timeAveraged_b25; 
            end
        end
        function this = buildRegistrationTargets(this, dyn_ic_)
            %% Builds registration targets comprising time-averaged emissions for times
            %  sampled at {0.1:0.25,0.25:0.5,0.5:0.75} of maximal whole-brain emissions.
            %  Viz., whole-brain emissions determine the sampling intervals, but registration targets are R^3 images.

            if contains(dyn_ic_.fileprefix, 'CO') || contains(dyn_ic_.fileprefix, 'OC')
                this = this.buildCORegistrationTargets(dyn_ic_);
                return
            end

            dyn_avgxyz = dyn_ic_.volumeAveraged(logical(this.wmparc_ic));
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
            end
        end
        function tbl_idif = call(this, varargin)
            %% CALL
            %  @param toglob, e.g., 'sub-*Dynamic*_on_T1w.nii.gz'
            %  @param iterations for Chan-Vese snakes.
            %  @param smoothFactor for Chan-Vese snakes.
            %  @return table of IDIFs; write table to text file.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'toglob', this.pet_toglob, @ischar)
            addParameter(ip, 'iterations', this.iterations, @isscalar)
            addParameter(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;

            % build segmentation
            this.buildSegmentation(ipr.iterations, 'smoothFactor', ipr.smoothFactor);
            if this.segmentation_only
                tbl_idif = [];
                return
            end

            % build intermediate objects
            niis = globT(ipr.toglob);
            niis = niis(~contains(niis, '_avgt'));    
            if ~isempty(getenv('DEBUG'))
                niis = niis(8:9);
            end
            niifqfn = cell(1, length(niis));
            tracer = cell(1, length(niis));
            IDIF = cell(1, length(niis));

            for inii = 1:length(niis)

                % sample input function from dynamic PET             
                this.dyn_ic = mlfourd.ImagingContext2(niis{inii});
                this.buildCenterlines(this.static_ic)
                this.buildRegistrationTargets(this.dyn_ic)
                this.registerCenterlines('alg', this.alg)
                this.idifmask_ic = this.pointCloudsToIC(); % single ImagingContext
                this.idifmask_ic.filepath = this.dyn_ic.filepath;
                this.idifmask_ic.fileprefix = [this.dyn_ic.fileprefix '_idifmask'];
                this.idifmask_ic.save()
                idif = this.dyn_ic.volumeAveraged(this.idifmask_ic);

                % construct table variables
                niifqfn{inii} = this.idifmask_ic.fqfilename;
                tracer_ = this.tracername(this.idifmask_ic.fileprefix);
                tracer{inii} = tracer_;
                IDIF_ = asrow(this.decay_uncorrected(idif));
                IDIF{inii} = IDIF_;
                this.writetable(this.timesMid(tracer_), IDIF_, this.dyn_ic.fileprefix)
            end

            % construct table and write
            tbl_idif = table(niifqfn', tracer', IDIF', 'VariableNames', {'niifqfn', 'tracer', 'IDIF'});
            tbl_idif.Properties.Description = fullfile(this.destinationPath, sprintf('Fung2013_tbl_idif_%s.mat', this.subFolder));
            tbl_idif.Properties.VariableUnits = {'', '', 'Bq/mL'};
            save(tbl_idif.Properties.Description, 'tbl_idif')

            % plot and save
            this.plotIdif(tbl_idif);
        end
        function h = plotIdif(this, tbl_idif)
            %% As requested by ploton, plots then saves all IDIFs in the subject collection.  Clobbers previously saved.
            %  As requested by plotclose, closes figures.

            if this.ploton
                h = figure;
                hold on
                tracer_ = tbl_idif.tracer;
                for irow = 1:size(tbl_idif,1)
                    timesMid_ = this.timesMid(tracer_{irow});
                    IDIF_ = tbl_idif.IDIF{irow};
                    N = min(length(timesMid_), length(IDIF_));
                    switch tracer_{irow}
                        case {'OC' 'CO'}
                            linestyle = '-.';
                        case 'OO'
                            linestyle = '-';
                        case 'HO'
                            linestyle = '--';
                        otherwise
                            linestyle = ':';
                    end
                    plot(timesMid_(1:N), IDIF_(1:N), linestyle)
                end
                xlim([0 350])
                xlabel('time (s)')
                ylabel('activity density (Bq/mL)')
                title('Image-derived Input Functions')
                legend(tracer_')
                hold off
                [~,fqfp] = fileparts(tbl_idif.Properties.Description);
                saveas(h, [fqfp '.fig'])
                saveas(h, [fqfp '.png'])
                if this.plotclose
                    close(h)
                end
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
                fp = fullfile(this.petPath, sprintf('%s_%s_centerline_target', this.dyn_ic.fileprefix, Laterality));
                h = figure;
                pcshow(ipr.target)
                hold on; 
                pcshow(ipr.centerline.Location, '*g', 'MarkerSize', 12); 
                pcshow(ipr.centerlineOnTarget.Location, '*m', 'MarkerSize', 12); 
                hold off;
                title(sprintf('centerline (green -> magenta) on target %s %s', upper(ipr.laterality), this.dyn_label))
                saveas(h, [fp '.fig'])
                set(h, 'InvertHardCopy', 'off');
                set(h,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
                saveas(h, [fp '.png'])
                if this.plotclose
                    close(h)
                end
            end
            if this.plotdebug
                fp1 = fullfile(this.petPath, sprintf('%s_%s_centerline_target_pair', this.dyn_ic.fileprefix, Laterality));
                h1 = figure;
                pcshowpair(ipr.target, ipr.centerlineOnTarget, 'VerticalAxis', 'Z') % only magenta & green available in R2021b
                title(sprintf('centerline (green) on target (magenta) %s %s', upper(ipr.laterality), this.dyn_label))
                saveas(h1, [fp1 '.fig'])
                set(h1, 'InvertHardCopy', 'off');
                set(h1,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
                saveas(h1, [fp1 '.png'])
                if this.plotclose
                    close(h1)
                end
            end
        end
        function h = plotSegmentation(this, ac, iterations, smoothFactor)
            %% As requested by plotqc, plots then saves segmentations by activecontour.
            %  As requested by plotclose, closes figure.
            %  @param required activecontour result.
            %  @param iterations is integer.
            %  @param smoothFactor is scalar.
            
            fp = fullfile(this.destinationPath, [this.T1w_ic.fileprefix '_snakes']);
            if this.plotqc
                h = figure;
                p = patch(isosurface(double(ac)));
                p.FaceColor = 'red';
                p.EdgeColor = 'none';
                daspect([1 1 1])
                camlight;
                lighting phong
                title(sprintf('iterations %i, smooth %g', iterations, smoothFactor))
                saveas(h, [fp '.fig'])
                saveas(h, [fp '.png'])
                if this.plotclose
                    close(h)
                end
            end
        end
        function ic = pointCloudsToIC(this, varargin)
            %% converts point clouds for both hemispheres into ImagingContext objects.
        
            icL = this.pointCloudToIC(this.registration.centerlineOnTarget{1}, varargin{:});
            icL = icL.imdilate(strel('sphere', this.dilationRadius));
            icR = this.pointCloudToIC(this.registration.centerlineOnTarget{2}, varargin{:});
            icR = icR.imdilate(strel('sphere', this.dilationRadius));
            ic = icL + icR;
            ic = ic.binarized();
        end
        function ic = pointCloudToIC(this, pc, varargin)
            ip = inputParser;
            addRequired(ip, 'pc', @(x) isa(x, 'pointCloud'))
            addOptional(ip, 'fileprefix', 'pointClouudToIC', @ischar)
            parse(ip, pc, varargin{:})
            ipr = ip.Results;
            
            ic = this.T1w_ic.zeros();
            ifc = ic.nifti;
            ifc.fileprefix = ipr.fileprefix;
            X = round(pc.Location(:,1));
            Y = round(pc.Location(:,2));
            Z = round(pc.Location(:,3));
            ind = sub2ind(size(ifc), X, Y, Z);
            ifc.img(ind) = 1;
            ic = mlfourd.ImagingContext2(ifc);
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
                m_ = dipmedian(img);
                s_ = dipstd(img);
                if m_ - s_ > 0
                    ipr.thresh = m_ - s_;
                else
                    ipr.thresh = m_;
                end
            end
            target = pointCloud(ipr.ic3d, 'thresh', ipr.thresh); 
            centerlineOri = copy(ipr.centerline);
            
            idx = strcmpi(ipr.laterality, 'R') + 1; % idx == 1 <-> left            
            switch ipr.alg
                case 'ndt'
                    [tform,centerlineOnTarget,rmse] = pcregisterndt(centerlineOri, target, ipr.gridStep, ...
                        'Tolerance', [0.01 0.05]);
                case 'icp'
                    if ipr.gridStep ~= 1
                        centerlineOri = pcdownsample(centerlineOri, 'gridAverage', ipr.gridStep);
                    end
                    [tform,centerlineOnTarget,rmse] = pcregistericp(centerlineOri, target, ...
                        'Extrapolate', true, 'Tolerance', [0.01 0.01]);
                case 'cpd'
                    if ipr.gridStep ~= 1
                        centerlineOri = pcdownsample(centerlineOri, 'gridAverage', ipr.gridStep);
                    end
                    [tform,centerlineOnTarget,rmse] = pcregistercpd(centerlineOri, target, ...
                        'Transform', 'Rigid', 'MaxIterations', 100, 'Tolerance', 1e-7); % 'InteractionSigma', 2
                case 'fung'
                    this.registration.tform{idx} = rigid3d(eye(4));
                    rr = mlvg.Reregistration(this.T1w_ic);
                    [tform,centerlineOnTarget,rmse] = rr.pcregistermax( ...
                        this.registration.tform{idx}, centerlineOri, target);
                otherwise
                    error('mlraichle:ValueError', ...
                        'Fung2013.registerCenterlines.ipr.alg == %s', ipr.alg)
            end
            this.registration.centerlineOnTarget{idx} = copy(centerlineOnTarget);
            this.registration.tform{idx} = tform;
            this.registration.rmse{idx} = rmse;
            this.plotRegistered(target, centerlineOnTarget, centerlineOri, ipr.laterality)
        end
        function n = tracername(this, str)
            n = this.bids_.tracername(str);
        end
        function writetable(this, t, activity, dynfp)
            len = min(length(t), length(activity));
            t = ascol(t(1:len));
            activity = ascol(activity(1:len));
            tbl = table(t, activity);
            tbl.Properties.Description = ['Fung2013_' this.subFolder];
            tbl.Properties.VariableUnits = {'s', 'Bq/mL'};

            fqfn = fullfile(this.destinationPath, sprintf('%s_idif.csv', dynfp));
            writetable(tbl, fqfn)
        end
    end
    
    %% PROTECTED    
    
    methods (Access = protected)
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.bids_ = copy(this.bids_);
            that.hunyadi_ = copy(this.hunyadi_);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        bids_
        hunyadi_
    end
    
    methods (Access = private)
        function decay_uncorrected = decay_uncorrected(this, idif)
            %  @param idif is an mlfourd.ImagingContext2 containing a double row.
            %  @returns decay_uncorrected, the IDIF as a double row.

            assert(isa(idif, 'mlfourd.ImagingContext2'))
            decay_corrected = idif.nifti.img;
            if contains(idif.fileprefix, 'co') || contains(idif.fileprefix, 'oc')
                tracer = 'CO';
            end
            if contains(idif.fileprefix, 'ho')
                tracer = 'HO';
            end
            if contains(idif.fileprefix, 'oo')
                tracer = 'OO';
            end
            if contains(idif.fileprefix, 'fdg')
                tracer = 'FDG';
            end
            taus_ = this.taus(tracer);
            N = min(length(decay_corrected), length(taus_));
            radio = mlpet.Radionuclides(tracer);
            decay_uncorrected = decay_corrected(1:N) ./ radio.decayCorrectionFactors('taus', taus_(1:N));
        end
        function ic = maskInBoundingBox2(this, ic, laterality)
            ifc = ic.nifti;
            img = zeros(size(ifc));
            bb2 = this.coords_bb2;
            img(bb2{1},bb2{2},bb2{3}) = ifc.img(bb2{1},bb2{2},bb2{3});
            if ~isempty(laterality)
                if strcmpi(laterality, 'L') % L has indices < Nx/2
                    img(ceil(this.Nx/2)+1:end,:,:) = zeros(ceil(this.Nx/2),this.Ny,this.Nz);
                else
                    img(1:ceil(this.Nx/2),:,:) = zeros(ceil(this.Nx/2),this.Ny,this.Nz);                
                end
            end
            ifc.img = img;
            ifc.fileprefix = [ifc.fileprefix '_maskInBoundingBox'];
            ic = mlfourd.ImagingContext2(ifc);
        end
        function parseDestinationPath(this, dpath)
            this.bids_.parseDestinationPath(dpath)
        end
    end
end