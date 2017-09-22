classdef HoDirector < mlpet.TracerDirector 
	%% HODIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:27
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties
 		
 	end

	methods        
        function ensureJSRecon(this)
        end
        function this = constructNAC(this)
            %this.builder.transferFromRawData;
            %this.builder.transferToE7tools('HO');
            %this.builder.transferFromE7tools('HO-Converted-NAC');
            this.builder.motionCorrectACFrames;
            this.builder.motionCorrectFrames;
            this.builder.buildCarneyUmap;
            this.builder.motionCorrectCTAndUmap;
            this.builder.product.view;
            this.builder.transferToE7tools('HO-Converted-NAC');
        end
        function this = constructAC(this)
            %this.builder.transferFromE7tools('HO-Converted-Frame*');
            %this.builder.buildACFrames;
            %this.builder.motionCorrectACFrames;
            this.builder.buildTracerAC;
            this.builder.product.view;
        end
        
 		function this = HoDirector(varargin)
 			%% HODIRECTOR
            %  @param required 'builder' is an 'mlraichle.HoBuilder'

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'builder', @(x) isa(x, 'mlraichle.HoBuilder'));
            parse(ip, varargin{:});
            this = this@mlpet.TracerDirector(varargin{:});
            this.sessionData.tracer = 'HO';
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

