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
        function sessd = staticSessionData(datobj)
            import mlraichle.*;
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, datobj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, 'sessionPath', sessp, ...
                                'tracer', 'FDG', 'ac', true, 'vnumber', datobj.vnumber);  
            if (isfield(datobj, 'parcellation') && ~isempty(datobj.parcellation))
                sessd.parcellation = datobj.parcellation;
            end
        end
        function c     = staticChpc(datobj)
            c = mldistcomp.CHPC( ...
                mlraichle.FDGKineticsParc.staticSessionData(datobj));
        end
        
        function jobs = godoChpc
            
            diary on
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            parcs  = FDGKineticsParc.PARCS;
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
                    pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                    FDGKineticsParc.pushToChpc(datobj);
                    for p = 1:length(parcs)
                        datobj.parcellation = parcs{p};
                        j = c.batch(@mlraichle.FDGKineticsParc.godo3, 1, {datobj});
                        jobs = [jobs j]; %#ok<AGROW>
                    end
                    popd(pwd1);
                end
            end
            save('mlraichle_FDGKineticsParc_godoChpc_jobs', 'jobs');
            popd(pwd0);
        end
        function sessions = godoWilliam
            tic 
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            parcs  = FDGKineticsParc.PARCS;
            sessions = cell(length(dth.dns), 2);
            for d = 1:1 % length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:1
                    datobj.vnumber = v;
                    pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                    states = {};
                    for p = 7:7 % length(parcs)
                        datobj.parcellation = parcs{p};
                        s = FDGKineticsParc.godo3(datobj);
                        states = [states s]; %#ok<AGROW>
                    end
                    popd(pwd1);
                    sessions{d,v} = states;
                end
            end
            popd(pwd0);
            
            toc
        end
        function pushToChpc(datobj)
            
            import mlraichle.* mlraichle.FDGKineticsParc.*;
            sessd           = FDGKineticsParc.staticSessionData(datobj);
            chpc            = mldistcomp.CHPC(sessd); 
            sessdr1         = sessd; sessdr1.rnumber = 1;
            chpcVPth        = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, '');
            chpcFdgPth      = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, ...
                              sessd.tracerLocation('typ', 'folder'), '');
            chpcListmodePth = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, ...
                              sessd.tracerConvertedLocation('typ','folder'), ...
                              sessd.tracerListmodeLocation('typ','folder'), '');
            chpcMriPth      = fullfile(chpc.freesurferLocation, ...
                              sprintf('%s_%s', sessd.sessionFolder, sessd.vfolder), 'mri', '');
            
            chpc.scpToChpc(sessd.CCIRRadMeasurementsTable, chpcVPth);
            
            chpc.sshMkdir(chpcMriPth);
            chpc.scpToChpc(sessd.brainmask('typ','mgz'), chpcMriPth);
            chpc.scpToChpc(sessd.aparcAseg('typ','mgz'), chpcMriPth);
            chpc.scpToChpc(fullfile(sessd.mriLocation, 'T1.mgz'), chpcMriPth);
            
            chpc.sshMkdir(chpcFdgPth);
            chpc.scpToChpc([sessdr1.tracerResolved1(    'typ','fqfp') '.4dfp.*'], chpcFdgPth);
            chpc.scpToChpc([sessdr1.tracerResolvedSumt1('typ','fqfp') '.4dfp.*'], chpcFdgPth); 
            
            chpc.sshMkdir(chpcListmodePth);
            chpc.scpToChpc(sessdr1.tracerListmodeMhdr, chpcListmodePth);           
        end
        function pullFromChpc(sessd)
        end
        function summary = godo3(datobj)
            import mlraichle.*;
            sessd = FDGKineticsParc.staticSessionData(datobj);
            summary = FDGKineticsParc.godo2(sessd);
        end
        function summary = godo2(sessd)
            try
                import mlraichle.*;
                [m,sessd] = FDGKineticsParc.godoMasks(sessd);
                fprintf('FDGKineticsParc.godo2:  returned from godoMasks\n');
                pwd0 = pushd(sessd.vLocation);
                summary.(m.fileprefix) = FDGKineticsParc.doBayes(sessd, m);
                fprintf('FDGKineticsParc.godo2:  returned from godoBayes\n');
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
                    state.(m.fileprefix) = FDGKineticsParc.doBayes(sessd, m);
                    popd(pwd0);
                end
            catch ME
                handwarning(ME);
            end
        end
        function [m,sessd,ct4rb] = godoMasks(sessd)
            import mlraichle.*;
            assert(isa(sessd, 'mlraichle.SessionData'));
            [sessd,ct4rb] = FDGKineticsWholebrain.godoMasks(sessd);            
            pwd0 = pushd(sessd.vLocation); 
            if (strcmp(sessd.parcellation(1), 'y'))
                m = FDGKineticsParc.yeoMask(sessd, sessd.parcellation);
            else
                m = FDGKineticsParc.aparcAseg(sessd, ct4rb, sessd.parcellation);
            end
            popd(pwd0);
        end
        function state = doBayes(sessd, mask)
            tic
            
            assert(isa(sessd, 'mlraichle.SessionData'));
            import mlpet.* mlraichle.*;
            this = FDGKineticsParc(sessd, 'mask', mask);
            fprintf('FDGKineticsParc.doBayes:  returned from FDGKineticsParc\n');
            fprintf('                          mask -> %s\n', mask.fqfilename);
            this.showAnnealing = false;
            this.showBeta      = false;
            this.showPlots     = false;
            this               = this.estimateParameters;
            fprintf('FDGKineticsParc.doBayes:  returned from estimateParameters\n');
            %this.plot;
            mnii = mlfourd.MaskingNIfTId(mask.niftid);
            
            state.this = this;
            state.fileprefix = ['mlraichle_FDGKineticsParc_doBayes_state_' sessd.parcellation];
            state.bestFitParams = this.bestFitParams;
            state.meanParams = this.meanParams;
            state.stdParams  = this.stdParams;
            state.kmin = this.kmin;
            state.chi = this.kmin(1)*this.kmin(3)/(this.kmin(2) + this.kmin(3));
            state.Kd = 100*this.v1*this.kmin(1);
            state.CMR = (this.v1/0.0105)*state.chi;
            state.maskCount = mnii.count;
            state.tracerLocation = sessd.tracerLocation;
            state.parcellation = sessd.parcellation;
            save([state.fileprefix '.mat'], 'state');
            
            lg = mlpipeline.Logger(state.fileprefix);
            lg.add('\n%s is working in %s\n', mfilename, pwd);
            lg.add('fileprefix -> %s\n', state.fileprefix);            
            lg.add('bestFitParams / s^{-1} -> %s\n', mat2str(state.bestFitParams));
            lg.add('meanParams / s^{-1} -> %s\n', mat2str(state.meanParams));
            lg.add('stdParams / s^{-1} -> %s\n', mat2str(state.stdParams)); 
            lg.add('[k_1 ... k_4] / min^{-1} -> %s\n', mat2str(state.kmin));
            lg.add('chi = frac{k_1 k_3}{k_2 + k_3} / min^{-1} -> %s\n', mat2str(state.chi));
            lg.add('Kd = K_1 = V_B k1 / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(state.Kd)); 
            lg.add('CMRglu/[glu] = V_B chi / (mL min^{-1} (100g)^{-1}) -> %s\n', mat2str(state.CMR));
            lg.add('mnii.count -> %i\n', state.maskCount);
            lg.add('sessd.tracerLocation -> %s\n', state.tracerLocation);
            lg.add('sessd.parcellation -> %s\n', state.parcellation);
            lg.add('\n');
            lg.save;                      
            
            toc
        end
        function appendState(fname, state)
            if (~lstrfind(fname, '.mat'))
                fname = [fname '.mat'];
            end
            state1 = state;
            fields1 = fieldnames(state1);
            load(fname, 'state');
            for f = 1:length(fields1)
                if (~isfield(state, fields1{f}))
                    state.(fields1{f}) = state1.(fields1{f});
                end
            end
            save(fname, 'state');
        end
        function saveState(fname, state)
            if (isempty(fname) || isempty(state))
                return
            end
            if (~lstrfind(fname, '.mat'))
                fname = [fname '.mat'];
            end
            save(fname, 'state');
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

