classdef SubjectImages 
	%% SUBJECTIMAGES provides detailed access to subject-specific images.

	%  $Revision$
 	%  was created 04-May-2018 12:10:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    
    properties (Constant)
        DISABLE_FINISHFILE = true % to load t4 files into class instances
    end
    
	properties (Dependent)
 		areAligned
        compositeRB
        product
        referenceImage
        referenceTracer   
        ReferenceTracer
        sessionData
        t4s
    end
    
    methods (Static)
        function repairCrossModalDynamic(varargin)
            %% repairCrossModalDynamic aligns, de novo, source dynamic images to a cross-modal reference.
            
            ip = inputParser;
            addParameter(ip, 'vallLocation', pwd, @isdir);
            addParameter(ip, 'vref', 1, @isnumeric);
            parse(ip, varargin{:});
            vref = ip.Results.vref;
            
            pwd0 = pushd(ip.Results.vallLocation);
            fprintf('mlraichle.SubjectImages.repairCrossModalDynamic is working in %s\n', pwd);
            outs = {};
            fv = mlfourdfp.FourdfpVisitor;
            
            for v = 1:4
                if (lexist(sprintf('fdgv%ir1_sumt_op_fdgv%ir1.4dfp.img ', v, vref)))
                    outs = [outs fdg]; %#ok<AGROW>
                end
            end            
            tr = {'oc' 'oo' 'ho'};
            for t = 1:length(tr)
                for v = 1:4
                    for s = 1:3
                        try
                            t4  = sprintf('%s%iv%ir1_sumtr1_to_op_fdgv%ir1_t4', tr{t}, s, v, vref);
                            src = sprintf('%s%iv%ir1', tr{t}, s, v);
                            out = sprintf('%s%iv%ir1_op_fdgv%ir1', tr{t}, s, v, vref);
                            fv.t4img_4dfp(t4, src, 'out', out, 'options', ['-O' src]);
                            nn = mlfourd.NumericalNIfTId.load([out '.4dfp.hdr']);
                            nn = nn.timeSummed;
                            nn.filesuffix = '.4dfp.hdr';
                            nn.save;
                            outs = [outs sprintf('%s.4dfp.img ', nn.fqfileprefix)]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME, 'mlraichle:RuntimeError', ...
                                'SubjectImages.repairCrossModalDynamic failed with src->%s, out->%', src, out);
                        end
                    end
                end
            end
            %mlfourdfp.Viewer.view(outs);
            popd(pwd0);
        end
    end
    
	methods 
        
        %% GET, SET
        
        function g = get.areAligned(this)
            g = this.areAligned_;
        end
        function g = get.compositeRB(this)
            g = this.cRB_;
        end
        function g = get.referenceImage(this)
            %  @return ImagingContext.
            
            sessd = this.sessionData_;
            sessd.tracer = upper(this.referenceTracer);
            sessd.rnumber = this.rnumberOfSource_;
            g = sessd.tracerResolvedFinal('typ', 'mlfourd.ImagingContext');
        end
        function g = get.ReferenceTracer(this)
            g = upper(this.referenceTracer_);
        end
        function this = set.ReferenceTracer(this, s)
            assert(ischar(s));
            this.referenceTracer_ = s;
        end
        function g = get.referenceTracer(this)
            g = lower(this.referenceTracer_);
        end
        function this = set.referenceTracer(this, s)
            assert(ischar(s));
            this.referenceTracer_ = s;
        end
        function g = get.product(this)
            g = this.product_;
        end
        function this = set.product(this, s)
            this.product_ = s;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.t4s(this)
            g = this.t4s_;
        end
        
        %%
        
        function this = alignCommonModal(this, tracer, varargin)
            %% ALIGNCOMMONMODAL
            %  @param tracer, ctor.census & ctor.sessionData select images.
            %  @return t4 in this.t4s:             e.g., {ho[1-9]v[1-9]r1_sumtr1_to_op_hov1r1_t4}.
            %  @return resolved in this.product:   e.g., {ho[1-9]v[1-9]r1_sumtr1_op_hov1r1.4dfp.hdr}.
            % 
            %  e.g., HYGLY24/Vall obtains:
            %  fdgv3r1.4dfp % the reference
            %  fdgv1r1_sumtr1_op_fdgv3r1.4dfp ... fdgv4r1_sumtr1_op_fdgv3r1.4dfp
            %  fdgv1r1_sumt_on_fdg.4dfp ... fdgv4r1_sumt_on_fdg.4dfp
            %  fdgv1r1_sumt.4dfp ... fdgv4r1_sumt.4dfp
            
            imgsSumt = this.sourceImages(tracer, true);
            this.sessionData_.tracer = upper(tracer);
            this.referenceTracer = lower(tracer);
            this = this.resolve(imgsSumt, varargin{:}); 
            % cell2str(this.t4s_) =>
            % ho1v1r1_sumtr1_to_op_hov1r1_t4
            % ho2v1r1_sumtr1_to_op_hov1r1_t4
            % ho1v2r1_sumtr1_to_op_hov1r1_t4
            % ho2v2r1_sumtr1_to_op_hov1r1_t4            
            % cellfun(@(x) ls(x.filename), this.product_, 'UniformOutput', false) =>
            % ho1v1r1_sumtr1_op_hov1r1.4dfp.hdr
            % ho2v1r1_sumtr1_op_hov1r1.4dfp.hdr
            % ho1v2r1_sumtr1_op_hov1r1.4dfp.hdr
            % ho2v2r1_sumtr1_op_hov1r1.4dfp.hdr
            % this.t4s_{1}' =>
            % 'oc1v1r1_sumtr1_to_op_ocv1r1_t4'
            % 'oc2v1r1_sumtr1_to_op_ocv1r1_t4'
            % 'oc1v2r1_sumtr1_to_op_ocv1r1_t4'
            % 'oc2v2r1_sumtr1_to_op_ocv1r1_t4'
            % cellfun(@(x) x.fqfilename, this.product_, 'UniformOutput', false)'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oc1v1r1_sumtr1_op_ocv1r1.4dfp.hdr'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oc2v1r1_sumtr1_op_ocv1r1.4dfp.hdr'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oc1v2r1_sumtr1_op_ocv1r1.4dfp.hdr'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oc2v2r1_sumtr1_op_ocv1r1.4dfp.hdr'
            
        end
        function this = alignCrossModal(this) 
            %% ALIGNCROSSMODAL
            %  theFdg,theHo,theOo,theOc
            %  @return t4 in this.t4s:            e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_to_op_fdgv1r1_t4}.
            %  @return resolved in this.product:  e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_op_fdgv1r1.4dfp.hdr}.            

            ensuredir(this.sessionData.vallLocation);
            pwd0   = pushd(this.sessionData.vallLocation);            
            theHo  = this.alignCommonModal('HO');
            theHo  = theHo.productAverage;            
            theOo  = this.alignCommonModal('OO');
            theOo  = theOo.productAverage; 
            theFdg = this.alignCommonModal('FDG');
            theFdg = theFdg.productAverage;
            this = theFdg;

            imgs = {theFdg.product{1}.fqfileprefix ...
                    theHo.product{1}.fqfileprefix ...
                    theOo.product{1}.fqfileprefix}; 
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_sumtr1_op_fdgv1r1_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/hov1r1_sumtr1_op_hov1r1_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oov1r1_sumtr1_op_oov1r1_avg'

            this = this.resolve(imgs, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'Msktgen');
            % cell2str(this.t4s_) =>
            % fdgv1r1_sumtr1_op_fdgv1r1_avgr1_to_op_fdgv1r1_t4
            % hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4
            % oov1r1_sumtr1_op_oov1r1_avgr1_to_op_fdgv1r1_t4
            % cellfun(@(x) ls(x.filename), this.product_, 'UniformOutput', false) =>
            % fdgv1r1_sumtr1_op_fdgv1r1_avgr1_op_fdgv1r1.4dfp.hdr
            % hov1r1_sumtr1_op_hov1r1_avgr1_op_fdgv1r1.4dfp.hdr
            % oov1r1_sumtr1_op_oov1r1_avgr1_op_fdgv1r1.4dfp.hdr

            this.saveThis('alignCrossModal_this');

            this.alignDynamicImages('commonRef', theHo,  'crossRef', this);
            this.alignDynamicImages('commonRef', theOo,  'crossRef', this);
            this.alignDynamicImages('commonRef', theFdg, 'crossRef', this);
            popd(pwd0);    

            that = this.alignCrossModalSubset;
            this.product_ = [this.product that.product];

            this.constructReferenceTracerToT1001T4;
        end
        function this = alignCrossModalSubset(this)
            pwd0   = pushd(this.sessionData.vallLocation);                     
            theFdg = this.constructFramesSubset('FDG', 1:8);
            theOc  = this.alignCommonModal('OC'); 
            theOc  = theOc.productAverage;
            theOc  = theOc.sqrt;
            
            imgs = {theFdg.product{1}.fqfileprefix ...
                    theOc.product{1}.fqfileprefix};
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_op_fdgv1r1_frames1to8_sumt_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/ocv1r1_sumtr1_op_ocv1r1_avg_sqrt'

            this = this.resolve(imgs, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'none');
            % cell2str(this.t4s_) =>            
            % fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_to_op_fdgv1r1_t4
            % ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4
            % cellfun(@(x) ls(x.filename), this.product_, 'UniformOutput', false) =>    
            % fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_op_fdgv1r1.4dfp.hdr
            % ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_op_fdgv1r1.4dfp.hdr

            this.saveThis('alignCrossModalSubset_this');
            this.alignDynamicImages('commonRef', theOc,  'crossRef', this);
            popd(pwd0);
        end
        function this = alignCrossModalVM(this)
            pwd0 = pushd(this.sessionData.vallLocation);
            this.buildVisitor_.sqrt_4dfp('ocv1r1_sumtr1_op_ocv1r1_avg');
            imgs = {'fdgv1r1_sumtr1_op_fdgv1r1_avg' ...
                    'hov1r1_sumtr1_op_hov1r1_avg' ...
                    'oov1r1_sumtr1_op_oov1r1_avg' ...
                    'ocv1r1_sumtr1_op_ocv1r1_avg_sqrt'}; % product averages
            this = this.resolveVM(imgs, 'compAlignMethod', 'align_crossModal');
            this.saveThis('alignCrossModalVM_this');
            popd(pwd0);
        end
        function this = alignDynamicImages(this, varargin)
            %% ALIGNDYNAMICIMAGES aligns common-modal source dynamic images to a cross-modal reference.
            %  @param commonRef, or common-modal reference, e.g., any of OC, OO, HO, FDG.
            %  @param crossRef,  or cross-modal reference, e.g., FDG.
            %  @return this.product := dynamic images aligned to a cross-modal reference is saved to the filesystem.
            
            %  TODO:  manage case of homo-tracer subsets
            
            ip = inputParser;
            addParameter(ip, 'commonRef', [], @(x) isa(x, 'mlraichle.SubjectImages'));
            addParameter(ip, 'crossRef',  [], @(x) isa(x, 'mlraichle.SubjectImages'));
            parse(ip, varargin{:});
            comm  = ip.Results.commonRef;
            cross = ip.Results.crossRef;
            
            pwd0 = pushd(this.sessionData.vallLocation);            
            comm = comm.t4imgDynamicImages; % comm.product := dynamic aligned to time-summed comm.product{1}
            t4form = comm.reshapeT4s(cross.selectT4s('sourceTracer', comm.referenceTracer)); % construct t4s{r} for comm.product to cross.product{1}
            % tmp = cross.selectT4s(); tmp{1} => 'hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4'
            % t4form{1}' =>
            % 'hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4'
            % 'hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4'
            % 'hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4'
            % 'hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4'
            % cellfun(@(x) x.filename, comm.product, 'UniformOutput', false)' =>
            % 'ho1v1r1_op_hov1r1.nii'
            % 'ho2v1r1_op_hov1r1.4dfp.hdr'
            % 'ho1v2r1_op_hov1r1.4dfp.hdr'
            % 'ho2v2r1_op_hov1r1.4dfp.hdr'            
            % tmp = cross.selectT4s(); tmp{1} => 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4'
            % t4form{1}' =>
            % 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4'
            % 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4'
            % 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4'
            % 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4'
            % cellfun(@(x) x.filename, comm.product, 'UniformOutput', false)' =>
            % 'oc1v1r1_op_ocv1r1.4dfp.hdr'
            % 'oc2v1r1_op_ocv1r1.4dfp.hdr'
            % 'oc1v2r1_op_ocv1r1.4dfp.hdr'
            % 'oc2v2r1_op_ocv1r1.4dfp.hdr'            
            
            this.constructTracerRevisionToReferenceT4(comm, comm.t4s_, t4form);
            % comm.t4s_{1}'
            % 'fdgv2r1_sumtr1_to_op_fdgv2r1_t4'
            % 'fdgv3r1_sumtr1_to_op_fdgv2r1_t4'
            % 'fdgv1r1_sumtr1_to_op_fdgv2r1_t4'
            % ans =>
            % 'fdgv2r1_to_fdg_t4'
            % 'fdgv3r1_to_fdg_t4'
            % 'fdgv1r1_to_fdg_t4'            
    
            comm.saveStandardized;
            comm.saveSumtStandardized;
            % cellfun(@(x) x.filename, comm.product, 'UniformOutput', false)' =>
            % 'fdgv2r1_op_fdgv2r1.4dfp.hdr'
            % 'fdgv3r1_op_fdgv2r1.4dfp.hdr'
            % 'fdgv1r1_op_fdgv2r1.4dfp.hdr'
    
            cross = cross.t4imgc(t4form, comm.product);            
            this.product_ = cross.product;
            this.saveStandardized;
            this.saveSumtStandardized;
            % cellfun(@(x) x.filename, this.product_, 'UniformOutput', false)' =>             
            % 'ho1v1r1_op_hov1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'ho2v1r1_op_hov1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'ho1v2r1_op_hov1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'ho2v2r1_op_hov1r1_on_op_fdgv1r1.4dfp.hdr'            
            % cellfun(@(x) x.filename, this.product_, 'UniformOutput', false)' => 
            % 'oc1v1r1_op_ocv1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'oc2v1r1_op_ocv1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'oc1v2r1_op_ocv1r1_on_op_fdgv1r1.4dfp.hdr'
            % 'oc2v2r1_op_ocv1r1_on_op_fdgv1r1.4dfp.hdr'            
            
            this.teardownIntermediates;
            popd(pwd0);
        end
        function this = alignFrameGroups(this, tracer, frames1, frames2, varargin)
            assert(ischar(tracer));
            assert(isnumeric(frames1));
            assert(isnumeric(frames2));
            
            g1 = this.constructFramesSubset(tracer, frames1, varargin{:});
            g2 = this.constructFramesSubset(tracer, frames2, varargin{:});
            this = this.resolve({g1.product{1} g2.product{1}}, varargin{:});
        end
        function this = alignOpT1001(this, varargin)
            %  @param this.product.
            %  @return resolved to T1001 in this.product.
            
            assert(lexist_4dfp('T1001'));
            imgs = ['T1001' cellfun(@(x) x.fqfileprefix, this.product, 'UniformOutput', false)];
            this = this.resolve(imgs, 'NRevisions', 1);
        end
        
        function this = constructFramesSubset(this, tracer, frames, varargin)
            assert(ischar(tracer));
            assert(isnumeric(frames));
            
            pwd0 = pushd(this.sessionData.vallLocation);
            this = this.alignCommonModal(tracer, varargin{:});
            % this.t4s_{1}' =>
            % 'fdgv1r1_sumtr1_to_op_fdgv1r1_t4'
            % 'fdgv2r1_sumtr1_to_op_fdgv1r1_t4'
            %  cellfun(@(x) x.fqfilename, this.product_, 'UniformOutput', false)' =>
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_sumtr1_op_fdgv1r1.4dfp.hdr'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv2r1_sumtr1_op_fdgv1r1.4dfp.hdr'
            
            this = this.t4imgDynamicImages(tracer);
            for d = 1:length(this.product)
                nn = this.product_{d}.numericalNiftid;
                assert(frames(end) <= size(nn, 4));
                nn.img = nn.img(:,:,:,frames);
                nn.filepath = this.sessionData.vallLocation;
                nn.filename = sprintf('%s_frames%ito%i.4dfp.hdr', nn.fileprefix, frames(1), frames(end));
                nn = nn.timeSummed;
                nn.save;
                this.product{d} = mlfourd.ImagingContext(nn);
                % this.product{d}.fqfilename => 
                % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_op_fdgv1r1_frames1to8_sumt.4dfp.hdr                

            end   
            this = this.productAverage;
            popd(pwd0);
        end
        function        constructReferenceTracerToT1001T4(this)
            pwd0 = pushd(this.sessionData.vallLocation);  
            ref  = this.referenceTracer;
            t40 = sprintf('%sv1r1_sumtr1_op_%sv1r1_avgr1_to_T1001r1_t4', ref, ref);
            if (~lexist(t40, 'file'))
                t40 = sprintf('%sv1r1_sumt_avgr1_to_T1001r1_t4', ref);
            end
            copyfile(t40, sprintf('%s_to_T1001_t4', ref));
            popd(pwd0);
        end
        function ref  = constructRefFramesSubset(this, frames)
            %% CONSTRUCTFRAMESSUBSET from this.sessionData_.tracerResolvedFinal.
            
            sd2 = this.sessionData_; sd2.rnumber = 2;
            ref = sd2.tracerResolvedFinal('typ', 'mlfourd.ImagingContext');
            nn  = ref.numericalNiftid;
            assert(frames(end) <= size(nn, 4));
            nn.img = nn.img(:,:,:,frames);
            nn.filepath = pwd;
            nn.filename = sprintf('%s_frames%ito%i.4dfp.hdr', nn.fileprefix, frames(1), frames(end));
            nn = nn.timeSummed;
            nn.save;
            ref = nn.fqfileprefix;
        end
        function t4   = constructTracerRevisionToReferenceT4(this, varargin)
            %  @param  required comm is mlraichle.SubjectImages.
            %  @param  required tracerToCommonT4 is char or {{}}.
            %  @param  required commonToCrossT4 is char or {{}}.
            %  @param  named reference is char.
            %  @return t4 ~ ho[1-9]v[1-9]r1_to_fdg_t4
            
            ip = inputParser;
            addRequired(ip, 'comm', @(x) isa(x, 'mlraichle.SubjectImages'));
            addRequired(ip, 'tracerToCommonT4', @(x) ischar(x) || iscell(x));
            addRequired(ip, 'commonToCrossT4',  @(x) ischar(x) || iscell(x));
            addParameter(ip, 'reference', this.referenceTracer, @ischar);
            parse(ip, varargin{:});
            comm             = ip.Results.comm;
            tracerToCommonT4 = ip.Results.tracerToCommonT4;
            commonToCrossT4  = ip.Results.commonToCrossT4;

            % recursion for cells
            if (iscell(tracerToCommonT4) && iscell(commonToCrossT4)) 
                assert(length(tracerToCommonT4) == length(commonToCrossT4));
                assert(length(tracerToCommonT4{1}) == length(commonToCrossT4{1}));
                t4 = cellfun(@(x,y) this.constructTracerRevisionToReferenceT4(comm, x,y), ...
                    tracerToCommonT4{1}, commonToCrossT4{1}, 'UniformOutput', false);
                return
            end
            
            % base case
            toks = regexp(tracerToCommonT4, '^(?<tracRev>\w+v\dr\d)_\w+_t4', 'names');
            if (~isempty(toks) && ~isempty(toks.tracRev))
                tracRev = toks.tracRev;
            else
                tracRev = this.frontOfFileprefix(comm.product_{1}.fileprefix);
            end
            t4 = sprintf('%s_to_%s_t4', tracRev, ip.Results.reference);
            this.buildVisitor_.t4_mul(tracerToCommonT4, commonToCrossT4, t4);
        end
        function fqfn = dropSumt(this, fqfn)
            
            if (iscell(fqfn))
                fqfn = cellfun(@(x) this.dropSumt(x), fqfn, 'UniformOutput', false);
                return
            end
            
            [p,f,x] = myfileparts(fqfn);            
            idx = regexp(f, '_sumt');
            if (~isempty(idx) && all(idx > 1))
                f = f(1:idx(1)-1);
            end
            fqfn = fullfile(p, [f x]);
        end
        function c    = extractCharFromNestedCells(this, c)
            %% EXTRACTCHARFROMNESTEDCELLS
            %  @param c is a cell or any valid argument for char().
            %  @return c is char.
            %  @throws exceptions of char.
            
            if (isempty(c))
                c = '';
                return
            end
            if (iscell(c))
                % recursion
                c = this.extractCharFromNestedCells(c{1});
                return
            end

            % basecase
            c = char(c);
        end
        function fp   = fileprefixStandardized(this, fp)
            toks = regexp(fp, sprintf('^(?<tracRev>\\w+v\\dr\\d)_op_\\w+_on_op_%s\\w+$', this.referenceTracer), 'names');
            if (isempty(toks))
                toks = regexp(fp, sprintf('^(?<tracRev>\\w+v\\dr\\d)_\\w*%s\\w*$', this.referenceTracer), 'names');
                assert(~isempty(toks), ...
                    'mlraichle:emptyRegexpTokens', 'SubjectImages.saveStandardized');
            end
            fp = sprintf('%s_op_%s', toks.tracRev, this.referenceTracer);
        end 
        function fp   = fileprefixSumtStandardized(this, fp)
            toks = regexp(fp, sprintf('^(?<tracRev>\\w+v\\dr\\d)_op_\\w+_on_op_%s\\w+_sumt$', this.referenceTracer), 'names');
            if (isempty(toks))
                toks = regexp(fp, sprintf('^(?<tracRev>\\w+v\\dr\\d)_\\w*%s\\w*_sumt$', this.referenceTracer), 'names');
                assert(~isempty(toks), ...
                    'mlraichle:emptyRegexpTokens', 'SubjectImages.saveSumtStandardized');
            end
            fp = sprintf('%s_sumt_op_%s', toks.tracRev, this.referenceTracer);
        end  
        function front = frontOfFileprefix(this, fps, varargin) 
            %  @param fps is cell (recursive) or char (base-case).
            %  @param optional avgt is boolean.
            
            ip = inputParser;
            addOptional(ip, 'avgt', false, @islogical);
            parse(ip, varargin{:});
            
            fps = mybasename(fps);
            if (iscell(fps))
                front = cellfun(@(x) this.frontOfFileprefix(x, varargin{:}), fps, 'UniformOutput', false);
                return
            end
            
            assert(ischar(fps));
            loc = regexp(fps, '_op_\w+');
            if (isempty(loc))
                front = fps;
                return
            end
            if (~ip.Results.avgt)
                front = fps(1:loc-1);
                return
            end
            if (~strcmp(fps(loc-7:loc-2), '_sumtr'))
                front = sprintf('%s_sumt', fps(1:loc-1));
            end
        end
        function front = frontOfFileprefixR1(this, fps, varargin)
            front = this.ensureLastRnumber( ...
                this.frontOfFileprefix(fps, varargin{:}), 1);
        end
        function this = productAverage(this)
            %  @param this.product_ is 1xN cell, N >= 1.
            %  @return this.product_ is 1x1 cell.
            
            avgf = this.product_{1}.fourdfp;
            for p = 2:length(this.product_)
                nextf = this.product_{p}.fourdfp;
                avgf.img = avgf.img + nextf.img;
            end
            avgf.img = avgf.img / length(this.product_);
            avgf.fileprefix = [this.scrubSNumber(avgf.fileprefix) '_avg'];
            this.product_ = {mlfourd.ImagingContext(avgf)};
            this.save;
        end     
        function ems  = reconstructErrMat(this, varargin)
            %% RECONSTRUCTERRMAT estimates t4_resolve discrepencies from t4 files associated with a tracer.
            %  Use cases include:  FDG_V1-AC/E1/fdgv1e1r2
            %  @param named vReference is determined by mlraichle.StudyCensus and is numeric.
            %  @param implicit this.sessionData.
            %  @return ems as a containers.Map of error matrices which have numeric values.            
            %  TODO:  replace hard-coded image-names with generalized references.
            
            ip = inputParser;
            addParameter(ip, 'vReference', 1, @isnumeric);
            parse(ip, varargin{:});
            v = ip.Results.vReference;
            
            import mlfourdfp.*;
            ems  = containers.Map;
            sd   = this.sessionData;
            pwd0 = pushd(sd.vallLocation);

            [~,ems('fho')] = T4ResolveError.errorMat( ...
                'sessionData', sd, ...
                'theImages', { sprintf('fdgv1r1_sumtr1_op_fdgv1r1_avgr1') ...
                               sprintf( 'hov1r1_sumtr1_op_hov1r1_avgr1') ...
                               sprintf( 'oov1r1_sumtr1_op_oov1r1_avgr1') }); 
            [~,ems('fc')] = T4ResolveError.errorMat( ...
                'sessionData', sd, ...
                'theImages', { sprintf('fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1') ...
                               sprintf('ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1') }); 
            ems('fhoc') = this.reshapeEM4(ems('fho'), ems('fc'));
            
            tracers = {'FDG' 'HO' 'OO' 'OC'};
            for it = 1:length(tracers)
                sd.tracer = tracers{it};
                [~,ems(sprintf('%sall', lower(sd.tracer)))] = T4ResolveError.errorMat( ...
                    'sessionData', sd, ...
                    'theImages', this.sourceImages(sd.tracer, true));
            end

            popd(pwd0);
        end      
        function [sessd,acopy] = refreshTracerResolvedFinal(this, sessd, sessdRef, varargin)
            %  @param sessionData.
            %  @param sessionData of reference.
            %  @param optional avgt is boolean.
            %  @return sessionData has refreshed supEpoch, checked against the filesystem.
            %  @return acopy created at this.frontOfFileprefixR1(sessd.tracerResolvedFinal('typ','fp')).
            
            ip = inputParser;
            addOptional(ip, 'avgt', false, @islogical);
            parse(ip, varargin{:});
            if (~ip.Results.avgt)
                meth = 'tracerResolvedFinal';
            else
                meth = 'tracerResolvedFinalAvgt';
                mlfourdfp.T4ResolveBuilder.ensureSumtSaved(sessd.(meth));
            end
            
            [sessd,sessdRef] = this.ensureRefreshedTracerResolvedFinal(sessd, sessdRef, meth); 
            ensuredir(sessdRef.vallLocation);
            pwd0 = pushd(sessdRef.vallLocation);
            acopy = this.frontOfFileprefixR1(sessd.(meth)('typ','fqfp'), ip.Results.avgt);
            if (~lexist_4dfp(acopy))
                this.buildVisitor_.copy_4dfp(sessd.(meth)('typ','fqfp'), acopy);
            end
            popd(pwd0);
            
            acopy = fullfile(sessdRef.vallLocation, acopy);
        end
        function [t4form,this] = reshapeT4s(this, t4R)
            %% RESHAPET4S should be placed inline with constructTracerRevisionToReferenceT4
            %  @param this.t4s_{1} is cell containing t4s:  comm_src -> comm_dest
            %  @param t4R is char, cell.
            %  @return t4form has form of this.t4s:  comm_src -> cross_dest.  
            %  this.t4s{r}{p} or t4R may be the identity.
            
            t4R = this.extractCharFromNestedCells(t4R);
            r = 1;
            bident = basename(this.buildVisitor_.transverse_t4);
            for p = 1:length(this.t4s_{r})
                % this.t4s_{r} =>
                % 'fdgv2r1_sumtr1_to_op_fdgv2r1_t4'
                % 'fdgv3r1_sumtr1_to_op_fdgv2r1_t4'
                % 'fdgv1r1_sumtr1_to_op_fdgv2r1_t4'       
                % t4R => fdgv2r1_sumtr1_op_fdgv2r1_avgr1_to_op_fdgv2r1_t4
                
                % working KLUDGE:
                if (~strcmp(basename(this.t4s_{r}{p}), bident))
                    this.t4s_{r}{p} = t4R;
                    continue
                end                
                if (~strcmp(basename(t4R), bident))
                    continue 
                end
                this.t4s_{r}{p} = this.buildVisitor_.transverse_t4; % this.buildVisitor_.t4_mul(this.t4s_{r}{p}, t4R);  
            end
            t4form = this.t4s_;
            % t4form{1}' =>
            % 'fdgv2r1_sumtr1_op_fdgv2r1_avgr1_to_op_fdgv2r1_t4'
            % 'fdgv2r1_sumtr1_op_fdgv2r1_avgr1_to_op_fdgv2r1_t4'
            % 'fdgv2r1_sumtr1_op_fdgv2r1_avgr1_to_op_fdgv2r1_t4'    
            
        end  
        function this = resolve(this, imgsSumt, varargin)
            %  @param imgsSumt = cell(Nvisits, Nscans) of char fqfp.
            %  @return this.cRB_ := compositeT4ResolveBuilder.resolved.
            %  @return this.t4s_ := compositeT4ResolveBuilder.t4s.  See also
            %  mlfourdfp.AbstractT4ResolveBuilder.cacheT4s.
            %  @return this.product := compositeT4ResolveBuilder.product.
            %  @return this.areAligned := true.
            
            ip = inputParser;
            addRequired( ip, 'imgsSumt', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.reference.vnumber), @ischar);
            addParameter(ip, 'compAlignMethod', 'align_commonModal7', @ischar);
            parse(ip, imgsSumt, varargin{:});
            
            assert(iscell(imgsSumt));
            if (isa(imgsSumt{1}, 'mlfourd.ImagingContext'))
                imgsSumt = cellfun(@(x) x.fqfileprefix, imgsSumt, 'UniformOutput', false);
            end
            pwd0 = pushd(fileparts(imgsSumt{1}));
            this.sessionData_.compAlignMethod = ip.Results.compAlignMethod;
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData',   this.sessionData_, ...
                'theImages',     imgsSumt, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag',    ip.Results.resolveTag, ...
                'NRevisions',    ip.Results.NRevisions, ...
                'logPath', ensuredir(fullfile(this.sessionData_.vallLocation, 'Log', '')));
            cRB.neverMarkFinished = this.DISABLE_FINISHFILE;
            cRB.ignoreFinishMark  = this.DISABLE_FINISHFILE;
            this.cRB_ = cRB.resolve; 
            this.t4s_ = this.cRB_.t4s;
            this.product_ = this.cRB_.product;
            this.areAligned_ = true;
            this.save;
            this.saveThis('resolve_this');
            popd(pwd0);
        end
        function this = resolveVM(this, imgsSumt, varargin)
            %  @param imgsSumt = cell(Nvisits, Nscans) of char fqfp.
            %  @return this.cRB_ := compositeT4ResolveBuilder.resolved.
            %  @return this.t4s_ := compositeT4ResolveBuilder.t4s.  See also
            %  mlfourdfp.AbstractT4ResolveBuilder.cacheT4s.
            %  @return this.product := compositeT4ResolveBuilder.product.
            %  @return this.areAligned := true.
            
            ip = inputParser;
            addRequired( ip, 'imgsSumt', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.vnumber), @ischar);
            addParameter(ip, 'compAlignMethod', 'align_crossModal', @ischar);
            parse(ip, imgsSumt, varargin{:});
            
            assert(iscell(imgsSumt));
            pwd0 = pushd(fileparts(imgsSumt{1}));
            this.sessionData_.compAlignMethod = ip.Results.compAlignMethod;
            vmRB = mlfourdfp.VariableMaskT4ResolveBuilder( ...
                'sessionData',   this.sessionData_, ...
                'theImages',     imgsSumt, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag',    ip.Results.resolveTag, ...
                'NRevisions',    ip.Results.NRevisions, ...
                'logPath', ensuredir(fullfile(this.sessionData_.vallLocation, 'Log', '')));
            vmRB.neverMarkFinished = this.DISABLE_FINISHFILE;
            vmRB.ignoreFinishMark  = this.DISABLE_FINISHFILE;
            this.cRB_ = vmRB.resolve; 
            this.t4s_ = this.cRB_.t4s;
            this.product_ = this.cRB_.product;
            this.areAligned_ = true;
            this.saveThis('resolveVM_this');
            popd(pwd0);            
        end
        function        save(this)
            for p = 1:length(this.product)
                pp = this.product{p};
                pp.filesuffix = '.4dfp.hdr';
                pp.save;
            end
        end
        function        saveStandardized(this)
            for p = 1:length(this.product)
                pp = this.product{p};
                pp.fileprefix = this.fileprefixStandardized(pp.fileprefix);
                pp.filesuffix = '.4dfp.hdr';
                pp.save;
                this.lnsLegacies(pp.fileprefix);
            end     
        end 
        function        saveSumtStandardized(this)
            for p = 1:length(this.product)
                pp = this.product{p};
                nn = pp.numericalNiftid;
                nn = nn.timeSummed;
                nn.fileprefix = this.fileprefixSumtStandardized(nn.fileprefix);
                nn.filesuffix = '.4dfp.hdr';
                nn.save;                
                this.lnsLegacies(nn.fileprefix);
            end          
        end
        function fn   = saveThis(this, varargin) 
            ip = inputParser;
            addOptional(ip, 'client', '', @ischar);
            parse(ip, varargin{:});
            fn = sprintf('mlraichle_SubjectImages_%s_this.mat', ip.Results.client);
            save(fn, 'this')
        end
        function ts   = selectT4s(this, varargin)
            %  @param this.rnumber == 1 even if this.NRevisions > 1.
            %  @param named sourceTracer specifies a key for lstrfind on the source term of 
            %  this.buildVisitor_.parseFilenanmeT4(this.t4s).
            %  @param named destTracer specifies a key for the dest term, respectively.
            %  @return subset of this.t4s containing matching keys.  For no matches, return {}, never {{}}.  
            
            ip = inputParser;
            addParameter(ip, 'sourceTracer', '', @ischar);
            addParameter(ip, 'destTracer',   '', @ischar);
            parse(ip, varargin{:});
            srcTr  = lower(ip.Results.sourceTracer);
            destTr = lower(ip.Results.destTracer);
            
            % trivial case
            if (isempty(srcTr) && isempty(destTr))
                ts = {};
                return
            end   
            
            ts = cell(1,this.compositeRB.NRevisions);
            r = 1;
            ts{r} = {};
            for it = 1:length(this.t4s{r})
                [s,d] = this.buildVisitor_.parseFilenameT4(this.t4s{r}{it});
                if (lstrfind(s, srcTr) || lstrfind(d, destTr))
                    ts{r} = [ts{r} this.t4s{r}{it}];
                end
            end            
            % simplify ts = {{}} to be isomorphic to trival case
            if (1 == length(ts) && isempty(ts{1}))
                ts = {};
            end
        end
        function imgs = sourceImages(this, tracer, varargin)
            %  @param tracer is char.
            %  @param optional avgt is boolean.
            %  @return imgs = cell(1, N(available images)) of char in location acopy from this.refreshTracerResolvedFinal.
            
            ip = inputParser;
            addOptional(ip, 'avgt', false, @islogical);
            parse(ip, varargin{:});
            
            sessd = this.sessionData_;
            sessd.tracer = upper(tracer);  
            sessd.rnumber = this.rnumberOfSource_;
            
            found    = strfind(this.census_.t4ResolvedCompleteWithAC, this.tracerAbbrev(tracer)); % cell \otimes double
            anyfound = cell2mat(cellfun(@(x) ~isempty(x), found, 'UniformOutput', false));            
            sid      = this.census_.subjectID(anyfound);
            v        = this.census_.v_(anyfound);
            imgs     = {};
            k        = 1;
            for i = 1:length(found)
                for j = 1:length(found{i})
                    try
                        sessd.sessionFolder = sid{i};
                        sessd.vnumber = v(i);
                        if (strcmpi(tracer, 'FDG'))
                            sessd.snumber = 1;
                        else
                            sessd.snumber = ...
                                str2double(this.census_.t4ResolvedCompleteWithAC{i}(found{i}(j)+1));
                        end
                        [sessd,acopy] = this.refreshTracerResolvedFinal(sessd, sessd.reference, ip.Results.avgt);
                        imgs{k} = acopy; %#ok<AGROW>
                        k = k + 1;
                    catch ME
                        dispexcept(ME, 'mlraichle:RuntimError', ...
                            'SubjectImages.sourceImages erred while updating internal sessionData');
                    end
                end
            end
        end
        function this = sqrt(this)
            for p = 1:length(this.product)                
                this.product_{p} = mlfourd.ImagingContext( ...
                    this.buildVisitor_.sqrt_4dfp(this.product{p}.fqfileprefix));
            end
        end
        function this = t4imgc(this, varargin)
            %% T4IMGC:  c denotes "cell"
            %  @param required t4s is char or cell.
            %  @param required sources is cell.
            %  @param named ref is char or ImagingContext.
            %  @return this.product is cell of ImagingContext.
            
            ip = inputParser;
            addRequired(ip, 't4s', @(x) ischar(x) || iscell(x));
            addRequired(ip, 'sources', @iscell);
            addParameter(ip, 'ref', varargin{2}{1}, @(x) ischar(x) || isa(x, 'mlfourd.ImagingContext'));
            parse(ip, varargin{:});
            ts = ip.Results.t4s;
            if (ischar(ip.Results.t4s))
                ts = {repmat({ts}, size(ip.Results.sources))}; % t4{1}{} := 'source_to_dest_t4'
            end
            ref = ip.Results.ref;
            if (isa(ref, 'mlfourd.ImagingContext'))
                ref = ref.fqfileprefix;
            end
            
            this.product_ = cell(size(ts{1}));
            r = 1;
            for i = 1:length(this.product_)
                fqfn = [this.buildVisitor_.t4img_4dfp( ...
                        ts{r}{i}, ip.Results.sources{i}.fqfileprefix, ...
                        'options', ['-O' ref]) '.4dfp.hdr'];
                this.product_{i} = mlfourd.ImagingContext(fqfn);
                this.product_{i}.fourdfp;
                this.product_{i}.numericalNiftid;
            end
        end
        function this = t4imgDynamicImages(this, varargin)
            %% T4IMGDYNAMICIMAGES applies accumulated this.t4s_, typically obtained from time-sums,
            %  to dynamic sources of the time-sums specified by parameter tracer.  
            %  @param optional tracer has default := this.referenceTracer.
            %  @param {this.cRB_ this.t4s_} := align* method.  NRevision >= 1 is managed by this.cRB_. 
            %  @return this.product_ := {dynamic sources for tracer} will have a messy, but unambiguous, name.
            
            ip = inputParser;
            addOptional(ip, 'tracer', this.referenceTracer, @ischar);
            parse(ip, varargin{:});
            assert(this.areAligned);  
            assert(~isempty(this.cRB_)); 
            assert(~isempty(this.t4s_)); 
            % this.cRB_.theImages' =>
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv2r1_sumt'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv3r1_sumt'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv1r1_sumt'
            % this.t4s_{1}' =>
            % 'fdgv2r1_sumtr1_to_op_fdgv2r1_t4'
            % 'fdgv3r1_sumtr1_to_op_fdgv2r1_t4'
            % 'fdgv1r1_sumtr1_to_op_fdgv2r1_t4'
            
            imgs = this.sourceImages(ip.Results.tracer, false); 
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv2r1'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv3r1'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv1r1' 
            
            this.product_ = cell(size(imgs));
            if (length(imgs) < 2)
                this.product_{1} = mlfourd.ImagingContext([imgs{1} '.4dfp.hdr']);
                this.product_{1}.fourdfp;
                % this.product_{i}.fileprefix => ho1v1r1_op_hov1r1
                
                toks = regexp(this.t4s_{1}{1}, '\w+_to(?<opTag>_op_[a-zA-Z0-9]+)_t4$', 'names');
                fp = this.product_{1}.fileprefix;
                if (strcmp(mybasename(this.t4s_{1}{1}), 'T_t4') || isempty(toks))
                    fp1 = sprintf('%s_op_%s', fp, this.scrubSNumber(fp));
                    this.product_{1}.fileprefix = fp1;
                    this.buildVisitor_.copyfilef_4dfp(fp, fp1);
                    return
                end
                fp1 = [fp toks.opTag];
                this.product_{1}.fileprefix = fp1;
                this.buildVisitor_.copyfilef_4dfp(fp, fp1);
                return
            end
            for i = 1:length(imgs)
                this.cRB_ = this.cRB_.t4img_4dfp( ...
                    this.t4s_{1}{i}, ...
                    this.frontOfFileprefixR1(imgs{i}), ...
                    'ref', this.frontOfFileprefixR1(imgs{1})); % 'out', [this.frontOfFileprefixR1(imgs{i}) '_op_' lower(ip.Results.tracer)], ...
                % this.t4s_{1}' =>                
                % 'fdgv2r1_sumtr1_to_op_fdgv2r1_t4'
                % 'fdgv3r1_sumtr1_to_op_fdgv2r1_t4'
                % 'fdgv1r1_sumtr1_to_op_fdgv2r1_t4'
                % this.frontOfFileprefixR1(imgs{1})) => fdgv2r1
                
                % fprintf('%sr0_to_%s_t4\n',  this.frontOfFileprefix(imgs{i}, true), this.cRB_.resolveTag) =>
                % fdgv2r1r0_to_op_fdgv2r1_t4
                this.product_{i} = this.cRB_.product;
                % cellfun(@(x) x.fqfilename, this.product_, 'UniformOutput', false)' =>
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv2r1_op_fdgv2r1.4dfp.hdr'
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv3r1_op_fdgv2r1.4dfp.hdr'
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv1r1_op_fdgv2r1.4dfp.hdr'
                % cellfun(@(x) x.fqfilename, this.product_, 'UniformOutput', false)' =>
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/fdgv2r1_sumtr1_op_fdgv2r1_avgr1_op_fdgv2r1.4dfp.hdr'
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/hov2r1_sumtr1_op_hov2r1_avgr1_op_fdgv2r1.4dfp.hdr'
                % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY37/Vall/oov2r1_sumtr1_op_oov2r1_avgr1_op_fdgv2r1.4dfp.hdr'
            end        
        end 
        function        teardownIntermediates(this)
            %deleteExisting('*_op_*_on_op_fdg*.4dfp.*');
            deleteExisting('*_b75.4dfp*');
            deleteExisting('*_mskt.4dfp*');
        end
        function view(this)
            mlfourdfp.Viewer.view(this.product);
        end
		  
 		function this = SubjectImages(varargin)
 			%% SUBJECTIMAGES
 			%  @param sessionData identifies the subject and provides utility methods.
            %  @param census is an mlpipeline.IStudyCensus.
            %  @param referenceTracer is 'fdg', 'ho', 'oo' or 'oc'.

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'census', [], @(x) isa(x, 'mlpipeline.IStudyCensus'));
            addParameter(ip, 'referenceTracer', 'fdg', @ischar);
            addParameter(ip, 'rnumberOfSource', 2, @isnumeric);
            parse(ip, varargin{:});

            this.sessionData_ = ip.Results.sessionData;
            this.sessionData_.attenuationCorrected = true;
            this.rnumberOfSource_ = ip.Results.rnumberOfSource;
            this.census_ = ip.Results.census.censusSubtable;
            this.referenceTracer_ = ip.Results.referenceTracer;
            this.buildVisitor_ = mlfourdfp.FourdfpVisitor;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        areAligned_ = false;
        buildVisitor_
        census_
        cRB_ % CompositeT4ResolveBuilder
        product_
        referenceTracer_
        rnumberOfSource_
        sessionData_
        t4s_
    end
    
    methods (Access = private)
        function fn   = ensureFourdfpIfh(~, fn)
            if (~lstrfind(fn, '.4dfp.hdr'))
                fn = [myfileprefix(fn) '.4dfp.hdr'];
            end
        end
        function fqfp = ensureLastRnumber(this, fqfp, r)
            %% ENSURELASTRNUMBER
            %  @param fqfp
            %  @param r integer
            %  @return             ${fqfp}r${r}                     if not fqfp has r[0-9]
            %  @return ${fqfp_upto_r[0-9]}r${r}${fqfp_after_r[0-9]} if fqfp has r[0-9]
            
            assert(isnumeric(r));
            
            if (iscell(fqfp))
                for f = 1:length(fqfp)
                    fqfp{f} = this.ensureLastRnumber(fqfp{f}, r);
                end
                return
            end
            
            startIdx = regexp(fqfp, 'r\d');
            if (~isempty(startIdx))
                fqfp(startIdx(end)+1) = num2str(r);
                return
            end
            fqfp = sprintf('%sr%i', fqfp, r);
        end
        function [sessd,sessdRef] = ensureRefreshedTracerResolvedFinal(~, sessd, sessdRef, meth)
            while (~lexist(sessd.(meth)) && sessd.supEpoch > 0)
                sessd.supEpoch    = sessd.supEpoch - 1;
                sessdRef.supEpoch = sessdRef.supEpoch - 1;
            end
            if (sessd.supEpoch == 0)
                error( ...
                    'mlraichle:invalidParamValue', ...
                    'SubjectImages.refreshTracerResolvedFinal.sessd.supEpoch->%i', sessd.supEpoch);
            end
            if (~lexist(sessd.(meth)('typ','fqfn')))
                error( ...
                    'mlraichle:missingPrerequisiteFile', ...
                    'SubjectImages.refreshTracerResolvedFinal.sessd.tracerResolvedFinal->%i', ...
                    sessd.(meth));                
            end  
        end
        function fps  = ics2fqfps(~, ics)
            fps = cellfun(@(x) x.fqfileprefix, ics, 'UniformOutput', false);
        end
        function        lns_4dfp(~, src, dest)
            exts = {'.4dfp.ifh' '.4dfp.hdr' '.4dfp.img' '.4dfp.img.rec'};
            for e = 1:length(exts)
                mlbash(sprintf('ln -s %s%s %s%s', src, exts{e}, dest, exts{e}));
            end
        end
        function        lnsLegacies(this, fp)
            this.lns_4dfp(fp, strrep(fp, '_op_', '_on_'));
        end
        function em   = reshapeEM4(~, em_fho, em_fc)
            em = nan(4,4);
            em(1:3,1:3) = em_fho;
            em(1,4)     = em_fc(1,2);
            em(4,1)     = em_fc(2,1);
        end
        function s    = scrubSNumber(~, s)
            tracers = {'oc' 'oo' 'ho'};
            for t = 1:length(tracers)
                pos = regexp(s, [tracers{t} '\d']);
                for p = 1:length(pos)
                    s = [s(pos:pos+1) s(pos+3:end)];
                end
            end
        end 
        function ab   = tracerAbbrev(~, tr)
            switch (upper(tr))
                case {'OC' 'CO'}
                    ab = 'c';
                case 'OO'
                    ab = 'o';
                case 'HO'
                    ab = 'h';
                case 'FDG'
                    ab = 'f';
                otherwise
                    error('mlraichle:unsupportedSwitchCase', 'SubjectImages.traerAbbrev.tr->%s', tr);
            end
        end
    end
    
    %% HIDDEN

    methods (Static, Hidden)
        function this = prepare_test_t4mulR(this, prod, t4s)
            this.product_ = prod;
            this.t4s_ = t4s;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

