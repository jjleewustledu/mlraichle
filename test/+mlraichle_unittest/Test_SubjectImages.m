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
        fast = true
 	end

	methods (Test)
        function test_ctor(this)
            disp(this.testObj);
            disp(this.testObj.referenceImage);
            this.verifyEqual(this.testObj.referenceImage.fileprefix, 'fdgv1r2_op_fdgv1e1to4r1_frame4');
            this.verifyTrue(lexist_4dfp(this.testObj.referenceImage.fqfileprefix));
        end
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_alignCommonModal_fdg(this) % effective tests resolve
            this.testObj = this.testObj.alignCommonModal('FDG');
            this.testObj.view;
        end
        function test_alignCommonModal_ho(this)
            if (this.fast); return; end
            this.testObj = this.testObj.alignCommonModal('HO');
            this.testObj.view;
        end
        function test_alignCommonModal_oo(this)
            if (this.fast); return; end
            this.testObj = this.testObj.alignCommonModal('OO');
            this.testObj.view;
        end
        function test_alignCommonModal_oc(this)
            if (this.fast); return; end
            this.testObj = this.testObj.alignCommonModal('OC');
            this.testObj.view;
        end
        function test_alignCrossModal(this)
            this.assertTrue(strcmpi(this.testObj.referenceTracer, 'FDG'));
            [this.testObj,theFdg,theHo,theOo,theOc] = this.testObj.alignCrossModal;
            this.testObj.view;
            theHo.view;
            theOo.view;
            theOc.view;
            theFdg.view;
        end
        function test_alignDynamicImages(this)
            [this.testObj,theFdg,theHo,theOo,theOc] = this.testObj.alignCrossModal;      
            [theFdg,theHo,theOo,theOc] = this.testObj.alignDynamicImages(theFdg,theHo,theOo,theOc);
            v = mlfourdfp.Viewer;
            v.view({theFdg.product{1},theHo.product{1},theOo.product{1},theOc.product{1}});
        end
        function test_alignOpT1001(this)
            return
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
            this.testObj = this.testObj.alignCommonModal('FDG'); % this.testObj contains necessary tracer information
            this.testObj = this.testObj.productAverage;
            this.testObj.view;
        end
        function test_refreshTracerResolvedFinal(this)
            this.sessd.rnumber = 2; % internal state of this.testObj uses this.rnumberOfSource_ := 2
            [sd,acopy] = this.testObj.refreshTracerResolvedFinal(this.sessd, this.sessd, true); % sumt := true
            
            refFqfn = fullfile(sd.tracerLocation, 'fdgv1r2_op_fdgv1e1to4r1_frame4_sumt.4dfp.ifh');
            this.verifyEqual(sd.supEpoch, 4);
            this.verifyTrue(isdir(sd.vallLocation));
            this.verifyEqual(sd.tracerResolvedFinalSumt, refFqfn);
            [~,r] = mlbash(sprintf('ls -l %s/%s*', ...
                sd.vallLocation, ...
                this.testObj.frontOfFileprefixR1(sd.('tracerResolvedFinalSumt')('typ','fqfp'), true)));
            this.verifyTrue(lstrfind(r, 'fdgv1r1_sumt'));
            
            this.verifyEqual(acopy, fullfile(sd.vallLocation, 'fdgv1r1_sumt'));
            %disp(r)
        end
        function test_sourceImages(this)
            imgs = this.testObj.sourceImages('FDG', true);
            this.verifyEqual(imgs{1}, fullfile(this.sessd.vallLocation,'fdgv1r1_sumt'));
            this.verifyEqual(imgs{2}, fullfile(this.sessd.vallLocation,'fdgv2r1_sumt'));
            %disp(imgs)
            
            imgs = this.testObj.sourceImages('FDG');
            this.verifyEqual(imgs{1}, fullfile(this.sessd.vallLocation, 'fdgv1r1'));
            this.verifyEqual(imgs{2}, fullfile(this.sessd.vallLocation, 'fdgv2r1'));
            %disp(imgs)
        end
        function test_t4imgDynamicImages(this)
        end
        function test_t4mulR(this)            
        end
	end

 	methods (TestClassSetup)
		function setupSubjectImages(this)
 			import mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', mlraichle.SynthStudyData, 'sessionFolder', this.sessf, 'tracer', 'FDG', 'ac', true); % referenceTracer
            assert(strcmp(this.sessd.subjectsDir, fullfile(getenv('PPG'), 'jjleeSynth', '')));
            this.census = StudyCensus('sessionData', this.sessd);
 			this.testObj_ = SubjectImages('sessionData', this.sessd, 'census', this.census);
 			this.addTeardown(@this.cleanFolders);
 		end
	end

 	methods (TestMethodSetup)
		function setupSubjectImagesTest(this)
 			this.testObj = this.testObj_;
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
		function cleanFolders(this)
            if (isdir(this.sessd.vallLocation))
                % rmdir(this.sessd.vallLocation, 's');
            end
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

