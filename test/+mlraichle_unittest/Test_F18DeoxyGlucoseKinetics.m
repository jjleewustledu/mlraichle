classdef Test_F18DeoxyGlucoseKinetics < matlab.unittest.TestCase
	%% TEST_F18DEOXYGLUCOSEKINETICS 

	%  Usage:  >> results = run(mlraichle_unittest.Test_F18DeoxyGlucoseKinetics)
 	%          >> result  = run(mlraichle_unittest.Test_F18DeoxyGlucoseKinetics, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Mar-2017 17:09:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		registry
        sessd
        sessionFolder = 'HYGLY28'
 		testObj
        vnumber = 1
 	end

	methods (Test)
		function test_godo2(this)
 			import mlraichle.*;
 			summary = FDGKineticsWholebrain.godo2(this.sessd);
            this = summary.aparcAsegBinarized_op_fdg;
            this.plot;
 		end
	end

 	methods (TestClassSetup)
		function setupF18DeoxyGlucoseKinetics(this)
 			import mlraichle.*;
            this.sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionFolder', this.sessionFolder, ...
                'vnumber', this.vnumber, ...
                'ac', true);
 		end
	end

 	methods (TestMethodSetup)
		function setupF18DeoxyGlucoseKineticsTest(this)
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

