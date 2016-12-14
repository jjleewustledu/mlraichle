classdef Test_F18ResolveBuilder < matlab.unittest.TestCase
	%% TEST_F18RESOLVEBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_F18ResolveBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_F18ResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 12-Dec-2016 16:18:51
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        folders = {'FDG_V1-Converted-NAC' 'FDG_V1-NAC'}
        hyglyNN = 'HYGLY00'
 		registry
        sessd
        studyd
 		testObj
 	end

	methods (Test)
		function test_ctor(this)
            disp(this.studyd);
            disp(this.sessd);
            disp(this.testObj);
        end
        function test_resolve(~)
            this.sessd.tracer = 'FDG';
            rb = mlraichle.F18ResolveBuilder( ...
                'sessionData', this.sessd, ...
                'frames', [0 0 0 1 1 1], ...
                'NRevisions', 2);
            rb = rb.arrangeMR;
            pwd0 = pushd(fullfile(this.sessd.fdgNACLocation));
            rb.resolve( ...
                'dest', 'fdgv1r1', ...
                'source', 'FDG_V1-LM-00-OP', ...
                'firstCrop', 0.5, ...
                'frames', [0 0 0 1 1 1], ...
                'mprage', 'mpr');
            this.verifyTrue(lexist('fdgv1r1.4dfp.ifh', 'file'));
            this.verifyTrue(lexist('fdgv1r1_resolved.4dfp.ifh', 'file'));
            this.verifyTrue(lexist('fdgv1r2_resolved.4dfp.ifh', 'file'));
            mlbash('fslview fdgv1r1.4dfp.hdr fdgv1r1_resolved.4dfp.hdr fdgv1r2_resolved.4dfp.hdr');
            popd(pwd0);
        end
	end

 	methods (TestClassSetup)
		function setupF18ResolveBuilder(this)
            [~,h] = mlbash('hostname');
            assert(lstrfind(h, 'william'));
            this.studyd = mlraichle.SynthStudyData;
            this.sessd = mlraichle.SynthSessionData( ...
                'studyData', this.studyd, 'sessionPath', fullfile(this.studyd.subjectsDir, this.hyglyNN, ''));  
            cd(this.sessd.vLocation); 
            this.setupClassFiles;         
            this.testObj_ = mlraichle.F18ResolveBuilder('sessionData', this.sessd);
            setenv('DEBUG', ''); % cf. dbbash
 		end
	end

 	methods (TestMethodSetup)
		function setupF18ResolveBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
        function setupClassFiles(this)
            for f = 1:length(this.folders)
                if (~isdir([this.folders{f} '-TestBackup']))
                    copyfile(this.folders{f}, [this.folders{f} '-TestBackup']);
                end
            end
        end
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

