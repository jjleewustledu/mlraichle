classdef Test_StudyCensus < matlab.unittest.TestCase
	%% TEST_STUDYCENSUS 

	%  Usage:  >> results = run(mlraichle_unittest.Test_StudyCensus)
 	%          >> result  = run(mlraichle_unittest.Test_StudyCensus, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-Mar-2018 14:45:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        fqfilename = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'census 2018mar29.xlsx')
 		registry
        sessd
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_t1MprageSagSeriesForReconall(this)
            this.verifyEqual( ...
                this.testObj.t1MprageSagSeriesForReconall(this.sessd), ...
                fullfile(this.sessd.sessionPath, 't1_mprage_sag_series8.4dfp.hdr'));
        end
	end

 	methods (TestClassSetup)
		function setupStudyCensus(this)
 			import mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionFolder', 'HYGLY28', ...
 			this.testObj_ = StudyCensus(this.fqfilename, 'sessionData', this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupStudyCensusTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

