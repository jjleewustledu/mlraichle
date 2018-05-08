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
        function test_alignCrossModal(this)
            this.assertTrue(strcmpi(this.testObj.referenceTracer, 'FDG'));
            [this.testObj,theFdg] = this.testObj.alignCrossModal;
            this.testObj.view;
            theFdg.view;
        end
        function test_alignOpT1001(this)
            imgsSumt = reshape(this.testObj.sourceImages('FDG', true), 1, []);
            this.testObj.product = imgsSumt;
            this.testObj = this.testObj.alignOpT1001;
            this.testObj.view;
        end
        function test_dropSumt(this)
            this.verifyEqual(this.testObj.dropSumt('/path/to/file_sumt_op_something_sumt.4dfp.ifh'), ...
                '/path/to/file.4dfp.ifh');
            this.verifyEqual(this.testObj.dropSumt('/path/to/file_sumt_op_something.4dfp.ifh'), ...
                '/path/to/file.4dfp.ifh');
            this.verifyEqual(this.testObj.dropSumt('/path/to/file_sumt_op_something'), ...
                '/path/to/file');
            this.verifyEqual(this.testObj.dropSumt({'file_sumt_op_something' 'stuff_sumt_op_or_other'}), ...
                {'file' 'stuff'});
        end
        function test_frontOfFileprefix(this)
            fps = {'fdgv1r2_op_fdgv1e1to4r1_frame4_sumt' 'fdgv1r2_op_fdgv1e1to4r1_frame4_sumt_op_somethingv1r1'};
            this.verifyEqual(this.testObj.frontOfFileprefix(fps{1}), 'fdgv1r2');
            this.verifyEqual(this.testObj.frontOfFileprefix(fps{2}), 'fdgv1r2');
            this.verifyEqual(this.testObj.frontOfFileprefix(fps), {'fdgv1r2' 'fdgv1r2'});
        end
        function test_productAverage(this)
            this.testObj = this.testObj.alignCommonModal('FDG');
            this.testObj = this.testObj.productAverage;
            this.testObj.view;
        end
        function test_sourceImages(this)
            disp(this.testObj.sourceImages('OC'))
            disp(this.testObj.sourceImages('OO'))
            disp(this.testObj.sourceImages('HO'))
            disp(this.testObj.sourceImages('FDG'))
        end
        function test_t4img_4dfp(this)
            this.testObj = this.testObj.alignCommonModal('FDG');
            this.testObj.view;
            this.testObj = this.testObj.t4img_4dfp('FDG');
            this.testObj.view;
        end
        function test_t4mul(this)
            
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

