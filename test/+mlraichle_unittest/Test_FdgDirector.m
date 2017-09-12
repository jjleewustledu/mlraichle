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
        hyglyNN = 'HYGLY28'
 		registry
        sessd
 		testObj
        view = true
 	end

	methods (Test)
        function test_constructNAC(this)
            % Subdomains of inputs:  
            % motion-corrected, back-projected; 
            % frames, epochs;
            % MR, CT, umap.
            % Testing the blackbox products.  
            
            this.testObj = this.testObj.constructNAC;
            this.verifyTestObjProduct;
        end
        function test_constructAC(this)
            this.testObj = this.testObj.constructAC('sessionData', this.sessd);
            this.verifyTestObjProduct;
        end
	end

 	methods (TestClassSetup)
		function setupFdgDirector(this)
 			import mlraichle.*;
            studyd = StudyData;
            this.sessd  = SessionData( ...
                'studyData', studyd, ...
                'sessionPath', fullfile(studyd.subjectsDir, this.hyglyNN, ''));
 			this.testObj_ = FdgDirector(FdgBuilder('sessionData', this.sessd));
 			this.addTeardown(@this.cleanFiles);
 		end
	end

 	methods (TestMethodSetup)
		function setupFdgDirectorTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
    end

    %% PRIVATE
    
	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
        function verifyTestObjProduct(this)
            this.verifyClass(this.testObj.product, 'mlfourd.ImagingContext');
            if (this.view)
                this.testObj.product.view;
            end
        end
        function verifyTestObjEntropy(this, H)
            this.verifyEqual(this.testObj.product.entropy, H);
        end
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

