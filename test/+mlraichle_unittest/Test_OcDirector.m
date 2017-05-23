classdef Test_OcDirector < matlab.unittest.TestCase
	%% TEST_OCDIRECTOR 

	%  Usage:  >> results = run(mlraichle_unittest.Test_OcDirector)
 	%          >> result  = run(mlraichle_unittest.Test_OcDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 19-May-2017 08:46:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		registry
 		testObj
        view = true
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
        function test_constructOcNAC(this)
            this.testObj = this.testObj.constructOcNAC;
            this.verifyTestObjProduct;
            this.verifyTestObjEntropy(nan);
        end
        function test_constructOcAC(this)
            this.testObj = this.testObj.constructOcAC;
            this.verifyTestObjProduct;
            this.verifyTestObjEntropy(nan);
        end
	end

 	methods (TestClassSetup)
		function setupOcDirector(this)
 			import mlraichle.*;
 			this.testObj_ = OcDirector;
 		end
	end

 	methods (TestMethodSetup)
		function setupOcDirectorTest(this)
 			import mlraichle.*;
            studyd = SynthStudyData;
            sessd  = SessionData( ...
                'studyData', studyd, ...
                'sessionPath', fullfile(studyd.subjectsDir, 'HYGLY09', ''));
 			this.testObj_ = FdgDirector(FdgBuilder('sessionData', sessd));
 			this.addTeardown(@this.cleanFiles);
 		end
    end

    %% PRIVATE

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
        end
        function verifyTestObjProduct(this)            
            this.verifyClass(this.testObj.product, 'mlpet.PETImagingContext');
            if (this.view)
                this.testObj.product.view;
            end
        end
        function verifyTestObjEntropy(this, H)
            this.verifyEqual(this.testObj.product.entropy, H);
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

