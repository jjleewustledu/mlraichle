classdef SessionContext < mlpipeline.ISessionContext
	%% SESSIONCONTEXT  

	%  $Revision$
 	%  was created 30-May-2018 00:26:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        sessionDate
        sessionFolder
        sessionPath
        subjectsDir
 		vnumber
        vnumberRef
 	end

	methods 
        
        %% GET/SET
        
        function g    = get.sessionDate(this)
           g = this.sessionDate_;
        end
        function g    = get.sessionFolder(this)
           g = this.sessionFolder_;
        end
        function g    = get.sessionPath(this)
           g = fullfile(this.subjectsDir, this.sessionFolder_);
        end
        function g    = get.subjectsDir(~)
           g = fullfile(getenv('PPG'), 'jjlee2', '');
        end
        function g    = get.vnumber(this)
           g = this.vnumber_;
        end
        function g    = get.vnumberRef(this)
            g = this.vnumberRef_;
        end
        
        %%
        
        function loc = vallLocation(this)
           loc = fullfile(this.subjectsDir, this.sessionFolder, 'Vall', '');
        end
		  
 		function this = SessionContext(varargin)
 			%% SESSIONCONTEXT
 			%  @param named:
            %         'sessionDate'   is datetime
            %         'sessionFolder' contains the session data
            %         'sessionPath'   is a path to the session data
            %         'vnumber'       is numeric
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionDate', NaT,  @isdatetime);
            addParameter(ip, 'sessionFolder', '', @ischar);
            addParameter(ip, 'sessionPath', '',   @ischar);
            addParameter(ip, 'vnumber', 1,        @isnumeric);
            addParameter(ip, 'vnumberRef', 1,     @isnumeric);
            parse(ip, varargin{:});            
            this.sessionDate_ = ip.Results.sessionDate;
            if (isempty(this.sessionDate_.TimeZone))
                this.sessionDate_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            end
            if (~isempty(ip.Results.sessionFolder))
                this.sessionFolder_ = ip.Results.sessionFolder;
            end
            if (~isempty(ip.Results.sessionPath))
                [~,this.sessionFolder_] = fileparts(ip.Results.sessionPath);
            end                           
            this.vnumber_ = ip.Results.vnumber;
            this.vnumberRef_ = ip.Results.vnumberRef;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        sessionDate_
        sessionFolder_
        vnumber_
        vnumberRef_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

