classdef FdgKinetics 
	%% FDGKINETICS  

	%  $Revision$
 	%  was created 30-May-2017 21:41:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function this = constructKinetics(varargin)
            %% GOCONSTRUCTKINETICS is a static method needed by parcluster.batch            
            
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addRequired(ip, 'roisBuild',   @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            import mlraichle.*;
            sessd = SessionData.struct2sessionData(ip.Results.sessionData);
            [m,sessd] = F18DeoxyGlucoseKinetics.godoMasks(sessd, ip.Results.rois);
            this = F18DeoxyGlucoseKinetics(sessd, 'mask', m);
            this = this.doItsBayes;
        end
    end
    
	methods 
		  
 		function this = FdgKinetics(varargin)
 			%% FDGKINETICS
            %  @param named 'sessionData' is an 'mlpipeline.ISessionData'.
            %  @returns this
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});		
            
            
        end
        
        function tf   = checkConstructKineticsPassed(this, varargin)
            %% CHECKCONSTRUCTKINETICSPASSED
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder, @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            error('mlraichle:notImplemented', 'FdgKinetics.checkConstructKineticsPassed');
        end
        function this = instanceConstructKinetics(this, varargin)
            %% INSTANCECONSTRUCTKINETICS
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder, @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            try                
                pwd0 = pushd(this.sessionData.vLocation);
                import mlraichle.*;
                CHPC4FdgKinetics.pushData0(this.sessionData);
                this = CHPC4FdgKinetics.batchSerial(@mlraichle.FdgKinetics.constructKinetics, 1, {this.sessionData, ip.Results.roisBuild});
                CHPC4FdgKinetics.pullData0(this.sessionData);
                popd(pwd0);
            catch ME
                dispwarning(ME);
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

