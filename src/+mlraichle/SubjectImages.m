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
            imgs = reshape(this.sourceImages(tracer), 1, []);
            this.sessionData_.tracer = upper(tracer);
            
            cwd_ = pushd(fileparts(imgs{1}));
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', mybasename(imgs), ...
                'maskForImages', 'Msktgen', ...
                'resolveTag', sprintf('op_%sv1r1', lower(tracer)), ...
                'NRevisions', 1);
            cRB_.neverTouchFinishfile = true;
            cRB_.ignoreFinishfile = true;
            cRB_ = cRB_.resolve;
            this.product_ = cRB_.product;
            popd(cwd_);
        end
        function this = alignCrossModalToReference(this, tracer)
        end
        function e = alignmentError(this, tracer)
            %  @return err of 2-way alignment with this.alignmentReference.
        end
        function sessd = refreshTracerResolvedFinalSumt(this, sessd, sessdRef)
            while (~lexist(sessd.tracerResolvedFinalSumt) && sessd.supEpoch > 0)
                sessd.supEpoch    = sessd.supEpoch - 1;
                sessdRef.supEpoch = sessdRef.supEpoch - 1;
            end
            if (sessd.supEpoch == 0)
                error( ...
                    'mlraichle:invalidParamValue', ...
                    'SubjectImages.refreshTracerResolvedFinalSumt.sessd.supEpoch->%i', sessd.supEpoch);
            end
            if ( lexist(sessd.tracerResolvedFinalSumt('typ','fqfn')) && ...
                ~lexist(sessdRef.tracerResolvedFinalSumt('typ','fqfn')))                
                this.buildVisitor_.copyfilef_4dfp( ...
                    sessd.tracerResolvedFinalSumt('typ','fqfp'), ...
                    sessdRef.tracerResolvedFinalSumt('typ','fqfp'));
                return
            end
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
                        imgs{i,j} = sessd.tracerResolvedFinalSumt('typ','fqfp');
                    catch ME
                        dispexcept(ME);
                    end
                end
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

