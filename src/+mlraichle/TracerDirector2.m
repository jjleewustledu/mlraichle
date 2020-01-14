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
        function constructPhantomStudy(varargin)
            %% CONSTRUCTPHANTOMSTUDY constructs objects required for niftypet on calibration phantoms.  
            %  It provides iterators for project, session and tracer folders on the filesystem.
            %  Usage:  constructPhantomStudy(<folders expression>)
            %          e.g.:  >> constructPhantomStudy('CCIR_00123/ses-E00123/FDG_DT20190101.000000-Converted-NAC')    
            %          e.g.:  >> constructPhantomStudy('CCIR_00123/ses-E0012*/FDG_DT*-Converted-NAC')
            %  
            %  @precondition fullfile(projectsDir, project, session, 'umaps', '*UMAP*') 
            %                for projectsDir := getenv('PROJECTS_DIR') and 
            %                {project, session, ...} = split(<folders_expression>)
            %  @param foldersExpr is char.
            %  @return results in fullfile(projectsDir, project, session, tracer) 
            %          for elements of projectsExpr, sessionsExpr and tracerExpr.

            import mlraichle.*; %#ok<NSTIMP>
            import mlsystem.DirTool;
            import mlpet.DirToolTracer;

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'foldersExpr', @ischar)
            addParameter(ip, 'getstats', false)
            parse(ip, varargin{:});
            ipr = TracerDirector2.adjustIprConstructResolvedStudy(ip.Results);

            registry = StudyRegistry.instance();
            for p = globT(fullfile(registry.projectsDir, ipr.projectsExpr))
                for s = globT(fullfile(p{1}, ipr.sessionsExpr))
                    pwd0 = pushd(s{1});
                    for t = globT(ipr.tracersExpr)
                        try
                            folders = fullfile(basename(p{1}), basename(s{1}), t{1});
                            sessd = SessionData.create(folders, ...
                                'ignoreFinishMark', true, ...
                                'reconstructionMethod', 'NiftyPET');

                            fprintf('constructPhantomStudy:\n');
                            fprintf([evalc('disp(sessd)') '\n']);
                            fprintf(['\tsessd.tracerLocation->' sessd.tracerLocation '\n']);

                            warning('off', 'MATLAB:subsassigndimmismatch');
                            pwd1 = pushd(t{1});
                            if ~ipr.getstats
                                TracerDirector2.constructPhantom('sessionData', sessd);
                            else
                                [me,sd] = TracerDirector2.constructPhantomStats('sessionData', sessd);
                                fprintf('mlraichle.TracerDirector2.constructPhantomStudy:\n')
                                fprintf('specific activity:  mean %g std %g', me, sd)
                            end
                            popd(pwd1)
                            warning('on',  'MATLAB:subsassigndimmismatch');
                        catch ME
                            dispwarning(ME)
                            getReport(ME)
                        end
                    end
                    popd(pwd0);
                end
            end
        end
        function constructResolvedStudy(varargin)
            %% CONSTRUCTRESOLVEDSTUDY supports t4_resolve for niftypet.  It provides iterators for 
            %  project, session and tracer folders on the filesystem.
            %  Usage:  constructResolvedStudy(<folders experssion>[, 'ignoreFinishMark', <true|false>])
            %          e.g.:  >> constructResolvedStudy('CCIR_00123/ses-E00123/OO_DT20190101.000000-Converted-NAC')    
            %          e.g.:  >> constructResolvedStudy('CCIR_00123/ses-E0012*/OO_DT*-Converted-NAC')
            %  
            %  @precondition fullfile(projectsDir, project, session, 'umapSynth_op_T1001_b43.4dfp.*') and
            %                         projectsDir := getenv('PROJECTS_DIR')
            %  @precondition files{.bf,.dcm} in fullfile(projectsDir, project, session, 'LM', '')
            %  @precondition files{.bf,.dcm} in fullfile(projectsDir, project, session, 'norm', '')
            %  @precondition FreeSurfer recon-all results in fullfile(projectsDir, project, session, 'mri', '')
            %
            %  @param foldersExpr is char.
            %  @return results in fullfile(projectsDir, project, session, tracer) 
            %          for elements of projectsExpr, sessionsExpr and tracerExpr.

            import mlraichle.*; %#ok<NSTIMP>
            import mlsystem.DirTool;
            import mlpet.DirToolTracer;

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'foldersExpr', @ischar)
            addParameter(ip, 'ignoreFinishMark', true, @islogical);
            addParameter(ip, 'reconstructionMethod', 'NiftyPET', @ischar);
            parse(ip, varargin{:});
            ipr = TracerDirector2.adjustIprConstructResolvedStudy(ip.Results);

            registry = StudyRegistry.instance();
            for p = globT(fullfile(registry.projectsDir, ipr.projectsExpr))
                for s = globT(fullfile(p{1}, ipr.sessionsExpr))
                    pwd0 = pushd(s{1});
                            
                    for t = globT(ipr.tracersExpr)
                        try
                            folders = fullfile(basename(p{1}), basename(s{1}), t{1});
                            sessd = SessionData.create(folders, ...
                                'ignoreFinishMark', ipr.ignoreFinishMark, ...
                                'reconstructionMethod', ipr.reconstructionMethod);                    
                            if ~isfile(fullfile(sessd.umapSynthOpT1001('typ','fqfn')))
                                TracerDirector2.constructUmaps('sessionData', sessd, 'umapType', registry.umapType);
                            end
                            if isempty(glob(fullfile(sessd.tracerLocation, 'umap', '*')))
                                TracerDirector2.populateTracerUmapFolder('sessionData', sessd)
                            end
                            if ~isfolder(sessd.tracerOutputLocation())
                                continue
                            end

                            fprintf('constructResolvedStudy:\n');
                            fprintf([evalc('disp(sessd)') '\n']);
                            fprintf(['\tsessd.tracerLocation->' sessd.tracerLocation '\n']);

                            warning('off', 'MATLAB:subsassigndimmismatch');
                            TracerDirector2.constructResolved('sessionData', sessd);
                            warning('on',  'MATLAB:subsassigndimmismatch');
                        catch ME
                            dispwarning(ME)
                            getReport(ME)
                        end
                    end
                    popd(pwd0);
                end
            end
        end
        function constructSessionsStudy(varargin)
            %% CONSTRUCTSESSIONSSTUDY
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345/ses-E12345'.
            
            import mlraichle.*
            import mlpet.SessionResolveBuilder
            import mlsystem.DirTool
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'foldersExpr', @ischar)
            addParameter(ip, 'makeClean', true, @islogical)  
            addParameter(ip, 'blur', [], @(x) isnumeric(x) || ischar(x) || isstring(x))
            addParameter(ip, 'makeAligned', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ss = strsplit(ipr.foldersExpr, '/');
            setenv('SUBJECTS_DIR', fullfile(getenv('SINGULARITY_HOME'), ss{1}))
            subpth = fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2});            
            
            %% redundant with mlpet.StudyResolveBuilder.configureSubjectData__ if ipr.makeClean
            if ~ipr.makeClean
                subd = SubjectData('subjectFolder', ss{2});
                subid = subFolder2subID(subd, ss{2});
                subd.aufbauSessionPath(subpth, subd.subjectsJson.(subid));
            end
            
            ensuredir(subpth)
            pwd0 = pushd(subpth);
            dt = DirTool([ss{3} '*']);
            for ses = dt.dns
                
                pwd1 = pushd(ses{1});
                if SessionResolveBuilder.validTracerSession()
                    sessd = SessionData( ...
                        'studyData', StudyData(), ...
                        'projectData', ProjectData('sessionStr', ses{1}), ...
                        'subjectData', SubjectData('subjectFolder', ss{2}), ...
                        'sessionFolder', ses{1}, ...
                        'tracer', 'FDG', 'ac', true); % referenceTracer
                    if ~isempty(ipr.blur)
                        sessd.tracerBlurArg = TracerDirector2.todouble(ipr.blur);
                    end
                    srb = SessionResolveBuilder('sessionData', sessd, 'makeClean', ipr.makeClean);
                    if ipr.makeAligned
                        srb.alignCrossModal();
                        srb.t4_mul();
                    end
                end
                popd(pwd1)
            end
            popd(pwd0)
            
            
            
            function sid = subFolder2subID(sdata, sfold)
                json = sdata.subjectsJson;
                for an_sid = asrow(fields(json))
                    if lstrfind(json.(an_sid{1}).sid, sfold(5:end))
                        sid = an_sid{1};
                        return
                    end
                end
            end
        end
        function constructSubjectsStudy(varargin)
            %% CONSTRUCTSUBJECTSSTUDY 
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            
            import mlraichle.*
            import mlsystem.DirTool
            import mlpet.SubjectResolveBuilder
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addParameter(ip, 'makeClean', true, @islogical)
            addParameter(ip, 'makeAligned', true, @islogical)
            addParameter(ip, 'compositionTarget', '', @ischar)
            addParameter(ip, 'blur', [], @(x) isnumeric(x) || ischar(x) || isstring(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            ss = strsplit(ipr.foldersExpr, '/');
            
            subPath = fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '');            
            pwd0 = pushd(subPath);
            subd = SubjectData('subjectFolder', ss{2});
            sesf = subd.subFolder2sesFolder(ss{2});
            sessd = SessionData( ...
                'studyData', StudyData(), ...
                'projectData', ProjectData('sessionStr', sesf), ...
                'subjectData', subd, ...
                'sessionFolder', sesf, ...
                'tracer', 'FDG', ...
                'ac', true); % referenceTracer
            if ~isempty(ipr.blur)
                sessd.tracerBlurArg = TracerDirector2.todouble(ipr.blur);
            end
            srb = SubjectResolveBuilder('subjectData', subd, 'sessionData', sessd, 'makeClean', ipr.makeClean);
            if ipr.makeAligned
                srb.alignCrossModal();
                srb.t4_mul();
                try
                    srb.lns_json_all();
                catch ME
                    handwarning(ME)
                end
            end
            srb.createResamplingRestricted('compositionTarget', ipr.compositionTarget)
            popd(pwd0)
        end
        function constructSubjectsVisualizations(varargin)
            %% CONSTRUCTSUBEJCTSVISUALIZATIONS 
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            
            import mlraichle.*
            import mlsystem.DirTool
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addParameter(ip, 'tmpPath', fullfile('/home2', 'jjlee', 'Tmp', ''), @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            ss = strsplit(ipr.foldersExpr, '/');
            
            dataPath = fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, 'resampling_restricted', '');
            pwd0 = pushd(dataPath);
            %mlbash(sprintf('t4img_4dfp %s %s %s -OT1001', , , ))
            popd(pwd0)
        end
        function repairSubjectsJson(varargin)
            %% REPAIRSUBJECTSJSON
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            
            %% Version $Revision$ was created $Date$ by $Author$,
            %% last modified $LastChangedDate$ and checked into repository $URL$,
            %% developed on Matlab 9.5.0.1067069 (R2018b) Update 4.  Copyright 2019 John Joowon Lee.
            
            import mlraichle.*
            import mlsystem.DirTool
            import mlpet.SubjectResolveBuilder
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            ss = strsplit(ipr.foldersExpr, '/');
            
            subPath = fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '');            
            pwd0 = pushd(subPath);
            subd = SubjectData('subjectFolder', ss{2});
            sesf = subd.subFolder2sesFolder(ss{2});
            sessd = SessionData( ...
                'studyData', StudyData(), ...
                'projectData', ProjectData('sessionStr', sesf), ...
                'subjectData', subd, ...
                'sessionFolder', sesf, ...
                'tracer', 'FDG', ...
                'ac', true); % referenceTracer
            srb = SubjectResolveBuilder('subjectData', subd, 'sessionData', sessd, 'makeClean', false);
            try
                srb.lns_json_all();
            catch ME
                dispexcept(ME)
            end
            popd(pwd0)
        end
        
        function        constructPhantom(varargin)   

            % clean up working area
            deleteExisting('*fdg*')
            deleteExisting('*T1001*')
            deleteExisting('umap*')
            deleteExisting('msk*')
            mlbash('rm -rf Log')
            mlbash('rm -rf output')
            
            % rename working dir -NAC to -AC
            if lstrfind(pwd, '-NAC')
                pwdNAC = pwd;
                pwdAC = strrep(pwdNAC, '-NAC', '-AC');
                cd(fileparts(pwdNAC));
                mlbash(sprintf('mv %s %s', pwdNAC, pwdAC))
                cd(pwdAC);
            elseif lstrfind(pwd, '-AC')
                pwdAC = pwd;
            else
                error('mlraichle:RuntimeError', 'TracerDirector2.constructPhantom')
            end
            
            % retrieve Head_MRAC_Brain_HiRes_in_UMAP_*; convert to NIfTI; resample for emissions
            pwdUmaps = fullfile(fileparts(pwdAC), 'umaps');
            globbed = globT(fullfile(pwdUmaps, 'Head_MRAC_*_in_UMAP*'));
            if isempty(globbed)
                globbed = globT(fullfile(pwdUmaps, '*UMAP*'));
            end
            assert(~isempty(globbed))
            pwdDcms = globbed{end};
            cd(pwdUmaps);
            mlbash(sprintf('dcm2niix -f umapSiemens -o %s -b y -z y %s', pwdUmaps, pwdDcms));
            globbedniix = glob('umapSiemens*.nii.gz');
            copyfile(fullfile(getenv('SINGULARITY_HOME'), 'zeros_frame.nii.gz'));
            mlbash(sprintf('reg_resample -ref zeros_frame.nii.gz -flo %s -res umapSynth.nii.gz', globbedniix{1}));
            delete('zeros_frame.nii.gz');
            movefile('umapSynth.nii.gz', pwdAC);
            cd(pwdAC);
            
            % adjust quantification:  blur, use expected phantom mu
            umap = mlfourd.ImagingContext2('umapSynth.nii.gz');
            umap = umap.blurred(mlnipet.ResourcesRegistry.instance().petPointSpread);
            umap = umap .* (0.09675 / 1e3);
            umap = umap.nifti;
            umap.img(umap.img < 0) = 0;
            umap.datatype = 'single';
            umap.saveas('umapSynth.nii.gz');
        end
        function [m,s] = constructPhantomStats(varargin) 
            
            pwd0 = pushd('output/PET/single-frame');
            
            globbed = glob('a_itr-*_t-0*sec_createPhantom.nii.gz');
            emissions = mlfourd.ImagingFormatContext(globbed{1});
            thresh = max(0, dipmax(emissions) - 8*dipstd(emissions));
            emissionsVec = emissions.img(emissions.img > thresh);
            m = mean(emissionsVec);
            s = std(emissionsVec);
            
            popd(pwd0)
        end
        function this = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
                      
            this = mlraichle.TracerDirector2(mlpet.TracerResolveBuilder(varargin{:}));
            this.fastFilesystemSetup;
            if (~this.sessionData.attenuationCorrected)
                if ~isfile(this.sessionData.umapSynthOpT1001)
                    this.constructUmaps(varargin{:})
                end
                this = this.instanceConstructResolvedNAC;                
                this.fastFilesystemTeardownWithAC(true); % intermediate artifacts
            else
                this = this.instanceConstructResolvedAC;
            end
            this.fastFilesystemTeardown;
            this.fastFilesystemTeardownProject;
        end
        function this = constructUmaps(varargin)
            import mlraichle.TracerDirector2;
            import mlfourd.ImagingContext2;           
            switch mlraichle.StudyRegistry.instance().umapType
                case 'ct'                    
                    this = TracerDirector2(mlfourdfp.CarneyUmapBuilder2(varargin{:}));
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                    if this.builder.isfinished
                        return
                    end 
                case 'ute'
                    this = TracerDirector2(mlfourdfp.UTEUmapBuilder(varargin{:}));
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                case 'mrac_hires'
                    this = TracerDirector2(mlfourdfp.MRACHiresUmapBuilder(varargin{:}));
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                case 'pseudoct'
                    this = mlfourdfp.PseudoCTBuilder(varargin{:});
                    this.builder_ = this.builder.prepareMprToAtlasT4;
                otherwise
                    error('mlraichle:ValueError', 'TracerDirector2.constructUmaps')
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
            import mlraichle.TracerDirector2.*
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
        function d = todouble(obj)
            if isnumeric(obj)
                d = obj;
                return
            end
            if ischar(obj) || isstring(obj)
                d = str2double(obj);
                return
            end
            error('mlpet:RuntimeError', 'TracerDirector2.todouble');
        end
    end
    
	methods
 		function this = TracerDirector2(varargin)
 			%% TRACERDIRECTOR2
 			%  @param builder must be an mlpet.TracerBuilder.

 			this = this@mlnipet.CommonTracerDirector(varargin{:});            
            this.prepareFreesurferData('sessionData', this.sessionData);
 		end
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

