classdef HoBuilder < mlpet.TracerKineticsBuilder
	%% HOBUILDER  

	%  $Revision$
 	%  was created 09-Mar-2017 20:57:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		Nepochs 
        resolveTag
 	end

	methods 
		            
        function this = gatherConvertedAC(this)
            %% GATHERCONVERTEDAC ensures working directories, cropped tracer field-of-view, tracer blurred to point-spread, 
            %  HO_sumt, T1 and umapSynth.  Working format is 4dfp.
            
            bv       = this.buildVisitor;
            meth     = [class(this) '.gatherConvertedAC'];
            sessd    = this.sessionData;
            sessdNAC = sessd;
            sessdNAC.attenuationCorrected = false;
            
            % actions
            
            pwd0 = sessd.tracerLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            assert(lexist_4dfp(sessd.tracerListmodeMhdr), '%s could not find %s', meth, sessd.tracerListmodeMhdr);            
            if (~lexist_4dfp(sessd.ho))
                if (~lexist_4dfp(sessd.tracerListmodeSif('typ', 'fqfp')))
                    bv.sif_4dfp(sessd.tracerListmodeMhdr, sessd.tracerListmodeSif('typ', 'fqfp'));
                end
                bv.cropfrac_4dfp(0.5, sessd.tracerListmodeSif('typ', 'fqfp'), sessd.ho);
            end
            if (~lexist_4dfp(sessd.ho('suffix', sessd.petPointSpreadSuffix)))
                bv.imgblur_4dfp(sessd.ho, mean(sessd.petPointSpread));
            end
            if (~lexist_4dfp(sessd.ho('suffix', '_sumt')))
                m =  bv.ifhMatrixSize(sessd.ho('typ', 'fqfn'));
                bv.actmapf_4dfp(sprintf('"%i+"', m(4)), sessd.ho, 'options', '-asumt');
            end
            assert(lexist_4dfp(sessd.T1));
            assert(lexist_4dfp(sessdNAC.umapSynth));
            popd(pwd0);
        end     
        
 		function this = HoBuilder(varargin)
 			%% HOBUILDER
 			%  Usage:  this = HoBuilder()
 			
 			this = this@mlpet.TracerKineticsBuilder(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', mlraichle.SessionData, @(x) isa(x, 'mlraichle.SessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_.tracer = 'HO';
            this.sessionData_.attenuationCorrected = true;                    
            %this.kinetics_ = mlraichle.HoKinetics( ...
            %    'scanData', mlraichle.ScanData('sessionData', this.sessionData), ...
            %    'roisBuild', this.roisBuilder);
            
            %this.finished = mlpipeline.Finished( ...
            %    this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

