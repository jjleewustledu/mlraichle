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
        sessf = 'HYGLY26'
 		testObj
        fast = false
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
            this.testObj = this.testObj.alignCrossModal;
            this.testObj.view;
            cellfun(@(p) p.view, this.testObj.product, 'UniformOutput', false);
        end
        function test_alignCrossModalSubset(this)
            this.testObj = this.testObj.alignCrossModalSubset;
            this.testObj.view;         
        end
        function test_alignDynamicImages(this)
            this.testObj = this.testObj.alignCrossModalSubset;      
            this.testObj = this.testObj.alignDynamicImages;
            this.testObj.view;
        end
        function test_alignFrameGroups(this)
            this.testObj.alignFrameGroups('FDG', 1:8, 9:73);
            disp(this.testObj.compositeRB.t4_resolve_err); % [NaN 0.140159562550168;0.140159562550168 NaN]
        end
        function test_alignOpT1001(this)
            return
            imgsSumt = reshape(this.testObj.sourceImages('FDG', true), 1, []);
            this.testObj.product = imgsSumt;
            this.testObj = this.testObj.alignOpT1001;
            this.testObj.view;
        end        
        
        function test_constructFramesSubset(this) % effective tests resolve
            this.testObj = this.testObj.constructFramesSubset('FDG', 1:8);
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
        function test_extractCharFromNestedCells(this)
            c = {{'some_to_other_t4'}};
            this.verifyEqual(this.testObj.extractCharFromNestedCells(c), c{1}{1});
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
        function test_reconstructErrMat(this)
            errs = this.testObj_.reconstructErrMat;
            this.verifyTrue(isa(errs, 'containers.Map'));
            % pcolor(errs('fdge1'));
            % pcolor(errs('fdge2'));
            % pcolor(errs('fdge3'));
            % disp(  errs('fdge1to4'));
            disp(  errs('fdgall'));
            disp(  errs('hoall'));
            disp(  errs('ooall'));
            disp(  errs('ocall'));
            disp(  errs('fho'));
            disp(  errs('fc'));
            disp(  errs('fhoc'));
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
        function test_selectT4s(this)
            cross = this.testObj.alignCrossModalSubset;  
            
            % select source 
            c = cross.selectT4s('sourceTracer', 'OC');
            this.verifyEqual(c{1}{1}, 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4');
            c = cross.selectT4s('sourceTracer', 'FDG');
            this.verifyEqual(c{1}{1}, 'fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_to_op_fdgv1r1_t4');
            
            % select dest
            c = cross.selectT4s('destTracer', 'FDG');
            this.verifyEqual(c{1}{1}, 'fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_to_op_fdgv1r1_t4');
            this.verifyEqual(c{1}{2}, 'ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4');
            
            % null results
            this.verifyTrue(isempty(cross.selectT4s('sourceTracer', 'HO')));    
            this.verifyTrue(isempty(cross.selectT4s('destTracer',   'OC')));
            this.verifyTrue(isempty(cross.selectT4s('destTracer',   'HO')));
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
            p = {[] []};
            fv = mlfourdfp.FourdfpVisitor;
            copyfile(fv.transverse_t4, 'testsrc_to_testdest_t4', 'f');
            copyfile(fv.transverse_t4, 'testdest_to_testdest2_t4', 'f');
            t{1} = {'testsrc_to_testdest_t4' 'testsrc_to_testdest_t4'};
            this.testObj = this.testObj.prepare_test_t4mulR(this.testObj, p, t);            
            mulled = this.testObj.t4mulR('testdest_to_testdest2_t4'); 
            this.verifyEqual(mulled{1}{1}, 'testsrc_to_testdest2_t4');
            this.verifyEqual(mulled{1}{2}, 'testsrc_to_testdest2_t4');
            mlbash(['cat ' mulled{1}{1}], 'echo', true);
        end
        function test_t4imgc(this) 
            fv = mlfourdfp.FourdfpVisitor;
            t4form = 'test_t4imgc_to_test_t4imgc_t4'; % file for identity
            copyfile(fv.transverse_t4, t4form, 'f');
            
            cross = this.testObj.alignCrossModalSubset;
            prod0 = cross.product;
            cross = cross.t4imgc(t4form, cross.product);
            mlfourdfp.Viewer.view([prod0 cross.product]);   
        end
	end

 	methods (TestClassSetup)
		function setupSubjectImages(this)
 			import mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', mlraichle.StudyData, 'sessionFolder', this.sessf, 'tracer', 'FDG', 'ac', true); % referenceTracer
            assert(strcmp(this.sessd.subjectsDir, fullfile(getenv('PPG'), 'jjlee2', '')));
            ensuredir(this.sessd.vallLocation);
            this.census = StudyCensus('sessionData', this.sessd);
 			this.testObj_ = SubjectImages('sessionData', this.sessd, 'census', this.census);
 			this.addTeardown(@this.cleanFolders);
 		end
	end

 	methods (TestMethodSetup)
		function setupSubjectImagesTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
            cd(this.sessd.vallLocation);
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

