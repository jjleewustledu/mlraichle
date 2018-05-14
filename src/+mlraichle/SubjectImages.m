classdef SubjectImages 
	%% SUBJECTIMAGES provides detailed access to subject-specific images.

	%  $Revision$
 	%  was created 04-May-2018 12:10:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		areAligned
        compositeRB
        product
        referenceImage
        referenceTracer        
        sessionData
        t4s
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
        function g = get.referenceTracer(this)
            g = this.referenceTracer_;
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
            %  @param tracer, ctor.census & ctor.sessionData select images.
            %  @return resolved in this.product.
            
            imgsSumt = reshape(this.sourceImages(tracer, true), 1, []);
            this.sessionData_.tracer = upper(tracer);
            this.referenceTracer_ = lower(tracer);
            this = this.resolve(imgsSumt, varargin{:});
        end
        function [this,theFdg,theHo,theOo,theOc] = alignCrossModal(this)
            theHo  = this.alignCommonModal('HO');
            theHo  = theHo.productAverage;     
            theHo.saveThis('alignCrossModal_theHo');
            theHo.save;
            theOo  = this.alignCommonModal('OO');
            theOo  = theOo.productAverage;  
            theOo.saveThis('alignCrossModal_theOo');        
            theOo.save;
            theOc  = this.alignCommonModal('OC');            
            theOc  = theOc.productAverage;
            theOc.saveThis('alignCrossModal_theOc');
            theOc.save;
            theFdg = this.alignCommonModal('FDG');
            theFdg = theFdg.productAverage;
            theFdg.saveThis('alignCrossModal_theFdg');
            theFdg.save;
            this = theFdg;

            imgs = {theFdg.product{1}.fqfileprefix ...
                    theHo.product{1}.fqfileprefix ...
                    theOo.product{1}.fqfileprefix ...
                    theOc.product{1}.fqfileprefix}; % product averages
            this = this.resolveVM(imgs, 'compAlignMethod', 'align_crossModal');
            this.saveThis('alignCrossModal_this');
        end
        function varargout = alignDynamicImages(this, varargin)
            %% ALIGNDYNAMICIMAGES aligns tracer-averages to this.referenceImage.
            %  this := alignCrossModal tracer-averages
            %  varargin := tracer-average instances of SubjectImages
            
            u = 1;
            for v = 1:length(varargin)
                intermed = varargin{v}.t4mulR(this.t4s_{u}{v});
                varargout{v} = intermed.t4imgDynamicImages; %#ok<AGROW>
            end
        end
        function this = alignOpT1001(this, varargin)
            %  @param this.product.
            %  @return resolved to T1001 in this.product.
            
            assert(lexist_4dfp('T1001'));
            imgs = ['T1001' cellfun(@(x) x.fqfileprefix, this.product, 'UniformOutput', false)];
            this = this.resolve(imgs, 'NRevisions', 1);
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
        function front = frontOfFileprefix(this, fps, varargin) 
            %  @param fps is cell (recursive) or char (base-case).
            %  @param optional sumt is boolean.
            
            ip = inputParser;
            addOptional(ip, 'sumt', false, @islogical);
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
            if (~ip.Results.sumt)
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
            %  @param this.product_ is 1xN cell.
            %  @return this.product_ is 1x1 cell.
            
            avgf = this.product_{1}.fourdfp;
            for p = 2:length(this.product_)
                nextf = this.product_{p}.fourdfp;
                avgf.img = avgf.img + nextf.img;
            end
            avgf.img = avgf.img / length(this.product_);
            avgf.fileprefix = [avgf.fileprefix '_avg'];
            this.product_ = {mlfourd.ImagingContext(avgf)};
        end
        function [sessd,acopy] = refreshTracerResolvedFinal(this, sessd, sessdRef, varargin)
            %  @param sessionData.
            %  @param sessionData of reference.
            %  @param optional sumt is boolean.
            %  @return sessionData has refreshed supEpoch, checked against the filesystem.
            %  @return acopy created at this.frontOfFileprefixR1(sessd.tracerResolvedFinal('typ','fp')).
            
            ip = inputParser;
            addOptional(ip, 'sumt', false, @islogical);
            parse(ip, varargin{:});
            if (~ip.Results.sumt)
                meth = 'tracerResolvedFinal';
            else
                meth = 'tracerResolvedFinalSumt';
            end
            
            [sessd,sessdRef] = this.ensureRefreshedTracerResolvedFinal(sessd, sessdRef, meth); 
            ensuredir(sessdRef.vallLocation);
            cwd = pushd(sessdRef.vallLocation);
            acopy = this.frontOfFileprefixR1(sessd.(meth)('typ','fqfp'), ip.Results.sumt);
            if (~lexist_4dfp(acopy))
                this.buildVisitor_.copy_4dfp(sessd.(meth)('typ','fqfp'), acopy);
            end
            popd(cwd);
            
            acopy = fullfile(sessdRef.vallLocation, acopy);
        end
        function this = resolve(this, imgsSumt, varargin)
            %  @param imgsSumt = cell(Nvisits, Nscans) of char fqfp.
            %  @return this.cRB_ := compositeT4ResolveBuilder.resolved.
            %  @return this.t4s_ := compositeT4ResolveBuilder.t4s.  See also
            %  mlfourdfp.AbstractT4ResolveBuilder.catchT4s.
            %  @return this.product := compositeT4ResolveBuilder.product.
            %  @return this.areAligned := true.
            
            ip = inputParser;
            addRequired( ip, 'imgsSumt', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.vnumber), @ischar);
            addParameter(ip, 'compAlignMethod', 'align_commonModal7', @ischar);
            parse(ip, imgsSumt, varargin{:});
            
            assert(iscell(imgsSumt));
            cwd = pushd(fileparts(imgsSumt{1}));
            this.sessionData_.compAlignMethod = ip.Results.compAlignMethod;
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', imgsSumt, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag', ip.Results.resolveTag, ...
                'NRevisions', ip.Results.NRevisions, ...
                'logPath', ensuredir(fullfile(cwd, 'Log', '')));
            cRB.neverTouchFinishfile = true;
            cRB.ignoreFinishfile = true;
            this.cRB_ = cRB.resolve; 
            this.t4s_ = this.cRB_.t4s;
            this.product_ = this.cRB_.product;
            this.areAligned_ = true;
            this.saveThis('resolve_this');
            popd(cwd);            
        end
        function this = resolveVM(this, imgsSumt, varargin)
            %  @param imgsSumt = cell(Nvisits, Nscans) of char fqfp.
            %  @return this.cRB_ := compositeT4ResolveBuilder.resolved.
            %  @return this.t4s_ := compositeT4ResolveBuilder.t4s.  See also
            %  mlfourdfp.AbstractT4ResolveBuilder.catchT4s.
            %  @return this.product := compositeT4ResolveBuilder.product.
            %  @return this.areAligned := true.
            
            ip = inputParser;
            addRequired( ip, 'imgsSumt', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.vnumber), @ischar);
            addParameter(ip, 'compAlignMethod', 'align_commonModal7', @ischar);
            parse(ip, imgsSumt, varargin{:});
            
            assert(iscell(imgsSumt));
            cwd = pushd(fileparts(imgsSumt{1}));
            this.sessionData_.compAlignMethod = ip.Results.compAlignMethod;
            vmRB = mlfourdfp.VariableMaskT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', imgsSumt, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag', ip.Results.resolveTag, ...
                'NRevisions', ip.Results.NRevisions, ...
                'logPath', ensuredir(fullfile(cwd, 'Log', '')));
            vmRB.neverTouchFinishfile = true;
            vmRB.ignoreFinishfile = true;
            this.cRB_ = vmRB.resolve; 
            this.t4s_ = this.cRB_.t4s;
            this.product_ = this.cRB_.product;
            this.areAligned_ = true;
            this.saveThis('resolveVM_this');
            popd(cwd);            
        end
        function        save(this)
            for p = 1:length(this.product)
                this.product{p}.save;
            end
        end
        function fn   = saveThis(this, varargin) %#ok<INUSL>
            ip = inputParser;
            addOptional(ip, 'client', '', @ischar);
            parse(ip, varargin{:});
            fn = sprintf('mlraichle_SubjectImages_%s_this.mat', ip.Results.client);
            save(fn, 'this')
        end
        function imgs = sourceImages(this, tracer, varargin)
            %  @param tracer is char.
            %  @param optional sumt is boolean.
            %  @return imgs = cell(Nvisits, Nscans) of char in location acopy from this.refreshTracerResolvedFinal.
            
            ip = inputParser;
            addOptional(ip, 'sumt', false, @islogical);
            parse(ip, varargin{:});
            
            sessd = this.sessionData_;
            sessd.tracer = upper(tracer);  
            sessd.rnumber = this.rnumberOfSource_;
            
            found    = strfind(this.census_.t4ResolvedCompleteWithAC, this.tracerAbbrev(tracer));  
            foundmat = cell2mat(found);
            anyfound = cell2mat(cellfun(@(x) ~isempty(x), found, 'UniformOutput', false));            
            sid      = this.census_.subjectID(anyfound);
            v        = this.census_.v_(anyfound);
            imgs     = cell(size(foundmat));
            for i = 1:size(foundmat,1)
                for j = 1:size(foundmat,2)
                    try
                        sessd.sessionFolder = sid{i};
                        sessd.vnumber = v(i);
                        if (strcmpi(tracer, 'FDG'))
                            sessd.snumber = 1;
                        else
                            sessd.snumber = ...
                                str2double(this.census_.t4ResolvedCompleteWithAC{i}(foundmat(i,j)+1));
                        end
                        if (1 == i && 1 == j)
                            sessdRef = sessd;
                        end
                        [sessd,acopy] = this.refreshTracerResolvedFinal(sessd, sessdRef, ip.Results.sumt);
                        imgs{i,j} = acopy;
                    catch ME
                        dispexcept(ME);
                    end
                end
            end
        end
        function this = t4imgDynamicImages(this)
            %% T4IMGDYNAMICIMAGES applies accumulated this.t4s_, typically obtained from time-sums,
            %  to the dynamic sources of the time-sums.  
            %  @param this.cRB_ and this.t4s_ obtained from an align* method.  
            %  Any NRevision > 1 is managed by this.cRB_. 
            
            assert(this.areAligned);  
            assert(~isempty(this.cRB_)); 
            imgs     = reshape(this.sourceImages(tracer, false), 1, []); % dynamic images
            
            this.product_ = cell(size(imgs));
            for i = 1:length(imgs)
                this.cRB_ = this.cRB_.t4img_4dfp( ...
                    this.t4s_{1}{i}, ...
                    this.frontOfFileprefixR1(imgs{i}), ...
                    'ref', this.frontOfFileprefixR1(imgs{1}));
                % sprintf('%sr0_to_%s_t4',  this.frontOfFileprefix(imgsSumt{i}, true), this.cRB_.resolveTag), ...
                this.product_{i} = this.cRB_.product;
            end        
        end
        function this = t4mulR(this, t4R)
            %% T4MULR updates this.t4s_ by right-multiplication.
            %  r := 1
            %  foreach p in this.product
            %      this.t4s_{p} := this.t4s_{p} * t4R            
            
            r = 1;
            for p = 1:size(this.product)
                this.t4s_{r}{p} = this.buildVisitor_.t4_mul( ...
                    this.t4s_{r}{p}, t4R);
            end
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
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'census', [], @(x) isa(x, 'mlpipeline.IStudyCensus'));
            addParameter(ip, 'referenceTracer', 'FDG', @ischar);
            addParameter(ip, 'rnumberOfSource', 2, @isnumeric);
            parse(ip, varargin{:});

            this.sessionData_ = ip.Results.sessionData;
            this.sessionData_.attenuationCorrected = true;
            this.rnumberOfSource_ = ip.Results.rnumberOfSource;
            this.census_ = this.censusSubtable(ip.Results.census);
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
        function stbl = censusSubtable(this, census)
            assert(isa(census, 'mlpipeline.IStudyCensus'));
            ctbl = census.censusTable;
            ctbl = ctbl(1 == ctbl.ready, :);
            stbl = ctbl(strcmpi(ctbl.subjectID, this.sessionData_.sessionFolder), :);
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
        function ab = tracerAbbrev(~, tr)
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

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

