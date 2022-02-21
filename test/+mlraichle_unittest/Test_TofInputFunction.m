classdef Test_TofInputFunction < matlab.unittest.TestCase
	%% TEST_TOFINPUTFUNCTION 

	%  Usage:  >> results = run(mlraichle_unittest.Test_TofInputFunction)
 	%          >> result  = run(mlraichle_unittest.Test_TofInputFunction, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 22-Nov-2021 20:34:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.11.0.1809720 (R2021b) Update 1 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        anatPath
        bbBuffer
        cacheMat % assign after segmentations, centerlines, registration targets are ready
        corners
        ho
        ho_sumt
        mmppix
        petPath
 		registry
        sourceAnatPath
        sourcePetPath
        t1w
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlraichle.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
            disp(this.testObj)
        end
        function test_taus(this)
            disp(this.testObj.taus)
            taus = this.testObj.taus;
            disp(this.testObj.timesMid)
            timesMid = this.testObj.timesMid;
            save(fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'taus.mat'), 'taus')
            save(fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559_00754', 'timesMid.mat'), 'timesMid')
        end
        function test_call(this)
            setenv('DEBUG', '')
            this.testObj_.segmentation_only = false;
            tbl = this.testObj_.call('tracerPatt', 'hodt20190523120249', ...
                'innerRadii', [0 1 3 7 15 31], ...
                'outerRadii', [1 2 4 8 16 32]);
            disp(tbl)
            setenv('DEBUG', '')
        end
        function test_buildPetOnTof(this)
            import mlfourd.*
            petfile = fullfile(this.petPath, 'fdgdt20190523132832_on_T1001.4dfp.hdr');
            petic = this.testObj_.buildPetOnTof(petfile);
            petic.view(this.testObj.anatomy);
        end
        function test_buildMasks(this)
            [tof_msk, t1w_msk] = this.testObj_.buildMasks();
            tof_msk.view();
            t1w_msk.view();
        end
        function test_ensureBoxInFieldOfView(this)
            ic = this.testObj_.anatomy;
            pc = ic.pointCloud('threshp', 25);
            figure; pcshow(pc)
            X = round(pc.Location(:,1));
            Y = round(pc.Location(:,2));
            Z = round(pc.Location(:,3));
            Z(Z < 64) = -1;
            [X,Y,Z] = this.testObj_.ensureSubInFieldOfView(X, Y, Z);
            
            ind = sub2ind(size(ic), X, Y, Z);
            img = zeros(size(ic));
            img(ind) = 1;
            ifc = ic.nifti;
            ifc.img = img;
            ifc.view();
        end
	end

 	methods (TestClassSetup)
		function setupTofInputFunction(this)
 			import mlraichle.*;
            this.anatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/derivatives/sub-S58163/anat');
            this.petPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/derivatives/sub-S58163/pet');
            this.sourceAnatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/sourcedata/sub-S58163/anat');
            this.sourcePetPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/sourcedata/sub-S58163/pet');
            this.mmppix = [0.2604 0.2604 0.5];

            cd(this.petPath) 
            this.t1w = mlfourd.ImagingContext2(fullfile(this.sourceAnatPath, 'T1001.4dfp.hdr'));
            this.ho = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001.4dfp.hdr'));
            this.ho_sumt = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001_avgt.4dfp.hdr'));

            % PPG T1001; [ x y z; ... ]; [ [RS medial]; [LS medial]; [RI lateral]; [LI lateral] ].  NIfTI space.
            this.corners = [370 530 60; 319 530 60; 484 374 1; 211 374 1];
            this.bbBuffer = ceil([0 0 0] ./ this.mmppix);

            this.project_corners_ = containers.Map; % voxel coords
            this.project_corners_('sub-S33789') = [];
            this.project_corners_('sub-S38938') = [];
            this.project_corners_('sub-S41723') = [];
            this.project_corners_('sub-S42130') = [];
            this.project_corners_('sub-S42756') = [];
            this.project_corners_('sub-S47634') = [];
            this.project_corners_('sub-S48783') = [];
            this.project_corners_('sub-S49157') = [];
            this.project_corners_('sub-S52590') = [];
            this.project_corners_('sub-S57920') = [];
            this.project_corners_('sub-S58163') = this.corners;
            this.project_corners_('sub-S58258') = [];
            this.project_corners_('sub-S63372') = [];
            this.project_bbBuffer_ = containers.Map; % lengths in mm
            this.project_bbBuffer_('sub-S33789') = [5 10 0];
            this.project_bbBuffer_('sub-S38938') = [3 3 0];
            this.project_bbBuffer_('sub-S41723') = [2 5 0];
            this.project_bbBuffer_('sub-S42130') = [3 6 0];
            this.project_bbBuffer_('sub-S42756') = [6 12 0];
            this.project_bbBuffer_('sub-S47634') = [3 10 0];
            this.project_bbBuffer_('sub-S48783') = [3 2 0];
            this.project_bbBuffer_('sub-S49157') = [3 4 0];
            this.project_bbBuffer_('sub-S52590') = [3 3 0];
            this.project_bbBuffer_('sub-S57920') = [3 3 0];
            this.project_bbBuffer_('sub-S58163') = this.bbBuffer;
            this.project_bbBuffer_('sub-S58258') = [1 1 0];
            this.project_bbBuffer_('sub-S63372') = [3 3 0];
            this.project_iterations_ = containers.Map;
            this.project_iterations_('sub-S33789') = 140;
            this.project_iterations_('sub-S38938') = 120;
            this.project_iterations_('sub-S41723') = 146;
            this.project_iterations_('sub-S42130') = 90;
            this.project_iterations_('sub-S42756') = 270;
            this.project_iterations_('sub-S47634') = 60;
            this.project_iterations_('sub-S48783') = 50;
            this.project_iterations_('sub-S49157') = 60;
            this.project_iterations_('sub-S52590') = 69;
            this.project_iterations_('sub-S57920') = 65;
            this.project_iterations_('sub-S58163') = 50;
            this.project_iterations_('sub-S58258') = 70;
            this.project_iterations_('sub-S63372') = 75;
            this.project_seg_thresh_ = containers.Map;
            this.project_seg_thresh_('sub-S33789') = 190;
            this.project_seg_thresh_('sub-S38938') = 190;
            this.project_seg_thresh_('sub-S41723') = 190;
            this.project_seg_thresh_('sub-S42130') = 190;
            this.project_seg_thresh_('sub-S42756') = 180;
            this.project_seg_thresh_('sub-S47634') = 150;
            this.project_seg_thresh_('sub-S48783') = 190;
            this.project_seg_thresh_('sub-S49157') = 190;
            this.project_seg_thresh_('sub-S52590') = 190;
            this.project_seg_thresh_('sub-S57920') = 190;
            this.project_seg_thresh_('sub-S58163') = 190;
            this.project_seg_thresh_('sub-S58258') = 209;
            this.project_seg_thresh_('sub-S63372') = 190;
            this.project_contract_bias_ = containers.Map;
            this.project_contract_bias_('sub-S33789') = 0.25;
            this.project_contract_bias_('sub-S38938') = 0.12;
            this.project_contract_bias_('sub-S41723') = 0.2;
            this.project_contract_bias_('sub-S42130') = 0.05;
            this.project_contract_bias_('sub-S42756') = 0.23;
            this.project_contract_bias_('sub-S47634') = 0.03;
            this.project_contract_bias_('sub-S48783') = 0.02;
            this.project_contract_bias_('sub-S49157') = 0.05;
            this.project_contract_bias_('sub-S52590') = 0.02;
            this.project_contract_bias_('sub-S57920') = 0.02;
            this.project_contract_bias_('sub-S58163') = 0.2;
            this.project_contract_bias_('sub-S58258') = 0.02;
            this.project_contract_bias_('sub-S63372') = 0.02;

 			this.testObj_ = TofInputFunction('corners', this.corners, 'iterations', 50, 'bbBuffer', this.bbBuffer, ...
                'contractBias', 0.2, 'smoothFactor', 0, 'segmentationThresh', 190, 'segmentationOnly', false, ...
                'innerRadius', 0, 'outerRadius', 2, 'subjectFolder', 'sub-S58163', 'plotdebug', true, 'plotclose', true, ...
                'destinationPath', this.petPath);
 		end
	end

 	methods (TestMethodSetup)
		function setupTofInputFunctionTest(this)
            if isempty(this.testObj_)
                return
            end
 			this.addTeardown(@this.cleanTestMethod);
            this.testObj = copy(this.testObj_);
 		end
	end

	properties (Access = private)
        project_bbBuffer_
        project_corners_
        project_iterations_
        project_seg_thresh_
        project_contract_bias_
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

