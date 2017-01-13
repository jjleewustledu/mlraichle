classdef Test_FdgDirector < matlab.unittest.TestCase
	%% TEST_FDGDIRECTOR 

	%  Usage:  >> results = run(mlraichle_unittest.Test_FdgDirector)
 	%          >> result  = run(mlraichle_unittest.Test_FdgDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Jan-2017 01:47:06
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_buildResolvedNACFrames(this)
        end
        function test_buildResolvedUmaps(this)
        end
        function test_buildResolvedACFrames(this)
            this.testObj.buildResolvedACFrames;
        end
	end

 	methods (TestClassSetup)
		function setupFdgDirector(this)
 			import mlraichle.*;
 			this.testObj_ = FdgDirector;
 		end
	end

 	methods (TestMethodSetup)
		function setupFdgDirectorTest(this)
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

