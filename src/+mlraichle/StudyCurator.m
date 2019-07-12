classdef StudyCurator 
	%% STUDYCURATOR  

	%  $Revision$
 	%  was created 11-Jul-2019 18:20:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		subPath % source
        subPath1 % curated        

        MAKE_MNI_IMG = true
        fdg_to_T1001_t4 = 'fdg_avgr1_to_T1001r1_t4'
        T1001_to_seven11_t4 = 'T1001_to_TRIO_Y_NDC_t4'
        T1001_to_MNI_t4 = 'T1001r1_to_MNI152lin_T1_t4'
        fdg_to_seven11_t4 = 'fdg_avgr1_to_TRIO_Y_NDC_t4'
        seven11_to_MNI_t4 = fullfile(getenv('RELEASE'), '711-2B_to_MNI152lin_T1_t4')
        fdg_to_MNI_t4 = 'fdg_avgr1_to_MNI152lin_T1_t4'
        bigO_MNI = fullfile(getenv('RELEASE'), 'MNI152_T1_2mm')
    end
    
    methods (Static)
        function fn = filenameJson(prefix)
            re = regexp(prefix, '(?<tracer>[a-z]+)(?<dt>dt\d+)', 'names');
            fn = sprintf('%s_%s.json', upper(re.tracer), upper(re.dt));
        end
        function sf = firstPopulatedSesFolder()
            dt = mlsystem.DirTool('ses-E*');
            for d = dt.dns
                if isfile(fullfile(d{1}, 'T1001.nii'))
                    sf = d{1};
                    return
                end
            end
        end
        function proj = sesFolder2project(sfold)
            g754 = glob(fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00754', sfold));
            g559 = glob(fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559', sfold));
            if ~isempty(g754)
                proj = 'CCIR_00754';
                return
            end
            if ~isempty(g559)
                proj = 'CCIR_00559';
                return
            end
            error('mlraichle:RuntimeError', 'StudyCurator.sesFolder2project could not find %s', sfold)
        end
        function stageAllBrain()
            projs = {'CCIR_00559' 'CCIR_00754'};
            for p = projs
                sess = glob(fullfile(getenv('SINGULARITY_HOME'), p{1}, 'ses-E*'));
                for s = asrow(sess)
                    try
                        pwd0 = pushd(s{1});
                        mlbash(sprintf('mri_convert %s.mgz %s.nii', fullfile('mri', 'brain'), 'brain'))
                        mlbash(        'nifti_4dfp -4 brain.nii brain.4dfp.hdr')
                        popd(pwd0)
                    catch ME
                        handwarning(ME)
                    end
                end
            end
        end
    end
    
	methods 
        function curate0(this)
            import mlraichle.StudyCurator.*
            import mlfourd.ImagingContext2

            pwd0 = pushd(this.subPath);
            t1 = ImagingContext2('T1001r1_op_fdg_avgr1.4dfp.hdr');
            t1.saveas(fullfile(this.subPath1,  'T1001_on_op_fdg.nii.gz'));
            t1 = ImagingContext2('T1001.4dfp.hdr');
            t1.saveas(fullfile(this.subPath1,  'T1001.nii.gz'));
            this.stageTracers;
            popd(pwd0)            
        end
        function curate(this)
            pwd0 = pushd(this.subPath);
            this.stageTracersOnMNI152
            this.stageFreeSurferObjects   
            popd(pwd0)  
        end
        function pth = firstPopulatedMriPath(this)
            pth = fullfile(this.firstPopulatedSingularitySesPath, 'mri', '');
        end
        function pth = firstPopulatedSesPath(this)
            dt = mlsystem.DirTool(fullfile(this.subPath, 'ses-E*'));
            for d = dt.fqdns
                if isfile(fullfile(d{1}, 'T1001.nii'))
                    pth = d{1};
                    return
                end
            end
        end
        function pth = firstPopulatedSingularitySesPath(this)
            sesFold = basename(this.firstPopulatedSesPath);
            pth = fullfile(getenv('SINGULARITY_HOME'), this.sesFolder2project(sesFold), sesFold, '');            
        end
        function stageFreeSurferObjects(this) 
%             
%             pwd0 = pushd(this.subPath);
%             deleteExisting('T1001.4dfp.*')
%             deleteExisting('T1001r1.4dfp.*')
%             lns_4dfp(fullfile(this.firstPopulatedSingularitySesPath, 'T1001'))
%             lns(fullfile(this.firstPopulatedSingularitySesPath, 'T1001.nii'))          
%             t4 = 'T1001r1_to_op_fdg_avgr1_t4';
%             for f = {'brain' 'wmparc' 'aparcAseg' 'aparcA2009sAseg'}
%                 try
%                     if ~isfile([f{1} '.4dfp.hdr'])                        
%                         lns_4dfp(fullfile(this.firstPopulatedSingularitySesPath, f{1}))                        
%                     end
%                     mlbash(sprintf('t4img_4dfp %s %s %s_op_fdg_avgr1 -OT1001r1_op_fdg_avgr1', t4, f{1}, f{1}))
%                     ic2 = mlfourd.ImagingContext2([f{1} '_op_fdg_avgr1.4dfp.hdr']);
%                     ic2.saveas(fullfile(this.subPath1, [f{1} '_on_op_fdg_avg.nii.gz']))
%                 catch ME
%                     handwarning(ME)
%                 end
%             end   
%             
%             popd(pwd0)
            
            
            
            pwd1 = pushd(this.subPath1);
            copyfile(fullfile(this.firstPopulatedSingularitySesPath, 'T1001.nii'))
            gzip('T1001.nii')
            mripth = this.firstPopulatedMriPath;
            mlbash(sprintf('mri_convert %s.mgz %s.nii.gz', fullfile(mripth, 'brain'), 'brain'))
            mlbash(sprintf('mri_convert %s.mgz %s.nii.gz', fullfile(mripth, 'wmparc'), 'wmparc'))
            mlbash(sprintf('mri_convert %s.mgz %s.nii.gz', fullfile(mripth, 'aparc+aseg'), 'aparcAseg'))
            mlbash(sprintf('mri_convert %s.mgz %s.nii.gz', fullfile(mripth, 'aparc.a2009s+aseg'), 'aparcA2009sAseg'))
            popd(pwd1) 
        end
        function stageTracers(this)
            %  @return this.subPath1/hodt20140514113341.nii.gz % on fdg
            %  @return this.subPath1/hodt20140514113341_avgt.nii.gz % on fdg
            %  @return this.subPath1/hodt20140514113341.json
            
            pwd0 = pushd(this.subPath);
            globbedHdr = glob('*_on_op_fdg*.4dfp.hdr');
            for g = asrow(globbedHdr)
                prefix = strsplit(g{1}, '_');
                prefix = prefix{1};
                niigz = [prefix '.nii.gz'];
                trac = mlfourd.ImagingContext2(g{1});
                trac.addLog('mlraichle.StudyCurator.stageTracers.g{1} -> %s', g{1})
                trac = trac.saveas(fullfile(this.subPath1, niigz));
                trac = trac.timeAveraged;
                trac.save;

                mlbash(sprintf('rsync -raL %s %s', this.filenameJson(prefix), fullfile(this.subPath1, [prefix '.json'])))
            end    
            popd(pwd0)
        end
        function stageTracersOnMNI152(this)
            %% STAGETRACERSONMNI152
            %  # from pascal:/scratch/jjlee/Singularity/subjects/history_20190711.log
            %  T4a=fdg_avgr1_to_T1001r1_t4
            %  T4b=T1001_to_TRIO_Y_NDC_t4
            %  t4_mul $T4a $T4b fdg_avgr1_to_TRIO_Y_NDC_t4
            %  t4_mul fdg_avgr1_to_TRIO_Y_NDC_t4 $RELEASE/711-2B_to_MNI152lin_T1_t4 fdg_avgr1_to_MNI152lin_T1_t4
            %  t4img_4dfp fdg_avgr1_to_MNI152lin_T1_t4  hodt20140514113341_op_hodt20140514113341r1_on_op_fdg_avgr1  hodt20140514113341_on_MNI152_2mm -O$RELEASE/MNI152_T1_2mm
            %  nifti_4dfp -n hodt20140514113341_on_MNI152_2mm.4dfp.hdr hodt20140514113341_on_MNI152_2mm.nii
            %
            %  @return this.subPath1/fdg_avg_to_T1001_t4
            %  @return this.subPath1/T1001_to_MNI152lin_T1_t4
            %  @return this.subPath1/fdg_avg_to_MNI152lin_T1_t4

            pwd0 = pushd(this.subPath);
            
            mlbash(sprintf('t4_mul %s %s %s', this.fdg_to_T1001_t4, this.T1001_to_seven11_t4, this.fdg_to_seven11_t4))
            mlbash(sprintf('t4_mul %s %s %s', this.fdg_to_seven11_t4, this.seven11_to_MNI_t4, this.fdg_to_MNI_t4))  
            mlbash(sprintf('t4_mul %s %s %s', this.T1001_to_seven11_t4, this.seven11_to_MNI_t4, this.T1001_to_MNI_t4))
            
            %copyfile(this.fdg_to_T1001_t4, fullfile(this.subPath1, 'fdg_avg_to_T1001_t4'))
            copyfile(this.T1001_to_MNI_t4, fullfile(this.subPath1, 'T1001_to_MNI152lin_T1_t4'))
            %copyfile(this.fdg_to_MNI_t4,   fullfile(this.subPath1, 'fdg_avg_to_MNI152lin_T1_t4'))
            
            tracers = glob('*_on_op_fdg*.4dfp.hdr');
            for t = asrow(tracers)
                                
                re = regexp(mybasename(t{1}), '(?<tracer>[a-z]+dt\d+)_\w+_on_op_fdg\w+', 'names');
                simplePrefix = [re.tracer];
                tracer_on_MNI = sprintf('%s_on_MNI152_2mm', simplePrefix);
                mlbash(sprintf('t4img_4dfp %s %s %s -O%s', this.fdg_to_MNI_t4, mybasename(t{1}), fullfile(this.subPath1, tracer_on_MNI), this.bigO_MNI))
                mlbash(sprintf('nifti_4dfp -n %s.4dfp.hdr %s.nii', fullfile(this.subPath1, tracer_on_MNI), fullfile(this.subPath1, tracer_on_MNI)))
                ic2 = mlfourd.ImagingContext2(fullfile(this.subPath1, [tracer_on_MNI '.nii']));
                ic2 = ic2.timeAveraged;
                ic2.filesuffix = '.nii.gz';
                ic2.save
                gzip(fullfile(this.subPath1, [tracer_on_MNI '.nii']))
                deleteExisting(fullfile(this.subPath1, [tracer_on_MNI '.4dfp.*']))
            end
            
            popd(pwd0)
        end
		  
 		function this = StudyCurator(varargin)
 			%% STUDYCURATOR
 			%  @param required subFolder is char.
            %  @param sourceFolder is folder.
            %  @param curatedFolder is folder.

            ip = inputParser;
            addRequired(ip, 'subFolder', @ischar)
            addParameter(ip, 'sourceFolder', '/scratch/jjlee/Singularity/subjects', @isfolder)
            addParameter(ip, 'curatedFolder', '/data/nil-bluearc/raichle/PPGdata/jjlee/subjects', @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.subPath = fullfile(ipr.sourceFolder, ipr.subFolder);
            this.subPath1 = fullfile(ipr.curatedFolder, ipr.subFolder);
            assert(isfolder(this.subPath))
            ensuredir(this.subPath1)
            
            this.subjectsJson_ = jsondecode( ...
                fileread(fullfile(getenv('SUBJECTS_DIR'), 'construct_ct.json')));
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        subjectsJson_
    end
    
    %% DEPRECATED
    
    methods (Hidden)
        function stageT4s__(this)
            import mlraichle.*
            
            pwd0 = pushd(this.subPath);
            subData = SubjectData('subjectFolder', basename(this.subPath));
            sesFold = subData.subFolder2sesFolder( basename(this.subPath));
            sesData = SessionData( ...
                'studyData', StudyData(), ...
                'projectData', ProjectData('sessionStr', sesFold), ...
                'subjectData', subData, ...
                'sessionFolder', sesFold, ...
                'tracer', 'FDG', ...
                'ac', true); 
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData',   sesData, ...
                'theImages',     {'T1001' 'fdg_avg'}, ...
                'maskForImages', 'Msktgen', ...
                'resolveTag',    'op_T1001r1', ...
                'NRevisions',    1, ...
                'logPath',       'Log');
            cRB.neverMarkFinished = true;
            cRB.ignoreFinishMark  = true;
            cRB = cRB.resolve; 
            disp(cRB.t4s)
            disp(cRB.product)
            
            error('mlraichle:NotImplementedError', 'StudyCurator.stageT4s')            
            
            %copyfile('', fullfile(this.subPath1, 'fdg_to_op_T1001_t4'))
            popd(pwd0)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

