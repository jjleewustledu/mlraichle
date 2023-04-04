classdef Test_Ccir559754 < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 22-Feb-2023 23:22:20 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
    %  Developed on Matlab 9.13.0.2126072 (R2022b) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlraichle.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_registry(this)
            this.verifyNotEmpty(mlraichle.Ccir559754Registry.instance())
            this.verifyNotEmpty(mlraichle.StudyRegistry.instance())
        end
    end
    
    methods (TestClassSetup)
        function setupCcir559754(this)
            import mlraichle.*
            this.testObj_ = Ccir559754();
        end
    end
    
    methods (TestMethodSetup)
        function setupCcir559754Test(this)
            this.testObj = this.testObj_;
            this.addTeardown(@this.cleanTestMethod)
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
