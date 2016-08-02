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
 		registry
        studyd
        sessPth
 		testObj
 	end

	methods (Test)
		function test_IMRData(this)
            this.verifyEqual(this.testObj.mpr('fqfn'), ...
                fullfile(this.sessPth, 'V1/mpr.4dfp.img'));
            ic = this.testObj.mpr('imagingContext');
            this.verifyClass(ic, 'mlfourd.ImagingContext');
            fprintf('test_IMRData:  viewing %s ..........\n', this.testObj.mpr('fqfn'));
            ic.view;
        end
        function test_IPETData(this)            
            this.verifyEqual(this.testObj.fdgNAC('fqfn'), ...
                fullfile(this.testObj.fdgListmodeLocation('path'), 'FDG_V1-LM-00-OP.4dfp.img'));
            ic = this.testObj.fdgNAC('imagingContext');
            this.verifyClass(ic, 'mlfourd.ImagingContext');
            fprintf('test_IPETData:  viewing %s ..........\n', this.testObj.fdgNAC('fqfn'));
            ic.view;
            
%             this.verifyEqual(this.testObj.ho('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/ho1.4dfp.img'));
%             this.verifyEqual(this.testObj.oc('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/oc1.4dfp.img'));
%             this.verifyEqual(this.testObj.oo('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/oo1.4dfp.img'));
%             this.verifyEqual(this.testObj.ho('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/ho2.4dfp.img'));
%             this.verifyEqual(this.testObj.oc('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/oc2.4dfp.img'));
%             this.verifyEqual(this.testObj.oo('fqfn'), ...
%                 fullfile(this.sessPth, 'V1/oo2.4dfp.img'));
        end
	end

 	methods (TestClassSetup)
		function setupSessionData(this)
 			import mlraichle.*;
            this.studyd = StudyDataSingleton.instance('initialize');
            this.sessPth = fullfile(getenv('PPG'), 'jjlee', 'HYGLY24', '');
 			this.testObj_ = SessionData( ...
                'studyData', this.studyd, ...
                'sessionPath', this.sessPth);
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

