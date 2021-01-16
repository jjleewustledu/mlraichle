classdef DispersedAerobicGlycolysisKit < handle & mlraichle.AerobicGlycolysisKit
	%% DISPERSEDAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 11-Aug-2020 23:14:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraihcle/src/+mlraihcle.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	  
	methods (Static)  
        function msk       = buildTrainingMask(sesd, nmae)
            assert(isa(sesd, 'mlpipeline.ISessionData'))
            assert(isa(nmae, 'mlfourd.ImagingContext2'))
            assert(contains(nmae.fileprefix, 'NMAE'))
            
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'ImagingContext2');
            wmparc1 = wmparc1.binarized();
            nmae = nmae .* wmparc1;
            msk = nmae.numlt(1) .* nmae.numgt(0);
            msk.fileprefix = strrep(nmae.fileprefix, 'fdg', 'mask');
        end
        function             checkArterial(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            
            devkit = mlpet.ScannerKit.createFromSession(sesd);
            counting = devkit.buildCountingDevice();
            plot(counting.times, counting.activityDensity(), ':o')
            title(sprintf('checkArterial: %s', datestr(sesd.datetime)))
            xlabel('time (s)')
            ylabel('activity (Bq/mL)')
        end  
        function aif       = constructCbfWholebrain(varargin)
            %% CONSTRUCTCBFWHOLEBRAIN
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param mask is char, e.g., 'brain_222.4dfp.hdr'
            %  @return numeric aif.
            %  @return raichle.  
            %  aif & raichle are written to 
            %  $SINGULARITY_HOME/subjects/sub-S58163/resampling_restricted/DispersedAerobicGlycolysisKit_constructFsWholebrain_dt20190523120249.mat.           
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'mask', 'brain_222.4dfp.hdr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            sesd = ipr.sessionData;
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);                   

            % solve Raichle
            tic
            devkit = mlpet.ScannerKit.createFromSession(sesd);     
            model = mloxygen.DispersedRaichle1983Model('histology', 's');
            [raichle,~,aif] = mloxygen.DispersedNumericRaichle1983.createFromDeviceKit( ...
                devkit, ...
                'roi', ipr.mask, ...
                'model', model);
            raichle = raichle.solve(@mloxygen.DispersedRaichle1983Model.loss_function);
            raichle.fs.save()
            toc

            % Dx 
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            h = raichle.plot('zoom', 10);
            title(sprintf('%s:\n%s; TAC zoom x%i', dbs(1).name, datestr(sesd.datetime), 10))
            try
                dtTag = lower(sesd.doseAdminDatetimeTag);
                savefig(h, fullfile(workdir, sprintf('%s_%s.fig', mname, dtTag)))
                figs = get(0, 'children');
                saveas(figs(1), fullfile(workdir, sprintf('%s_%s.png',  mname, dtTag)))
                close(figs(1))
                save(fullfile(workdir, sprintf('%s_%s.mat', mname, dtTag)), 'aif', 'raichle')
            catch ME
                handwarning(ME)
            end   
            
            popd(pwd0)
        end
        function [fs,msk]  = constructCbfByRegion(varargin)
            %% CONSTRUCTCBFBYREGION
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return fs as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Fs and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            fs = this.(['buildFsBy' Region])(); 
            this.saveAllFormats(fs)
            fs = fs.blurred(4.3);
            this.saveAllFormats(fs)           
