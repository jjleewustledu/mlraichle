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
        
        function this  = constructNAC(varargin)
            this = mlraichle.FdgDirector.constructResolved(varargin{:}, 'ac', false);
        end        
        function this  = constructNACRemotely(varargin)
            this = mlraichle.FdgDirector.constructResolvedRemotely(varargin{:}, 'ac', false);
        end
        function those = pullNACFromRemote(varargin)
            those = mlraichle.FdgDirector.pullResolvedFromRemote(varargin{:}, 'ac', false);
        end
        
        function this  = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @param ac is logical for attenuation correction.
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ac', false, @islogical);
            parse(ip, varargin{:});
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instanceConstructResolved;
        end
        function those = constructResolvedRemotely(varargin)
            %  @param distcompHost is the hostname or distcomp profile.
            %  @param sessionsExpr is an argument for mlsystem.DirTool.
            %  @param ac is logical for attenuation correction.
            %  @return this, a composite of mlraichle.FdgDirector instances of size N{sessions} x NUM_VISITS.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'sessionsExpr', fullfile(getenv('PPG'), 'jjlee2', 'HYGLY*'), @ischar);
            addParameter(ip, 'ac', false, @islogical);
            parse(ip, varargin{:});
            
            dt = mlsystem.DirTool(ip.Results.sessionsExpr);
            assert(~isempty(dt.fqdns));
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder('sessionData', ...
                    mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionPath', dt.fqdns{1}), ...
                        'ac', ip.Results.ac));
            those = this.instanceConstructRemotely( ...
                @mlraichle.SessionData, @mlraichle.FdgDirector.constructNAC, ...
                'nArgout', 1, 'dirTool', dt, 'distcompHost', ip.Results.distcompHost, 'ac', ip.Results.ac);
        end
        function those = pullResolvedFromRemote(varargin)
            %  @param ac is logical for attenuation correction.
            %  @param distcompHost is the hostname or distcomp profile.
            %  @param sessionsExpr is an argument for mlsystem.DirTool.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'sessionsExpr', fullfile(getenv('PPG'), 'jjlee2', 'HYGLY*'), @ischar);
            addParameter(ip, 'ac', false, @islogical);
            parse(ip, varargin{:});
            
            dt = mlsystem.DirTool(ip.Results.sessionsExpr);
            assert(~isempty(dt.fqdns));
            
            this = mlraichle.FdgDirector( ...
                mlpet.TracerResolveBuilder('sessionData', ...
                    mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionPath', dt.fqdns{1}, ...
                    'ac', ip.Results.ac)));
            those = this.instancePullFromRemote( ...
                @mlraichle.SessionData, @mlraichle.FdgDirector.constructResolved, ...
                'nArgout', 1, 'dirTool', dt, 'distcompHost', ip.Results.distcompHost, 'ac', ip.Results.ac);            
        end        
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
            this = this.instanceConstructResolvedTof;
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

