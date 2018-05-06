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
        
        %%
        
        function this = alignCommonModal(this, tracer)
            %  @param tracer, ctor.census & ctor.sessionData select images.
            %  @return resolved in this.product.
            
            imgs = reshape(this.sourceImages(tracer), 1, []);
            this.sessionData_.tracer = upper(tracer);
            this.referenceTracer_ = lower(tracer);
            this = this.resolve(imgs);
        end
        function [this,opT1001] = alignCrossModal(this)
            theHo  = this.alignCommonModal('HO');
            theHo  = theHo.productAverage;         
            theOo  = this.alignCommonModal('OO');
            theOo  = theOo.productAverage;          
            theOc  = this.alignCommonModal('OC');            
            theOc  = theOc.productAverage;
            this   = this.alignCommonModal('FDG');
            this   = this.productAverage;
            theFdg = this;
            
            imgs = {theFdg.product.fqfileprefix ...
                    theHo.product.fqfileprefix ...
                    theOo.product.fqfileprefix ...
                    theOc.product.fqfileprefix};
            this = this.resolve(imgs, 'NRevisions', 2);
           
            opT1001 = theFdg.alignOpT1001;
        end
        function this = alignOpT1001(this)
            %  @param this.product.
            %  @return resolved to T1001 in this.product.
            
            assert(lexist_4dfp('T1001'));
            imgs = {'T1001' this.product.fqfileprefix};
            this = this.resolve(imgs);
        end
        function front = frontOfFileprefix(this, fps)
            fps = mybasename(fps);
            if (iscell(fps))
                front = cellfun(@(x) this.frontOfFileprefix(x), fps, 'UniformOutput', false);
                return
            end
            assert(ischar(fps));
            loc = regexp(fps, '_op_\w+');
            front = fps(1:loc-1);
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
        function sessd = refreshTracerResolvedFinalSumt(this, sessd, sessdRef)
            %  @param sessionData.
            %  @param sessionData of reference.
            %  @return sessionData has refreshed supEpoch.
            %  @return sym-link created at (sessdRef.vallLocation, sessd.tracerResolvedFinalSumt('typ','fp')).
            
            while (~lexist(sessd.tracerResolvedFinalSumt) && sessd.supEpoch > 0)
                sessd.supEpoch    = sessd.supEpoch - 1;
                sessdRef.supEpoch = sessdRef.supEpoch - 1;
            end
            if (sessd.supEpoch == 0)
                error( ...
                    'mlraichle:invalidParamValue', ...
                    'SubjectImages.refreshTracerResolvedFinalSumt.sessd.supEpoch->%i', sessd.supEpoch);
            end
            if (~lexist(sessd.tracerResolvedFinalSumt('typ','fqfn')))
                error( ...
                    'mlraichle:missingPrerequisiteFile', ...
                    'SubjectImages.refreshTracerResolvedFinalSumt.sessd.tracerResolvedFinalSumt->%i', ...
                    sessd.tracerResolvedFinalSumt);                
            end   
            ensuredir(sessdRef.vallLocation);
            cwd = pushd(sessdRef.vallLocation);
            this.buildVisitor_.lns_4dfp(sessd.tracerResolvedFinalSumt('typ','fqfp'));
            popd(cwd);
        end
        function this = resolve(this, imgs, varargin)
            %  @param imgs = cell(Nvisits, Nscans) of char fqfp.
            
            ip = inputParser;
            addRequired( ip, 'imgs', @iscell);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            addParameter(ip, 'maskForImages', 'Msktgen');
            addParameter(ip, 'resolveTag', ...
                sprintf('op_%sv%ir1', lower(this.referenceTracer), this.sessionData_.vnumber), @ischar);
            parse(ip, imgs, varargin{:});
            
            assert(iscell(imgs));
            cwd = pushd(fileparts(imgs{1}));
            cellfun(@(x) this.buildVisitor_.copy_4dfp(x, this.frontOfFileprefix(x)), ...
                mybasename(imgs), ...
                'UniformOutput', false);
            imgs = this.frontOfFileprefix(imgs);
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', imgs, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag', ip.Results.resolveTag, ...
                'NRevisions', ip.Results.NRevisions);
            cRB.neverTouchFinishfile = true;
            cRB.ignoreFinishfile = true;
            this.cRB_ = cRB.resolve;
            this.product_ = this.cRB_.product;
            popd(cwd);
            
            this.areAligned_ = true;
        end
        function imgs = sourceImages(this, tracer)
            %  @return imgs = cell(Nvisits, Nscans) of char fqfp.
            
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
                        sessd = this.refreshTracerResolvedFinalSumt(sessd, sessdRef);
                        imgs{i,j} = fullfile(sessdRef.vallLocation, ...
                            sessd.tracerResolvedFinalSumt('typ','fp')); % sym-link
                    catch ME
                        dispexcept(ME);
                    end
                end
            end
        end
        function this = t4img_4dfp(this, varargin)
            
            in_ = this.sessionData_.tracerResolvedFinal('typ','fqfp');
            out_ = this.sessionData_.tracerResolvedSubj('typ','fqfp');
            
            ip = inputParser;
            addOptional(ip, 'in', in_, @ischar);
            addOptional(ip, 'out', out_, @ischar);
            parse(ip, varargin{:});
            
            %this.cRB_.t4img_4dfp();
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
            addParameter(ip, 'referenceTracer', varargin{2}.tracer, @ischar);
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
    end
    
    methods (Access = private)
        function stbl = censusSubtable(this, census)
            assert(isa(census, 'mlpipeline.IStudyCensus'));
            ctbl = census.censusTable;
            ctbl = ctbl(1 == ctbl.ready, :);
            stbl = ctbl(strcmpi(ctbl.subjectID, this.sessionData_.sessionFolder), :);
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

