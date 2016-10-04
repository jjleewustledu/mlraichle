classdef Test_StudyDataSingleton < matlab.unittest.TestCase
	%% TEST_STUDYDATASINGLETON 

	%  Usage:  >> results = run(mlraichle_unittest.Test_StudyDataSingleton)
 	%          >> result  = run(mlraichle_unittest.Test_StudyDataSingleton, 'test_dt')
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
        function test_instance(this)
            this.verifyClass(this.testObj, 'mlraichle.StudyDataSingleton');
            this.verifyEqual(this.testObj.dicomExtension, 'dcm');            
        end
        function test_freesurfersDir(this)
            this.verifyEqual(this.testObj.freesurfersDir, ...
                fullfile(getenv('PPG'), 'freesurfer', ''));
        end
        function test_rawdataDir(this)
            this.verifyEqual(this.testObj.rawdataDir, ...
                fullfile(getenv('PPG'), 'rawdata', ''));
        end
        function test_subjectsDir(this)
            this.verifyEqual(this.testObj.subjectsDir, ...
                fullfile(getenv('PPG'), 'jjlee', ''));
        end
        function test_register(this)
            sdss = mlpipeline.StudyDataSingletons.instance;
            this.verifyTrue(lstrfind(sdss.registry.keys, 'raichle'));
            this.verifyClass(mlpipeline.StudyDataSingletons.instance('raichle'), 'mlraichle.StudyDataSingleton');
        end
        function test_replaceSessionData(this)
            this.testObj = this.testObj.replaceSessionData('sessionPath', this.aSessionPath('NP995_09'));
            this.verifyClass(this.testObj.sessionData, 'mlraichle.SessionData');
            this.verifyEqual(this.testObj.sessionData.sessionPath, this.aSessionPath('NP995_09'));
        end
        function test_sessionData_sessionDataComposite_(this)
            cc = this.testObj.sessionData;
            this.verifyClass(cc, 'mlpatterns.CellComposite');
            this.verifyEqual(cc{1}.sessionPath, this.aSessionPath('HYGLY05'));
            this.verifyEqual(length(cc), length(this.testObj.subjectsDirFqdns));
        end
        function test_sessionData_sessionPath(this)
            sessPth = this.aSessionPath('HYGLY24');
            sessd = this.testObj.sessionData('sessionPath', sessPth);
            this.verifyClass(sessd, 'mlraichle.SessionData');
            this.verifyEqual(sessd.sessionPath, sessPth);
        end
        function test_sessionData_instance1(this)
            import mlraichle.*;
            testObj_inst1 = StudyDataSingleton.instance( ...
                            SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY05')));
            this.verifyClass(testObj_inst1.sessionData, 'mlraichle.SessionData');
            this.verifyEqual(testObj_inst1.sessionData.sessionPath, this.aSessionPath('HYGLY05'));
        end
        function test_sessionData_instance2(this)
            import mlraichle.*;
            testObj_inst2 = StudyDataSingleton.instance( ...
                            SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY05')), ...
                            SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY08')));
            this.verifyClass(testObj_inst2.sessionData, 'mlpatterns.CellComposite');
            this.verifyEqual(testObj_inst2.sessionData.length, 2);
            this.verifyEqual(testObj_inst2.sessionData{1}.sessionPath, this.aSessionPath('HYGLY05'));
            this.verifyEqual(testObj_inst2.sessionData{2}.sessionPath, this.aSessionPath('HYGLY08'));
        end
        function test_sessionData_instanceComposite(this)
            import mlraichle.* mlpatterns.*;
            cc = CellComposite({ ...
                 SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY05')) ...
                 SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY08')) ...
                 SessionData('studyData', this.testObj, 'sessionPath', this.aSessionPath('HYGLY09')) });
            testObj_CC = StudyDataSingleton.instance(cc);
            this.verifyClass(testObj_CC.sessionData, 'mlpatterns.CellComposite');
            this.verifyEqual(testObj_CC.sessionData.length, 3);
            this.verifyEqual(testObj_CC.sessionData{3}.sessionPath, this.aSessionPath('HYGLY09'));
        end
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
	end

 	methods (TestClassSetup)
		function setupStudyDataSingletons(this)
 		end
	end

 	methods (TestMethodSetup)
		function setupStudyDataSingletonsTest(this)
            this.testObj_ = mlraichle.StudyDataSingleton.instance('initialize');
            this.testObj = this.testObj_;
 		end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function pth = aSessionPath(~, fold)
            pth = fullfile(getenv('PPG'), 'jjlee', fold, '');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

