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
        NCenterlineSamples % 1 voxel/mm for coarse representation of b-splines
    end

    methods (Abstract)
        buildAnatomy(this)
        buildCenterlines(this)
        buildCorners(this)
        buildSegmentation(this)
        call(this)
        pointCloudsToIC(this)
    end

    properties 
        bbBuffer % extra voxels padded to coords to create convex bounding box for segmentation & centerline
        bbRange % coord ranges {x1:xN, y1:yN, z1:zN} for bounding box
        centerlines_ics % L, R in cell
        centerlines_pcs % L, R in cell
        contractBias % used by activecontour
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
        segmentationThresh
        smoothFactor
        taus % containers.Map
        threshqc
        times % containers.Map
        timesMid % containers.Map 

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
        dx
        dy
        dz
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
        function g = get.dx(this)
            g = this.anatomy.nifti.mmppix(1);
        end
        function g = get.dy(this)
            g = this.anatomy.nifti.mmppix(2);
        end
        function g = get.dz(this)
            g = this.anatomy.nifti.mmppix(3);
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
            %  @param corners from fsleyes NIfTI [ x y z; ... ], [ [RS]; [LS]; [RI]; [LI] ].
            %  @param bbBuffer is the bounding box buffer ~ [x y z] in voxels.
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
            %  @param threshqc for buildCenterline.

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
            addParameter(ip, 'threshqc', 0.75, @isnumeric)
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
            this.contractBias = ipr.contractBias;
            this.smoothFactor = ipr.smoothFactor;
            this.segmentation_only = ipr.segmentationOnly;
            this.segmentation_blur = ipr.segmentationBlur;
            this.segmentationThresh = ipr.segmentationThresh;
            this.ploton = ipr.ploton;
            this.plotqc = ipr.plotqc;
            this.plotdebug = ipr.plotdebug;
            this.plotclose = ipr.plotclose;
            this.threshqc = ipr.threshqc;

            % gather requirements
            this.hunyadi_ = mlvg.Hunyadi2021();
            this.buildAnatomy();
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
            if this.plotqc
                h = figure;
                pcshow(pointCloud(this.anatomy, 'thresh', this.threshqc*dipmax(this.anatomy)))
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
            if this.plotdebug
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
        function box = ensureBoxInFieldOfView(this, box)
            %% removes any elements of box := {xrange yrange zrange}, with anisotropic ranges, 
            %  that lie outside of the field of view of this.anatomy.

            assert(iscell(box), 'mlraichle:ValueError', ...
                'AbstractFung2013.ensureBoxInFieldOfView: class(box)->%s', class(box))
            size_ = size(this.anatomy);
            for m = 1:length(box)
                bm = box{m};
                box{m} = bm(1 <= bm & bm <= size_(m));
            end
        end
        function [X,Y,Z] = ensureSubInFieldOfView(this, X, Y, Z)
            %% removes any subscripts X, Y, and Z, which are equally sized, that lie outside of 
            %  the field of view of this.anatomy.

            assert(isvector(X))
            assert(isvector(Y))
            assert(isvector(Z))
            assert(length(X) == length(Y) && length(Y) == length(Z))

            size_ = size(this.anatomy);
            toss_ =          X < 1 | size_(1) < X;
            toss_ = toss_ | (Y < 1 | size_(2) < Y);
            toss_ = toss_ | (Z < 1 | size_(3) < Z);

            X = X(~toss_);
            Y = Y(~toss_);
            Z = Z(~toss_);
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
        function h = plotSegmentation(this, ac, varargin)
            %% As requested by plotqc, plots then saves segmentations by activecontour.
            %  As requested by plotclose, closes figure.
            %  @param required activecontour result.
            %  @param iterations is integer.
            %  @param smoothFactor is scalar.

            ip = inputParser;
            addRequired(ip, 'ac', @islogical)
            addOptional(ip, 'iterations', this.iterations, @isscalar)
            addOptional(ip, 'smoothFactor', this.smoothFactor, @isscalar)
            parse(ip, ac, varargin{:})
            ipr = ip.Results;
            
            fp = fullfile(this.destinationPath, [this.anatomy.fileprefix '_snakes']);
            if this.plotqc
                h = figure;
                mmppix = this.anatomy.imagingFormat.mmppix;
                L = (size(ipr.ac) - 1) .* mmppix;
                [X,Y,Z] = meshgrid(0:mmppix(1):L(1), 0:mmppix(2):L(2), 0:mmppix(3):L(3));
                X = permute(X, [2 1 3]);
                Y = permute(Y, [2 1 3]);
                Z = permute(Z, [2 1 3]);
                p = patch(isosurface(X, Y, Z, double(ipr.ac)));
                p.FaceColor = 'red';
                p.EdgeColor = 'none';
                daspect([1 1 1])
                camlight;
                lighting phong
                title(sprintf('iterations %i, contractBias %g, smoothFactor %g, segmentationThresh %g', ...
                    ipr.iterations, this.contractBias, ipr.smoothFactor, this.segmentationThresh))
                saveas(h, [fp '.fig'])
                saveas(h, [fp '.png'])
                if this.plotclose
                    close(h)
                end
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
            [X,Y,Z] = this.ensureSubInFieldOfView(X, Y, Z);
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
            tbl.Properties.Description = [class(this) '_' this.subFolder];
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

