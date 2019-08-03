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
        function t4resolve_to_T1001(folders, varargin)
            %% subjects/sub-S12345/tradt<datetime>
            
            import mlraichle.*
            import mlraichle.StudyCurator.*
            ip = inputParser;
            addParameter(ip, 'fsleyes', true, @islogical)
            parse(ip, varargin{:})
            
            fprintf('t4resolve_to_T1001:  working on %s', folders)
            if lstrfind(folders, '*')
                error('mlraichle:RuntimeError', 'StudyCurator.t4resolve_to_T1001.folders->%s', folders)
            end
            fv = mlfourdfp.FourdfpVisitor();
            json = mlraichle.Json();
            ss = strsplit(folders, filesep);
            subf = ss{2};
            tradt = ss{3};
            prjf = json.tradt_to_projectFolder(tradt);
            sesf = json.tradt_to_sessionFolder(tradt);
            TRAF = tradt_to_TRA_DTFolder(tradt);            

            rrdir = fullfile(getenv('SUBJECTS_DIR'), subf, 'resampling_restricted', '');
            pwd0 = pushd(rrdir);            
            ensuredir('Tmp');
            pwd1 = pushd('Tmp');

            fv.lns_4dfp(fullfile(rrdir, tradt), [tradt 'r1'])
            fv.lns_4dfp(fullfile(rrdir, [tradt '_avgt']), [tradt '_avgtr1'])
            fv.lns_4dfp(fullfile(rrdir, 'T1001'), 'T1001r1')
            folders1 = fullfile(prjf, sesf, TRAF);
            sesd = SessionData.create(folders1);
            if lstrfind(tradt, 'oc')
                maskForImages = {'none' 'none'};
            else
                maskForImages = {'T1001' 'Msktgen'};
            end
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData',   sesd, ...
                'theImages',     {'T1001r1' [tradt '_avgtr1']}, ...
                'maskForImages', maskForImages, ...
                'resolveTag',    'op_T1001', ...
                'NRevisions', 1);
            cRB.resolve();
            t4ori = sprintf('%s_to_T1001_t4', tradt);
            t4new = sprintf('%s_avgtr1_to_op_T1001_t4', tradt);
            fpori = sprintf('%s_avgt_on_T1001', tradt);
            fpnew = sprintf('%s_avgtr1_op_T1001', tradt);
            if ip.Results.fsleyes
                mlbash(sprintf('fsleyes %s.4dfp.img T1001.4dfp.img', fpnew))
            end
            popd(pwd1)

            ensuredir('Previous')
            movefile(t4ori, fullfile('Previous', t4ori))
            movefile(fullfile('Tmp', t4new), t4ori)
            fv.movefile_4dfp(fpori, fullfile('Previous', fpori))
            fv.movefile_4dfp(fullfile('Tmp', fpnew), fpori)
            mlbash('rm -rf Tmp')

            popd(pwd0)
        end
        function t4resolves_to_T1001(folders)
            %% subjects/sub-S12345/tradt<datetime>, globbing enabled
            
            ss = strsplit(folders, filesep);
            pwd0 = pushd(fullfile(getenv('SUBJECTS_DIR'), ss{2}, 'resampling_restricted'));
            ss3 = ss{3};
            if ~lstrfind(ss3, '_avgt_on_T1001.4dfp.hdr')
                ss3 = [ss3 '_avgt_on_T1001.4dfp.hdr'];
            end
            for tradt = asrow(glob(ss3))
                re = regexp(tradt{1}, '^(?<tradt>[a-z]+dt\d+)_avgt_on_T1001.4dfp.\w+$', 'names');
                if ~isempty(re)
                    mlraichle.StudyCurator.t4resolve_to_T1001( ...
                        fullfile(ss{1}, ss{2}, re.tradt), 'fsleyes', false)
                end
            end
            popd(pwd0)
        end
        function tdt = TRA_DTFolder_to_tradt(TDT)
            if lstrfind(TDT, '.')
                TDT = strsplit(TDT, '.');
                TDT = TDT{1};
            end
            ss = strsplit(TDT, '_');
            tdt = lower([(ss{1}) ss{2}]);
        end
        function TDT = tradt_to_TRA_DTFolder(tdt)
            re = regexp(tdt, '^(?<tra>[a-z]+)dt(?<datetime>\d+)$', 'names');
            TDT = sprintf('%s_DT%s.000000-Converted-AC', upper(re.tra), re.datetime);
        end
        function c = dtcode(tdt)
            re = regexp(tdt, '^[a-z]+(?<code>dt\d+)\S*', 'names');
            c = re.code;            
        end
%        function sf = find_sesfold(subfold, tracerdt)
%        end
        function c = tracercode(tdt)
            re = regexp(tdt, '^(?<code>[a-z]+)dt\d+\S*', 'names');
            c = re.code;
        end
        function tdtses = tracerdt_session(sesfold, tdt)
            for t4s = asrow(glob(fullfile(sesfold, [tdt '*_avgtr1_to_op_*_avgtr1_t4'])))
                re = regexp(t4s{1}, ['^' tdt '_avgtr1_to_op_(?<tdtses>\w+dt\d+)_avgtr1_t4$'], 'names');
                if ~isempty(re.tdtses)
                    if ~strcmp(tdt, re.tdtses)
                        tdtses = re.tdtses;
                    end
                    return
                end
                
                % globbed, no matches
                error('mlraichle:NotImplementedError', 'StudyCurator.tracerdt_session')
            end
            
            % no globs, no matches  
            error('mlraichle:NotImplementedError', 'StudyCurator.tracerdt_session')            
        end
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
        function curate00(this)
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
        function curate0(this)
            pwd0 = pushd(this.subPath);
            this.stageTracersOnMNI152
            this.stageFreeSurferObjects   
            popd(pwd0)  
        end
        function curate(this)
            pwd0 = pushd(this.subPath);
            this.stageTracers
            this.stageT4s
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
            error('mlraichle:RuntimeError', 'StudyCurator.firstPopulatedSesPath could not find a valid session')
        end
        function pth = firstPopulatedSingularitySesPath(this)
            sesFold = basename(this.firstPopulatedSesPath);
            pth = fullfile(getenv('SINGULARITY_HOME'), this.sesFolder2project(sesFold), sesFold, '');            
        end
        function stageFreeSurferObjects(this) 
            pwd1 = pushd(this.subPath1);
            copyfile(fullfile(this.firstPopulatedSingularitySesPath, 'T1001.nii'))
            gzip('T1001.nii')
            deleteExisting('T1001.nii')
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
        function stageT4s(this)
            pwd0 = pushd(this.subPath);
            globbedHdr = glob('*_on_op_fdg*.4dfp.hdr');
            for g = asrow(globbedHdr)
                prefix = strsplit(g{1}, '_');
                prefix = prefix{1};            
                mlbash(sprintf('rsync -raL %s %s', 'fdg_avgr1_to_T1001r1_t4', fullfile(this.subPath1, [prefix '_to_T1001_t4'])))
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
            addParameter(ip, 'curatedFolder', '/data/nil-bluearc/raichle/PPGdata/jjlee/subjects2', @isfolder)
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

