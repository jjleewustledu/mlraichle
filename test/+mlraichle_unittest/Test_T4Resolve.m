classdef Test_T4Resolve < matlab.unittest.TestCase
	%% TEST_T4RESOLVE 

	%  Usage:  >> results = run(mlraichle_unittest.Test_T4Resolve)
 	%          >> result  = run(mlraichle_unittest.Test_T4Resolve, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 28-Feb-2016 12:21:00
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_parseLog(this)
            this.verifyEqual(this.testObj.imgregLog.length, 144259);
            this.verifyEqual(this.testObj.etas{4,5}, 0.43914);
            this.verifyEqual(this.testObj.curves{4,5}, [615. 589. 746. 370. 434. 302.]);
        end
		function test_report(this)
            r = this.testObj.report;
            this.verifyInstanceOf(r, 'mlraichle.T4ResolveReport');
            r.bar3('etas');
            r.bar3('curves');
 		end
	end

 	methods (TestClassSetup)
		function setupT4Resolve(this)
 			import mlraichle.*;
            studyd = mlpipeline.StudyDataSingletons.instance('test_raichle');
            sessd = SessionData( ...
                'studyData',   studyd, ...
                'sessionPath', fullfile(studyd.subjectsDir, 'NP995_09'), ...
                'snumber',     1, ...
                'vnumber',     1);
 			this.testObj_ = T4Resolve('sessionData', sessd, 'frameLength', 28);
            this.testObj_ = this.testObj_.parseLog( ...
                fullfile(this.testObj_.sessionData.sessionPath, 'V1', 'imgreg_4dfp_pid3054.log'));
 		end
	end

 	methods (TestMethodSetup)
		function setupT4ResolveTest(this)
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

