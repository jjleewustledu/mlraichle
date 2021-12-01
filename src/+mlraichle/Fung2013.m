classdef Fung2013 < handle & mlraichle.AbstractFung2013
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
        it10
        it25
        it50
        it75
        registration % struct
            % tform
            % centerlineOnTarget
            % rmse 
            % target_ics are averages of frames containing 10-25 pcnt, 10-50 pcnt, 10-75 pcnt of max emissions
        taus % containers.Map
        times % containers.Map
        timesMid % containers.Map        
    end
    
    properties (Dependent)
        bbBufferMax % max voxels padded to coords to create convex bounding box for registration target by PET
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
        
        function g = get.bbBufferMax(this)
            g = round([this.Nx/16 this.Ny/16 3]);
        end
        
        %%
        
        function this = Fung2013(varargin)
            %% FUNG2013
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
            %  @param alg is 'cpd' or 'fung', used by registerCenterline(). 
            %  @param ploton is bool for showing IDIFs.
            %  @param plotqc is bool for showing QC.
            %  @param plotdebug is bool for showing information for debugging.
            %  @param plotclose closes plots after saving them.

            this = this@mlraichle.AbstractFung2013(varargin{:});

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'alg', 'fung', @(x) strcmpi(x, 'ndt') || strcmpi(x, 'icp') || strcmpi(x, 'cpd') || strcmpi(x, 'fung'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.alg = lower(ipr.alg);
            
            % gather requirements
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
        function this = buildAnatomy(this)
            this.anatomy_ = this.bids_.T1w_ic;
            this.anatomy_mask_ = this.bids_.wmparc_ic;
        end
        function this = buildPet(this)
            fnStatic = fullfile(this.petPath, [this.petBasename '_avgt_on_T1001.4dfp.hdr']);
            assert(isfile(fnStatic))
            this.petStatic_ = mlfourd.ImagingContext2(fnStatic);
            this.petStatic_.selectNifti();

            fnDynamic = fullfile(this.petPath, [this.petBasename '_on_T1001.4dfp.hdr']);
            assert(isfile(fnDynamic))
            this.petDynamic_ = mlfourd.ImagingContext2(fnDynamic);
            this.petDynamic_.selectNifti();
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
            end
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
                tbl_idif = [];
                return
            end

            % build intermediate objects
            niis = this.petGlobbed('isdynamic', false);
            if ~isempty(getenv('DEBUG'))
                niis = niis(8:9);
            end
            niifqfn = cell(1, length(niis));
            tracer = cell(1, length(niis));
            IDIF = cell(1, length(niis));

            for inii = 1:length(niis)

                % sample input function from dynamic PET
                this.petStatic = mlfourd.ImagingContext2(niis{inii});
                this.petDynamic = mlfourd.ImagingContext2(strrep(niis{inii}, '_avgt', ''));
                this.buildCenterlines()
                this.buildRegistrationTargets(this.petDynamic)
                this.registerCenterlines('alg', this.alg)
                this.idifmask_ic = this.pointCloudsToIC(); % single ImagingContext
                this.idifmask_ic.filepath = this.petDynamic.filepath;
                this.idifmask_ic.fileprefix = [this.petDynamic.fileprefix '_idifmask'];
                this.idifmask_ic.save()
                idif = this.petDynamic.volumeAveraged(this.idifmask_ic);

                % construct table variables
                niifqfn{inii} = this.idifmask_ic.fqfilename;
                tracer_ = this.tracername();
                tracer{inii} = tracer_;
                IDIF_ = asrow(this.decay_uncorrected(idif));
                IDIF{inii} = IDIF_;
                this.writetable(this.timesMid(tracer_), IDIF_, this.petDynamic.fileprefix)
            end

            % construct table and write
            tbl_idif = table(niifqfn', tracer', IDIF', 'VariableNames', {'niifqfn', 'tracer', 'IDIF'});
            tbl_idif.Properties.Description = fullfile(this.destinationPath, sprintf('Fung2013_tbl_idif_%s.mat', this.subFolder));
            tbl_idif.Properties.VariableUnits = {'', '', 'Bq/mL'};
            save(tbl_idif.Properties.Description, 'tbl_idif')

            % plot and save
            this.plotIdif(tbl_idif);
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
                    rr = mlvg.Reregistration(this.anatomy);
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
    end
    
    %% PRIVATE
    
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