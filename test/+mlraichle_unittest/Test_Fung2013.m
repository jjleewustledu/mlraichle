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
            [~,ics] = this.testObj.call();
            disp(ics)
%             for i = 1:length(ics)
%                 ics{i}.fsleyes(this.t1w.fqfilename, ics{i}.fqfilename)
%             end
        end
	end

 	methods (TestClassSetup)
		function setupFung2013(this)
 			import mlraichle.*;
            %this.anatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/derivatives/sub-108293/anat');
            %this.petPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/derivatives/sub-108293/pet');
            %this.sourceAnatPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/sourcedata/sub-108293/anat');
            %this.sourcePetPath = fullfile(getenv('HOME'), 'Singularity/CCIR_01211/sourcedata/sub-108293/pet');
            this.anatPath = fullfile(getenv('HOME'), 'Singularity/subjects/sub-S58163/resampling_restricted');
            this.petPath = fullfile(getenv('HOME'), 'Singularity/subjects/sub-S58163/resampling_restricted');
            this.sourceAnatPath = fullfile(getenv('HOME'), 'Singularity/subjects/sub-S58163/resampling_restricted');
            this.sourcePetPath = fullfile(getenv('HOME'), 'Singularity/subjects/sub-S58163/resampling_restricted');
            cd(this.petPath)         
            %this.corners = [113 178 140; 87 178 140; 136 149 58; 62 148 59] + 1; % long vglab
            %this.corners = [140 144 109; 60 144 105; 136 149 58; 62 148 59] + 1; % short vglab
            %this.corners = [121 102 25; 62 104 28; 117 98 1; 69 99 1]; % PPG T1001_111; [ x y z; ... ]; [ [RS]; [LS]; [RI]; [LI] ].
            this.corners = [159 120 81; 99 122 81; 156 116 31; 102 113 31]; % PPG T1001; [ x y z; ... ]; [ [RS]; [LS]; [RI]; [LI] ].
 			this.testObj_ = Fung2013('coords', this.corners, 'iterations', 80, 'BBBuf', [10 10 1], ...
                'subFolder', 'sub-S58163', 'plotdebug', false, 'alg', 'fung');
            %this.t1w = mlfourd.ImagingContext2(fullfile(this.sourceAnatPath, 'sub-108293_20210218081030_T1w.nii.gz'));
            this.t1w = mlfourd.ImagingContext2(fullfile(this.sourceAnatPath, 'T1001.4dfp.hdr'));
            %this.ho = mlfourd.ImagingContext2(fullfile(this.petPath, 'sub-108293_20210421134537_Water_Dynamic_13_on_T1w.nii.gz'));
            this.ho = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001.4dfp.hdr'));
            %this.ho_sumt = mlfourd.ImagingContext2(fullfile(this.petPath, 'sub-108293_20210421134537_Water_Static_12_on_T1w.nii.gz'));
            this.ho_sumt = mlfourd.ImagingContext2(fullfile(this.petPath, 'hodt20190523120249_on_T1001_avgt.4dfp.hdr'));
            %this.cacheMat = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlvg', 'test', '+mlvg_unittest', 'Test_Fung2013_Vision_20211109.mat');
            this.cacheMat = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlraichle', 'test', '+mlraichle_unittest', 'Test_Fung2013_PPG_20211109.mat');
 		end
	end

 	methods (TestMethodSetup)
		function setupFung2013Test(this)
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
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

