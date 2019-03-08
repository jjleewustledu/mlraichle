classdef FDGKineticsParc < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSPARC  

	%  $Revision$
 	%  was created 17-Feb-2017 07:41:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Constant)
        
        PARCS = {'striatum' 'thalamus' 'cerebellum' 'brainstem' 'ventralDC' 'white' 'amygdala' 'hippocampus' ...
                 'yeo1' 'yeo2' 'yeo3' 'yeo4' 'yeo5' 'yeo6' 'yeo7'}; % N=15
                
        %% aparc+aseg
        
 		striatum   = [11 50 12 51 13 52] % caudate, putamen, pallidus
        thalamus   = [10 49]
        cerebellum = [7 46 8 47]
        brainstem  = 16
        ventralDC  = [28 60 26 58] % ventral DC, accumbens
        white      = [2 41]
        amygdala   = [18 54]
        hippocampus = [17 53]        
        
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
            tic
            diary on   
            
            import mlraichle.*;
            ip = inputParser;
            addOptional(ip, 'dirToolArg', 'HYGLY28*', @ischar);
            addOptional(ip, 'vs', 2:2, @isnumeric);
            addParameter(ip, 'sessionDate', nat, @isdatetime);
            addParameter(ip, 'parcs', FDGKineticsParc.PARCS, @iscell);
            parse(ip, varargin{:});                     
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            dthDns = dth.dns; % for parfor
            parcs  = ip.Results.parcs;
            jobs   = cell(length(dth.dns), 2);
            c      = myparcluster;
            for d = 1:length(dth.dns)
                for p = 1:length(parcs)  
                    datobj = struct('sessionFolder', dthDns{d}, 'sessionDate', ip.Results.sessionDate, 'parcellation', parcs{p});
                    try
                        pwd1 = pushd(fullfile(dthDns{d}, ''));
                        %CHPC4FdgKinetics.pushData0(datobj);
                        jobs{d,v} = c.batch(@mlraichle.FDGKineticsParc.godo3, 1, {datobj});
                        popd(pwd1);
                    catch ME
                        dispwarning(ME);                        
                    end
                end
            end
            popd(pwd0);
            
            diary off
            toc
        end
        function jobs = godoWilliam(varargin)
            tic 
            diary on
            
            import mlraichle.*;
            ip = inputParser;
            addOptional(ip, 'dirToolArg', 'HYGLY28*', @ischar);
            addOptional(ip, 'vs', 2:2, @isnumeric);
            addParameter(ip, 'sessionDate', nat, @isdatetime);
            parse(ip, varargin{:});                     
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            dthDns = dth.dns; % for parfor
            parcs  = FDGKineticsParc.PARCS;
            jobs = cell(length(dth.dns), 2);
            for d = 1:length(dth.dns)
                for p = 1:length(parcs)
                    datobj = struct('sessionFolder', dthDns{d}, 'sessionDate', ip.Results.sessionDate, 'parcellations', parcs{p});
                    try
                        pwd1 = pushd(fullfile(dthDns{d},  ''));
                        jobs{d} = FDGKineticsParc.godo3(datobj);
                        saveFigures(sprintf('fig_%s', mydatetimestr(now)));                       
                        popd(pwd1);                    
                    catch ME
                        dispwarning(ME);                        
                    end
                end
            end
            popd(pwd0);
            
            diary off
            toc        
        end
        function goPlotOnWilliam
            import mlraichle.*;
            parcs  = FDGKineticsParc.PARCS;             
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for p = 1:length(parcs)
                    datobj.parcellation = parcs{p};
                    sessd = SessionData.struct2sessionData(datobj);
                    FDGKineticsParc.godoPlots(sessd);
                end
            end
            popd(pwd0);
        end
        function goWritetable(varargin)
            ip = inputParser;
            addOptional(ip, 'pullData0', true, @islogical);
            parse(ip, varargin{:});
            
            import mlraichle.*;
            parcs  = FDGKineticsParc.PARCS;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            fqfp   = fullfile(pwd0, sprintf('mlraiche_FDGKineticsParc_goWritetable_%s', mydatetimestr(now)));
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for p = 1:length(parcs)
                    datobj.parcellation = parcs{p};
                    pwd1 = pushd(fullfile(dth.dns{d}, ''));
                    sessd = SessionData.struct2sessionData(datobj);
                    if (ip.Results.pullData0)
                        CHPC4FdgKinetics.pullData0(sessd);
                    end
                    this = FDGKineticsParc.load(sprintf('mlraichle_FDGKineticsParc_%s.mat', datobj.parcellation));
                    if (isempty(this.sessionData.bloodGlucoseAndHct)) %% KLUDGE:   not sure why this is not in this.
                        this.sessionData.bloodGlucoseAndHct = BloodGlucoseAndHct( ...
                            fullfile(this.sessionData.subjectsDir, this.sessionData.bloodGlucoseAndHctXlsx));
                    end
                    row = 2*d + 2*length(dth.dns)*(p-1);
                    try
                        this.writetable('fqfp', fqfp, 'Range', sprintf('A%i:V%i', row, row), 'writeHeader', 1==d && 1==p);
                    catch ME
                        handwarning(ME);
                    end
                    popd(pwd1);
                end
            end
            popd(pwd0);
        end
        function [datobj,this] = godo3(sessStruct)
            import mlraichle.*;
            sessd = SessionData.struct2sessionData(sessStruct);
            [datobj,this] = FDGKineticsParc.godo2(sessd);
        end
        function [datobj,this] = godo2(sessobj, varargin)
            try
                import mlraichle.*;
                if (isstruct(sessobj))
                    sessobj = SessionData.struct2sessionData(sessobj);
                end
                assert(isdir(sessobj.tracerLocation));
                pwd0 = pushd(sessobj.tracerLocation);
                [m,sessobj] = FDGKineticsParc.godoMasks(sessobj);
                this = FDGKineticsParc.factory(sessobj, 'mask', m);
                datobj.(m.fileprefix) = this.doItsBayes(varargin{:});
                popd(pwd0);
            catch ME
                dispwarning(ME);
            end
        end
        function state = godo(sessd)
            try
                import mlraichle.*;                
                for p = 1:length(FDGKineticsParc.PARCS)
                    sessd.parcellation = FDGKineticsParc.PARCS{p};
                    [m,sessd] = FDGKineticsParc.godoMasks(sessd);
                    sessd.selectedMask = ''; %% KLUDGE
                    assert(isdir(sessd.tracerLocation));
                    pwd0 = pushd(sessd.tracerLocation);
                    this = FDGKineticsParc(sessd, 'mask', m);
                    state.(m.fileprefix) = this.doItsBayes;
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
                assert(isdir(sessd.sessionPath));
                pwd0 = pushd(sessd.sessionPath);
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
            pwd0 = pushd(sessd.sessionPath); 
            if (strcmp(sessd.parcellation(1), 'y'))
                m = FDGKineticsParc.yeoMask(sessd, sessd.parcellation);
            elseif (~isempty(sessd.parcellation))
                m = FDGKineticsParc.aparcAseg(sessd, ct4rb, sessd.parcellation);
            end
            popd(pwd0);
        end
        
        function aa = aparcAseg(sessd, ct4rb, parc)
            if (~lexist('aparcAseg_op_fdg.4dfp.hdr', 'file'))
                aa = sessd.aparcAseg('typ', 'mgz');
                aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
                aa = mybasename(aa);
                sessd.nifti_4dfp_4(aa);
                t4 = sprintf('%s_to_%s_t4', sessd.brainmask('typ','fp'), ct4rb.resolveTag);
                aa = ct4rb.t4img_4dfp(t4, aa, 'options', '-n');
                aa = mlfourd.ImagingContext([aa '.4dfp.hdr']);
                nn = aa.numericalNiftid;
                aa.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.hdr']);
            else                
                aa = mlfourd.ImagingContext('aparcAseg_op_fdg.4dfp.hdr');
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
            bm    = fv.ensureSafeFileprefix('brainmaskr2_op_fdg');
            bmNii = [bm '.nii.gz'];
            if (~lexist(bmNii, 'file'))
                sessd.nifti_4dfp_n(bm);
            end
            %if (~lexist_4dfp(bm))
            %    sessd.nifti_4dfp_4(bm);
            %end
                     
            fdgBrain = fv.ensureSafeFileprefix([sessd.tracerResolvedSumt1('typ','fp') '_brain']); % created by FDGKineticsWholebrain.godoMasks?
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgBrain mybasename(bmNii)}, ...
                'resolveTag', 'op_fdg');            
            mni = fullfile(mlraichle.RaichleRegistry.instance.YeoDir, 'FSL_MNI152_FreeSurferConformed_1mm.nii.gz');
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
            ymni = fullfile(mlraichle.RaichleRegistry.instance.YeoDir,'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_LiberalMask.nii.gz');
            yNii = 'Yeo7_op_fdg.nii.gz';            
            if (~lexist('Yeo7_op_fdg.4dfp.hdr', 'file'))
                mlbash(sprintf('flirt -in %s -ref %s -applyxfm -init %s -out %s -interp nearestneighbour', ymni, bmr2Nii, mat, yNii));
                y = mlfourd.ImagingContext(yNii);
                y.fourdfp;
                y.save;
                return
            end
            
            y = mlfourd.ImagingContext('Yeo7_op_fdg.4dfp.hdr');
        end
        function this = factory(varargin)
            fn = sprintf('mlraichle_FDGKineticsParc_this.mat');
            if (strcmp(getenv('UNITTESTING'), 'true') && lexist(fn, 'file'))
                load(fn, 'this');
                return
            end
            this = mlraichle.FDGKineticsParc(varargin{:});
            this.saveas(fn);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

