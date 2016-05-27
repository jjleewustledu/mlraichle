classdef T4ResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 18-Apr-2016 19:22:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	
    
    properties (Dependent)
        blurArg
        gaussArg
    end
    
    methods % GET
        function g = get.blurArg(this)
            g = 5.5;
            %g = this.petBlur;
        end
        function g = get.gaussArg(this)
            g = 1.1;
            %g = this.F_HALF_x_FWHM/this.petBlur;
        end
    end
    
	properties
        atlasTag  = 'TRIO_Y_NDC'
        firstCrop = 0.5
        initialT4 = fullfile(getenv('RELEASE'), 'S_t4')        
 	end

	methods
        function this = t4ResolveSubject(this)
            this.sourceImage = this.sessionData.pet;
            this = this.t4ResolvePET;
            pet  = this.product;

            this.sourceImage = this.sessionData.mr;
            this = this.t4ResolveMR;
            mr   = this.product;            

            this.sourceImage = mlfourd.ImagingContext({pet mr});
            this = this.t4ResolveMultispectral;
        end  
        function this = t4ResolvePET3(this)

            subject = 'NP995_09';
            convdir = fullfile(getenv('PPG'), 'converted', subject, '');
            nacdir  = fullfile(convdir, '');
            workdir = fullfile(getenv('PPG'), 'jjlee', subject, 'V1', '');
            mpr     = [subject '_mpr'];

            mprImg = [mpr '.4dfp.img'];
            if (~lexist(mprImg, 'file'))
                if (lexist(fullfile(convdir, mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, mpr));
                elseif (lexist(fullfile(convdir, 'V1', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V1', mpr));
                elseif (lexist(fullfile(convdir, 'V2', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V2', mpr));
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mprImg);
                end
            end
            if (~lexist([mpr '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(mpr, this.atlasTag);
            end

            tracer = 'fdg';
            for visit = 1:1 %2
                tracerdir = fullfile(workdir, sprintf('%s_v%i', upper(tracer), visit));
                if (~isdir(tracerdir))
                    mkdir(tracerdir);
                end
                cd(tracerdir);
                fdfp0 = sprintf('%s%s_v%i', subject, tracer, visit);
                fdfp1 = sprintf('%sv%i', tracer, visit);
                this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
                this.buildVisitor.lns_4dfp(fullfile(convdir,  mpr));
                this.buildVisitor.lns_4dfp(fullfile(nacdir, fdfp0));
                this.t4ResolveIterative(fdfp0, fdfp1, mpr);
            end
        end
        function this = t4ResolvePET2(this)
            subject = 'HYGLY09';
            convdir = fullfile(getenv('PPG'), 'converted', subject, 'V1', '');
            nacdir  = this.sessionData.petPath;
            mpr     = [subject '_mpr'];

            mprImg = [mpr '.4dfp.img'];
            if (~lexist(mprImg, 'file'))
                if (lexist(fullfile(convdir, mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, mpr));
                elseif (lexist(fullfile(convdir, 'V1', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V1', mpr));
                elseif (lexist(fullfile(convdir, 'V2', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V2', mpr));
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mprImg);
                end
            end
            if (~lexist([mpr '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(mpr, this.atlasTag);
            end

            tracer = 'fdg';
            for visit = 1:1 %2
                tracerdir = fullfile(nacdir, sprintf('%s_v%i', upper(tracer), visit));
                if (~isdir(tracerdir))
                    mkdir(tracerdir);
                end
                cd(tracerdir);
                this.buildVisitor.lns(     fullfile(nacdir, [mpr '_to_' this.atlasTag '_t4']));
                this.buildVisitor.lns_4dfp(fullfile(convdir,  mpr));
                fdfp0 = sprintf('%sv%i_AC_frames1to31', tracer, visit);
                this.buildVisitor.lns_4dfp(fullfile(nacdir, fdfp0));
                fdfp1 = sprintf('%sv%i', tracer, visit);
                this.t4ResolveIterative(fdfp0, fdfp1, mpr);
            end
        end
        function this = t4ResolvePET(this)

            subject = 'HYGLY09';
            convdir = fullfile(getenv('PPG'), 'converted', subject, 'V1', '');
            nacdir  = fullfile(convdir, '');
            workdir = fullfile(getenv('PPG'), 'jjlee', subject, '');
            mpr     = [subject '_mpr'];

            mprImg = [mpr '.4dfp.img'];
            if (~lexist(mprImg, 'file'))
                if (lexist(fullfile(convdir, mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, mpr));
                elseif (lexist(fullfile(convdir, 'V1', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V1', mpr));
                elseif (lexist(fullfile(convdir, 'V2', mprImg)))
                    this.buildVisitor.lns_4dfp(fullfile(convdir, 'V2', mpr));
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mprImg);
                end
            end
            if (~lexist([mpr '_to_' this.atlasTag '_t4']))
                this.msktgenMprage(mpr, this.atlasTag);
            end

            tracer = 'fdg';
            for visit = 1:1 %2
                tracerdir = fullfile(workdir, sprintf('%s_v%i', upper(tracer), visit));
                cd(tracerdir);
                this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
                this.buildVisitor.lns_4dfp(fullfile(convdir,  mpr));
                this.buildVisitor.lns_4dfp(fullfile(nacdir, sprintf('%s%s_v%i_AC', subject, tracer, visit)));
                fdfp0 = sprintf('%s%s_v%i_AC', subject, tracer, visit);
                fdfp1 = sprintf('%sv%i', tracer, visit);
                this.t4ResolveIterative(fdfp0, fdfp1, mpr);
            end
            
%             tracers = {'ho' 'oo'};
%             for t = 1:1 %length(tracers)
%                 for visit = 1:1 %2
%                     for scan = 2:2
%                         tracerdir = fullfile(workdir, sprintf('%s%i_v%i', upper(tracers{t}), scan, visit));
%                         this.buildVisitor.mkdir(tracerdir);
%                         cd(tracerdir);
%                         this.buildVisitor.lns(     fullfile(workdir, [mpr '_to_' this.atlasTag '_t4']));
%                         this.buildVisitor.lns_4dfp(fullfile(workdir,  mpr));
%                         this.buildVisitor.lns_4dfp(fullfile(nacdir, sprintf('%s%s%i_v%i', subject, tracers{t}, scan, visit)));
%                         fdfp0 = sprintf('%s%s%i_v%i', subject, tracers{t}, scan, visit);
%                         fdfp1 = sprintf('%s%iv%i', tracers{t}, scan, visit);
%                         this.t4ResolveIterative(fdfp0, fdfp1, mpr);
%                     end
%                 end
%             end
        end
        
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

