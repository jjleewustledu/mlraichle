classdef TracerDirector2 < mlnipet.CommonTracerDirector
	%% TRACERDIRECTOR2  

	%  $Revision$
 	%  was created 17-Nov-2018 10:26:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
 		CHART_TAG = '_avgt'
    end
    
    methods (Static)
        function this = constructUmaps(varargin)
            import mlraichle.TracerDirector2;
            import mlfourd.ImagingContext2;           
            switch mlraichle.StudyRegistry.instance().umapType
                case 'ct'                    
                    this = TracerDirector2(mlfourdfp.CarneyUmapBuilder2(varargin{:}));
                    TracerDirector2.prepareFreesurferData(varargin{:});
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                case 'ute'
                    this = TracerDirector2(mlfourdfp.UTEUmapBuilder(varargin{:}));
                    TracerDirector2.prepareFreesurferData(varargin{:});
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                case 'mrac_hires'
                    this = TracerDirector2(mlfourdfp.MRACHiresUmapBuilder(varargin{:}));
                    TracerDirector2.prepareFreesurferData(varargin{:});
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                case 'pseudoct'
                    this = mlfourdfp.PseudoCTBuilder(varargin{:});
                    TracerDirector2.prepareFreesurferData(varargin{:});
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                otherwise
                    error('mlraichle:ValueError', 'TracerDirector2.constructUmaps')
            end
            if this.builder.isfinished
                return
            end 
            
            pwd0 = pushd(this.sessionData.sessionPath);
            umap = this.builder.buildUmap;
            umap = ImagingContext2([umap '.4dfp.hdr']);
            umap = umap.blurred(mlnipet.ResourcesRegistry.instance().petPointSpread);
            umap.save;
            this.builder_ = this.builder.packageProduct(umap);
            this.builder.teardownBuildUmaps;
            popd(pwd0);
        end
        function objs = migrateResolvedToVall(varargin)
            import mlraichle.TracerDirector2
            import mlfourd.ImagingContext2           
            import mlraichle.TracerDirector2.migrationTeardown
            import mlraichle.TracerDirector2.CHART_TAG
            import mlsystem.DirTool
            
            this = TracerDirector2(mlpet.TracerResolveBuilder(varargin{:}));  
            sess = this.sessionData;
            src  = sess.sessionPath;
            dest = fullfile( ...
                '/data/nil-bluearc/raichle/PPGdata/jjlee4', ...
                sess.sessionLocation('typ','folder'), ...
                sess.vallLocation('typ','folder'), '');
            ensuredir(dest);
            logs = fullfile(dest, 'Log', '');
            ensuredir(logs);
            res = mlpipeline.ResourcesRegistry.instance();
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
                warning('mlraichle:FileNotFoundWarning', 'TracerDirector2.migrateResolvedToVall');
                fprintf([ME.message '\n']);
            end
            
            %% clean up
            
            migrationTeardown(fps, logs, dest_fqfp0, dest);
            popd(pwd0);            
            res.keepForensics = true;
            objs = {dest ct4rb};
        end
        function tmp  = migrationTeardown(fps, logs, dest_fqfp0, dest)
            tmp = protectFiles(fps, fps{1}, logs);
            deleteFiles(dest_fqfp0, fps{1}, fps, dest);   
            unprotectFiles(tmp);
                        
            function tmp = protectFiles(fps, fps1, logs)
                
                % in tempFilepath
                tmp = tempFilepath('protectFiles');
                ensuredir(tmp);                
                for f = 1:length(fps)
                    moveExisting([fps{f} '.4dfp.*'], tmp);
                    moveExisting([fps{f} 'r1_b43.4dfp.*'], tmp);
                end
                moveExisting( 'T1001.4dfp.*', tmp);
                moveExisting(['T1001r1_op_' fps1 '.4dfp.*'], tmp);
                moveExisting(sprintf('T1001_to_op_%s_t4', fps1), tmp)
                moveExisting( 'T1001_to_TRIO_Y_NDC_t4', tmp)

                % in Log
                moveExisting('*.mat0', logs);
                moveExisting('*.sub',  logs);
                moveExisting('*.log',  logs);  
            end
            function deleteFiles(dest_fqfp0, fps1, fps, dest)
                assert(lstrfind(dest_fqfp0{end}, '_sumt'));
                deleteExisting([dest_fqfp0{end} 'r1.4dfp.*']);
                deleteExisting([dest_fqfp0{end} 'r1_op_' fps1 '.4dfp.*']);
                deleteExisting([dest_fqfp0{end} 'r1_to_op_' fps1 '_t4']);
                deleteExisting([dest_fqfp0{end} 'r1_to_T1001r1_t4']);
                for f = 1:length(fps)
                    deleteExisting(fullfile(dest, ['T1001r1_to_' fps{f} 'r1_t4']));
                end
                deleteExisting('T1001r1.4dfp.*');
                deleteExisting('T1001r1_b43.4dfp.*');
                deleteExisting('*_mskt.4dfp.*');
                deleteExisting('*_g11.4dfp.*');       
            end
            function unprotectFiles(tmp)
                movefile(fullfile(tmp, '*'), pwd);
                rmdir(tmp);
            end
        end
    end
    
	methods
 		function this = TracerDirector2(varargin)
 			%% TRACERDIRECTOR2
 			%  @param builder must be an mlpet.TracerBuilder.

 			this = this@mlnipet.CommonTracerDirector(varargin{:});
 		end
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

