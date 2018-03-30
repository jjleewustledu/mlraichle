classdef Test_HyperinsulinemiaDirector < matlab.unittest.TestCase
	%% TEST_HYPERINSULINEMIADIRECTOR 

	%  Usage:  >> results = run(mlraichle_unittest.Test_HyperinsulinemiaDirector)
 	%          >> result  = run(mlraichle_unittest.Test_HyperinsulinemiaDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Jan-2017 18:32:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
	end

 	methods (TestClassSetup)
		function setupHyperinsulinemiaDirector(this)
 			import mlraichle.*;
 			this.testObj_ = HyperinsulinemiaDirector;
 		end
	end

 	methods (TestMethodSetup)
		function setupHyperinsulinemiaDirectorTest(this)
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

