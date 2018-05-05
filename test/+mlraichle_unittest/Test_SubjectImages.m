classdef Test_SubjectImages < matlab.unittest.TestCase
	%% TEST_SUBJECTIMAGES 

	%  Usage:  >> results = run(mlraichle_unittest.Test_SubjectImages)
 	%          >> result  = run(mlraichle_unittest.Test_SubjectImages, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 04-May-2018 16:07:48 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        census
 		registry
        sessd
        sessf = 'HYGLY28'
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_alignCommonModal_fdg(this)
            this.testObj = this.testObj.alignCommonModal('FDG');
            this.testObj.view;
        end
        function test_alignCommonModal_ho(this)
            this.testObj = this.testObj.alignCommonModal('HO');
            this.testObj.view;
        end
        function test_alignCommonModal_oo(this)
            this.testObj = this.testObj.alignCommonModal('OO');
            this.testObj.view;
        end
        function test_alignCommonModal_oc(this)
            this.testObj = this.testObj.alignCommonModal('OC');
            this.testObj.view;
        end
        function test_alignCrossModalToReference(this)
            this.assertTrue(strcmpi(this.testObj.referenceImage, 'FDG'));
            this.testObj.alignCrossModalToReference;
        end
        function test_sourceImages(this)
            disp(this.testObj.sourceImages('OC'))
            disp(this.testObj.sourceImages('OO'))
            disp(this.testObj.sourceImages('HO'))
            disp(this.testObj.sourceImages('FDG'))
        end
	end

 	methods (TestClassSetup)
		function setupSubjectImages(this)
 			import mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', mlraichle.StudyData, 'sessionFolder', this.sessf, 'tracer', 'FDG'); % referenceTracer
            this.census = StudyCensus('sessionData', this.sessd);
 			this.testObj_ = SubjectImages( ...
                'sessionData', this.sessd, 'census', this.census);
 		end
	end

 	methods (TestMethodSetup)
		function setupSubjectImagesTest(this)
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

