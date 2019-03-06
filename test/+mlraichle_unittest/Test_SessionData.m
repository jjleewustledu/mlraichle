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
        constructView = true
        sessf = 'HYGLY09';
        sessp
        studyd
 		testObj
        tracer = 'FDG'
 	end

	methods (Test)
        
        %% TOP-LEVEL
        
        function test_testObj(this)
            this.verifyClass(this.testObj, 'mlraichle.SessionData');
        end
        function test_subjectsDir(this)
            this.verifyEqual(this.testObj.subjectsDir, this.studyd.subjectsDir);
        end
        function test_sessionFolder(this)
            this.verifyEqual(this.testObj.sessionFolder, this.sessf);
        end
        function test_sessionLocation(this)
            this.verifyEqual(this.testObj.sessionLocation, this.sessp);
        end
        function test_sessionPath(this)
            this.verifyEqual(this.testObj.sessionPath, this.sessp);
        end
        function test_vLocation(this)
            this.verifyEqual(this.testObj.sessionPath, this.sessp);
        end
        
        %% IMRData
        
        function test_aparcA2009sAseg(this)
            this.verifyEqual(this.testObj.aparcA2009sAseg('typ', 'fqfn'), ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY28_V1', 'mri', 'aparc.a2009s+aseg.mgz'));
        end
        function test_atlas(this)
            this.verifyEqual(this.testObj.atlas('typ', 'fqfn'), ...
                fullfile(getenv('REFDIR'), 'TRIO_Y_NDC.4dfp.hdr'));
        end
        function test_brainmask(this)
            this.verifyEqual(this.testObj.brainmask('typ', 'fqfn'), ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY28_V1', 'mri', 'brainmask.mgz'));
        end
        function test_freesurferLocation(this)
            this.verifyEqual(this.testObj.freesurferLocation, fullfile(getenv('PPG'), 'freesurfer', 'HYGLY28_V1'));
        end
        function test_fslLocation(this)
            this.verifyEqual(this.testObj.fslLocation, fullfile(this.sessp, 'fsl', ''));
        end
        function test_mriLocation(this)
            this.verifyEqual(this.testObj.mriLocation, ...
                fullfile(getenv('PPG'), 'freesurfer', 'HYGLY28_V1', 'mri', ''));
        end              
        function test_T1(this)
            this.verifyEqual(this.testObj.T1('typ', 'fqfn'), ...
                fullfile(this.sessp, 'T1001.4dfp.hdr'));
        end     
        function test_T1001(this)
            this.verifyEqual(this.testObj.T1('typ', 'fqfn'), ...
                fullfile(this.sessp, 'T1001.4dfp.hdr'));
        end
        
        function test_mpr_path(this)
            this.verifyEqual(this.testObj.mpr('typ', 'path'), ...
                fullfile(this.sessp, ''));
        end
        function test_mpr_fqfp(this)
            this.verifyEqual(this.testObj.mpr('typ', 'fqfp'), ...
                fullfile(this.sessp, 'T1001'));
        end
        function test_mpr_4dfpIfh(this)
            this.verifyEqual(this.testObj.mpr('typ', '.4dfp.hdr'), ...
                fullfile(this.sessp, 'T1001.4dfp.hdr'));
        end
        function test_mpr_niiGz(this)
            this.verifyEqual(this.testObj.mpr('typ', '.nii.gz'), ...
                fullfile(this.sessp, 'T1001.nii.gz'));
        end
        function test_mpr_imagingContext(this)
            ic = this.testObj.mpr('typ', 'mlmr.MRImagingContext');
            this.verifyClass(ic, 'mlmr.MRImagingContext');
            if (this.constructView)
                ic.view;
            end
        end        
        
        %% IPETData
        
        function test_ct(this)
            this.verifyEqual(this.testObj.ct('typ', 'fqfp'), fullfile(this.sessp, 'ct'));
        end
        function test_hdrinfoLocation(this)
            this.verifyEqual(this.testObj.hdrinfoLocation, fullfile(this.sessp));
        end
        function test_petLocation(this)
            this.verifyEqual(this.testObj.petLocation, fullfile(this.sessp, 'FDG_V1-NAC', ''));
        end
        
        function test_tracerListmodeFrameV(this)
            this.verifyEqual( ...
                this.testObj.tracerListmodeFrameV(1, 'typ', 'fqfn'), ...
                fullfile(this.testObj.tracerListmodeLocation, 'FDG_V1-LM-00-OP_001_000_frame1.v'));
        end
        function test_tracerListModeLocation(this)
            this.verifyEqual( ...
                this.testObj.tracerListmodeLocation, ...
                fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-Converted-NAC', 'FDG_V1-LM-00', ''));
        end
        function test_tracerListmodeSif(this)
            this.verifyEqual( ...
                this.testObj.tracerListmodeSif('typ', 'fqfn'), ...
                fullfile(this.testObj.tracerListmodeLocation, 'FDG_V1-LM-00-OP.4dfp.hdr'));
        end
        function test_tracerListmodeUmap(this)
            this.verifyEqual( ...
                this.testObj.tracerListmodeUmap('typ', 'fqfn'), ...
                fullfile(this.testObj.tracerListmodeLocation, 'FDG_V1-LM-00-umap.v'));
        end        
        
        function test_tracerAC(this)
%             this.verifyEqual( ...
%                 this.testObj.tracerAC('typ', 'fqfn'), ...
%                 fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-AC', 'FDG_V1-LM-00-OP.4dfp.hdr'));
        end
        function test_tracerNAC(this)
%             this.verifyEqual( ...
%                 this.testObj.tracerNAC('typ', 'fqfn'), ...
%                 fullfile(this.testObj.sessionPath, 'V1', 'FDG_V1-NAC', 'FDG_V1-LM-00-OP.4dfp.hdr'));
        end
        function test_tracerLocation(this)
            this.testObj.attenuationCorrected = true;
            this.verifyEqual(this.testObj.tracerLocation, ...
                sprintf('%s/%s/%s-AC', ...
                this.studyd.subjectsDir, this.sessf, this.tracer));
        end
        function test_tracerRevision(this)
            this.testObj.attenuationCorrected = true;
            this.verifyEqual(this.testObj.tracerRevision, ...
                sprintf('%s/%s/%s-AC/%sr1.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer)));
            % fdgv1r1.4dfp.hdr            
            this.testObj.epoch = 1;             
            this.verifyEqual(this.testObj.tracerRevision, ...
                sprintf('%s/%s/%s-AC/E1/%se1r1.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer)));
            % E1/fdgv1e1r1.4dfp.hdr
            this.testObj.epoch = 1:4; 
            this.verifyEqual(this.testObj.tracerRevision, ...
                sprintf('%s/%s/%s-AC/E1to4/%se1to4r1.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer)));
            % E1to4/fdgv1e1to4r1.4dfp.hdr  
            this.testObj.rnumber = 2;
            this.verifyEqual(this.testObj.tracerRevision, ...
                sprintf('%s/%s/%s-AC/E1to4/%se1to4r2.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer)));
            % E1to4/fdgv1e1to4r2.4dfp.hdr  
        end
        function test_resolveTagFrame(this)
            this.testObj.attenuationCorrected = true;
            this.verifyEqual(this.testObj.resolveTagFrame(24, 'reset', false), ...
                sprintf('op_%sr1_frame24', lower(this.tracer)));
            this.verifyEqual(this.testObj.resolveTagFrame(24, 'reset', true), ...
                sprintf('op_%sr1_frame24', lower(this.tracer)));
        end
        function test_tracerResolved(this)
            this.testObj.attenuationCorrected = true;
            this.verifyEqual(this.testObj.tracerResolved, ...
                sprintf('%s/%s/%s-AC/%sr1_op_%sr1.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % fdgv1r1_op_fdgv1r1.4dfp.hdr
            this.testObj.epoch = 1;            
            this.verifyEqual(this.testObj.tracerResolved, ...
                sprintf('%s/%s/%s-AC/E1/%se1r1_op_%se1r1.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % E1/fdgv1e1r1_op_fdgv1e1r1.4dfp.hdr
            this.testObj.epoch = 1; 
            this.testObj.resolveTag = this.testObj.resolveTagFrame(24, 'reset', true);  
            this.verifyEqual(this.testObj.tracerResolved, ...
                sprintf('%s/%s/%s-AC/E1/%se1r1_op_%se1r1_frame24.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % E1/fdgv1e1r1_op_fdgv1e1r1_frame24.4dfp.hdr  
            this.testObj.epoch = 1:4;
            this.testObj.resolveTag = this.testObj.resolveTagFrame(4, 'reset', true);              
            this.verifyEqual(this.testObj.tracerResolved, ...
                sprintf('%s/%s/%s-AC/E1to4/%se1to4r1_op_%se1to4r1_frame4.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % E1to4/fdgv1e1to4r1_op_fdgv1e1to4r1_frame4.4dfp.hdr 
            this.testObj.rnumber = 2;
            this.verifyEqual(this.testObj.tracerResolved, ...
                sprintf('%s/%s/%s-AC/E1to4/%se1to4r2_op_%se1to4r1_frame4.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % E1to4/fdgv1e1to4r2_op_fdgv1e1to4r1_frame4.4dfp.hdr 
        end
        function test_tracerResolvedFinal(this)
            this.testObj.attenuationCorrected = true;
            this.verifyEqual(this.testObj.tracerResolvedFinal, ...
                sprintf('%s/%s/%s-AC/%sr1_op_%se1to4r1_frame4.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % fdgv1r1_op_fdgv1e1to4r1_frame4.4dfp.hdr
            this.testObj.epoch = 1;
            this.verifyEqual(this.testObj.tracerResolvedFinal, ...
                sprintf('%s/%s/%s-AC/E1/%se1r1_op_%se1to4r1_frame4.4dfp.hdr', ...
                this.studyd.subjectsDir, this.sessf, this.tracer, lower(this.tracer), lower(this.tracer)));
            % E1/fdgv1e1r1_op_fdgv1e1to4r1_frame4.4dfp.hdr            
        end
        function test_fdg(this)
        end
        function test_ho(this)
        end 
        function test_oo(this)
        end 
        function test_oc(this)
        end
        function test_oef(this)
        end 
        function test_cmro2(this)
        end 
        function test_cmrglc(this)
        end        
	end

 	methods (TestClassSetup)
		function setupSessionData(this)
            this.studyd = mlraichle.StudyData;
            this.sessp  = fullfile(this.studyd.subjectsDir, this.sessf, '');
 			this.testObj_  = mlraichle.SessionData( ...
                'studyData', this.studyd, ...
                'sessionPath', this.sessp, ...
                'snumber', 1, ...
                'tracer', this.tracer);
 		end
	end

 	methods (TestMethodSetup)
		function setupSessionDataTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this) %#ok<MANU>
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

