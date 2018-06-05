classdef HerscovitchContext < mlraichle.SessionData
	%% HERSCOVITCHCONTEXT  

	%  $Revision$
 	%  was created 02-Jun-2018 20:35:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent) 	
        INV_EFF_MMR
        INV_EFF_TWILITE
        o2Content
        vnumberRef
 	end

	methods 
        
        %% GET
		  
        function g = get.INV_EFF_MMR(~)
            g = 1.1551 * 1.5;
        end
        function g = get.INV_EFF_TWILITE(this)
            if (this.sessionDate < datetime(2017,4,1,'TimeZone', 'America/Chicago'))
                g = 409; % [invEffTwilite] = (Bq s)/(mL counts); 
                         % estimated using TwiliteBuilder.counts2specificActivity;
                         % pre-3/2016:  mean := 409, covar := 0.0336;
                         % post-3/2016: mean := 216, covar := 0.0862.
            else
                g = 216; % [invEffMMR] = 1.
            end
        end
        function g = get.o2Content(~)
            g = 18.55; % mean := 18.55, std := 1.57, N := 38
        end
        function g = get.vnumberRef(this)
            g = this.vnumberRef_;
        end
        
        %%
        
        function obj  = T1001OpFdg(this)
            obj = mlfourd.ImagingContext( ...
                fullfile(this.vallLocation, ...
                         sprintf('T1001r1_op_fdgv%ir1.4dfp.ifh', this.vnumberRef)));
        end
        function obj  = MaskBrainOpFdg(this)
            obj = mlfourd.ImagingContext( ...
                fullfile(this.vallLocation, ...
                         sprintf('aparcAseg_op_fdgv%ir1_mskb.4dfp.ifh', this.vnumberRef)));
        end
        
        function obj  = tracerResolvedFinal(this, varargin)            
            fqfn = sprintf('%s_%s%s', ...
                this.tracerRevision('typ', 'fqfp'), ...
                sprintf('op_fdgv%ir1', this.vnumberRef), ...
                this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalOnAtl(this, varargin)
            fqfn = fullfile(this.vallLocation, ...
                sprintf('%s_on_%s_%i%s', this.tracerResolvedFinal('typ', 'fp'), this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerResolvedFinal('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedSubj(this, varargin)
            obj = this.tracerResolvedFinal(varargin{:});
        end
        function obj  = tracerRevision(this, varargin)
            %  @param named rLabel is char and overrides any specifications of r-number;
            %  it may be useful for generating filenames such as '*r1r2_to_resolveTag_t4'.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'rLabel', sprintf('r%i', this.rnumber), @ischar);
            parse(ip, varargin{:});
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.vallLocation, ...
                sprintf('%s%sv%i%s%s%s', lower(ipr.tracer), schar, this.vnumber, this.epochTag, ip.Results.rLabel, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRefRevision(this, varargin)
            %  @param named rLabel is char and overrides any specifications of r-number;
            %  it may be useful for generating filenames such as '*r1r2_to_resolveTag_t4'.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'rLabel', sprintf('r%i', this.rnumber), @ischar);
            parse(ip, varargin{:});
            
            [ipr,schar] = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.vallLocation, ...
                sprintf('%s%sv%i%s%s%s', lower(ipr.tracer), schar, this.vnumberRef, this.epochTag, ip.Results.rLabel, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevisionSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerRevision('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        
        function loc  = freesurferLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.freesurfersDir, ...
                         sprintf('%s_V%i', this.sessionLocation('typ', 'folder'), this.vnumberRef)));
        end 
        function loc  = vallLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionPath, 'Vall'));
        end          
        
 		function this = HerscovitchContext(varargin)
 			%% HERSCOVITCHCONTEXT
 			%  @param .

 			this = this@mlraichle.SessionData(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addParameter(ip, 'vnumberRef', 1, @isnumeric);
            parse(ip, varargin{:});
            this.vnumberRef_ = ip.Results.vnumberRef;
            
            this.attenuationCorrected = true;
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        vnumberRef_
    end
    
    methods (Access = protected)
        function obj  = visitMapOnAtl(this, map, varargin)
            fqfn = fullfile(this.vallLocation, ...
                sprintf('%s_on_%s_%i%s', map, this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end     
        function obj  = visitMapOpFdg(this, map, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'avg', false, @islogical);
            parse(ip, varargin{:});
            
            if (ip.Results.avg)
                fqfn = fullfile(this.vallLocation, ...
                    sprintf('%sv%i_op_%s_avg%s', map, this.vnumber, this.fdgRefRevision('typ', 'fp'), this.filetypeExt));
            else
                fqfn = fullfile(this.vallLocation, ...
                    sprintf('%s%iv%i_op_%s%s', map, this.snumber, this.vnumber, this.fdgRefRevision('typ', 'fp'), this.filetypeExt));
            end
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = fdgRevision(this, varargin)
            obj = this.tracerRevision('tracer', 'FDG', varargin{:});
        end
        function obj  = fdgRefRevision(this, varargin)
            obj = this.tracerRefRevision('tracer', 'FDG', varargin{:});
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

