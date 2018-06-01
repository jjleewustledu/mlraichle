classdef Test_Herscovitch1985Director < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985DIRECTOR 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_Herscovitch1985Director)
 	%          >> result  = run(mlsiemens_unittest.Test_Herscovitch1985Director, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-May-2018 22:30:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		sessc
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        
        %% physiological diffs/ratios
        
        function test_constructAgi(this)
            this.testObj = this.testObj.constructAgi;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        function test_constructOgi(this)
            this.testObj = this.testObj.constructOgi;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        
        %% traditional physiologicals
        
        function test_constructCmrglc(this)
            this.testObj = this.testObj.constructCmrglc;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        function test_constructCmro2(this)
            this.testObj = this.testObj.constructCmro2;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        function test_constructOef(this)
            this.testObj = this.testObj.constructOef;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        function test_constructCbf(this)
            this.testObj = this.testObj.constructCbf;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        function test_constructCbv(this)
            this.testObj = this.testObj.constructCbv;
            disp(this.testObj.summary)
            this.testObj.aview;
        end
        
        %% tracers aligned to fdg
        
        function test_constructFdg(this)
            this.testObj = this.testObj.constructFdg;
            this.testObj.aview('fslview_deprecated');
        end
        function test_constructOc(this)
            this.testObj = this.testObj.constructOc;
            this.testObj.aview('fslview_deprecated');
        end
        function test_constructHo(this)
            this.testObj = this.testObj.constructHo;
            this.testObj.aview('fslview_deprecated');
        end
        function test_constructOo(this)
            this.testObj = this.testObj.constructOo;
            this.testObj.aview('fslview_deprecated');
        end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985Director(this)
 			import mlraichle.*;
            this.sessc = SessionContext( ...
                'sessinDate', datetime(2016,9,23, 'TimeZone', 'America/Chicago'), ...
                'sessionFolder', 'HYGLY28', 'vnumber', 2);
 			this.testObj_ = Herscovitch1985Director('sessionContext', this.sessc);
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985DirectorTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