%            fs = sesd.fsOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1');
            msk = this.ensureTailoredMask();
            
            % build mat files for cbf, msk            
            [cbf_,msk_] = DispersedAerobicGlycolysisKit.constructCbfAndSupportInfo(sesd);
            Fsc_ = DispersedAerobicGlycolysisKit.iccrop(cbf_, 1:3);
            DispersedAerobicGlycolysisKit.ic2mat(Fsc_)
            DispersedAerobicGlycolysisKit.ic2mat(msk_)
            popd(pwd0)
        end  
        function [cbf,msk] = constructCbfAndSupportInfo(varargin)
            %% CONSTRUCTCBFANDSUPPORTINFO
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbf in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            raichle = this.loadImagingRaichle();
            raichle = raichle.ensureModel();
            pred = raichle.buildPrediction();
            this.saveAllFormats(pred)
            resid = raichle.buildResidual(); 
            this.saveAllFormats(resid)
            residwm = raichle.buildResidualWmparc1(); 
            this.saveAllFormats(residwm)
            [mae,nmae] = raichle.buildMeanAbsError(); 
            this.saveAllFormats(mae)
            this.saveAllFormats(nmae)
            cbf = this.metric2cbf(raichle.metric); 
            this.saveAllFormats(cbf)
            if strcmp('fs', this.sessionData.metric) || isempty(this.sessionData.metric)
                E = this.metric2E(raichle.metric);
                this.saveAllFormats(E)
            end
            msk = this.buildTrainingMask(raichle.sessionData, nmae);
            this.saveAllFormats(msk)
            popd(pwd0)
        end
        function aif       = constructCbvWholebrain(varargin)
            %% CONSTRUCTCBVWHOLEBRAIN
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param mask is char, e.g., 'brain_222.4dfp.hdr'
            %  @return numeric aif.
            %  @return martin.  
            %  aif & martin are written to 
            %  $SINGULARITY_HOME/subjects/sub-S58163/resampling_restricted/DispersedAerobicGlycolysisKit_constructCbvWholebrain_dt20190523120249.mat.           
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'mask', 'brain_222.4dfp.hdr')
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            sesd = ipr.sessionData;
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);                 

            % solve Martin
            tic  
            devkit = mlpet.ScannerKit.createFromSession(sesd);
            [martin,~,aif] = mloxygen.Martin1987.createFromDeviceKit( ...
                devkit, ...
                'roi', ipr.mask);
            martin = martin.solve('tags', '_wholebrain');  
            martin.cbv.save()
            toc

            % Dx 
            h = martin.plot();
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            title(sprintf('%s:\n%s', dbs(1).name, datestr(sesd.datetime)))
            try
                dtTag = lower(sesd.doseAdminDatetimeTag);
                savefig(h, fullfile(workdir, sprintf('%s_%s.fig', mname, dtTag)))
                figs = get(0, 'children');
                saveas(figs(1), fullfile(workdir, sprintf('%s_%s.png',  mname, dtTag)))
                close(figs(1))
                save(fullfile(workdir, sprintf('%s_%s.mat', mname, dtTag)), 'aif', 'martin')
            catch ME
                handwarning(ME)
            end
            
            popd(pwd0)
        end
        function [cbv,msk] = constructCbvByRegion(varargin)
            %% CONSTRUCTCBVBYREGION
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbv as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Ks and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
            %sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            %this.constructWmparc1OnAtlas(sesd)
            cbv = this.(['buildCbvBy' Region])(); 
            cbv.save()
            cbv = cbv.blurred(4.3);
            cbv.save()             
            msk = this.ensureTailoredMask();            
            popd(pwd0)
        end  
        function aif       = constructCmrglcWholebrain(varargin)
            %% CONSTRUCTCMRGLCWHOLEBRAIN
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param mask is char, e.g., 'brain_222.4dfp.hdr'
            %  @return numeric aif.
            %  @return huang.  
            %  aif & huang are written to 
            %  $SINGULARITY_HOME/subjects/sub-S58163/resampling_restricted/DispersedAerobicGlycolysisKit_constructKsWholebrain_dt20190523120249.mat.           
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'mask', 'brain_222.4dfp.hdr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            % build aif
            sesd = ipr.sessionData;
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            
            pwd0 = pushd(workdir);                 
            devkit = mlpet.ScannerKit.createFromSession(sesd); 
            %cbv = sesd.cbvOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            cbv = sesd.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
            cbv = cbv.fourdfp; 
            msk = mlfourd.ImagingContext2(ipr.mask);
            msk = msk.binarized(); 
            msk = msk.fourdfp;
            ks = copy(msk);
            ks.fileprefix = sesd.fsOnAtlas('typ', 'fp', 'tags', '_wholebrain');
            lenKs = mlglucose.DispersedNumericHuang1980.LENK + 1;
            ks.img = zeros([size(msk) lenKs]);  

            tic
            mskbin = msk.img > 0;

            % solve Huang
            roicbv = mean(cbv.img(mskbin));
            [huang,~,aif] = mlglucose.DispersedNumericHuang1980.createFromDeviceKit( ...
                devkit, ...
                'cbv', roicbv, ...
                'roi', mlfourd.ImagingContext2(msk));
            huang = huang.solve();
            toc

            % insert Raichle solutions on roibin(idx) into fs
            fscache = huang.ks();
            fscache(huang.LENK+1) = huang.Dt;
            for ik = 1:huang.LENK+1
                rate = ks.img(:,:,:,ik);
                rate(mskbin) = fscache(ik);
                ks.img(:,:,:,ik) = rate;
            end

            % Dx 
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            h = huang.plot('zoom', 10);
            title(sprintf('%s:\n%s; TAC zoom x%i', dbs(1).name, datestr(sesd.datetime), 10))
            try
                dtTag = lower(sesd.doseAdminDatetimeTag);
                savefig(h, ...
                    fullfile(workdir, ...
                    sprintf('%s_%s.fig', mname, dtTag)))
                figs = get(0, 'children');
                saveas(figs(1), ...
                    fullfile(workdir, ...
                    sprintf('%s_%s.png',  mname, dtTag)))
                close(figs(1))
                save(fullfile(workdir, ...
                    sprintf('%s_%s.mat', mname, dtTag)), 'aif', 'huang')
            catch ME
                handwarning(ME)
            end   
            
            popd(pwd0)
        end
        function [ks,msk]  = constructCmrglcByRegion(varargin)
            %% CONSTRUCTCMRGLCBYREGION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param region is char:  'wmparc', 'wbrain'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Ks and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            ks = this.(['buildKsBy' Region])(); 
            ks.save()
            ks = ks.blurred(4.3);
            ks.save()             
            msk = this.ensureTailoredMask();               
            
            % build mat files for cbf, msk  
            [cmrglc,Ks,msk] = DispersedAerobicGlycolysisKit.constructCmrglcAndSupportInfo(sesd);
            Ksc = DispersedAerobicGlycolysisKit.iccrop(Ks, 1:4);
            DispersedAerobicGlycolysisKit.ic2mat(Ksc)
            DispersedAerobicGlycolysisKit.ic2mat(cmrglc)
            DispersedAerobicGlycolysisKit.ic2mat(msk)
            popd(pwd0)
        end  
        function [cmrglc,Ks,msk] = constructCmrglcAndSupportInfo(varargin)
            %% CONSTRUCTCMRGLCANDSUPPORTINFO
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cmrglc in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return Ks in (s^{-1}) as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            huang = this.loadImagingHuang();
            pred = huang.buildPrediction(); 
            pred.save(); 
            resid = huang.buildResidual(); 
            resid.save(); 
            [mae,nmae] = huang.buildMeanAbsError(); 
            mae.save(); 
            nmae.save();
            Ks = this.k1_to_K1(huang.ks, huang.v1 ./ 0.0105);
            Ks.save()
            chi = this.ks2chi(huang.ks); 
            chi.save(); 
            cmrglc = this.ks2cmrglc(huang.ks, huang.v1 ./ 0.0105, this.devkit_.radMeasurements); 
            cmrglc.save();
            msk = this.buildTrainingMask(huang.sessionData, nmae);
            msk.save();
            popd(pwd0)
        end
        function aif       = constructCmro2Wholebrain(varargin)
            %% CONSTRUCTCMRO2WHOLEBRAIN
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @param mask is char, e.g., 'brain_222.4dfp.hdr'
            %  @return numeric aif.
            %  @return raichle.  
            %  aif & raichle are written to 
            %  $SINGULARITY_HOME/subjects/sub-S58163/resampling_restricted/DispersedAerobicGlycolysisKit_constructFsWholebrain_dt20190523120249.mat.           
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'mask', 'brain_222.4dfp.hdr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            sesd = ipr.sessionData;
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);  

            % solve Raichle
            tic  
            model = mloxygen.DispersedMintun1984Model.createFromSession( ...
                sesd, 'roi', ipr.mask);
            devkit = mlpet.ScannerKit.createFromSession(sesd);   
            [mintun,~,aif] = mloxygen.DispersedNumericMintun1984.createFromDeviceKit( ...
                devkit, ...
                'roi', ipr.mask, ...
                'model', model);
            mintun = mintun.solve(@mloxygen.DispersedMintun1984Model.loss_function);
            mintun.os.save()
            toc

            % Dx 
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            h = mintun.plot('zoom', 10);
            title(sprintf('%s:\n%s; TAC zoom x%i', dbs(1).name, datestr(sesd.datetime), 10))
            try
                dtTag = lower(sesd.doseAdminDatetimeTag);
                savefig(h, fullfile(workdir, sprintf('%s_%s.fig', mname, dtTag)))
                figs = get(0, 'children');
                saveas(figs(1), fullfile(workdir, sprintf('%s_%s.png',  mname, dtTag)))
                close(figs(1))
                save(fullfile(workdir, sprintf('%s_%s.mat', mname, dtTag)), 'aif', 'mintun')
            catch ME
                handwarning(ME)
            end   
            
            popd(pwd0)          
        end
        function [os,msk]  = constructCmro2ByRegion(varargin)            
            %% CONSTRUCTCMRO2BYREGION
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return os as mlfourd.ImagingContext2 or cell array.
            %  @return msk as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Os and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            os = this.(['buildOsBy' Region])(); 
            this.saveAllFormats(os)
            os = os.blurred(4.3);
            this.saveAllFormats(os)           
