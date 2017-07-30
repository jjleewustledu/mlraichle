classdef FDGKineticsWholebrain < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSWHOLEBRAIN  

	%  $Revision$
 	%  was created 17-Feb-2017 07:19:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties (Constant)
        REUSE_APARCASEG = true
 		REUSE_BRAINMASK = true
 	end

	methods
 		function this = FDGKineticsWholebrain(varargin)
 			%% FDGKINETICSWHOLEBRAIN
 			%  Usage:  this = FDGKineticsWholebrain()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
            this.sessionData.parcellation = 'wholebrain';
 		end
    end 

    methods (Static)
        function this = goConstructKinetics(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            
            try
                pwd1 = pushd(ip.Results.sessionData.vLocation);
                this = mlraichle.CHPC.batchSerial(@mlraichle.FDGKineticsWholebrain.godo__, 1, {ip.Results.sessionData});
                popd(pwd1);
            catch ME
                handwarning(ME, struct2str(ME.stack));
            end
        end
        
        function jobs = godoChpcPart(varargin)
            diary on   
            
            import mlraichle.*;
            ip = inputParser;
            addOptional(ip, 'dirToolArg', 'HYGLY2*', @ischar);
            addOptional(ip, 'vs', 1:2, @isnumeric);
            parse(ip, varargin{:});                     
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            jobs   = {};
            if (hostnameMatch('ophthalmic'))
                c = parcluster('chpc_remote_r2016b');
            elseif (hostnameMatch('william'))
                c = parcluster('chpc_remote_r2016a');
            else
                error('mlraichle:unsupportedHost', 'FDGKineticsWholebrain.godoChpc.hostname->%s', hostname);
            end
            ClusterInfo.setEmailAddress('jjlee.wustl.edu@gmail.com');
            ClusterInfo.setMemUsage('32000');
            ClusterInfo.setWallTime('02:00:00');
            %ClusterInfo.setPrivateKeyFile('~/id_rsa.pem');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = ip.Results.vs
                    datobj.vnumber = v;
                    try
                        pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                        %CHPC.pushToChpc(datobj);
                        j = c.batch(@mlraichle.FDGKineticsWholebrain.godo3, 1, {datobj});
                        jobs = [jobs j]; %#ok<AGROW>
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
            jobs   = {};
            if (hostnameMatch('ophthalmic'))
                c = parcluster('chpc_remote_r2016b');
            elseif (hostnameMatch('william'))
                c = parcluster('chpc_remote_r2016a');
            else
                error('mlraichle:unsupportedHost', 'FDGKineticsWholebrain.godoChpc.hostname->%s', hostname);
            end
            ClusterInfo.setEmailAddress('jjlee.wustl.edu@gmail.com');
            ClusterInfo.setMemUsage('32000');
            ClusterInfo.setWallTime('02:00:00');
            %ClusterInfo.setPrivateKeyFile('~/.ssh/id_rsa');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    try
                        pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                        %CHPC.pushToChpc(datobj);
                        j = c.batch(@mlraichle.FDGKineticsWholebrain.godo3, 1, {datobj});
                        jobs = [jobs j]; %#ok<AGROW>
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
            dth    = mlsystem.DirTools({'HYGLY1*' 'HYLGY0*'});
            dthDns = dth.dns;
            sessions = cell(length(dth.dns), 2);
            parfor d = 1:length(dth.dns)
                datobj = struct('sessionFolder', '', 'vnumber', []);
                datobj.sessionFolder = dthDns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    pwd1 = pushd(fullfile(dthDns{d}, sprintf('V%i', v), ''));
                    %sessions{d,v} = FDGKineticsWholebrain.godo3(datobj);
                    FDGKineticsWholebrain.godoMasksOnly(datobj);
                    saveFigures(sprintf('fig_%s', datestr(now,30)));
                    popd(pwd1);
                end
            end
            popd(pwd0);
            
            toc
        end
        function goPlotOnWilliam
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    sessd = CHPC.staticSessionData(datobj);
                    FDGKineticsWholebrain.godoPlots(sessd);
                end
            end
            popd(pwd0);
        end
        function goWritetable
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            fqfp   = fullfile(pwd0, sprintf('mlraiche_FDGKineticsWholebrain_goWritetable_%s', datestr(now, 30)));
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                for v = 1:2
                    datobj.vnumber = v;
                    pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                    sessd = CHPC.staticSessionData(datobj);
                    CHPC.pullFromChpc(sessd);
                    this = FDGKineticsWholebrain.load('mlraichle_FDGKineticsWholebrain_.mat');
                    try
                        this.writetable('fqfp', fqfp, 'Range', sprintf('A%i:V%i', 2*d+v, 2*d+v), 'writeHeader', 1==d&&1==v);
                    catch ME
                        handwarning(ME);
                    end
                    popd(pwd1);
                end
            end
            popd(pwd0);
        end
        function godoMasksOnly(datobj)
            import mlraichle.*;
            sessd = CHPC.staticSessionData(datobj);
            try
                import mlraichle.*;
                FDGKineticsWholebrain.godoMasks(sessd);
                fprintf('FDGKineticsWholebrain.godoMasksOnly:  returned from godoMasks\n');
            catch ME
                fprintf('%s\n', ME.identifier);
                fprintf('%s\n', ME.message);
                fprintf('%s\n', struct2str(ME.stack));
                handwarning(ME);
            end
        end
        function this = godo__(sessd)
            import mlraichle.*;
            sessd = CHPC.staticSessionData(sessd);
            [m,sessd] = FDGKineticsWholebrain.godoMasks(sessd);
            this = FDGKineticsWholebrain(sessd, 'mask', m);
            this = this.doItsBayes;
        end
        function summary = godo3(datobj)
            import mlraichle.*;
            sessd = CHPC.staticSessionData(datobj);
            summary = FDGKineticsWholebrain.godo2(sessd);
        end
        function summary = godo2(sessd)
            try
                import mlraichle.*;
                [m,sessd] = FDGKineticsWholebrain.godoMasks(sessd);
                fprintf('FDGKineticsWholebrain.godo2:  returned from godoMasks\n');
                pwd0 = pushd(sessd.vLocation);
                this = FDGKineticsWholebrain(sessd, 'mask', m);
                summary.(m.fileprefix) = this.doItsBayes;
                fprintf('FDGKineticsWholebrain.godo2:  returned from doItsBayes\n');
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
                [m,sessd] = FDGKineticsWholebrain.godoMasks(sessd);
                assert(isdir(sessd.vLocation));
                pwd0 = pushd(sessd.vLocation);
                this = FDGKineticsWholebrain(sessd, 'mask', m);
                state = this.doItsBayes;
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function godoPlots(sessd)
            try
                import mlraichle.*;
                [~,sessd] = FDGKineticsWholebrain.godoMasks(sessd);
                assert(isdir(sessd.vLocation));
                pwd0 = pushd(sessd.vLocation);
                this = FDGKineticsWholebrain.load( ...
                    fullfile(sessd.vLocation, sprintf('mlpowers_FDGKineticsWholebrain_%s', sessd.parcellation)), 'this');
                this.plotAnnealing;
                this.plot;
                saveFigures(sprintf('fig_%s_wholebrain', strrep(class(this), '.','_')));
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        function [m, sessd,ct4rb] = godoMasks(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            try
                import mlraichle.*;
                assert(isdir(sessd.vLocation));
                pwd0 = pushd(sessd.vLocation);
                [~,msktn] = FDGKineticsWholebrain.mskt(sessd);
                [~,ct4rb] = FDGKineticsWholebrain.brainmaskBinarized(sessd, msktn);                
                m = FDGKineticsWholebrain.aparcAsegBinarized(sessd, ct4rb);
                sessd.selectedMask = [m.fqfp '.4dfp.ifh'];
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end
        
        function [m,n] = mskt(sessd)
            import mlfourdfp.*;
            f = [sessd.tracerResolved1('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeFileprefix(f));
            if (lexist([f1 '_mskt.4dfp.ifh'], 'file') && lexist([f1 '_msktNorm.4dfp.ifh'], 'file'))
                m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
                n = mlfourd.ImagingContext([f1 '_msktNorm.4dfp.ifh']);
                return
            end
            
            lns_4dfp(f, f1);
            
            ct4rb = CompositeT4ResolveBuilder('sessionData', sessd);
            ct4rb.msktgenImg(f1);          
            m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
            n = m.numericalNiftid;
            n.img = n.img/n.dipmax;
            n.fileprefix = [f1 '_msktNorm'];
            n.filesuffix = '.4dfp.ifh';
            n.save;
            n = mlfourd.ImagingContext(n);
        end
        function [b,ct4rb] = brainmaskBinarized(sessd, msktNorm)
            fdgSumt = mlpet.PETImagingContext(sessd.tracerResolvedSumt1('typ','fqfn'));
            if (~lexist([sessd.tracerResolvedSumt1('typ','fp') '_brain.4dfp.ifh'], 'file'))
                fnii = fdgSumt.numericalNiftid;
                msktNorm = mlfourd.ImagingContext(msktNorm);
                mnii = msktNorm.numericalNiftid;
                fnii = fnii.*mnii;
                fdgSumt = mlpet.PETImagingContext(fnii);
                fdgSumt.filepath = pwd;
                fdgSumt.fileprefix = [sessd.tracerResolvedSumt1('typ','fp') '_brain'];
                fdgSumt.filesuffix = '.4dfp.ifh';
                fdgSumt.save;
            end
            
            brainmask = mlfourd.ImagingContext(sessd.brainmask);
            if (~lexist('brainmask.4dfp.ifh', 'file'))
                brainmask.fourdfp;
                brainmask.filepath = pwd;
                brainmask.save;
                if (lexist('brainmask.nii')); gzip('brainmask.nii'); end
            end
            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgSumt.fileprefix brainmask.fileprefix});
            if (mlraichle.FDGKineticsWholebrain.REUSE_BRAINMASK && ...
                lexist(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh'], 'file'))
                b = mlpet.PETImagingContext(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
                return
            end
            ct4rb = ct4rb.resolve;
            b = ct4rb.product{2};
            b.numericalNiftid;
            b.saveas(['brainmask_' ct4rb.resolveTag '.4dfp.ifh']);
            b = b.binarizeBlended;
            b.saveas(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
        end
        function aa = aparcAsegBinarized(sessd, ct4rb)
            if (mlraichle.FDGKineticsWholebrain.REUSE_APARCASEG && ...
                lexist('aparcAsegBinarized_op_fdg.4dfp.ifh', 'file'))
                aa = mlpet.PETImagingContext('aparcAsegBinarized_op_fdg.4dfp.ifh');
                return
            end
            
            aa = sessd.aparcAseg('typ', 'mgz');
            aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
            aa = mybasename(aa);
            sessd.nifti_4dfp_4(aa);
            aa = ct4rb.t4img_4dfp( ...
                sessd.brainmask('typ','fp'), aa, 'opts', '-n');
            aa = mlpet.PETImagingContext([aa '.4dfp.ifh']);
            nn = aa.numericalNiftid;
            nn.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.ifh']);
            nn = nn.binarized; % set threshold to intensity floor
            nn.saveas(['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.ifh']);
            aa = mlfourd.ImagingContext(nn);
        end
        
        function teardown(sessd)
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

