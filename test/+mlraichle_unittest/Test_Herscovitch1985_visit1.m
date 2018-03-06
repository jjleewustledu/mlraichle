classdef Test_Herscovitch1985_visit1 < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985_VISIT1 

	%  Usage:  >> results = run(mlraichle_unittest.Test_Herscovitch1985_visit1)
 	%          >> result  = run(mlraichle_unittest.Test_Herscovitch1985_visit1, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 31-May-2017 14:20:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
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
		function setupHerscovitch1985(this)
 			import mlraichle.*;
 			this.testObj_ = Herscovitch1985;
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985Test(this)
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