%           os = sesd.osOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1');
            msk = this.ensureTailoredMask();
            
            % build mat files for oef, cmro2, msk            
            %[cmro2_,msk_] = DispersedAerobicGlycolysisKit.constructCmro2AndSupportInfo(sesd);
            %Osc_ = DispersedAerobicGlycolysisKit.iccrop(cmro2_, 1:3);
            %DispersedAerobicGlycolysisKit.ic2mat(Osc_)
            %DispersedAerobicGlycolysisKit.ic2mat(msk_)
            popd(pwd0)
        end
        function [cmro2,msk] = constructCmro2AndSupportInfo(varargin)
            %% CONSTRUCTCMRO2ANDSUPPORTINFO
            %  @param required sessionData is mlpipeline.ISessionData.
            %  @return cbf in mumoles/hg/min as mlfourd.ImagingContext2.
            %  @return msk as mlfourd.ImagingContext2.
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            mintun = this.loadImagingMintun();
            cmro2 = [];
            msk = [];
            popd(pwd0)
        end
        function [gs,msk]  = constructGsByRegion(varargin)
            %% CONSTRUCTGSBYREGION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric (compatibility). 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param region is char:  'wmparc', 'wbrain'.
            %  @return gs as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            sesd = ip.Results.sessionData;
            Region = [upper(sesd.region(1)) sesd.region(2:end)];
            
            % build Gs and their masks
            pwd0 = pushd(sesd.subjectPath);             
            this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
            sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
            this.constructWmparc1OnAtlas(sesd)
            gs = this.(['buildGsBy' Region])(); 
            this.saveAllFormats(gs)
            gs = gs.blurred(4.3);
            this.saveAllFormats(gs)
            msk = this.ensureTailoredMask();

