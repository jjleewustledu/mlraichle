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
        view = true
 	end

	methods (Test)
        function test_constructFdgNAC(this)
            this.testObj = this.testObj.constructFdgNAC;
            this.verifyClass(this.testObj.product, 'mlpet.PETImagingContext');
            this.verifyEqual(this.testObj.product.entropy, nan);
            if (this.view)
                this.testObj.product.view;
            end
        end
        function test_constructFdgAC(this)
            this.testObj = this.testObj.constructFdgAC;
            this.verifyClass(this.testObj.product, 'mlpet.PETImagingContext');
            this.verifyEqual(this.testObj.product.entropy, nan);
            if (this.view)
                this.testObj.product.view;
            end
        end
	end

 	methods (TestClassSetup)
		function setupFdgDirector(this)
 			import mlraichle.*;
            studyd = SynthStudyData;
            sessd  = SessionData('studyData', studyd, ...
                                 'sessionPath', fullfile(getenv('PPG'), 'jjleeSynth', 'HYGLY09', ''));
 			this.testObj_ = FdgDirector( ...
                            FdgBuilder('sessionData', sessd));
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
