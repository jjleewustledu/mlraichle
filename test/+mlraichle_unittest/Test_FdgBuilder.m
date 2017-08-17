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
        hyglyNN = 'HYGLY28'
        pwd0
 		registry
 		testObj
        tic0
 	end

	methods (Test)
        function test_ctor(this)
        end
        function test_motionCorrectFrames(this)
        end
        function test_motionCorrectEpochs(this)
        end
        function test_motionCorrectModalities(this)
        end
        function test_backProjectUmapToEpochs(this)
        end
        function test_backProjectUmapToFrames(this)
        end
        function test_reconstituteComposites(this)
        end
        
        
        
        function test_motionCorrectNACimageComposite(this)
            this.testObj.motionCorrectNACimageComposite;
        end
        function test_buildCarneyUmap(this)
            this.testObj.buildCarneyUmap;
        end
        function test_buildNACimageComposite(this)
            this.testObj.buildNACimageComposite;
        end
        function test_motionCorrectUmaps(this)
            this.testObj.motionCorrectUmaps;
        end
        function test_buildACimageComposite(this)
            this.testObj.buildACimageComposite;
        end
        function test_motionCorrectACimageComposite(this)
            this.testObj.motionCorrectACimageComposite;
        end
        function test_assembleFdg(this)
            this.testObj.assembleFdg;
        end
        
		function test_resolveFdg(this)
 			this.testObj.resolvePartition;
 		end
		function test_resolveFdgr2(this)
 			import mlraichle.*;
            sessd = this.testObj.sessionData;
            sessd.rnumber = 2;
            fdgb = FdgBuilder('sessionData', sessd, 'indicesLogical', this.indicesLogical, 'NRevisions', 2);
 			fdgb.resolvePartition;
        end
        function test_teardownResolve(this)
            this.testObj.teardownResolve;
        end
        function test_resolveFdgEarlyR1(this)
            this.testObj.indicesLogical = [0 0 1 1 1 1 1 1 1 1 1 1];
            this.testObj.indexOfReference = 12;
            this.testObj.NRevisions = 1;
            this.testObj.resolveTag = 'op_early';
            this.testObj.resolvePartition;
        end
        function test_resolveFdgEarlyR2(this)
            sessd = this.testObj.sessionData;
            sessd.rnumber = 2;    
 			testObj = mlraichle.FdgBuilder( ...
                'sessionData', sessd, 'indicesLogical', [0 0 1 1 1 1 1 1 1 1 1 1], ...
                'indexOfReference', 12, ...
                'NRevisions', 2, ...
                'resolveTag', 'op_early'); %#ok<*PROP>
            testObj.resolvePartition;
        end
        function test_resolveFdgPartitions(this)
            this.testObj.resolveFdgPartitions(3:12,13:24,25:36,37:48,49:60,61:72);
        end
	end

 	methods (TestClassSetup)
		function setupFdgBuilder(this)
 			this.addTeardown(@this.cleanClassFiles);
 		end
	end

 	methods (TestMethodSetup)
		function setupFdgBuilderTest(this)
 			import mlraichle.*;
            studyd = StudyData;
            sessp  = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            sessd  = SessionData('studyData', studyd, 'sessionPath', sessp);
 			this.testObj_ = FdgBuilder('sessionData', sessd, 'NRevisions', 2);
            %this.pwd0 = pushd(sessd.vLocation);
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanMethodFiles);
            this.tic0 = tic;
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
            toc(this.tic0);
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

