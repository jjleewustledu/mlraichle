classdef Test_AerobicGlycolysisKit < matlab.unittest.TestCase
	%% TEST_AEROBICGLYCOLYSISKIT 

	%  Usage:  >> results = run(mlraichle_unittest.Test_AerobicGlycolysisKit)
 	%          >> result  = run(mlraichle_unittest.Test_AerobicGlycolysisKit, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Apr-2020 10:54:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        aif_fdg = [9910 18311 32947 50604 68071 89563 112399 123023 122491 121012] % 1:10
        aif_ho = [11279 24474 48459 87548 131461 181359 245367 315365 372520 423723] % 31:40
        aif_oc = [412707 564143 672891 737259 756274 716177 650525 560965 489974 448912] % 11:20
        aif_oo = [[421173 482167 504553 504746 480355 435967 388576 344048 317828 299290]] % 21:30
        datetime0_fdg = datetime(2019,5,23,13,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeF_fdg = datetime(2019,5,23,14,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetime0_oc  = datetime(2019,5,23,12,22,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeF_oc  = datetime(2019,5,23,12,27,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        home
        intermediary = 'subjects'
        obj_fdg
        obj_oc
 		registry
        resampling_restricted
        sesd_fdg
        sesd_oc
        sesf_fdg = 'CCIR_00559_00754/derivatives/nipet/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
        sesf_ho  = 'CCIR_00559_00754/derivatives/nipet/ses-E03056/HO_DT20190523125900.000000-Converted-AC'
        sesf_oo  = 'CCIR_00559_00754/derivatives/nipet/ses-E03056/OO_DT20190523123738.000000-Converted-AC'
        sesf_oc  = 'CCIR_00559_00754/derivatives/nipet/ses-E03056/OC_DT20190523122016.000000-Converted-AC'
        subjectFolder = 'sub-S58163'
        subjectPath
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_alignArterialToScanner(this)
            nipet_pth = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'derivatives', 'nipet', '');
            for s = globFoldersT(fullfile(nipet_pth, 'ses-E*', '*_DT*.000000-Converted-AC'))
                try
                    sessd = mlraichle.SessionData.create(s{1});    
                    artdev = mlswisstrace.TwiliteDevice.createFromSession(sessd);
                    if isempty(artdev)
                        continue
                    end
                    artdev.deconvCatheter = true;    
                    brain = sessd.brainOnAtlas('typ', 'mlfourd.ImagingContext2'); 
                    scakit = mlpet.ScannerKit.createFromSession(sessd);
                    sca = scakit.buildScannerDevice();
                    scadev = sca.volumeAveraged(brain.binarized());
        
                    [artdev1,dtpeak] = mlsiemens.BiographKit.alignArterialToReference(artdev, scadev);
        
                    disp(dtpeak)
                    disp(mlaif.AifData.instance())
                    plot(scadev)
                    plot(artdev1)
                catch ME
                    handwarning(ME)
                end
            end
        end
        function test_ctor(this)
            disp(this.obj_oc)
            disp(this.obj_fdg)
        end
        function test_buildCbv_imaging(this)
            % ocdt20190523112618_on_T1001, ocdt20190523122016_on_T1001 
            
            this.sesd_oc = SessionData.create(this.sesf_oc);
 			this.obj_oc  = AerobicGlycolysisKit.createFromSession(this.sesd_oc);
            this.obj_oc.buildCbv( ...
                'filesExpr', 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr', ...
                'averageVoxels', false)
        end
        function test_buildCbv_scalar(this)
            this.sesd_oc = SessionData.create(this.sesf_oc);
 			this.obj_oc  = AerobicGlycolysisKit.createFromSession(this.sesd_oc);
            this.obj_oc.buildCbv( ...
                'filesExpr', 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr')
        end
        function test_buildKs_imaging(this)
            assert(isfile(fullfile(this.home, 'subjects/sub-S58163/resampling_restricted/cbvdt20190523000000_on_T1001_decayUncorrect0.4dfp.hdr')))
            this.obj_fdg.buildKs( ...
                'filesExpr', 'subjects/sub-S58163/resampling_restricted/fdgdt20190523132832_on_T1001.4dfp.hdr', ...
                'cpuIndex', 1, ...
                'averageVoxels', false)
        end
        function test_buildRoiset(this)
            deleteExisting(fullfile(this.home, 'subjects/sub-S58163/resampling_restricted/wmparc_selectedIndices.mat'))
            roiset = this.obj_fdg.buildRoiset('wmparc', 'cpuIndex', 1);
            for r = roiset
                disp(r{1})
            end
        end
        function test_construct_Cbf_wholebrain(this)
            pwd0 = pushd(this.resampling_restricted);
            mlraichle.AerobicGlycolysisKit.construct('cbf', 'debug', true)
            m = load('DispersedAerobicGlycolysisKit_constructCbfWholebrain_dt20190523120249.mat');
            this.verifyEqual(round(m.aif(31:40)), this.aif_ho)
            this.verifyEqual(m.raichle.k1(), 0.008413609918501, 'RelTol', 1e-2)
            this.verifyEqual(m.raichle.k2(), 0.018688163140637, 'RelTol', 1e-2)
            this.verifyEqual(m.raichle.k3(), 0.893546113586472, 'RelTol', 1e-2)
            this.verifyEqual(m.raichle.k4(), 0.486102109932821, 'RelTol', 1e-2)
            this.verifyEqual(m.raichle.k5(), 5, 'RelTol', 1e-2)
            uiopen('DispersedAerobicGlycolysisKit_constructCbfWholebrain_dt20190523120249.fig',1)
            popd(pwd0)
        end
        function test_construct_Cbv_wholebrain(this)
            pwd0 = pushd(this.resampling_restricted);
            mlraichle.AerobicGlycolysisKit.construct('cbv', 'debug', true)
            m = load('DispersedAerobicGlycolysisKit_constructCbvWholebrain_dt20190523112618.mat');
            this.verifyEqual(round(m.aif(11:20)), this.aif_oc)
            this.verifyEqual(double(m.martin.v1.dipmax), 0.0506881, 'RelTol', 1e-4)
            uiopen('DispersedAerobicGlycolysisKit_constructCbvWholebrain_dt20190523112618.fig',1)
            popd(pwd0)
        end
        function test_construct_Cmro2_wholebrain(this)
            pwd0 = pushd(this.resampling_restricted);
            mlraichle.AerobicGlycolysisKit.construct('cmro2', 'debug', true)
            m = load('DispersedAerobicGlycolysisKit_constructCmro2Wholebrain_dt20190523123738.mat');
            this.verifyEqual(round(m.aif(21:30)), this.aif_oo)
            this.verifyEqual(m.mintun.k1(), 0.013081348700298, 'RelTol', 1e-2)
            this.verifyEqual(m.mintun.k2(), 0.500767899397380, 'RelTol', 1e-2)
            uiopen('DispersedAerobicGlycolysisKit_constructCmro2Wholebrain_dt20190523123738.fig',1)
            popd(pwd0)
        end
        function test_construct_Cmrglc_wholebrain(this)
            pwd0 = pushd(this.resampling_restricted);
            construct_Ks_wholebrain('sub-S58163*')
            m = load('DispersedAerobicGlycolysisKit_constructCmrglcWholebrain_dt20190523132832.mat');
            this.verifyEqual(round(m.aif(1:10)), this.aif_fdg)
            this.verifyEqual(m.huang.ks(), [0.027584688611627 0.002436253620294 0.001684261449861 0.000416960745906 1.999554856926497], 'RelTol', 5-2)
            uiopen('DispersedAerobicGlycolysisKit_constructCmrglcWholebrain_dt20190523132832.fig',1)
            popd(pwd0)
        end
        function test_construct_Ks(this)
            deleteExisting(fullfile(this.home, 'subjects/sub-S58163/resampling_restricted/wmparc_selectedIndices.mat'))
            construct_Ks('subjects/sub-S58163', 1, 'sessionsExpr', 'ses-E03056', 'wallClockLimit', '1081')
            inst = mlraichle.StudyRegistry.instance();
            inst.wallClockLimit = 168*3600;
        end
        function test_constructQC(this)
            import mlraichle.*
            cd(fullfile(this.home, 'subjects'))
            QuadraticAerobicGlycolysisKit.constructQC('cbv', 'subjectsExpr', 'sub-S*', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.constructQC('cbf', 'subjectsExpr', 'sub-S*', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.constructQC('oef', 'subjectsExpr', 'sub-S*', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.constructQC('cmro2', 'subjectsExpr', 'sub-S*', 'Nthreads', 1)
        end
        function test_ensureModelPrereq(this)
            pwd0 = pushd(this.resampling_restricted);
            popd(pwd0)
        end
        function test_fs_R_M(this)
            pwd0 = pushd(this.resampling_restricted);
            sesf_oo = 'CCIR_00559/ses-E03056/OO_DT20190523114543.000000-Converted-AC';
            sesd = mlraichle.SessionData.create(sesf_oo);
            sesd.region = 'wholebrain';
            roi = mlfourd.ImagingContext2('brain_222.4dfp.hdr');
            roi = roi.binarized();
            tmp = mloxygen.DispersedMintun1984Model.fs_R_M(sesd, roi);
            this.verifyEqual(double(tmp), [0.00841269269585609 0.0186939630657434 0.893551290035248 0.486106723546982 5 0.0506881438195705], 'RelTol', 1e-2)
            popd(pwd0)
        end
        function test_DispersedAerobicGlycolysisKit(this)
            import mlraichle.*
            cd(fullfile(this.home, 'subjects'))
            DispersedAerobicGlycolysisKit_construct('cbv', 'subjectsExpr', 'sub-S*', 'Nthreads', 14)
            DispersedAerobicGlycolysisKit_construct('cbf', 'subjectsExpr', 'sub-S*', 'Nthreads', 14)
            DispersedAerobicGlycolysisKit_construct('cmro2', 'subjectsExpr', 'sub-S*', 'Nthreads', 14)
            DispersedAerobicGlycolysisKit_construct('cmrglc', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 14)            
        end
        function test_QuadraticAerobicGlycolysisKit(this)
            import mlraichle.*
            cd(fullfile(this.home, 'subjects'))
            QuadraticAerobicGlycolysisKit.construct('cbv', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.construct('cbf', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.construct('cmro2', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
        end
        function test_subject(this)
            import mlraichle.*
            cd(this.resampling_restricted)
            %DispersedAerobicGlycolysisKit_construct('cbv', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 14)
            %DispersedAerobicGlycolysisKit_construct('cbf', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 14)
            %DispersedAerobicGlycolysisKit_construct('cmro2', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 14)
            %DispersedAerobicGlycolysisKit_construct('cmrglc', 'subjectsExpr', 'sub-S58163*', 'Nthreads', 14)
            
            %QuadraticAerobicGlycolysisKit.construct('cbv', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
            %QuadraticAerobicGlycolysisKit.construct('cbf', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
            QuadraticAerobicGlycolysisKit.construct('cmro2', 'subjectsExpr', 'sub-S58163', 'Nthreads', 1)
        end
        function test_subS33789(this)
            %% Diagnose creation of SessionData objects for sub-S33789, which is not getting 
            %  tracer data through pipelines defined by QuadraticAerobicGlycolysis.            
            
            import mlraichle.*
            cd(fullfile(this.home, 'subjects'))
            QuadraticAerobicGlycolysisKit.constructQC('cbv', 'subjectsExpr', 'sub-S33789', 'Nthreads', 14)
            QuadraticAerobicGlycolysisKit.constructQC('cbf', 'subjectsExpr', 'sub-S33789', 'Nthreads', 14)
            QuadraticAerobicGlycolysisKit.constructQC('oef', 'subjectsExpr', 'sub-S33789', 'Nthreads', 14)
            QuadraticAerobicGlycolysisKit.constructQC('cmro2', 'subjectsExpr', 'sub-S33789', 'Nthreads', 14)
        end
	end

 	methods (TestClassSetup)
		function setupAerobicGlycolysisKit(this)
 			import mlraichle.*;
            %this.sesd_fdg = SessionData.create(this.sesf_fdg);
            this.home = fullfile(getenv('SINGULARITY_HOME'));
            this.subjectPath = fullfile(this.home, this.intermediary, this.subjectFolder);
            this.resampling_restricted = ...
                fullfile(this.subjectPath, 'resampling_restricted', '');
 		end
	end

 	methods (TestMethodSetup)
		function setupAerobicGlycolysisKitTest(this)
 			import mlraichle.*;
 			%this.obj_fdg = AerobicGlycolysisKit.createFromSession(this.sesd_fdg);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

