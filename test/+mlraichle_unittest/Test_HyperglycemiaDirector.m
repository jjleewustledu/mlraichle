classdef Test_HyperglycemiaDirector < matlab.unittest.TestCase
	%% TEST_HYPERGLYCEMIADIRECTOR 

	%  Usage:  >> results = run(mlraichle_unittest.Test_HyperglycemiaDirector)
 	%          >> result  = run(mlraichle_unittest.Test_HyperglycemiaDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 01-Jan-2017 18:32:38
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2016, 2017 John J. Lee.
 	

	properties
 		registry
 		testObj
        brainmaskBldr
 	end

	methods (Test)
        function test_ctor(this)
            disp(this.testObj.sessionData);
            this.brainmaskBldr.product.view;
        end
        
        function test_analyzeCohort(this)
        end
        function test_analyzeSubject(this)
        end
        function test_analyzeVisit(this)
        end
        function test_analyzeTracers(this)
        end
        
		function test_instanceConstructKinetics(this)
            this.testObj = this.testObj.instanceConstructKinetics('roisBuild', this.brainmaskBldr);
            this.verifyTrue(this.testObj.instanceConstructKineticsPassed);
        end
        
		function test_sortDownloads(this)
        end
		function test_sortDownloadCT(this)
        end
		function test_sortDownloadFreesurfer(this)
        end
	end

 	methods (TestClassSetup)
		function setupHyperglycemiaDirector(this)
 			import mlraichle.*;
            sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionPath', fullfile(getenv('PPG'), 'jjleeSynth', 'HYGLY28', ''), ...
                'vnumber', 1, ...
                'tracer', 'HO', ...
                'snumber', 1, ...
                'abs', true, ...
                'ac', true);
            sessd.subjectsFolder = 'jjleeSynth'; %% KLUDGE
            this.brainmaskBldr = mlpet.BrainmaskBuilder('sessionData', sessd);
 			this.testObj_ = HyperglycemiaDirector('sessionData', sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupHyperglycemiaDirectorTest(this)
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

