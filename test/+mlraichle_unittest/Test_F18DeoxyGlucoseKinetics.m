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
        ccirRadMeasurementsDir = fullfile(getenv('HOME'), 'Documents', 'private', '')
        dta
        fqfnman = fullfile(getenv('HOME'), 'Documents/private/CCIRRadMeasurements 2016sep23.xlsx')
        frame = 0
        pwd0
 		registry
        sessd
        sessdate = datetime(2016,9,23)
        sessp = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28'
 		testObj
        tsc
        vnumber = 2
    end
    
    methods
        function pth = workPath(this)            
            pth = fullfile(this.sessp, sprintf('V%i', this.vnumber), sprintf('FDG_V%i-AC', this.vnumber));
        end
    end

	methods (Test)
        function test_factory(this)
            import mlraichle.*;
            msk = mlfourd.ImagingContext( ...
                fullfile(this.workPath, 'aparcAsegBinarized_op_fdgv2r1.4dfp.ifh'));
            testobj = FDGKineticsWholebrain.factory(this.sessd, 'mask', msk);
            disp(testobj);
        end
        function test_plot(this)            
            import mlraichle.*;
            msk = mlfourd.ImagingContext( ...
                fullfile(this.workPath, 'aparcAsegBinarized_op_fdgv2r1.4dfp.ifh'));
            testobj = FDGKineticsWholebrain.factory(this.sessd, 'mask', msk);
            plot(testobj);
        end
        function test_godoMasks(this)
 			import mlraichle.*;
            [msk,sessd_,ct4rb] = FDGKineticsWholebrain.godoMasks(this.sessd);
            msk.view;
            this.verifyEqual(sessd_, this.sessd);
            this.verifyEqual(ct4rb.theImages,  {'fdgv2r1OnResolved_sumt'  'brainmask'});
        end
		function test_godo2(this)
 			import mlraichle.*;
 			datstruct = FDGKineticsWholebrain.godo2( ...
                this.sessd, ...
                'adjustment', 'nBeta', 'value', 50);
            disp(datstruct);
            datobj = datstruct.aparcAsegBinarized_op_fdgv2r1;
            disp(datobj);
            plot(datobj);
        end
		function test_godoWilliam(this)
 			import mlraichle.*;
 			jobs = FDGKineticsWholebrain.godoWilliam(this.sessd);
            datobj = jobs{end,end}.aparcAsegBinarized_op_fdgv2r1;
            plot(datobj);            
            disp(datobj);
        end
        function test_godo2Parc(this)
 			import mlraichle.*;
 			datstruct = FDGKineticsParc.godo2(this.sessd);
            disp(datstruct);
            iterator = fields(datstruct);
            for it = 1:length(iterator)            
                datobj = datstruct.(iterator{it});
                disp(datobj);
                plot(datobj);
            end
        end
	end

 	methods (TestClassSetup)
		function setupF18DeoxyGlucoseKinetics(this)
 			import mlraichle.*;
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            this.sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', this.sessp, ...
                'vnumber', this.vnumber, ...
                'ac', true, ...
                'frame', this.frame, ...
                'tracer', 'FDG', ...
                'sessionDate', this.sessdate);
            mand = mlsiemens.XlsxObjScanData( ...
                'sessionData', this.sessd, ...
                'fqfilename', this.fqfnman);
            this.tsc = mlsiemens.BiographMMR0( ...
                mlfourd.NIfTId.load(this.sessd.tracerResolvedFinal), ...
                'sessionData', this.sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'), ...
                'manualData', mand);
            this.dta = mlcapintec.Caprac( ...
                'fqfilename', this.sessd.CCIRRadMeasurements, ...
                'sessionData', this.sessd, ...
                'manualData', mand, ...
                'isotope', '18F', ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'));
 		end
	end

 	methods (TestMethodSetup)
		function setupF18DeoxyGlucoseKineticsTest(this)
 			this.testObj = this.testObj_;
            setenv('UNITTESTING', 'true');      
            this.pwd0 = pushd(this.workPath);
 			this.addTeardown(@this.cleanFiles);      
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
            deleteExisting( ...
                fullfile(this.sessd.tracerLocation, 'mlraichle.FDGKineticsWholebrain.mat'));
            setenv('UNITTESTING', '');
            popd(this.pwd0);
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