%            gs = []; % DEBUGGING
            
            % build mat files for cbf, msk            
            [cbf_,msk_] = DispersedAerobicGlycolysisKit.constructCbfAndSupportInfo(sesd);
            Gsc_ = DispersedAerobicGlycolysisKit.iccrop(cbf_, 1:3);
            DispersedAerobicGlycolysisKit.ic2mat(Gsc_)
            DispersedAerobicGlycolysisKit.ic2mat(msk_)
            popd(pwd0)
        end  
        function             constructSubjectByRegion(varargin)   
            %% CONSTRUCTSUBJECTBYREGION constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            %  @param region is char:  'wmparc1', 'wbrain'.
            %  @param saveMat is logical.
            
            import mlraichle.*
            import mlraichle.DispersedAerobicGlycolysisKit.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'region', '', @(x) ischar(x) && ~isempty(x))
            addParameter(ip, 'saveMat', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Region = [upper(ipr.region(1)) ipr.region(2:end)];
            
            ss = strsplit(ipr.foldersExpr, '/');           
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = mlraichle.SubjectData('subjectFolder', ss{2});             
            sesfs = subd.subFolder2sesFolders(ss{2});
            
            for sesf = sesfs(contains(sesfs, ipr.sessionsExpr))
                try
                    sesd = SessionData( ...
                        'studyData', StudyData(), ...
                        'projectData', ProjectData('sessionStr', sesf{1}), ...
                        'subjectData', subd, ...
                        'sessionFolder', sesf{1}, ...
                        'tracer', 'FDG', ...
                        'ac', true, ...
                        'region', ipr.region); 
                    if sesd.datetime < mlraichle.StudyRegistry.instance.earliestCalibrationDatetime
                        continue
                    end
                    if ipr.saveMat
                        fdg = sesd.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
                        fdg = fdg.blurred(4.3);
                        DispersedAerobicGlycolysisKit.ic2mat(fdg)
                    end
                    
                    DispersedAerobicGlycolysisKit.(['constructKsBy' Region])(sesd); % memory ~ 5.5 GB
                catch ME
                    handwarning(ME)
                end
            end            
            popd(pwd0)            
        end
        function             constructSubjectByWmparc1(varargin)
            %% CONSTRUCTSUBJECTBYWMPARC1 constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param sessionsExpr is char, e.g., 'ses-E' selects all sessions.
            
            mlraichle.DispersedAerobicGlycolysisKit.constructSubjectByRegion(varargin{:}, 'region', 'wmparc1')               
        end
        function ic        = constructWmparc1OnAtlas(sesd)
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            
            deleteExisting([sesd.wmparc1OnAtlas('typ', 'fqfileprefix') '.4dfp.*'])
            
            % define CSF
            wmparc = ImagingFormatContext(sesd.wmparcOnAtlas());
            wmparc1 = ImagingFormatContext(sesd.brainOnAtlas());
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1;
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);
            
            % define venous
            ven = sesd.cbvOnAtlas('typ', 'ImagingContext2', 'dateonly', true);
            ven = ven.blurred(4.3);
            ven = ven.thresh(10.29); % mean + 10 sigmas (mL/hg) per Ito 2004
            ven = ven.binarized();
            ven.fqfilename = sesd.venousOnAtlas();
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            selected = logical(ven.fourdfp.img) & wmparc1.img < 2;
            wmparc1.img(selected) = 6000;
            
            % construct wmparc1
            ic = ImagingContext2(wmparc1);
            ic.save()
        end
        function this      = createFromSession(varargin)
            this = mlraichle.DispersedAerobicGlycolysisKit('sessionData', varargin{:});
        end
        function these     = createFromSubjectSession(varargin)
            %% CREATEFROMSUBJECTSESSION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param region is char, e.g., 'brain' | 'wmparc'
            %  @return these is {mlraichle.DispersedAerobicGlycolysisKit, ...}
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ss = strsplit(ipr.foldersExpr, '/');         
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, ''));            
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            these = {};
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true, ...
                    'region', ipr.region); 
                this = DispersedAerobicGlycolysisKit.createFromSession(sesd);
                these = [these this]; %#ok<AGROW>
            end
            popd(pwd0)
        end
        function h         = index2histology(idx)
            h = '';
            if (1000 <= idx && idx < 3000) || (11000 <= idx && idx < 13000)
                h = 'g';
                return
            end
            if (3000 <= idx && idx <= 5217) || (13000 <= idx && idx < 15000)
                h = 'w';
                return
            end
            if 8000 <= idx && idx <= 9999
                h = 's';
                return
            end
            switch idx
                case {3 42}
                    h = 'g';
                case {2 7 27 28 41 46 59 60}
                    h = 'w';
                case num2cell([170:179 7100:7101])
                    h = 'w';
                case num2cell([9:13 16 18 48:52 54 101 102 104 105 107 110 111 113 114 116])
                    h = 's';
                otherwise
            end
        end
        function             plotDxDTimes(varargin)
            %% PLOTDXDTIMES plots diagnosstics for \Delta t shifts of AIF.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1().    
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            addParameter(ip, 'Delta', 0.5, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results; 
            DELTA = ipr.Delta;
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
            sesd = this.sessionData;
            pwd0 = pushd(sesd.tracerOnAtlas('typ', 'filepath'));            
            
            % select ROI
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            roi = copy(wmparc1);
            roi.img = single(wmparc1.img == ipr.voxelIndex);
            fprintf('plotDxPrediction:  #roi = %g\n', dipsum(roi.img))
            if dipsum(roi.img) == 0
                return
            end
            roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, ipr.voxelIndex); 
            
            % select data
            cbv = sesd.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
            cbv = cbv.volumeAveraged(roi);
            cbv = cbv .* 0.0105;
            devkit = mlpet.ScannerKit.createFromSession(sesd);            
            counting = devkit.buildCountingDevice();
            scanner = devkit.buildScannerDevice();
            scanner = scanner.blurred(4.3);
            scanner = scanner.volumeAveraged(roi);
            Dt = mlglucose.DispersedNumericHuang1980.DTimeToShift(counting, scanner);
            timesInterp = 0:scanner.times(end);
            aif0 = cbv.fourdfp.img * pchip(counting.times, counting.activityDensity(), timesInterp);     
            aif1 = cbv.fourdfp.img * pchip(counting.times + Dt, counting.activityDensity(), timesInterp);    
            aif2 = conv(aif1, DELTA*exp(-DELTA*timesInterp));
            aif2 = aif2(1:length(timesInterp));
            tac = scanner.activityDensity(); 
            
            % plot
            figure
            plot(scanner.times, tac, ':o', ...
                 timesInterp, aif0, '--', ...
                 timesInterp, aif1, '-', ...
                 timesInterp, aif2, '-.')
            legend('TAC', 'AIF_{Dt=0}', sprintf('AIF_{Dt=%g}', Dt), sprintf('AIF_{Dt=%g, Delta=%g}', Dt, 1/DELTA))
            xlim([0 360])
            xlabel('time frames')
            ylabel('activity (Bq/mL)')
            title(sprintf('plotDxTimes: index = %g', ipr.voxelIndex))
            
            popd(pwd0)
        end 
        function             plotDxPrediction(varargin)
            %% PLOTDXPREDICTION plots diagnosstics for model predictions.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param voxelIndex is numeric, following parcellation conventions of
            %         mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1().   
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelIndex', 1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this = mlraichle.DispersedAerobicGlycolysisKit.createFromSubjectSession(varargin{:});            
            sesd = this.sessionData;
            pwd0 = pushd(sesd.tracerOnAtlas('typ', 'filepath')); 
            
            % select ROI
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingFormatContext');
            roi = copy(wmparc1);
            roi.img = single(wmparc1.img == ipr.voxelIndex);
            fprintf('plotDxPrediction:  #roi = %g\n', dipsum(roi.img))
            if dipsum(roi.img) == 0
                return
            end
            roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, ipr.voxelIndex); 
            
            % select data
            fdg = sesd.tracerOnAtlas('typ', 'ImagingContext2');
            fdg1d = fdg.volumeAveraged(roi);
            fdg1d = fdg1d.fourdfp.img;
            pred = sesd.tracerOnAtlas('typ', 'mlfourd.ImagingContext2', 'tags', '_b43_wmparc1_predicted');
            pred1d = pred.volumeAveraged(roi);
            pred1d = pred1d.fourdfp.img;
            times = cumsum(sesd.taus);
            times = [0 times(1:end-1)];
            
            % plot
            figure
            plot(times, fdg1d, ':o', times, pred1d, '-')
            xlim([0 1000])
            xlabel('time frames')
            ylabel('activity (Bq/mL)')
            title(sprintf('plotDxPrediction: index = %g', ipr.voxelIndex))         
            
            popd(pwd0)
        end 	
        function             saveAllFormats(ic)
            assert(isa(ic, 'mlfourd.ImagingContext2'))
            ic.fourdfp.save()
            ic.nifti.save()
        end
    end
    
    methods
        
        %%
        
        function cbv   = buildCbvByWmparc1(this, varargin)
            %% BUILDCBVBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return fs as mlfourd.ImagingContext2, without saving to filesystems.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', this.indicesToCheck, @(x) any(x == this.indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);  
            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);  
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            cbv = copy(wmparc1);
            cbv.fileprefix = sesd.cbvOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            cbv.img = zeros(size(wmparc1));  

            for idx = 1:length(this.indices) % parcs

                % for parcs, build roibin as logical, roi as single                    
                fprintf('starting %s.index -> %i\n', dbs(1).name, this.indices(idx))
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == this.indices(idx);
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, this.indices(idx));
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Martin  
                % insert Martin solutions on roibin(indices) into cbv
                martin = mloxygen.Martin1987.createFromDeviceKit( ...
                    devkit, ...
                    'roi', roi);
                martin = martin.solve();
                img = martin.cbv('typ', 'single');
                cbv.img(roibin) = img(roibin);
                toc                

                % Dx
                if any(this.indices(idx) == ipr.indicesToCheck)     
                    h = martin.plot('index', this.indices(idx), 'roi', roi);                    
                    title(sprintf('%s:  indices %i\n%s', ...
                        mname, this.indices(idx), datestr(sesd.datetime)))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i_%s.fig', mname, this.indices(idx), dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i_%s.png', mname, this.indices(idx), dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            cbv = mlfourd.ImagingContext2(cbv);
            popd(pwd0)
        end
        function         buildDataAugmentation(~, sesd)
            assert(isa(sesd, 'mlpipeline.ISessionData'))
            if isfield(sesd.dataAugmentation, 'fdgCal')
                fdg = sesd.fdgOnAtlas('typ', 'ImagingContext2', 'getAugmented', false);
                fdg = fdg .* sesd.dataAugmentation.fdgCal;
                fdg.fileprefix = sesd.fdgOnAtlas('typ', 'fileprefix');
                try
                    fdg.save()
                catch ME
                    handexcept(ME)
                end
            end
        end
        function fs    = buildFsByWmparc1(this, varargin)
            %% BUILDFSBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return fs as mlfourd.ImagingContext2, without saving to filesystems.
            
            import mlraichle.DispersedAerobicGlycolysisKit.index2histology
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', this.indicesToCheck, @(x) any(x == this.indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);  
            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);  
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            fs = copy(wmparc1);
            fs.fileprefix = sesd.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            lenKs = mloxygen.DispersedNumericRaichle1983.LENK + 1;
            fs.img = zeros([size(wmparc1) lenKs]);   

            for idx = 1:length(this.indicesL) % parcs

                % for parcs, build roibin as logical, roi as single    
                fprintf('starting %s.indices -> %i, %i\n', dbs(1).name, this.indicesL(idx), this.indicesR(idx))
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == this.indicesL(idx) | wmparc1.img == this.indicesR(idx);
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_indices%i,%i', roi.fileprefix, this.indicesL(idx), this.indicesR(idx));
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Raichle
                % insert Raichle solutions on roibin(indices) into fs
                model = mloxygen.DispersedRaichle1983Model( ...
                    'histology', index2histology(this.indicesL(idx)));
                raichle = mloxygen.DispersedNumericRaichle1983.createFromDeviceKit( ...
                    devkit, ...
                    'roi', roi, ...
                    'model', model);
                raichle = raichle.solve(@mloxygen.DispersedRaichle1983Model.loss_function);
                toc

                % insert Raichle solutions on roibin(idx) into fs
                fs.img = fs.img + raichle.fs('typ', 'single');

                % Dx
                if any(this.indicesL(idx) == ipr.indicesToCheck)                        
                    h = raichle.plot('zoom', 10);
                    title(sprintf('%s:  indices %i, %i\n%s; TAC zoom x%i', ...
                        mname, this.indicesL(idx), this.indicesR(idx), datestr(sesd.datetime), 10))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i,%i_%s.fig', mname, this.indicesL(idx), this.indicesR(idx), dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i,%i_%s.png', mname, this.indicesL(idx), this.indicesR(idx), dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            fs = mlfourd.ImagingContext2(fs);
            popd(pwd0)
        end
        function gs    = buildGsByWmparc1(this, varargin)
            %% BUILDGSBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return gs as mlfourd.ImagingContext2, without saving to filesystems.
            
            import mlraichle.DispersedAerobicGlycolysisKit.index2histology
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', this.indicesToCheck, @(x) any(x == this.indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');
            
            pwd0 = pushd(workdir);            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);  
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            gs = copy(wmparc1);
            gs.fileprefix = sesd.gsOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            lenKs = mloxygen.DispersedNumericRaichle1983.LENK + 1;
            gs.img = zeros([size(wmparc1) lenKs]);   

            for idx = 1:length(this.indicesL) % parcs

                % for parcs, build roibin as logical, roi as single                    
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildGsByWmparc1.indices -> %i, %i\n', ...
                    this.indicesL(idx), this.indicesR(idx))
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == this.indicesL(idx) | wmparc1.img == this.indicesR(idx);
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_indices%i,%i', roi.fileprefix, this.indicesL(idx), this.indicesR(idx));
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Raichle
                model = mloxygen.ConstantERaichle1983Model( ...
                    'histology', index2histology(this.indicesL(idx)));
                raichle = mloxygen.DispersedNumericRaichle1983.createFromDeviceKit( ...
                    devkit, ...
                    'roi', mlfourd.ImagingContext2(roi), ...
                    'model', model);
                raichle = raichle.solve(@mloxygen.ConstantERaichle1983Model.loss_function);
                toc

                % insert Raichle solutions on roibin(idx) into fs
                fscache = raichle.ks();
                fscache(raichle.LENK+1) = raichle.Dt;
                for ik = 1:raichle.LENK+1
                    rate = gs.img(:,:,:,ik);
                    rate(roibin) = fscache(ik);
                    gs.img(:,:,:,ik) = rate;
                end

                % Dx
                if any(this.indicesL(idx) == ipr.indicesToCheck)                        
                    h = raichle.plot();
                    title(sprintf('DispersedAerobicGlycolysisKit.buildGsByWmparc1:  indices %i, %i\n%s', ...
                        this.indicesL(idx), this.indicesR(idx), datestr(sesd.datetime)))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildGsByWmparc1_indices%i,%i_%s.fig', ...
                            this.indicesL(idx), this.indicesR(idx), dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildGsByWmparc1_indices%i,%i_%s.png', ...
                            this.indicesL(idx), this.indicesR(idx), dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            gs = mlfourd.ImagingContext2(gs);
            popd(pwd0)
        end
        function ks    = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return ks as mlfourd.ImagingContext2, without saving to filesystems.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', this.indicesToCheck, @(x) any(x == this.indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');
            
            pwd0 = pushd(workdir);            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);                
            cbv = sesd.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
            cbv = cbv.fourdfp;
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            ks = copy(wmparc1);
            ks.fileprefix = sesd.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            lenKs = mlglucose.DispersedNumericHuang1980.LENK + 1;
            ks.img = zeros([size(wmparc1) lenKs]);   

            for idx = this.indices % parcs

                % for parcs, build roibin as logical, roi as single                    
                fprintf('starting mlpet.DispersedAerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == idx;
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Huang
                roicbv = mean(cbv.img(roibin));
                huang = mlglucose.DispersedNumericHuang1980.createFromDeviceKit( ...
                    devkit, ...
                    'cbv', roicbv, ...
                    'roi', mlfourd.ImagingContext2(roi));
                huang = huang.solve();
                toc

                % insert Huang solutions on roibin(idx) into ks
                kscache = huang.ks();
                kscache(huang.LENK+1) = huang.Dt;
                for ik = 1:huang.LENK+1
                    rate = ks.img(:,:,:,ik);
                    rate(roibin) = kscache(ik);
                    ks.img(:,:,:,ik) = rate;
                end

                % Dx
                if any(idx == ipr.indicesToCheck)                        
                    h = huang.plot();
                    title(sprintf('DispersedAerobicGlycolysisKit.buildKsByWmparc1:  idx == %i\n%s', idx, datestr(sesd.datetime)))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('DispersedAerobicGlycolysisKit_buildKsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            ks = mlfourd.ImagingContext2(ks);
            popd(pwd0)
        end
        function os    = buildOsByWmparc1(this, varargin)
            %% BUILDOSBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return os as mlfourd.ImagingContext2, without saving to filesystems.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', this.indicesToCheck, @(x) any(x == this.indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            dbs = dbstack;
            mname = strrep(dbs(1).name, '.', '_');
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');            
            pwd0 = pushd(workdir);  
            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);  
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            os = copy(wmparc1);
            os.fileprefix = sesd.osOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            lenKs = 2;
            os.img = zeros([size(wmparc1) lenKs]);   

            for idx = 1:length(this.indicesL) % parcs

                % for parcs, build roibin as logical, roi as single    
                fprintf('starting %s.indices -> %i, %i\n', dbs(1).name, this.indicesL(idx), this.indicesR(idx))
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == this.indicesL(idx) | wmparc1.img == this.indicesR(idx);
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_indices%i,%i', roi.fileprefix, this.indicesL(idx), this.indicesR(idx));
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Mintun
                % insert Mintun solutions on roibin(indices) into os
                model = mloxygen.DispersedMintun1984Model.createFromSession( ...
                    sesd, 'roi', roi);
                mintun = mloxygen.DispersedNumericMintun1984.createFromDeviceKit( ...
                    devkit, ...
                    'roi', roi, ...
                    'model', model);
                mintun = mintun.solve(@mloxygen.DispersedMintun1984Model.loss_function);
                toc

                % insert Raichle solutions on roibin(idx) into os
                os.img = os.img + mintun.os('typ', 'single');

                % Dx
                if any(this.indicesL(idx) == ipr.indicesToCheck)                        
                    h = mintun.plot('zoom', 10);
                    title(sprintf('%s:  indices %i, %i\n%s; TAC zoom x%i', ...
                        mname, this.indicesL(idx), this.indicesR(idx), datestr(sesd.datetime), 10))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i,%i_%s.fig', mname, this.indicesL(idx), this.indicesR(idx), dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('%s_indices%i,%i_%s.png', mname, this.indicesL(idx), this.indicesR(idx), dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            os = mlfourd.ImagingContext2(os);
            popd(pwd0)
        end
        function msk   = ensureTailoredMask(this)
            msk = this.sessionData.wmparc1OnAtlas('typ', 'ImagingContext2');
            fqfn = [msk.fqfileprefix '_binarized.4dfp.hdr'];
            if isfile(fqfn)
                msk = mlfourd.ImagingContext2(fqfn);
                return
            end 
            % msk = msk.uthresh(5999); % exclude venous
            % msk = msk.binarized();
            % msk = msk.blurred(4.3);
            msk = msk.binarized();
            msk.save()
        end 
        function r     = loadImagingHuang(this, varargin)
            %%
            %  @return mlglucose.DispersedImagingHuang1980  
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mask = this.maskOnAtlasTagged();
            m = this.metricOnAtlasTagged();
            r = mlglucose.DispersedImagingHuang1980.createFromDeviceKit(this.devkit_, 'cbv', cbv, 'roi', mask);
            r.ks = m;
        end
        function im    = loadImagingMintun(this, varargin)
            %% LOADIMAGINGMINTUN
            %  @return mloxygen.DispersedImagingMintun1984
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            mask = this.maskOnAtlasTagged();
            im = [];

        end
        function ir    = loadImagingRaichle(this, varargin)
            %% LOADIMAGINGRAICHLE
            %  @return mloxygen.DispersedImagingRaichle1983 
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            mask = this.maskOnAtlasTagged();
            ir = mloxygen.DispersedImagingRaichle1983.createFromDeviceKit(this.devkit_, 'roi', mask);
            ir.metric = this.metricOnAtlasTagged();
        end
        function ic    = maskOnAtlasTagged(this, varargin)
            fqfp = this.sessionData.wmparc1OnAtlas('typ', 'fqfp');
            fqfp_bin = [fqfp '_binarized'];
            
            % 4dfp exists
            if isfile([fqfp_bin '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp_bin '.4dfp.hdr']);
                return
            end
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                ic = ic.binarized();
                ic.save()
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp_bin);
            if isfile([fqfp_bin '.mat'])
                msk = load([fqfp_bin '.mat'], 'img');
                ifc.img = reshape(single(msk.img), [128 128 75]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.maskOnAtlasTagged')
        end
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = DispersedAerobicGlycolysisKit(varargin)
 			this = this@mlraichle.AerobicGlycolysisKit(varargin{:});
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

