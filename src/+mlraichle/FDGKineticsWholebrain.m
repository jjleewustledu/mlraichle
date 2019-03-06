classdef FDGKineticsWholebrain < mlraichle.F18DeoxyGlucoseKinetics
	%% FDGKINETICSWHOLEBRAIN has factories named godo*.

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

    methods (Static)
        function this = constructKinetics(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});
            
            try
                import mlraichle.*;
                pwd1 = pushd(ip.Results.sessionData.sessionPath);
                this = CHPC4FdgKinetics.batchSerial(@mlraichle.FDGKineticsWholebrain.godo__, 1, {ip.Results.sessionData});
                popd(pwd1);
            catch ME
                dispwarning(ME);
            end
        end
        function jobs = godoChpcPart(varargin)
            tic
            diary on   
            
            import mlraichle.*;
            ip = inputParser;
            addOptional(ip, 'dirToolArg', 'HYGLY28*', @ischar);
            addOptional(ip, 'vs', 2:2, @isnumeric);
            addParameter(ip, 'sessionDate', nat, @isdatetime);
            addParameter(ip, 'service', myparcluster);
            parse(ip, varargin{:}); 
            c = ip.Results.service;                    
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            dthDns = dth.dns; % for parfor
            jobs   = cell(length(dth.dns), 2);
            for d = 1:length(dth.dns)
                datobj = struct('sessionFolder', dthDns{d}, 'sessionDate', ip.Results.sessionDate);
                try
                    pwd1 = pushd(fullfile(dthDns{d}, sprintf('V%i', v), ''));

                    %CHPC4FdgKinetics.pushData0(datobj);
                    c.batch(@mlraichle.FDGKineticsWholebrain.godoMasksOnly, 1, {datobj});
                    jobs{d,v} = c.batch(@mlraichle.FDGKineticsWholebrain.godo3, 1, {datobj});

                    popd(pwd1);
                catch ME
                    dispwarning(ME);                        
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
            addParameter(ip, 'service', []);
            parse(ip, varargin{:}); 
            c = ip.Results.service;                    
            
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool(ip.Results.dirToolArg);
            dthDns = dth.dns; % for parfor
            jobs   = cell(length(dth.dns), 2);
            for d = 1:length(dth.dns) 
                datobj = struct('sessionFolder', dthDns{d}, 'sessionDate', ip.Results.sessionDate);
                try
                    pwd1 = pushd(fullfile(dthDns{d}, sprintf('V%i', v), ''));

                    FDGKineticsWholebrain.godoMasksOnly(datobj);
                    jobs{d,v} = FDGKineticsWholebrain.godo3(datobj);
                    saveFigures(sprintf('fig_%s', datestr(now,30)));

                    popd(pwd1);                    
                catch ME
                    dispwarning(ME);                        
                end
            end
            popd(pwd0);
            
            diary off
            toc
        end
        function goPlotOnWilliam
            
            import mlraichle.*;
            studyd = StudyData;
            pwd0   = pushd(studyd.subjectsDir);
            dth    = mlsystem.DirTool('HYGLY2*');
            for d = 1:length(dth.dns)
                datobj.sessionFolder = dth.dns{d};
                sessd = SessionData.struct2sessionData(datobj);
                FDGKineticsWholebrain.godoPlots(sessd);
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
                pwd1 = pushd(fullfile(dth.dns{d}, sprintf('V%i', v), ''));
                sessd = SessionData.struct2sessionData(datobj);
                CHPC4FdgKinetics.pullData0(sessd); % previously built
                this = FDGKineticsWholebrain.load('mlraichle_FDGKineticsWholebrain_.mat');
                try
                    this.writetable('fqfp', fqfp, 'Range', sprintf('A%i:V%i', 2*d+v, 2*d+v), 'writeHeader', 1==d&&1==v);
                catch ME
                    dispwarning(ME);
                end
                popd(pwd1);
            end
            popd(pwd0);
        end
        
        function datobj = godo3(sessStruct)
            import mlraichle.*;
            sessd = SessionData.struct2sessionData(sessStruct);
            datobj = FDGKineticsWholebrain.godo2(sessd);
        end
        function datobj = godo2(varargin)
            import mlraichle.*;
            datobj = FDGKineticsWholebrain.godo(varargin{:});
        end
        function datobj = godo(varargin)
            import mlraichle.*;
            datobj = FDGKineticsWholebrain.godo__(varargin{:});
        end
        function datobj = godo__(sessobj, varargin)
            try
                import mlraichle.*;
                if (isstruct(sessobj))
                    sessobj = SessionData.struct2sessionData(sessobj);
                end
                assert(isdir(sessobj.tracerLocation));
                pwd0 = pushd(sessobj.tracerLocation);
                [m,sessobj] = FDGKineticsWholebrain.godoMasks(sessobj);
                this = FDGKineticsWholebrain.factory(sessobj, 'mask', m, varargin{:});
                this.fileprefix = 'mlraichle.FDGKineticsWholebrain_godo__';
                datobj.(m.fileprefix) = this.doItsBayes(varargin{:});
                popd(pwd0);
            catch ME
                dispwarning(ME);
            end
        end
        
        function [m, sessd,ct4rb] = godoMasks(sessd)
            assert(isa(sessd, 'mlraichle.SessionData'));
            try
                import mlraichle.*;
                assert(isdir(sessd.tracerLocation));
                pwd0 = pushd(sessd.tracerLocation);
                [~,msktn] = FDGKineticsWholebrain.mskt(sessd);
                [~,ct4rb] = FDGKineticsWholebrain.brainmaskBinarized(sessd, msktn);                
                m = FDGKineticsWholebrain.aparcAsegBinarized(sessd, ct4rb);
                sessd.selectedMask = [m.fqfp '.4dfp.hdr'];
                fprintf('mlraichle.FDGKineticsWholebrain.godoMasks:  completed work in %s\n', pwd);
                popd(pwd0);
            catch ME
                dispwarning(ME);
            end
        end
        function godoPlots(sessd)
            try
                import mlraichle.*;
                [~,sessd] = FDGKineticsWholebrain.godoMasks(sessd);
                assert(isdir(sessd.sessionPath));
                pwd0 = pushd(sessd.sessionPath);
                this = FDGKineticsWholebrain.load( ...
                    fullfile(sessd.sessionPath, sprintf('mlraichle_FDGKineticsWholebrain_%s', sessd.parcellation)), 'this');
                this.plotAnnealing;
                this.plot;
                saveFigures(sprintf('fig_%s_wholebrain', strrep(class(this), '.','_')));
                popd(pwd0);
            catch ME
                dispwarning(ME);
            end
        end
        
        function [m,n] = mskt(sessd)
            import mlfourdfp.*;
            f = [sessd.tracerResolved1('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeFileprefix(f));
            if (lexist([f1 '_mskt.4dfp.hdr'], 'file') && lexist([f1 '_msktNorm.4dfp.hdr'], 'file'))
                m = mlfourd.ImagingContext([f1 '_mskt.4dfp.hdr']);
                n = mlfourd.ImagingContext([f1 '_msktNorm.4dfp.hdr']);
                return
            end
            
            lns_4dfp(f, f1);
            
            ct4rb = CompositeT4ResolveBuilder('sessionData', sessd);
            ct4rb.msktgenImg(f1);          
            m = mlfourd.ImagingContext([f1 '_mskt.4dfp.hdr']);
            n = m.numericalNiftid;
            n.img = n.img/n.dipmax;
            n.fileprefix = [f1 '_msktNorm'];
            n.filesuffix = '.4dfp.hdr';
            n.save;
            n = mlfourd.ImagingContext(n);
        end
        function [b,ct4rb] = brainmaskBinarized(sessd, msktNorm)
            fdgSumt = mlpet.PETImagingContext(sessd.tracerResolvedSumt1('typ','fqfn'));
            if (~lexist([sessd.tracerResolvedSumt1('typ','fp') '_brain.4dfp.hdr'], 'file'))
                fnii = fdgSumt.numericalNiftid;
                msktNorm = mlfourd.ImagingContext(msktNorm);
                mnii = msktNorm.numericalNiftid;
                fnii = fnii.*mnii;
                fdgSumt = mlpet.PETImagingContext(fnii);
                fdgSumt.filepath = pwd;
                fdgSumt.fileprefix = [sessd.tracerResolvedSumt1('typ','fp') '_brain'];
                fdgSumt.filesuffix = '.4dfp.hdr';
                fdgSumt.save;
            end
            
            brainmask = mlfourd.ImagingContext(sessd.brainmask);
            if (~lexist('brainmask.4dfp.hdr', 'file'))
                brainmask.fourdfp;
                brainmask.filepath = pwd;
                brainmask.save;
                if (lexist('brainmask.nii')); gzip('brainmask.nii'); end
            end
            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgSumt.fileprefix brainmask.fileprefix});
            if (mlraichle.FDGKineticsWholebrain.REUSE_BRAINMASK && ...
                lexist(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.hdr'], 'file'))
                b = mlpet.PETImagingContext(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.hdr']);
                return
            end
            if (lexist(fullfile(sessd.tracerLocation, ['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.hdr']), 'file'))
                b = mlfourd.ImagingContext(fullfile(sessd.tracerLocation, ['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.hdr']));
                return
            end
            ct4rb = ct4rb.resolve;
            b = ct4rb.product{2};
            b.numericalNiftid;
            b.saveas(['brainmask_' ct4rb.resolveTag '.4dfp.hdr']);
            b = b.binarizeBlended;
            b.saveas(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.hdr']);
        end
        function aa = aparcAsegBinarized(sessd, ct4rb)
            if (mlraichle.FDGKineticsWholebrain.REUSE_APARCASEG && ...
                lexist(fullfile(sessd.tracerLocation, ['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.hdr']), 'file'))
                aa = mlfourd.ImagingContext(fullfile(sessd.tracerLocation, ['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.hdr']));
                return
            end
            
            aa = sessd.aparcAseg('typ', 'mgz');
            aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
            aa = mybasename(aa);
            sessd.nifti_4dfp_4(aa);
            t4 = sprintf('%s_to_%s_t4', sessd.brainmask('typ','fp'), ct4rb.resolveTag);
            aa = ct4rb.t4img_4dfp(t4, aa, 'options', '-n');
            aa = mlfourd.ImagingContext([aa '.4dfp.hdr']);
            nn = aa.numericalNiftid;
            nn.saveas(['aparcAseg_' ct4rb.resolveTag '.4dfp.hdr']);
            nn = nn.binarized; % set threshold to intensity floor
            nn.saveas(['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.hdr']);
            aa = mlfourd.ImagingContext(nn);
        end        
        
        function this = factory(varargin)
            fn = sprintf('mlraichle_FDGKineticsWholebrain_this.mat');
            if (strcmp(getenv('UNITTESTING'), 'true') && lexist(fn, 'file'))
                load(fn, 'this');
                return
            end
            this = mlraichle.FDGKineticsWholebrain(varargin{:});
            this.saveas(fn);
        end
    end

	methods    
    end 
    
    %% PRIVATE
    
    methods (Access = private)   
        function [m,sessd] = godoMasksOnly(datobj)
            try
                import mlraichle.*;
                sessd = SessionData.struct2sessionData(datobj);
                [m, sessd] = FDGKineticsWholebrain.godoMasks(sessd);
            catch ME
                dispwarning(ME);
            end
        end 
            
 		function this = FDGKineticsWholebrain(varargin)
 			%% FDGKINETICSWHOLEBRAIN
 			%  Usage:  this = FDGKineticsWholebrain()

 			this = this@mlraichle.F18DeoxyGlucoseKinetics(varargin{:});
            this.sessionData.parcellation = 'wholebrain';
 		end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

