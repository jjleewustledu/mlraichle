classdef FDGKineticsParc < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSPARC  

	%  $Revision$
 	%  was created 17-Feb-2017 07:41:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Constant)
        
        PARCS = {'striatum' 'thalamus' 'cerebellum' 'brainstem' 'ventralDC' 'white' ...
                 'yeo1' 'yeo2' 'yeo3' 'yeo4' 'yeo5' 'yeo6' 'yeo7'}; % N=13 
             
        HCTS = [35.7 33.6 33.4 34.5 41.4; ...
                31.3 32.5 34.6 34.5 37.2]; % KLUDGE:  better placed in .xlsx subject data files
                     
        %% aparc+aseg
        
 		striatum   = [11 50 12 51 13 52] % caudate, putamen, pallidus
        thalamus   = [10 49]
        cerebellum = [7 46 8 47]
        brainstem  = 16
        ventralDC  = [28 60 18 54 17 53] % ventral DC, amygdala, hippocampus
        white      = [2 41]
        
        %% yeo
        
        yeo1 = 1
        yeo2 = 2
        yeo3 = 3
        yeo4 = 4
        yeo5 = 5
        yeo6 = 6
        yeo7 = 7
 	end

	methods
 		function this = FDGKineticsParc(varargin)
 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
 		end
 	end

    methods (Static)
        function jobs = godoChpcPart(varargin)
            diary on   
            
            import mlraichle.*;
            ip = inputParser;
            addOptional(ip, 'dirToolArg', 'HYGLY2*', @ischar);
            addOptional(ip, 'vs', 1:2, @isnumeric);
            addParameter(ip, 'parcs', FDGKineticsParc.PARCS, @iscell);
            addParameter(ip, 'hcts', FDGKineticsParc.HCTS, @isnumeric); 
            parse(ip, varargin{:});                     
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            parcs  = ip.Results.parcs;
            hcts   = ip.Results.hcts;
            jobs   = {};
            if (hostnameMatch('innominate'))
                c = parcluster('chpc_remote_r2016b');
            elseif (hostnameMatch('william'))
                c = parcluster('chpc_remote_r2016a');
            else
                error('mlraichle:unsupportedHost', 'FDGKineticsParc.godoChpc.hostname->%s', hostname);
            end
            ClusterInfo.setEmailAddress('jjlee.wustl.edu@gmail.com');
            ClusterInfo.setMemUsage('32000');
            ClusterInfo.setWallTime('02:00:00');
            %ClusterInfo.setPrivateKeyFile('~/id_rsa.pem');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = ip.Results.vs
                    datobj.vnumber = v;
                    datobj.hct = hcts(v,d);
                    try
                        pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                        %CHPC.pushToChpc(datobj);
                        for p = 1:length(parcs)
                            datobj.parcellation = parcs{p};
                            j = c.batch(@mlraichle.FDGKineticsParc.godo3, 1, {datobj});
                            jobs = [jobs j]; %#ok<AGROW>
                        end
                        popd(pwd1);
                    catch ME
                        disp(ME);
                        struct2str(ME.stack);
                        handwarning(ME);                        
                    end
                end
            end
            popd(pwd0);
            
            diary off
        end
        function jobs = godoChpc
            
            diary on            
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            parcs  = FDGKineticsParc.PARCS;
            hcts   = FDGKineticsParc.HCTS;
            jobs   = {};
            if (hostnameMatch('innominate'))
                c = parcluster('chpc_remote_r2016b');
            elseif (hostnameMatch('william'))
                c = parcluster('chpc_remote_r2016a');
            else
                error('mlraichle:unsupportedHost', 'FDGKineticsParc.godoChpc.hostname->%s', hostname);
            end
            ClusterInfo.setEmailAddress('jjlee.wustl.edu@gmail.com');
            ClusterInfo.setMemUsage('32000');
            ClusterInfo.setWallTime('02:00:00');
            %ClusterInfo.setPrivateKeyFile('~/id_rsa.pem');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    datobj.hct = hcts(v,d);
                    try
                        pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                        %CHPC.pushToChpc(datobj);
                        for p = 1:length(parcs)
                            datobj.parcellation = parcs{p};
                            j = c.batch(@mlraichle.FDGKineticsParc.godo3, 1, {datobj});
                            jobs = [jobs j]; %#ok<AGROW>
                        end
                        popd(pwd1);
                    catch ME
                        disp(ME);
                        struct2str(ME.stack);
                        handwarning(ME);                        
                    end
                end
            end
            popd(pwd0);
            
            diary off
        end
        function sessions = godoWilliam
            tic 
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY22*');
            hcts   = FDGKineticsParc.HCTS;
            parcs  = FDGKineticsParc.PARCS;
            sessions = cell(length(dth.dns), 2);
            for d = 1:1 % length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 2:2
                    datobj.vnumber = v;
                    datobj.hct = hcts(v,d);
                    pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                    states = {};
                    for p = 11:13 % length(parcs)
                        datobj.parcellation = parcs{p};
                        s = FDGKineticsParc.godo3(datobj);
                        states = [states s]; %#ok<AGROW>
                        saveFigures(sprintf('fig_%s', datestr(now,30)));
                    end
                    popd(pwd1);
                    sessions{d,v} = states;
                end
            end
            popd(pwd0);
            
            toc
        end
        function goPlotOnWilliam            
            import mlraichle.*;
            hcts   = FDGKineticsParc.HCTS;
            parcs  = FDGKineticsParc.PARCS;             
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    datobj.hct = hcts(v,d);
                    for p = 1:length(parcs)
                        datobj.parcellation = parcs{p};
                        sessd = CHPC.staticSessionData(datobj);
                        FDGKineticsParc.godoPlots(sessd);
                    end
                end
            end
            popd(pwd0);
        end
        function goWritetable            
            import mlraichle.*;
            parcs  = FDGKineticsParc.PARCS;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            fp     = fullfile(pwd0, sprintf('mlraiche_FDGKineticsParc_goWritetable_%s', datestr(now, 30)));
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    for p = 1:length(parcs)
                        datobj.parcellation = parcs{p};
                        pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                        sessd = CHPC.staticSessionData(datobj);
                        CHPC.pullFromChpc(sessd);
                        this = FDGKineticsParc(sessd, 'mask', '');
                        row = 2*d + v + 2*length(dth.dns)*(p-1);
                        this.writetable('fileprefix', fp, 'Range', sprintf('A%i:U%i', row, row), 'writeHeader', 1==d&&1==v&&1==p);
                        popd(pwd1);
                    end
                end
            end
            popd(pwd0);
        end
        function summary = godo3(datobj)
            import mlraichle.*;
            sessd = CHPC.staticSessionData(datobj);
            summary = FDGKineticsParc.godo2(sessd);
        end
        function summary = godo2(sessd)
            try
                import mlraichle.*;
                [m,sessd] = FDGKineticsParc.godoMasks(sessd);
                fprintf('FDGKineticsParc.godo2:  returned from godoMasks\n');
                pwd0 = pushd(sessd.vLocation);
                this = FDGKineticsParc(sessd, 'mask', m, 'hct', sessd.hct);
                summary.(m.fileprefix) = this.doBayes;
                fprintf('FDGKineticsParc.godo2:  returned from doBayes\n');
                popd(pwd0);
            catch ME
                fprintf('%s\n', ME.identifier);
                fprintf('%s\n', ME.message);
                fprintf('%s\n', struct2str(ME.stack));
                handwarning(ME);
            end
        end
        function state = godo(sessd)
            try
                import mlraichle.*;                
                for p = 1:length(FDGKineticsParc.PARCS)
                    sessd.parcellation = FDGKineticsParc.PARCS{p};
                    [m,sessd] = FDGKineticsParc.godoMasks(sessd);
                    sessd.selectedMask = ''; %% KLUDGE
                    assert(isdir(sessd.vLocation));
                    pwd0 = pushd(sessd.vLocation);
                    this = FDGKineticsParc(sessd, 'mask', m);
                    state.(m.fileprefix) = this.doBayes;
                    popd(pwd0);
                end
            catch ME
                handwarning(ME);
            end
        end
        function godoPlots(sessd)            
            try
                import mlraichle.*;
                [m,sessd] = FDGKineticsParc.godoMasks(sessd);
                assert(isdir(sessd.vLocation));
                pwd0 = pushd(sessd.vLocation);
                this = FDGKineticsParc(sessd, 'mask', m);
                state = this.stateOfBayes; this = state.this;
                this.plotAnnealing;
                this.plot;
                saveFigures(sprintf('fig_%s_%s', strrep(class(this), '.','_'), sessd.parcellation));
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function [m,sessd,ct4rb] = godoMasks(sessd)
            import mlraichle.*;
            assert(isa(sessd, 'mlraichle.SessionData'));
            [m, sessd,ct4rb] = FDGKineticsWholebrain.godoMasks(sessd);            
            pwd0 = pushd(sessd.vLocation); 
            if (strcmp(sessd.parcellation(1), 'y'))
                m = FDGKineticsParc.yeoMask(sessd, sessd.parcellation);
            elseif (~isempty(sessd.parcellation))
                m = FDGKineticsParc.aparcAseg(sessd, ct4rb, sessd.parcellation);
            end
            popd(pwd0);
        end
        
        function aa = aparcAseg(sessd, ct4rb, parc)
            if (~lexist('aparcAseg_op_fdg.4dfp.ifh', 'file'))
                aa = sessd.aparcAseg('typ', 'mgz');
                aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
                aa = mybasename(aa);
                sessd.nifti_4dfp_4(aa);
                aa = ct4rb.t4img_4dfp(sessd.brainmask('typ','fp'), aa, 'opts', '-n');
                aa = mlfourd.ImagingContext([aa '.4dfp.ifh']);
                nn = aa.numericalNiftid;
                aa.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.ifh']);
            else                
                aa = mlfourd.ImagingContext('aparcAseg_op_fdg.4dfp.ifh');
                nn = aa.numericalNiftid;
            end
            
            ids = mlraichle.FDGKineticsParc.(parc);
            ff  = nn.false;
            for i = 1:length(ids)
                ff  = ff | (nn == ids(i));
            end
            ff  = ff.binarized;
            ff.fileprefix = [aa.fileprefix '_' parc];
            aa  = mlfourd.ImagingContext(ff);
        end
        function ym = yeoMask(sessd, parc)
            %% YEOMASK creates masks in memory only
                       
            import mlraichle.*;
            [mat_mni,ct4rb_mni,bmNii] = FDGKineticsParc.resolveMNI152(sessd);
            y                         = FDGKineticsParc.resolveYeo7(sessd, mat_mni, ct4rb_mni, bmNii); 
            nn                        = y.numericalNiftid;
            
            id = FDGKineticsParc.(parc);
            nn = (nn == id);
            nn = nn.binarized;
            nn.fileprefix = [nn.fileprefix '_' parc];
            ym = mlfourd.ImagingContext(nn);
        end
        function [mat,ct4rb,bmr2Nii] = resolveMNI152(sessd)
            fv = mlfourdfp.FourdfpVisitor;
            bm    = fv.ensureSafeOp('brainmaskr2_op_fdg');
            bmNii = [bm '.nii.gz'];
            if (~lexist(bmNii, 'file'))
                sessd.nifti_4dfp_n(bm);
            end
            %if (~lexist_4dfp(bm))
            %    sessd.nifti_4dfp_4(bm);
            %end
                     
            fdgBrain = fv.ensureSafeOn([sessd.tracerResolvedSumt1('typ','fp') '_brain']); % created by FDGKineticsWholebrain.godoMasks?
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgBrain mybasename(bmNii)}, ...
                'resolveTag', 'op_fdg');            
            mni = fullfile(getenv('PPG'), 'jjlee2', 'FSL_MNI152_FreeSurferConformed_1mm.nii.gz');
            mniResolved = 'MNI152_op_fdg.nii.gz';
            bmr2Nii = [bm 'r2_op_fdg.nii.gz'];
            mat = [mybasename(mniResolved) '.mat'];
            if (lexist(mat, 'file') && ...
                lexist_4dfp(mybasename(bmr2Nii)) && ...
                lexist_4dfp(mybasename(mniResolved)))
                return
            end
            
            ct4rb.resolve;     
            
            sessd.nifti_4dfp_n(mybasename(bmr2Nii));
            mlbash(sprintf('flirt -in %s -ref %s -out %s -omat %s -cost normmi -dof 12', ...
                mni, bmr2Nii, mniResolved, mat)); 
            sessd.nifti_4dfp_4(mybasename(bmr2Nii));
            sessd.nifti_4dfp_4(mybasename(mniResolved));           
        end
        function y = resolveYeo7(~, mat, ~, bmr2Nii)
            ymni = fullfile(getenv('PPG'), 'jjlee2', 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii.gz');
            yNii = 'Yeo7_op_fdg.nii.gz';
            
            mlbash(sprintf('flirt -in %s -ref %s -applyxfm -init %s -out %s -interp nearestneighbour', ymni, bmr2Nii, mat, yNii));  
            
            y = mlfourd.ImagingContext(yNii);
            y.fourdfp;
            y.save;
        end
        
        function teardown(sessd)
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

