classdef Test_UmapResolveBuilder < matlab.unittest.TestCase
	%% TEST_UMAPRESOLVEBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_UmapResolveBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_UmapResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 20-Jul-2016 18:14:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_parTriggeringOnResolvedNAC(this)
 			import mlraichle.*;
 		end
		function test_runSingleOnResolvedNAC(this)
 			import mlraichle.*;
 		end
	end

 	methods (TestClassSetup)
		function setupUmapResolveBuilder(this)
 			import mlraichle.*;
 			this.testObj_ = UmapResolveBuilder;
 		end
	end

 	methods (TestMethodSetup)
		function setupUmapResolveBuilderTest(this)
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

