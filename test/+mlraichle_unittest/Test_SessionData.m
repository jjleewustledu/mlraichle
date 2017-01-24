classdef Test_SessionData < matlab.unittest.TestCase
	%% TEST_SESSIONDATA 

	%  Usage:  >> results = run(mlraichle_unittest.Test_SessionData)
 	%          >> result  = run(mlraichle_unittest.Test_SessionData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 10-Jun-2016 14:13:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	

	properties
        sessionPath = fullfile(getenv('PPG'), 'jjlee', 'HYGLY09', '')
        vPath       = fullfile(getenv('PPG'), 'jjlee', 'HYGLY09', 'V1', '') 
        studyData
 		testObj
        view = false
 	end

	methods (Test)
        
        %% TOP-LEVEL
        
        function test_freesurfersDir(this)
            this.verifyEqual(this.testObj.freesurfersDir, ...
                fullfile(getenv('PPG'), 'freesurfer', ''));
        end
        function test_subjectsDir(this)
            this.verifyEqual(this.testObj.subjectsDir, ...
                fullfile(getenv('PPG'), 'jjlee2', ''));
        end
        function test_sessionPath(this)
            this.verifyEqual(this.testObj.sessionPath, this.sessionPath);
        end
        function test_sessionFolder(this)
            [~,fold] = fileparts(this.sessionPath);
            this.verifyEqual(this.testObj.sessionFolder, fold);
        end
        function test_sessionLocation(this)
            this.verifyEqual(this.testObj.sessionLocation, this.sessionPath);
        end
        function test_vLocation(this)
            this.verifyEqual(this.testObj.vLocation, fullfile(this.sessionPath, 'V1'));
        end
        
        %% IMRData
        
        function test_fourdfpLocation(this)
            this.verifyEqual(this.testObj.fourdfpLocation, fullfile(this.sessionPath, 'V1'));
        end
        function test_freesurferLocation(this)
            this.verifyEqual(this.testObj.freesurferLocation, fullfile(getenv('PPG'), 'freesurfer', 'HYGLY09_V1'));
        end
        function test_fslLocation(this)
            this.verifyEqual(this.testObj.fslLocation, fullfile(this.vPath, 'fsl', ''));
        end
        function test_mriLocation(this)
            this.verifyEqual(this.testObj.mriLocation, ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY09_V1', 'mri', ''));
        end
        
        function test_aparcA2009sAseg(this)
            this.verifyEqual(this.testObj.aparcA2009sAseg('typ', 'fqfn'), ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY09_V1', 'mri', 'aparc.a2009s+aseg.mgz'));
        end
        function test_atlas(this)
            this.verifyEqual(this.testObj.atlas('typ', 'fqfn'), ...
                fullfile(getenv('REFDIR'), 'TRIO_Y_NDC.4dfp.ifh'));
        end
        function test_mpr_path(this)
            this.verifyEqual(this.testObj.mpr('typ', 'path'), ...
                fullfile(this.vPath, ''));
        end
        function test_mpr_fqfp(this)
            this.verifyEqual(this.testObj.mpr('typ', 'fqfp'), ...
                fullfile(this.vPath, 'mpr'));
        end
        function test_mpr_4dfpIfh(this)
            this.verifyEqual(this.testObj.mpr('typ', '.4dfp.ifh'), ...
                fullfile(this.vPath, 'mpr.4dfp.ifh'));
        end
        function test_mpr_niiGz(this)
        end
        function test_mpr_mgz(this)
        end
        function test_mpr_imagingContext(this)
            ic = this.testObj.mpr('typ', 'imagingContext');
            this.verifyClass(ic, 'mlfourd.ImagingContext');
            if (this.view)
                fprintf('\ntest_mpr_imagingContext:  viewing %s\n', this.testObj.mpr('typ', '4dfp.img'));
                ic.view;
            end
        end
        function test_ensureMRFqfilename(this)
            %delete(this.testObj.t2);
        end
        
        %% IPETData
        
        function test_ct(this)
            this.verifyEqual(this.testObj.ct('typ', 'fqfp'), ...
                fullfile(this.sessionPath, 'ct'));
        end
        function test_hdrinfoLocation(this)
            this.verifyEqual(this.testObj.hdrinfoLocation, fullfile(this.vPath));
        end
        function test_petLocation(this)
            this.verifyEqual(this.testObj.petLocation, fullfile(this.vPath));
        end
        function test_scanLocation(this)
            this.verifyEqual(this.testObj.scanLocation, fullfile(this.vPath));
        end
        
        function test_fdgAC(this)
            this.verifyEqual( ...
                this.testObj.fdgAC('typ', 'fqfn'), ...
                fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-AC', 'FDG_V1-LM-00-OP.4dfp.ifh'));
        end
        function test_fdgListmodeFrameV(this)
            this.verifyEqual( ...
                this.testObj.fdgListmodeFrameV(1, 'typ', 'fqfn'), ...
                fullfile(this.testObj.fdgListmodeLocation, 'FDG_V1-LM-00-OP_001_000.v'));
        end
        function test_fdgListModeLocation(this)
            this.verifyEqual( ...
                this.testObj.fdgListmodeLocation, ...
                fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-Converted-NAC', 'FDG_V1-LM-00', ''));
        end
        function test_fdgListmodeSif(this)
            this.verifyEqual( ...
                this.testObj.fdgListmodeSif('typ', 'fqfn'), ...
                fullfile(this.testObj.fdgListmodeLocation, 'FDG_V1-LM-00-OP.4dfp.ifh'));
        end
        function test_fdgListmodeUmap(this)
            this.verifyEqual( ...
                this.testObj.fdgListmodeUmap('typ', 'fqfn'), ...
                fullfile(this.testObj.fdgListmodeLocation, 'FDG_V1-LM-00-umap.v'));
        end
        function test_fdgNAC(this)
            this.verifyEqual( ...
                this.testObj.fdgNAC('typ', 'fqfn'), ...
                fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-NAC', 'FDG_V1-LM-00-OP.4dfp.ifh'));
        end
        function test_fdgNACResolved(this)
            this.testObj.builder = mlfourdfp.T4ResolveBuilder('sessionData', this.testObj);
            this.verifyEqual( ...
                this.testObj.fdgNACResolved('typ', 'fqfn'), ...
                fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-NAC', 'fdgv1r1_resolved.4dfp.ifh'));
        end
        function test_fdg(this)
        end
        function test_ho(this)
        end 
        
	end

 	methods (TestClassSetup)
		function setupSessionData(this)
            this.studyData = mlraichle.StudyData;
 			this.testObj_  = mlraichle.SessionData( ...
                'studyData', this.studyData, ...
                'sessionPath', this.sessionPath, ...
                'snumber', 1, ...
                'vnumber', 1);
 		end
	end

 	methods (TestMethodSetup)
		function setupSessionDataTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this) %#ok<MANU>
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

