classdef Test_HyperglycemiaDirector2 < matlab.unittest.TestCase
	%% TEST_HYPERGLYCEMIADIRECTOR2 

	%  Usage:  >> results = run(mlraichle_unittest.Test_HyperglycemiaDirector2)
 	%          >> result  = run(mlraichle_unittest.Test_HyperglycemiaDirector2, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 15-Nov-2018 15:25:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/test/+mlraichle_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        pwd0
 		registry
        sessd
 		testObj
        tracerDir
 	end

	methods (Test)
        function test_prepareNipet(this)            
            tobj = mlnipet.NipetBuilder.CreatePrototype;
            disp(tobj.product)
        end
        function test_constructUmaps(this)
            those = this.testObj.constructUmaps( ...
                'sessionsExpr', 'NP995_24*', ...
                'visitsExpr', 'V1*', ...
                'tracer', 'FDG', 'ac', false);
            those{1}.builder.product.view;
        end
        function test_prepareFreesurferData(this)
            this.pwd0 = pushd(this.sessd.tracerLocation);
            mlraichle.TracerDirector2.prepareFreesurferData('sessionData', this.sessd); 
            vloc = this.sessd.vLocation;
            this.verifyTrue(lexist_4dfp(fullfile(vloc, 'aparcAseg')));
            this.verifyTrue(lexist_4dfp(fullfile(vloc, 'aparcA2009sAseg')));
            this.verifyTrue(lexist_4dfp(fullfile(vloc, 'brainmask')));
            this.verifyTrue(lexist_4dfp(fullfile(vloc, 'T1')));
        end       
        function test_constructResolvedNAC1(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            disp(td);
        end  
        function test_constructResolvedNAC2(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            td = td.setBuilder__(td.builder.prepareMprToAtlasT4);
            disp(td);            
        end  
        function test_constructResolvedNAC3(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            td = td.setBuilder__(td.builder.prepareMprToAtlasT4);
            td = td.setBuilder__(td.builder.partitionMonolith); 
            disp(td);
        end  
        function test_constructResolvedNAC4(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            td = td.setBuilder__(td.builder.prepareMprToAtlasT4);
            td = td.setBuilder__(td.builder.partitionMonolith); 
            [bldr,epochs,reconstituted] = td.builder.motionCorrectFrames; td = td.setBuilder__(bldr);
            save('test_constructResolvedNAC4.mat');
            td.builder.logger.save;
            disp(bldr);
            disp(epochs);
            disp(reconstituted);            
        end  
        function test_constructResolvedNAC5(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            td = td.setBuilder__(td.builder.prepareMprToAtlasT4);
            td = td.setBuilder__(td.builder.partitionMonolith); 
            [bldr,~,reconstituted] = td.builder.motionCorrectFrames; td = td.setBuilder__(bldr);
%            load('test_constructResolvedNAC4.mat');
            reconstituted = reconstituted.motionCorrectCTAndUmap;
            save('test_constructResolvedNAC5.mat');
            reconstituted.logger.save;
            disp(reconstituted);
        end  
        function test_constructResolvedNAC6(this)
            td = this.tracerDir;
            td = td.prepareNipetTracerImages;
            td = td.setBuilder__(td.builder.prepareMprToAtlasT4);
            td = td.setBuilder__(td.builder.partitionMonolith); 
            [bldr,epochs,reconstituted] = td.builder.motionCorrectFrames; td = td.setBuilder__(bldr);
            reconstituted = reconstituted.motionCorrectCTAndUmap;             
%            load('test_constructResolvedNAC5.mat');
            td = td.setBuilder__(reconstituted.motionUncorrectUmap(epochs));
            save('test_constructResolvedNAC6.mat');
            td.builder.logger.save;
        end    
        function test_constructResolvedNAC(this)
            those = this.testObj.constructResolvedNAC( ...
                'sessionsExpr', 'NP995_24', ...
                'visitsExpr', 'V1', ...
                'tracer', 'FDG', 'ac', false);
            those{1}.builder.product.view;
        end
	end

 	methods (TestClassSetup)
		function setupHyperglycemiaDirector2(this)
 			import mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', fullfile(RaichleRegistry.instance.subjectsDir, 'NP995_24', ''), ...
                'vnumber', 1, ...
                'ac', false);
 			this.testObj_ = HyperglycemiaDirector2('sessionData', this.sessd);   
 		end
	end

 	methods (TestMethodSetup)
		function setupHyperglycemiaDirector2Test(this)
            this.pwd0 = pushd(this.sessd.vLocation);
 			this.testObj = this.testObj_;
            this.tracerDir = mlraichle.TracerDirector2( ...
                mlpet.TracerResolveBuilder('sessionData', this.sessd));  
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
            popd(this.pwd0);
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

