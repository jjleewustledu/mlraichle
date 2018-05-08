classdef SubjectImages 
	%% SUBJECTIMAGES provides detailed access to subject-specific images.

	%  $Revision$
 	%  was created 04-May-2018 12:10:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		areAligned
        product
        referenceImage
        referenceTracer        
 	end

	methods 
        
        %% GET, SET
        
        function g = get.areAligned(this)
            g = this.areAligned_;
        end
        function g = get.referenceImage(this)
            %  @return ImagingContext.
            
            sessd = this.sessionData_;
            sessd.tracer = upper(this.referenceTracer);
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
        
        %%
        
        function this = alignCommonModal(this, tracer)
            %  @param tracer, ctor.census & ctor.sessionData select images.
            %  @return resolved in this.product.
            
            imgsSumt = reshape(this.sourceImages(tracer, true), 1, []);
            this.sessionData_.tracer = upper(tracer);
            this.referenceTracer_ = lower(tracer);
            this = this.resolve(imgsSumt);
        end
        function [this,theFdg,theHo] = alignCrossModal(this)
            theHo  = this.alignCommonModal('HO');
            theHo  = theHo.productAverage;     
            theHo.save;
            theOo  = this.alignCommonModal('OO');
            theOo  = theOo.productAverage;          
            theOo.save;
            theOc  = this.alignCommonModal('OC');            
            theOc  = theOc.productAverage;
            theOc.save;
            this   = this.alignCommonModal('FDG');
            this   = this.productAverage;
            this.save;
            theFdg = this;
            
            imgs = {theFdg.product{1}.fqfileprefix ...
                    theHo.product{1}.fqfileprefix ...
                    theOo.product{1}.fqfileprefix ...
                    theOc.product{1}.fqfileprefix ...
                    'T1001'};
            this = this.resolve(imgs);
            theFdg = theFdg.t4mulR(this.t4s_{1}{1});
            theFdg = theFdg.t4imgDynamicImages;  
            theHo  = theHo.t4mulR(this.t4s_{1}{2});
            theHo  = theHo.t4imgDynamicImages;           
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
            avgf = this.product_{1}.fourdfp;
            for p = 2:length(this.product_)
                nextf = this.product_{p}.fourdfp;
                avgf.img = avgf.img + nextf.img;
            end
            avgf.img = avgf.img / length(this.product_);
            avgf.fileprefix = [avgf.fileprefix '_avg'];
            this.product_ = {mlfourd.ImagingContext(avgf)};
        end
        function sessd = refreshTracerResolvedFinal(this, sessd, sessdRef, varargin)
            %  @param sessionData.
            %  @param sessionData of reference.
            %  @param optional sumt is boolean.
            %  @return sessionData has refreshed supEpoch.
            %  @return sym-link created at (sessdRef.vallLocation, sessd.tracerResolvedFinal('typ','fp')).
            
            ip = inputParser;
            addOptional(ip, 'sumt', false, @islogical);
            parse(ip, varargin{:});
            if (~ip.Results.sumt)
                meth = 'tracerResolvedFinal';
            else
                meth = 'tracerResolvedFinalSumt';
            end
            
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
            ensuredir(sessdRef.vallLocation);
            cwd = pushd(sessdRef.vallLocation);
            this.buildVisitor_.lns_4dfp( ...
                sessd.(meth)('typ','fqfp'), ...
                this.frontOfFileprefixR1(sessd.(meth)('typ','fqfp'), ip.Results.sumt));
            popd(cwd);
        end
        function this = resolve(this, imgsSumt, varargin)
            %  @param imgsSumt = cell(Nvisits, Nscans) of char fqfp.
            
            ip = inputParser;
            addRequired( ip, 'imgsSumt', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.vnumber), @ischar);
            parse(ip, imgsSumt, varargin{:});
            
            assert(iscell(imgsSumt));
            cwd = pushd(fileparts(imgsSumt{1}));
            cellfun(@(x) this.buildVisitor_.copy_4dfp(x, this.frontOfFileprefixR1(x, true)), ...
                mybasename(imgsSumt), ...
                'UniformOutput', false);
            imgsSumt = this.frontOfFileprefixR1(imgsSumt, true);
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', imgsSumt, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag', ip.Results.resolveTag, ...
                'NRevisions', ip.Results.NRevisions);
            cRB.neverTouchFinishfile = true;
            cRB.ignoreFinishfile = true;
            this.cRB_ = cRB.resolve; 
            this.t4s_ = this.cRB_.t4s;
            this.product_ = this.cRB_.product;
            this.areAligned_ = true;
            popd(cwd);            
        end
        function        save(this)
            for p = 1:length(this.product)
                this.product{p}.save;
            end
        end
        function imgs = sourceImages(this, tracer, varargin)
            %  @param tracer is char.
            %  @param optional sumt is boolean.
            %  @return imgs = cell(Nvisits, Nscans) of char fqfp.
            
            ip = inputParser;
            addOptional(ip, 'sumt', false, @islogical);
            parse(ip, varargin{:});
            if (~ip.Results.sumt)
                meth = 'tracerResolvedFinal';
            else
                meth = 'tracerResolvedFinalSumt';
            end
            
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
                        sessd = this.refreshTracerResolvedFinal(sessd, sessdRef, ip.Results.sumt);
                        imgs{i,j} = fullfile(sessdRef.vallLocation, ...
                            sessd.(meth)('typ','fp')); % sym-link
                    catch ME
                        dispexcept(ME);
                    end
                end
            end
        end
        function this = t4imgDynamicImages(this)
            
            assert(this.areAligned);  
            assert(~isempty(this.cRB_));
            %imgsSumt = cellfun(@(x) x.fqfileprefix, this.product, 'UniformOutput', false);   
            imgs     = reshape(this.sourceImages(tracer), 1, []);
            
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
            for t = 1:size(this.t4s_{1})
                this.t4s_{1}{t} = this.buildVisitor_.t4_mul( ...
                    this.t4s_{1}{t}, t4R);
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
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'census', [], @(x) isa(x, 'mlpipeline.IStudyCensus'));
            addParameter(ip, 'referenceTracer', 'FDG', @ischar);
            addParameter(ip, 'rnumberOfSource', 2, @isnumeric);
            parse(ip, varargin{:});

            this.sessionData_ = ip.Results.sessionData;
            this.rnumberOfSource_ = ip.Results.rnumberOfSource;
            this.sessionData_.attenuationCorrected = true;
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

