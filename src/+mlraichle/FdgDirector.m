classdef FdgDirector < mlpet.TracerDirector
	%% FDGDIRECTOR

	%  $Revision$
 	%  was created 26-Dec-2016 12:49:55
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    
    methods (Static) 
        
        %% factory methods 
        
        function this = constructNAC(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            this.sessionData.attenuationCorrected = false;            
            this = this.instanceConstructNAC;
        end
        function those = constructNACRemotely(varargin)
            %  @param distcompHost is the hostname or distcomp profile.
            %  @param sessionsExpr is an argument for mlsystem.DirTool.
            %  @return this, a composite of mlraichle.FdgDirector instances of size N{sessions} x NUM_VISITS.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'sessionsExpr', fullfile(getenv('PPG'), 'jjlee2', 'HYGLY*'), @ischar);
            parse(ip, varargin{:});
            
            dt = mlsystem.DirTool(ip.Results.sessionsExpr);
            assert(~isempty(dt.fqdns));
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder('sessionData', ...
                    mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionPath', dt.fqdns{1})));
            this.sessionData.attenuationCorrected = false;     
            those = this.instanceConstructRemotely( ...
                @mlraichle.SessionData, @mlraichle.FdgDirector.constructNAC, ...
                'nArgout', 1, 'dirTool', dt, 'distcompHost', ip.Results.distcompHost);
        end
        function this = constructAC(varargin)
            %  @return this.sessionData.attenuationCorrection == true.
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            this.sessionData.attenuationCorrected = true;
            this = this.instanceConstructAC;
        end
        function those = pullNACFromRemote(varargin)
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'sessionsExpr', fullfile(getenv('PPG'), 'jjlee2', 'HYGLY*'), @ischar);
            addParameter(ip, 'ac', false, @islogical);
            parse(ip, varargin{:});
            
            dt = mlsystem.DirTool(ip.Results.sessionsExpr);
            assert(~isempty(dt.fqdns));
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder('sessionData', ...
                    mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionPath', dt.fqdns{1})));
            this.sessionData.attenuationCorrected = false;   
            those = this.instancePullFromRemote( ...
                @mlraichle.SessionData, @mlraichle.FdgDirector.constructNAC, ...
                'nArgout', 1, 'dirTool', dt, 'distcompHost', ip.Results.distcompHost);            
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)
 		function this = FdgDirector(varargin)
 			%% FDGDIRECTOR

            this = this@mlpet.TracerDirector(varargin{:});
            this.sessionData.tracer = 'FDG';
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

