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
        datetime0_fdg = datetime(2019,5,23,13,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeF_fdg = datetime(2019,5,23,14,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetime0_oc  = datetime(2019,5,23,12,22,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeF_oc  = datetime(2019,5,23,12,27,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        home
        obj_fdg
        obj_oc
 		registry
        sesd_fdg
        sesd_oc
        sesf_fdg = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
        sesf_ho  = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC'
        sesf_oo  = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC'
        sesf_oc  = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC'
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
            disp(this.obj_oc)
            disp(this.obj_fdg)
        end
        function test_buildCbv_imaging(this)
            % ocdt20190523112618_on_T1001, ocdt20190523122016_on_T1001 
            this.obj_oc.buildCbv( ...
                'filesExpr', 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr', ...
                'averageVoxels', false)
        end
        function test_buildCbv_scalar(this)
            this.obj_oc.buildCbv( ...
                'filesExpr', 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr')
        end
        function test_buildCMRglc_imaging(this)
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
        function test_construct_Ks(this)
            deleteExisting(fullfile(this.home, 'subjects/sub-S58163/resampling_restricted/wmparc_selectedIndices.mat'))
            construct_Ks('subjects/sub-S58163', 1, 'sessionsExpr', 'ses-E03056', 'wallClockLimit', '1081')
            inst = mlraichle.StudyRegistry.instance();
            inst.wallClockLimit = 168*3600;
        end
	end

 	methods (TestClassSetup)
		function setupAerobicGlycolysisKit(this)
 			import mlraichle.*;
            this.sesd_fdg = SessionData.create(this.sesf_fdg);
            this.sesd_oc = SessionData.create(this.sesf_oc);
            this.home = fullfile(getenv('SINGULARITY_HOME'));
 		end
	end

 	methods (TestMethodSetup)
		function setupAerobicGlycolysisKitTest(this)
 			import mlraichle.*;
 			this.obj_fdg = AerobicGlycolysisKit.createFromSession(this.sesd_fdg);
 			this.obj_oc  = AerobicGlycolysisKit.createFromSession(this.sesd_oc);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

