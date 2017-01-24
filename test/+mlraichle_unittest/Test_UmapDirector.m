classdef Test_UmapDirector < matlab.unittest.TestCase
	%% TEST_UMAPDIRECTOR 

	%  Usage:  >> results = run(mlraichle_unittest.Test_UmapDirector)
 	%          >> result  = run(mlraichle_unittest.Test_UmapDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Jan-2017 01:52:12
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_constructUmap(this)
 			this.testObj.constructUmap;
 		end
	end

 	methods (TestClassSetup)
		function setupUmapDirector(this)
 			import mlraichle.*;
 			this.testObj_ = UmapDirector;
 		end
	end

 	methods (TestMethodSetup)
		function setupUmapDirectorTest(this)
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

