classdef AbstractFung2013 < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% ABSTRACTFUNG2013 provides abstractions and reusable implementations of  
    %  Edward K Fung and Richard E Carson.  Cerebral blood flow with [15O]water PET studies using 
    %  an image-derived input function and MR-defined carotid centerlines.  
    %  Phys. Med. Biol. 58 (2013) 1903–1923.  doi:10.1088/0031-9155/58/6/1903

	%  $Revision$
 	%  was created 22-Nov-2021 20:56:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.11.0.1809720 (R2021b) Update 1 for MACI64.  Copyright 2021 John Joowon Lee.

	properties (Abstract)

    end

    methods (Abstract)
        buildAnatomy(this)
        buildPet(this)
        call(this)
    end

    properties 
        bbBuffer % extra voxels padded to coords to create convex bounding box for segmentation & centerline
        bbRange % coord ranges {x1:xN, y1:yN, z1:zN} for bounding box
        centerlines_ics % L, R in cell
        centerlines_pcs % L, R in cell
        contract_bias % used by activecontour
        coords % 4 coord points along carotid centerlines at corners
        coords_b1_ic % coord points, blurred by 1 voxel fwhm, as ImagingContext2
        dilationRadius = 2 % Fung reported best results with radius ~ 2.5, but integers may be faster
        idifmask_ic % contains centerline expanded by dilationRadius as ImagingContext
        iterations
        plotclose % close plots after saving
        plotdebug % show debugging plots
        ploton % show final results
        plotqc % show more plots for QA
        segmentation_blur
        segmentation_only
        segmentation_ic % contains solid 3D volumes for carotids
        segmentation_thresh
        smoothFactor

        %% for B-splines in mlvg.Hunyadi2021

        k = 4
        t = [0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
        U % # samples for bspline_deboor()
        Cs % curves in cell, 3 x this.U
        Ps % control points in cell, 3 x M
    end

    properties (Dependent)
        anatomy
        anatomy_mask
        anatPath
        derivativesPath
        destinationPath
        NCenterlineSamples % 1 voxel/mm for coarse representation of b-splines
        Nx
        Ny
        Nz
        mriPath
        petPath
        petBasename
        petDynamic % contains PET dynamic as ImagingContext2 (LARGE)
        petStatic % contains PET static as ImagingContext2
        projPath
        sourcedataPath
        sourceAnatPath
        sourcePetPath
        subFolder
    end

	methods 
        
        %% GET
        
        function g = get.anatomy(this)
            g = this.anatomy_;
        end
        function g = get.anatomy_mask(this)
            g = this.anatomy_mask_;
        end
        function g = get.anatPath(this)
            g = this.bids_.anatPath;
        end
        function g = get.derivativesPath(this)
            g = this.bids_.derivativesPath;
        end
        function g = get.destinationPath(this)
            g = this.bids_.destinationPath;
        end
        function g = get.NCenterlineSamples(this)
            rngz = max(this.bbRange{3}) - min(this.bbRange{3});
            g = ceil(rngz/this.anatomy.nifti.mmppix(3)); % sample single voxels along z
        end
        function g = get.Nx(this)
            g = size(this.anatomy, 1);
        end
        function g = get.Ny(this)
            g = size(this.anatomy, 2);
        end
        function g = get.Nz(this)
            g = size(this.anatomy, 3);
        end
        function g = get.mriPath(this)
            g = this.bids_.mriPath;
        end
        function g = get.petPath(this)
            g = this.bids_.petPath;
        end
        function g = get.petBasename(this)
            if ~isempty(this.petBasename_)
                g = this.petBasename_;
                return
            end
            if ~isempty(this.petStatic)
                str = this.petStatic.fileprefix;
            elseif ~isempty(this.petDynamic)
                str = this.petDynamic.fileprefix;
            else
                g = '';
                return
            end
            re = regexp(str, '(?<basename>[a-z]+dt\d{14})', 'names');
            g = re.basename;
        end
        function     set.petBasename(this, s)
            assert(ischar(s))
            this.petBasename_ = s;
        end
        function g = get.petDynamic(this)
            if ~isempty(this.petDynamic_)
                g = copy(this.petDynamic_);
                return
            end
            g = [];
        end
        function     set.petDynamic(this, s)
            assert(isa(s, 'mlfourd.ImagingContext2'))
            this.petDynamic_ = s;
        end
        function g = get.petStatic(this)
            if ~isempty(this.petStatic_)
                g = copy(this.petStatic_);
                return
            end
            g = [];
        end
        function     set.petStatic(this, s)
            assert(isa(s, 'mlfourd.ImagingContext2'))
            this.petStatic_ = s;
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
        function g = get.subFolder(this)
            g = this.bids_.subFolder;
        end

        %%
		  
 		function this = AbstractFung2013(varargin)
 			%% ABSTRACTFUNG2013
            %  @param destinationPath is the path for writing outputs.  Default is MMRBids.destinationPath.  
            %         Must specify project ID & subject ID.
            %  @param corners from fsleyes [ x y z; ... ], [ [RS]; [LS]; [RI]; [LI] ].
            %  @param bbBuffer is the bounding box buffer ~ [x y z].
            %  @param iterations ~ 80:130.
            %  @param smoothFactor ~ 0.
            %  @param contractBias is the contraction bias for activecontour():  ~[-1 1], bias > 0 contracting.
            %  @param segmentationOnly is logical.
            %  @param segmentationBlur is scalar.
            %  @param segmentationThresh is scalar.
            %  @param ploton is bool for showing IDIFs.
            %  @param plotqc is bool for showing QC.
            %  @param plotdebug is bool for showing information for debugging.
            %  @param plotclose closes plots after saving them.

 			this.bids_ = mlraichle.MMRBids(varargin{:}); 

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'destinationPath', this.bids_.destinationPath, @isfolder)
            addParameter(ip, 'corners', [], @(x) ismatrix(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'bbBuffer', [3 3 0], @(x) isvector(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'iterations', 70, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'smoothFactor', 0, @isscalar)
            addParameter(ip, 'contractBias', 0.02, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'segmentationOnly', false, @islogical)
            addParameter(ip, 'segmentationBlur', 0, @(x) isscalar(x) || isa(x, 'containers.Map'))
            addParameter(ip, 'segmentationThresh', 190, @(x) isscalar(x) || isa(x, 'containers.Map')) % tuned for PPG T1001
            addParameter(ip, 'ploton', true, @islogical)
            addParameter(ip, 'plotqc', true, @islogical)
            addParameter(ip, 'plotdebug', false, @islogical)
            addParameter(ip, 'plotclose', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.bids_.parseDestinationPath(ipr.destinationPath)
            if isa(ipr.corners, 'containers.Map')
                ipr.corners = ipr.corners(this.subFolder);
            end
            if isa(ipr.bbBuffer, 'containers.Map')
                ipr.bbBuffer = ipr.bbBuffer(this.subFolder);
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
            this.coords = ipr.corners;
            this.bbBuffer = ipr.bbBuffer;
            this.iterations = ipr.iterations;
            this.contract_bias = ipr.contractBias;
            this.smoothFactor = ipr.smoothFactor;
            this.segmentation_only = ipr.segmentationOnly;
            this.segmentation_blur = ipr.segmentationBlur;
            this.segmentation_thresh = ipr.segmentationThresh;
            this.ploton = ipr.ploton;
            this.plotqc = ipr.plotqc;
            this.plotdebug = ipr.plotdebug;
            this.plotclose = ipr.plotclose;

            % gather requirements
            this.hunyadi_ = mlvg.Hunyadi2021();
            this.buildAnatomy();
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
                error('mlraichle:Fung2013', ...
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
            this.coords_b1_ic.fileprefix = 'corners_on_T1w_spheres';

            % build bbRange
            for m = 1:3
                bb_m_ = (min(this.coords(:,m)) - this.bbBuffer(m)):(max(this.coords(:,m)) + this.bbBuffer(m) + 1);
                this.bbRange{m} = bb_m_(bb_m_ >=1 & bb_m_ <= this.anatomy.size(m));
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
                        
            blurred = this.anatomy.blurred(this.segmentation_blur);
            anatomyb_img = blurred.nifti.img(this.bbRange{:});
            threshed_ic = this.anatomy.thresh(this.segmentation_thresh);
            imfilled_ic = threshed_ic.imfill(6, 'holes'); % 6, 18, 26
            if this.plotdebug
                figure
                pcshow(imfilled_ic.pointCloud)
                figure
                pcshow(threshed_ic.pointCloud)
                %threshed_ic.fsleyes
            end
            %imfilled_img = logical(imfilled_ic.nifti.img(this.bbRange{:}));
            coords_bb_img = logical(this.coords_b1_ic.nifti.img(this.bbRange{:}));
            
            % call snakes, viz., iterate
            ac = activecontour(anatomyb_img, coords_bb_img, ipr.iterations, 'Chan-Vese', ...
                'ContractionBias', this.contract_bias, 'SmoothFactor', ipr.smoothFactor);
            this.plotSegmentation(ac, ipr.iterations, ipr.smoothFactor);

            % fit back into anatomy
            ic = this.anatomy.zeros;
            ic.filepath = this.destinationPath;
            ic.fileprefix = [ic.fileprefix '_segmentation'];
            nii = ic.nifti;
            nii.img(this.bbRange{:}) = ac;
            %%nii.save()
            this.segmentation_ic = mlfourd.ImagingContext2(nii);
        end
        function this = buildCenterlines(this)
            %% builds left and right centerlines, calling this.buildCenterline() for each.
            %  Requires this.petStatic to contain time-averaged PET which delimits spatial extent of centerlines.
            %  @return this.centerlines_pcs are the pointCloud representation of the centerlines.
            %  @return this.Cs are {L,R} points of the B-spline curve.
            %  @return this.Ps are {L,R} matrices of B-spline control points.

            img = logical(this.segmentation_ic) .* logical(this.petStatic);
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
            %  as requested by plotqc and plotdebug, plots centerline with thresholded anatomy and,
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
            
            fp = fullfile(this.destinationPath, sprintf('%s_centerline_in_%s', tag, this.anatomy.fileprefix));
            if ~isfile([fp '.fig']) && this.plotqc
                h = figure;
                pcshow(pointCloud(this.anatomy, 'thresh', 0.75*dipmax(this.anatomy)))
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
            if ~isfile([fp1 '.fig']) && this.plotdebug
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
        function g = petGlobbed(this, varargin)
            ip = inputParser;
            addOptional(ip, 'isdynamic', true, @islogical)
            parse(ip, varargin{:})

            g = glob(fullfile(this.petPath, '*dt*_on_T1001.4dfp.hdr'));
            if ip.Results.isdynamic
                g = g(~contains(g, '_avgt'));
            else
                g = g(contains(g, '_avgt'));
            end
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
        function h = plotSegmentation(this, ac, iterations, smoothFactor)
            %% As requested by plotqc, plots then saves segmentations by activecontour.
            %  As requested by plotclose, closes figure.
            %  @param required activecontour result.
            %  @param iterations is integer.
            %  @param smoothFactor is scalar.
            
            fp = fullfile(this.destinationPath, [this.anatomy.fileprefix '_snakes']);
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
            if this.plotdebug
                ic.fsleyes()
            end
        end
        function ic = pointCloudToIC(this, pc, varargin)
            ip = inputParser;
            addRequired(ip, 'pc', @(x) isa(x, 'pointCloud'))
            addOptional(ip, 'fileprefix', 'pointCloudToIC', @ischar)
            parse(ip, pc, varargin{:})
            ipr = ip.Results;
            
            ifc = this.anatomy.nifti;
            ifc.fileprefix = ipr.fileprefix;
            X = round(pc.Location(:,1));
            Y = round(pc.Location(:,2));
            Z = round(pc.Location(:,3));
            ind = sub2ind(size(ifc), X, Y, Z);
            img = zeros(size(this.anatomy));
            img(ind) = 1;
            ifc.img = img;
            ic = mlfourd.ImagingContext2(ifc);
        end
        function n = tracername(this)
            n = this.bids_.tracername(this.petBasename);
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
    
    properties (Access = protected)
        anatomy_
        anatomy_mask_
        bids_
        petBasename_
        petDynamic_
        hunyadi_
        petStatic_
    end

    methods (Access = protected)
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.bids_ = copy(this.bids_);
            that.hunyadi_ = copy(this.hunyadi_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

