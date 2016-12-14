classdef Test_O15ResolveBuilder < matlab.unittest.TestCase
	%% TEST_O15RESOLVEBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_O15ResolveBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_O15ResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 12-Dec-2016 16:18:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        folders = {'OC1_V1-Converted-NAC' 'OC1_V1-NAC'}
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
            this.sessd.tracer = 'OC';
            rb = mlraichle.O15ResolveBuilder( ...
                'sessionData', this.sessd, ...
                'frames', [1 1 1], ...
                'NRevisions', 2);
            rb = rb.arrangeMR;
            pwd0 = pushd(fullfile(this.sessd.tracerNACLocation));
            rb.resolve( ...
                'dest', 'oc1v1r1', ...
                'source', 'OC1_V1-LM-00-OP', ...
                'firstCrop', 0.5, ...
                'frames', [1 1 1], ...
                'mprage', 'mpr');
            this.verifyTrue(lexist('oc1v1r1.4dfp.ifh', 'file'));
            this.verifyTrue(lexist('oc1v1r1_resolved.4dfp.ifh', 'file'));
            this.verifyTrue(lexist('oc1v1r2_resolved.4dfp.ifh', 'file'));
            mlbash('fslview oc1v1r1.4dfp.hdr oc1v1r1_resolved.4dfp.hdr oc1v1r2_resolved.4dfp.hdr');
            popd(pwd0);
        end
	end

 	methods (TestClassSetup)
		function setupO15ResolveBuilder(this)
            [~,h] = mlbash('hostname');
            assert(lstrfind(h, 'william'));
            this.studyd = mlraichle.SynthStudyData;
            this.sessd = mlraichle.SynthSessionData( ...
                'studyData', this.studyd, 'sessionPath', fullfile(this.studyd.subjectsDir, this.hyglyNN, ''));
            cd(this.sessd.vLocation);
            this.setupClassFiles;           
            this.testObj_ = mlraichle.O15ResolveBuilder('sessionData', this.sessd);
            setenv('DEBUG', ''); % cf. dbbash
 		end
	end

 	methods (TestMethodSetup)
		function setupO15ResolveBuilderTest(this)
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

