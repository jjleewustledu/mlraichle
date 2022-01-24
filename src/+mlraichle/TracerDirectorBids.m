classdef TracerDirectorBids < mlpipeline.AbstractDirector
	%% TRACERDIRECTORBIDS

	%  $Revision$
 	%  was created 08-Apr-2019 15:17:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1049112 (R2018b) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties (Constant)
 		CHART_TAG = '_avgt'
    end

    methods (Static)
        function objs = migrateResolvedToVall(varargin)
            import mlraichle.TracerDirectorBids
            import mlfourd.ImagingContext2           
            import mlraichle.TracerDirectorBids.migrationTeardown
            import mlraichle.TracerDirectorBids.CHART_TAG
            import mlsystem.DirTool
            
            this = TracerDirectorBids(mlpet.TracerResolveBuilder(varargin{:}));  
            sess = this.sessionData;
            src  = sess.sessionPath;
            dest = fullfile( ...
                '/data/nil-bluearc/raichle/PPGdata/jjlee4', ...
                sess.sessionLocation('typ','folder'), ...
                sess.vallLocation('typ','folder'), '');
            ensuredir(dest);
            logs = fullfile(dest, 'Log', '');
            ensuredir(logs);
            res = mlpipeline.ResourcesRegistry.instance;
            res.keepForensics = false;
            fv = mlfourdfp.FourdfpVisitor;
            
            %% migrate PET without flipping
            
            tra = lower(this.sessionData.tracer);
            tags = {'' CHART_TAG};
            fps = {};
            dest_fqfp0 = {};
            for g = 1:length(tags)
                dt = DirTool(sprintf('%sr2_op_%se1to*r1_frame*%s.4dfp.hdr', tra, tra, tags{g}));
                if (dt.length > 0)
                    fp0_ = myfileprefix(dt.fns{1});
                    fps{g} = [sess.tracerRevision('typ','fp') tags{g}];
                    src_fqfp0{g}  = fullfile(src,  fp0_); %#ok<*AGROW>
                    dest_fqfp0{g} = fullfile(dest, fps{g});
                    copyfile([src_fqfp0{g} '.log'], [dest_fqfp0{g} '.log']);
                end
            end

            %% copy/move src_fqfp0

            fv.copy_4dfp(src_fqfp0{end}, dest_fqfp0{end});
            if (~lexist_4dfp(dest_fqfp0{1}))
                fv.move_4dfp(src_fqfp0{1}, dest_fqfp0{1});
            end                

            %% migrate and resolve T1001

            pwd0 = pushd(dest);
            if (~lexist_4dfp(fullfile(dest, 'T1001')))
                copyfile(fullfile(src, 'T1001.4dfp.*'), dest);
            end
            theImages = {fps{end} 'T1001'};
            try
                ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                    'sessionData', sess, ...
                    'theImages', theImages, ...
                    'blurArg', [4.3 4.3], ...
                    'maskForImages', {'Msktgen' 'T1001'}, ...
                    'NRevisions', 1);
                ct4rb = ct4rb.resolve;       
            catch ME
                warning('mlraichle:FileNotFoundWarning', 'TracerDirector3.migrateResolvedToVall');
                fprintf([ME.message '\n']);
            end
            
            %% clean up
            
            migrationTeardown(fps, logs, dest_fqfp0, dest);
            popd(pwd0);            
            res.keepForensics = true;
            objs = {dest ct4rb};
        end
    end
    
	methods 
 		function this = TracerDirectorBids(varargin)
 			%% TRACERDIRECTORBIDS
 			%  @param builder must be an mlpet.TracerBuilder.
            %  @param anatomy is 4dfp, e.g., T1001.

 			this = this@mlpipeline.AbstractDirector(varargin{:});
            
            ip = inputParser;
            addOptional( ip, 'builder', [], @(x) isempty(x) || isa(x, 'mlfourdfp.AbstractSessionBuilder'));
            addParameter(ip, 'anatomy', 'T1001', @ischar);
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
            this.anatomy_ = ip.Results.anatomy;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

