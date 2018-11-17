classdef Test_HyperglycemiaDirector2 < matlab.unittest.TestCase
	%% TEST_HYPERGLYCEMIADIRECTOR2 

	%  Usage:  >> results = run(mlraichle_unittest.Test_HyperglycemiaDirector2)
 	%          >> result  = run(mlraichle_unittest.Test_HyperglycemiaDirector2, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 15-Nov-2018 15:25:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_normalizeNames(this)
            
        end
        function test_constructUmaps(this)
            those = this.testObj.constructUmaps( ...
                'sessionsExpr', 'NP995_24*', ...
                'visitsExpr', 'V1*', ...
                'tracer', 'FDG');
            those.builder.product.view;
        end
	end

 	methods (TestClassSetup)
		function setupHyperglycemiaDirector2(this)
 			import mlraichle.*;
            sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', fullfile(RaichleRegistry.instance.subjectsDir, 'NP995_24', ''), ...
                'vnumber', 1, ...
                'ac', false);
 			this.testObj_ = HyperglycemiaDirector2('sessionData', sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupHyperglycemiaDirector2Test(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

