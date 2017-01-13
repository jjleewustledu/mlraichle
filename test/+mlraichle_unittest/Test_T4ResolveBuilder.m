classdef Test_T4ResolveBuilder < matlab.unittest.TestCase
	%% TEST_T4RESOLVEBUILDER 

	%  Usage:  >> results = run(mlraichle_unittest.Test_T4ResolveBuilder)
 	%          >> result  = run(mlraichle_unittest.Test_T4ResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 08-May-2016 16:17:00
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	

	properties
 		registry
        sessd
        studyd
 		testObj
        hygly = 'HYGLY14'
 	end

	methods (Test)
		function test_ctor(this)
            disp(this.studyd);
            disp(this.sessd);
            disp(this.testObj);
        end
        function test_resolve_SYNTH09(~)
            studyd_ = mlraichle.SynthDataSingleton.instance;
            sessd_  = mlraichle.SessionSynthData( ...
                'studyData', studyd_, ...
                'sessionPath', fullfile(studyd_.subjectsDir, 'SYNTH09', ''), ...
                'tracer', 'FDG', ...
                'vnumber', 1);
            t4rb = mlraichle.T4ResolveBuilder( ...
                'sessionData', sessd_, ...
                'frames', [1 1], ...
                'NRevisions', 3);  
            t4rb = t4rb.arrangeMR;
            cd(fullfile(sessd_.fdgNACLocation));
            t4rb.resolve( ...
                'dest', 'fdgv1r1', ...
                'source', 'FDG_V1-LM-00-OP_meant_x2', ...
                'firstCrop', 0.5, ...
                'frames', [1 1], ...
                'mprage', 'mpr');
        end
        function test_runSingleOnConvertedNAC_HYGLY(this)
            mlraichle.T4ResolveBuilder.runSingleOnConvertedNAC( ...
                'sessionFolder', this.hygly, 'visitFolder', 'V2', 'tracerFolder', 'FDG_V2-NAC', 'frames', [zeros(1,12) ones(1,60)], 'NRevisions', 2);
        end
        function test_runSingleOnConvertedNAC_HYGLY_small(this)
            mlraichle.T4ResolveBuilder.runSingleOnConvertedNAC( ...
                'sessionFolder', this.hygly, 'visitFolder', 'V1', 'tracerFolder', 'FDG_V1-NAC', 'frames', this.testingFrames, 'NRevisions', 2);
        end
        function test_buildUmapFrames(this)
            cd(fullfile(this.sessd.sessionPath, 'V1', 'FDG_V1-AC', ''));
            %this.testObj.buildVisitor.copy_4dfp(this.sessd.umap_fqfp, 'fdgv1_umap');
            %copyfile([this.sessd.umap_fqfp '.4dfp.ifh'], 'fdgv1_umap.4dfp.ifh', 'f');
            ipr = struct( ...
                'source',  'fdgv1r1', ...
                'dest',  'fdgv1r1', ...
                'frame0',  4, ...
                'frameF',  64, ...
                'rnumber', 1);
            this.testObj = this.testObj.buildUmapFrames(ipr);
        end
        function test_pasteFramesUmap(this)
            cd(fullfile(this.sessd.sessionPath, 'V1', 'FDG_V1-AC', ''));
            %this.testObj.buildVisitor.copy_4dfp(this.sessd.umap_fqfp, 'fdgv1_umap');
            %copyfile([this.sessd.umap_fqfp '.4dfp.ifh'], 'fdgv1_umap.4dfp.ifh', 'f');
            ipr = struct( ...
                'source',  'fdgv1r1', ...
                'dest',  'fdgv1r1', ...
                'frame0',  4, ...
                'frameF',  64, ...
                'rnumber', 1);
            this.testObj = this.testObj.pasteFramesUmap(ipr);
        end
	end

 	methods (TestClassSetup)
		function setupT4ResolveBuilder(this)
            this.studyd = mlpipeline.StudyDataSingletons.instance('raichle');
            this.sessd = mlraichle.SessionData( ...
                'studyData', this.studyd, 'sessionPath', fullfile(this.studyd.subjectsDir, this.hygly, ''));            
            this.testObj_ = mlraichle.T4ResolveBuilder('sessionData', this.sessd);
            setenv('DEBUG', ''); % cf. dbbash
 		end
	end

 	methods (TestMethodSetup)
		function setupT4ResolveBuilderTest(this)
 			this.testObj = this.testObj_;            
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(~)
 		end
        function frms = testingFrames(~)
            frms = zeros(1,72);
            frms(13) = 1; frms(72) = 1;
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

