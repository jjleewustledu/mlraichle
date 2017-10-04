classdef FdgDirector < mlraichle.TracerDirector
	%% FDGDIRECTOR

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    
    methods (Static) 
        
        %% factory methods 
         
        function [reports,this] = constructResolveReports(varargin)
            %  @return composite of mlfourdfp.T4ResolveReport objects for each epoch.
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));              
            this = this.instanceConstructResolveReports;
            reports = this.getResult;
        end
        function this  = constructResolvedModalities(varargin)
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));   
            this.sessionData.epoch = 1;
            this = this.instanceConstructResolvedT1;
            %this = this.instanceConstructResolvedTof;
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR

            this = this@mlraichle.TracerDirector(varargin{:});
            this.sessionData.tracer = 'FDG';
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

