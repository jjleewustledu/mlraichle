classdef Test_FdgBuilder < matlab.unittest.TestCase
	%% TEST_FDGBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_FdgBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_FdgBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-Dec-2016 17:08:01
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        frames = [0 0 0 1 1 1]
        pwd0
 		registry
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this.verifyEqual(sum(this.testObj.frames), 3);
            this.verifyEqual(sum(this.testObj.frame0), 4);
            this.verifyEqual(sum(this.testObj.frameF), 6);
            this.verifyEqual(sum(this.testObj.blurArg), 5.5, 'RelTol', 1e-2);
        end
		function test_resolveFdg(this)
 			this.testObj.resolveFdg;
 		end
		function test_resolveFdgr2(this)
 			import mlraichle.*;
            sessd = this.testObj.sessionData;
            sessd.rnumber = 2;
            fdgb = FdgBuilder('sessionData', sessd, 'frames', this.frames, 'NRevisions', 2);
 			fdgb.resolveFdg;
        end
        function test_teardownResolve(this)
            this.testObj.teardownResolve;
        end
	end

 	methods (TestClassSetup)
		function setupFdgBuilder(this)
 			import mlraichle.*;
            studyd = SynthStudyData;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY00', '');
            sessd = SynthSessionData('studyData', studyd, 'sessionPath', sessp);
 			this.testObj_ = FdgBuilder('sessionData', sessd, 'frames', this.frames, 'NRevisions', 2);
            this.pwd0 = pushd(sessd.vLocation);
            %backupn(fullfile(sessd.fdgNACLocation), 2);
 			this.addTeardown(@this.cleanClassFiles);
 		end
	end

 	methods (TestMethodSetup)
		function setupFdgBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanMethodFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanClassFiles(this)
            cd(this.pwd0);
 		end
		function cleanMethodFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

