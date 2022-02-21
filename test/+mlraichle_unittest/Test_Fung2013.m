classdef Test_Fung2013 < matlab.unittest.TestCase
	%% TEST_FUNG2013 

	%  Usage:  >> results = run(mlraichle_unittest.Test_Fung2013)
 	%          >> result  = run(mlraichle_unittest.Test_Fung2013, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 25-Mar-2021 21:45:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        anatPath
        cacheMat % assign after segmentations, centerlines, registration targets are ready
        corners
        ho
        ho_sumt
        petPath
 		registry
        sourceAnatPath
        sourcePetPath
        t1w
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            disp(this.testObj)
        end
        function test_cache(this)
            disp(this.testObj)
        end
        function test_buildSegmentation(this)
            this.testObj.buildSegmentation(80, 'smoothFactor', 0);
            disp(this.testObj)
        end
		function test_buildCenterlines(this)
            f = this.testObj;        
            f.buildSegmentation(80, 'smoothFactor', 0);
            f.buildCenterlines()
        end
        function test_registerCenterline_cpd(this) 
            assert(~isempty(this.cacheMat), 'testObj needs some aufbau to proceed with testing')
            f = this.testObj;          
            f.registerCenterline(f.centerlines_pcs{1}, 'alg', 'cpd', 'laterality', 'L')
            disp(f)
            disp(f.registration)
        end
        function test_registerCenterline_fung(this) 
            assert(~isempty(this.cacheMat), 'testObj needs some aufbau to proceed with testing')
            testObj = this.testObj;          
            testObj.registerCenterline(testObj.centerlines_pcs{1}, 'alg', 'fung', 'laterality', 'L');
            disp(testObj)
            disp(testObj.registration)
        end
        function test_pointCloudToIC(this)
            f = this.testObj;
            f.registerCenterline(f.centerlines_pcs{1}, 'alg', 'cpd', 'laterality', 'L')
            ic = f.pointCloudToIC(f.registration.centerlineOnTarget{1}, 'centerlineOnTarget');
            ic = ic.imdilate(strel('sphere', 2));
            ic.fsleyes
        end
        function test_decay_uncorrected(this)
            obj = this.testObj;
            %mask = mlfourd.ImagingContext2('~jjlee/Singularity/CCIR_01211/derivatives/sub-108293/mri/wmparc_on_T1w.nii.gz');
            ho_ = this.ho.volumeAveraged(logical(obj.wmparc_ic));
            ho_row = obj.decay_uncorrected(ho_);
            plot(obj.timesMid('HO'), ho_row, obj.timesMid('HO'), ho_.nifti.img)
            legend('decay uncorrected', 'decay corrected')
        end
        function test_tracername(this)
            for g = globT(fullfile(this.petPath, 'sub-*Dynamic*_on_T1w.nii.gz'))
                fprintf('%s contains %s\n', g{1}, this.testObj.tracername(g{1}))
            end
        end
        function test_call(this)
            setenv('DEBUG', '')
            obj = mlraichle.Fung2013('corners', this.corners, 'iterations', 65, 'bbBuffer', [3 3 0], ...
                'subjectFolder', 'sub-S58163', 'plotdebug', false, 'plotclose', false, 'alg', 'fung');
            tbl = obj.call();
            disp(tbl)
            setenv('DEBUG', '')
        end
        function test_call_on_project(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(1:2, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_project2(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(3:4, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_project3(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(5:6, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_project4(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(7:8, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_project5(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(9:10, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_project6(this)
            setenv('DEBUG', '')
            mlraichle.Fung2013.call_on_project(12:13, ...
                'corners', this.project_corners_, ...
                'bbBuffer', this.project_bbBuffer_, ...
                'iterations', this.project_iterations_, ...
                'contractBias', this.project_contract_bias_, ...
                'segmentationThresh', this.project_seg_thresh_, ...
                'segmentationOnly', false, 'plotclose', true, 'alg', 'fung'); 
        end
        function test_call_on_subject(~)
            setenv('DEBUG', '')
            cd(fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/derivatives/sub-S58163/pet'))
            tbls_idif = mlraichle.Fung2013.call_on_subject( ...
                'corners', [159 120 81; 99 122 81; 156 116 31; 102 113 31], ...
                'bbBuffer', [3 3 0], ...
                'iterations', 65, ...
                'contractBias', 0.02, ...
                'segmentationThresh', 190, ...
                'segmentationOnly', false, ...
                'alg', 'fung', ...
                'ploton', true, 'plotqc', true, 'plotdebug', false, 'plotclose', true);
            for i = 1:size(tbls_idif, 1)
                disp(tbls_idif(i,:))
            end
        end
        function test_zeros_nifti(this)
            anatomy_ = mlfourd.ImagingContext2('T1001.nii.gz');
            ic_ = anatomy_.zeros();
            ifc_ = ic_.nifti;
            this.assertTrue(contains(ifc_.fileprefix, '_zeros'))
            this.assertEqual(dipsum(ifc_.img), 0)
        end
        function test_zeros_copy(this)
            anatomy_ = copy(mlfourd.ImagingContext2('T1001.nii.gz'));
            anatomy = copy(anatomy_);
            ic = anatomy.zeros();
            ifc = ic.nifti;
            this.assertTrue(contains(ifc.fileprefix, '_zeros'))
            this.assertEqual(dipsum(ifc.img), 0)
        end
        function test_zeros_MMRBids(this)
            bids = mlraichle.MMRBids();
            anatomy = bids.T1w_ic;
            ic = anatomy.zeros();
            ifc = ic.nifti;
            this.assertTrue(contains(ifc.fileprefix, '_zeros'))
            this.assertEqual(dipsum(ifc.img), 0)
        end
        function test_sum(this)
            bids = mlraichle.MMRBids();
            anatomy = bids.T1w_ic;
            ic = sum(anatomy, 3);
            ifc = ic.nifti;
            this.assertTrue(contains(ifc.fileprefix, '_sum_3'))
            this.assertEqual(ndims(ifc), 2)
        end
	end

 	methods (TestClassSetup)
		function setupFung2013(this)
 			import mlraichle.*;
            %this.anatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/derivatives/sub-108293/anat');
            %this.petPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/derivatives/sub-108293/pet');
            %this.sourceAnatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/sourcedata/sub-108293/anat');
            %this.sourcePetPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/sourcedata/sub-108293/pet');
            this.anatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/derivatives/sub-S58163/anat');
            this.petPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/derivatives/sub-S58163/pet');
            this.sourceAnatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/sourcedata/sub-S58163/anat');
            this.sourcePetPath = fullfile(getenv('HOME'), 'Singularity/CCIR_00559_00754/sourcedata/sub-S58163/pet');
            cd(this.petPath)         
            %this.corners = [113 178 140; 87 178 140; 136 149 58; 62 148 59] + 1; % long vglab
            %this.corners = [140 144 109; 60 144 105; 136 149 58; 62 148 59] + 1; % short vglab
            %this.corners = [121 102 25; 62 104 28; 117 98 1; 69 99 1]; % PPG T1001_111; [ x y z; ... ]; [ [RS]; [LS]; [RI]; [LI] ].
            this.corners = [159 120 81; 99 122 81; 156 116 31; 102 113 31]; % PPG T1001; [ x y z; ... ]; [ [RS]; [LS]; [RI]; [LI] ].
 			this.testObj_ = Fung2013('corners', this.corners, 'iterations', 80, 'bbBuffer', [10 10 1], ...
                'subjectFolder', 'sub-S58163', 'plotdebug', false, 'alg', 'cpd');
            %this.t1w = mlfourd.ImagingContext2(fullfile(this.sourceAnatPath, 'sub-108293_20210218081030_T1w.nii.gz'));
            this.t1w = mlfourd.ImagingContext2(fullfile(this.sourceAnatPath, 'T1001.4dfp.hdr'));
            %this.ho = mlfourd.ImagingContext2(fullfile(this.petPath, 'sub-108293_20210421134537_Water_Dynamic_13_on_T1w.nii.gz'));
            this.ho = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001.4dfp.hdr'));
            %this.ho_sumt = mlfourd.ImagingContext2(fullfile(this.petPath, 'sub-108293_20210421134537_Water_Static_12_on_T1w.nii.gz'));
            this.ho_sumt = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001_avgt.4dfp.hdr'));
            %this.cacheMat = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlvg', 'test', '+mlvg_unittest', 'Test_Fung2013_Vision_20211109.mat');
            %this.cacheMat = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'test', '+mlraichle_unittest', 'Test_Fung2013_PPG_20211109.mat');

            this.project_corners_ = containers.Map;
            this.project_corners_('sub-S33789') = [165 124 103; 100 123 103; 160 123 32; 97 120 32];
            this.project_corners_('sub-S38938') = [160 122 98; 99 120 98; 159 109 32; 101 108 32];
            this.project_corners_('sub-S41723') = [162 120 82; 97 116 82; 156 115 31; 99 109 31];
            this.project_corners_('sub-S42130') = [156 127 104; 95 124 104; 153 127 51; 95 126 51];
            this.project_corners_('sub-S42756') = [155 120 104; 97 118 104; 152 119 41; 98 123 41];
            this.project_corners_('sub-S47634') = [156 121 91; 100 128 91; 161 112 33; 94 117 33];
            this.project_corners_('sub-S48783') = [153 136 80; 96 131 80; 155 135 42; 99 127 42];
            this.project_corners_('sub-S49157') = [161 128 90; 94 130 90; 151 130 47; 98 130 47];
            this.project_corners_('sub-S52590') = [157 131 115; 97 130 115; 152 126 45; 95 125 45];
            this.project_corners_('sub-S57920') = [158 123 99; 94 121 99; 149 119 57; 98 120 57];
            this.project_corners_('sub-S58163') = [159 120 81; 99 122 81; 156 116 31; 102 113 31];
            this.project_corners_('sub-S58258') = [150 133 97; 101 131 97; 145 118 42; 92 125 42];
            this.project_corners_('sub-S63372') = [159 118 88; 96 120 88; 158 118 22; 96 118 22];
            this.project_bbBuffer_ = containers.Map;
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
            this.project_bbBuffer_('sub-S58163') = [3 3 0];
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
            this.project_iterations_('sub-S58163') = 65;
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
            this.project_contract_bias_('sub-S58163') = 0.02;
            this.project_contract_bias_('sub-S58258') = 0.02;
            this.project_contract_bias_('sub-S63372') = 0.02;
 		end
	end

 	methods (TestMethodSetup)
		function setupFung2013Test(this)
            if isempty(this.testObj_)
                return
            end
 			this.addTeardown(@this.cleanTestMethod);
            if isempty(this.cacheMat)
                this.testObj = copy(this.testObj_);
                return
            end
            if isfile(this.cacheMat)
                ld = load(this.cacheMat, 'testObj');
                this.testObj = ld.testObj;
                return
            end
            this.testObj = copy(this.testObj_);
            this.testObj.buildSegmentation();
            this.testObj.buildCenterlines()                
            this.testObj.buildRegistrationTargets(this.ho)
            if ~isfile(this.cacheMat)
                testObj = this.testObj; %#ok<PROP> 
                save(this.cacheMat, 'testObj')
            end
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

