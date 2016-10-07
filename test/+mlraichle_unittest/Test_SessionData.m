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
        studyData
 		testObj
        view = true
 	end

	methods (Test)
        function test_(this)
        end
        function test_freesurfersDir(this)
            this.verifyEqual(this.testObj.freesurfersDir, ...
                fullfile(getenv('PPG'), 'freesurfer', ''));
        end
        function test_subjectsDir(this)
            this.verifyEqual(this.testObj.subjectsDir, ...
                fullfile(getenv('PPG'), 'jjlee', ''));
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
        function test_fourdfpLocation(this)
            this.verifyEqual(this.testObj.fourdfpLocation, fullfile(this.sessionPath, 'V1'));
        end
        function test_fslLocation(this)
            this.verifyEqual(this.testObj.fslLocation, fullfile(this.sessionPath, 'V1', 'fsl', ''));
        end
        function test_mriLocation(this)
            this.verifyEqual(this.testObj.mriLocation, ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY09_V1', 'mri', ''));
        end
        function test_hdrinfoLocation(this)
            this.verifyEqual(this.testObj.hdrinfoLocation, fullfile(this.sessionPath, 'V1'));
        end
        function test_petLocation(this)
            this.verifyEqual(this.testObj.petLocation, fullfile(this.sessionPath, 'V1'));
        end
        function test_scanLocation(this)
            this.verifyEqual(this.testObj.scanLocation, fullfile(this.sessionPath, 'V1'));
        end
        
        function test_aparcA2009sAseg(this)
        end
        function test_atlas(this)
        end
        function test_boldResting(this)
        end
        function test_mpr_path(this)
        end
        function test_mpr_fqfp(this)
        end
        function test_mpr_4dfpIfh(this)
            this.verifyEqual(this.testObj.mpr('typ', '.4dfp.ifh'), ...
                fullfile(this.sessionPath, 'V1', 't1_mprage_sag.4dfp.img'));
        end
        function test_mpr_niiGz(this)
        end
        function test_mpr_mgz(this)
        end
        function test_mpr_imagingContext(this)
            ic = this.testObj.mpr('typ', 'imagingContext');
            this.verifyClass(ic, 'mlfourd.ImagingContext');
            fprintf('test_IMRData:  viewing %s ..........\n', this.testObj.mpr('typ', 'fqfn'));
            ic.view;
        end
        function test_ct(this)
        end
        function test_fdg(this)
        end
        function test_oo(this)
        end        
        function test_umap(this)
        end
        
%         function test_ho1(this)
%             this.testObj.snumber = 1;
%             this.verifyTrue(lexist(this.testObj.ho_fqfn));
%             ho1 = this.testObj.ho;
%             if (this.view); ho1.view; end
%             ho1.save;            
%             this.verifyTrue(lexist(ho1.fqfilename, 'file'));
%             %deleteExisting(oc2.fqfilename);
%         end
%         function test_oc2(this)
%             this.testObj.snumber = 2;
%             this.verifyTrue(lexist(this.testObj.oc_fqfn));
%             oc2 = this.testObj.oc;
%             if (this.view); oc2.view; end
%             oc2.save;            
%             this.verifyTrue(lexist(oc2.fqfilename, 'file'));
%             %deleteExisting(oc2.fqfilename);
%         end
%         function test_oo2(this)
%             this.testObj.snumber = 2;
%             this.verifyTrue(lexist(this.testObj.oo_fqfn));
%             oo2 = this.testObj.oo;
%             if (this.view); oo2.view; end
%             oo2.save;            
%             this.verifyTrue(lexist(oo2.fqfilename, 'file'));
%             %deleteExisting(oc2.fqfilename);
%         end
%         function test_fdg(this)
%             fdg = this.testObj.fdg;
%             this.verifyTrue(lexist(this.testObj.fdg_fqfn));
%             if (this.view); fdg.view; end
%             fdg.save;
%             this.verifyTrue(lexist(fdg.fqfilename, 'file'));
%             %deleteExisting(fdg.fqfilename);
%         end

%         function test_IPETData(this)            
%             this.verifyEqual(this.testObj.fdgNAC('typ', 'fqfn'), ...
%                 fullfile(this.testObj.fdgListmodeLocation, 'FDG_V1-LM-00-OP.4dfp.img'));
%             ic = this.testObj.fdgNAC('typ', 'imagingContext');
%             this.verifyClass(ic, 'mlfourd.ImagingContext');
%             fprintf('test_IPETData:  viewing %s ..........\n', this.testObj.fdgNAC('typ', 'fqfn'));
%             ic.view;
            
%             this.verifyEqual(this.testObj.ho('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/ho1.4dfp.img'));
%             this.verifyEqual(this.testObj.oc('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/oc1.4dfp.img'));
%             this.verifyEqual(this.testObj.oo('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/oo1.4dfp.img'));
%             this.verifyEqual(this.testObj.ho('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/ho2.4dfp.img'));
%             this.verifyEqual(this.testObj.oc('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/oc2.4dfp.img'));
%             this.verifyEqual(this.testObj.oo('fqfn'), ...
%                 fullfile(this.sessionPath, 'V1/oo2.4dfp.img'));
%        end
	end

 	methods (TestClassSetup)
		function setupSessionData(this)
 		end
	end

 	methods (TestMethodSetup)
		function setupSessionDataTest(this)
            this.studyData = mlraichle.StudyDataSingleton.instance('initialize');
 			this.testObj_  = mlraichle.SessionData( ...
                'studyData', this.studyData, ...
                'sessionPath', this.sessionPath, ...
                'snumber', 1, ...
                'vnumber', 1);
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

