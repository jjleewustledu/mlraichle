classdef Test_StudyDataSingleton < matlab.unittest.TestCase
	%% TEST_STUDYDATASINGLETON 

	%  Usage:  >> results = run(mlpipeline_unittest.Test_StudyDataSingleton)
 	%          >> result  = run(mlpipeline_unittest.Test_StudyDataSingleton, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Jan-2016 15:41:13
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpipeline/test/+mlpipeline_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
        testObj
 	end

	methods (Test)
        function test_imagingType(this)
            import mlraichle.*;
            obj = fullfile(getenv('PPG'), 'jjlee', 'HYGLY24', 'V1', 'mpr.4dfp.img');
            this.verifyEqual(StudyDataSingleton.imagingType('fn', obj),             basename(obj));
            this.verifyEqual(StudyDataSingleton.imagingType('fqfn', obj),           obj);
            this.verifyEqual(StudyDataSingleton.imagingType('fp', obj),             'mpr');
            this.verifyEqual(StudyDataSingleton.imagingType('fqfp', obj),           myfileprefix(obj));
            this.verifyEqual(StudyDataSingleton.imagingType('folder', obj),         'V1');
            this.verifyEqual(StudyDataSingleton.imagingType('path', obj),           myfileparts(obj));
            this.verifyEqual(StudyDataSingleton.imagingType('ext', obj),            '.4dfp.img');
            this.verifyClass(StudyDataSingleton.imagingType('imagingContext', obj), 'mlfourd.ImagingContext');
        end
        function test_locationType(this)
            import mlraichle.*;
            loc = fullfile(getenv('PPG'), 'jjlee', 'HYGLY24', 'V1', '');
            this.verifyEqual(StudyDataSingleton.locationType('path', loc), loc);
            this.verifyEqual(StudyDataSingleton.locationType('folder', loc), 'V1');
        end
        function test_saveWorkspace(this)
            this.assertFalse(this.testObj.isChpcHostname);
            loc = this.testObj.saveWorkspace;
            this.verifyTrue(lexist(loc, 'file'));
            delete(loc);
        end
        function test_sessionData(this)
            sessd = this.testObj.sessionData('sessionPath', fullfile(getenv('PPG'), 'jjlee', 'HYGLY24', ''));
            this.verifyClass(sessd, 'mlraichle.SessionData');
        end
	end

 	methods (TestClassSetup)
		function setupStudyDataSingletons(this)
            this.testObj = mlraichle.StudyDataSingleton.instance('initialize');
 		end
	end

 	methods (TestMethodSetup)
		function setupStudyDataSingletonsTest(this) %#ok<MANU>
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

