classdef FdgKinetics 
	%% FDGKINETICS  

	%  $Revision$
 	%  was created 30-May-2017 21:41:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function this = goConstructKinetics(varargin)
            %% GOCONSTRUCTKINETICS is a static method needed by parcluster.batch            
            
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addRequired(ip, 'roisBuild',   @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            import mlraichle.*;
            sessd = CHPC.staticSessionData(ip.Results.sessionData);
            [m,sessd] = F18DeoxyGlucoseKinetics.godoMasks(sessd, ip.Results.rois);
            this = F18DeoxyGlucoseKinetics(sessd, 'mask', m);
            this = this.doBayes;
        end
    end
    
	methods 
		  
 		function this = FdgKinetics(varargin)
 			%% FDGKINETICS
            %  @param named 'sessionData' is an 'mlpipeline.SessionData'.
            %  @returns this
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});		
            
            
        end
        
        function tf   = checkConstructKineticsPassed(this, varargin)
            %% CHECKCONSTRUCTKINETICSPASSED
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder, @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            error('mlraichle:notImplemented');
        end
        function this = constructKinetics(this, varargin)
            %% CONSTRUCTKINETICS
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder, @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            try                
                pwd0 = pushd(this.sessionData.vLocation);
                import mlraichle.*;
                CHPC.pushToChpc(this.sessionData);
                this = CHPC.batchSerial(@mlraichle.FdgKinetics.goConstructKinetics, 1, {this.sessionData, ip.Results.rois});
                CHPC.pullFromChpc(this.sessionData);
                popd(pwd0);
            catch ME
                handwarning(ME, struct2str(ME.stack));
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

