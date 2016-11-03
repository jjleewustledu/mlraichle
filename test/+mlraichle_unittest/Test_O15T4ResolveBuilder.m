classdef Test_O15T4ResolveBuilder < matlab.unittest.TestCase
	%% TEST_O15T4RESOLVEBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_O15T4ResolveBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_O15T4ResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Oct-2016 22:21:08
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
		function setupO15T4ResolveBuilder(this)
 			import mlraichle.*;
 			this.testObj_ = O15T4ResolveBuilder;
 		end
	end

 	methods (TestMethodSetup)
		function setupO15T4ResolveBuilderTest(this)
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

