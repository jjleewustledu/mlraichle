classdef CHPC4FdgKinetics < mldistcomp.CHPC
	%% CHPC4FDGKINETICS  

	%  $Revision$
 	%  was created 13-Mar-2017 18:04:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    methods
        function this = pushData(this)
        end
        function this = pullData(this)
        end
        function this = CHPC4FdgKinetics(varargin)
            this = this@mldistcomp.CHPC(varargin{:});
        end
    end
    
    %% HIDDEN, DEPRECATED
    
    methods (Static, Hidden)   
        function [obj,j,c] = batchSerial(varargin)
            ip = inputParser;
            addRequired(ip, 'h', @(x) isa(x, 'function_handle'));
            addRequired(ip, 'nargout_', @isnumeric);
            addRequired(ip, 'varargin_', @iscell);
            parse(ip, varargin{:});            
            
            try
                c = myparcluster;
                j = c.batch(ip.Results.h, ip.Results.nargout_, ip.Results.varargin_);
                obj = j.fetchOutputs{:};
            catch ME
                dispwarning(ME);
            end
        end  
        function pushData0(datobj)
            import mlraichle.*;
            sessd           = SessionData.struct2sessionData(datobj);
            chpc            = CHPC('sessionData', sessd); 
            chpcVPth        = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, '');
            chpcFdgPth      = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, ...
                              sessd.tracerLocation('typ', 'folder'), '');
            chpcListmodePth = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder,...
                              sessd.tracerConvertedLocation('typ','folder'), ...
                              sessd.tracerListmodeLocation('typ','folder'), '');
            chpcMriPth      = fullfile(chpc.sessionData.freesurferLocation, ...
                              sessd.sessionFolder, 'mri', '');
            
            chpc.scpToChpc(sessd.bloodGlucoseAndHctXlsx, chpc.chpcSubjectsDir);
            chpc.scpToChpc(sessd.CCIRRadMeasurements, chpcVPth);
            
            chpc.sshMkdir(chpcMriPth);
            chpc.scpToChpc(sessd.brainmask('typ','mgz'), chpcMriPth);
            chpc.scpToChpc(sessd.aparcAseg('typ','mgz'), chpcMriPth);
            chpc.scpToChpc(fullfile(sessd.mriLocation, 'T1.mgz'), chpcMriPth);
            
            chpc.sshMkdir(chpcFdgPth);
            sessdr1 = sessd; sessdr1.rnumber = 1;
            chpc.scpToChpc([sessdr1.tracerResolved1(    'typ','fqfp') '.4dfp.*'], chpcFdgPth);
            chpc.scpToChpc([sessdr1.tracerResolvedSumt1('typ','fqfp') '.4dfp.*'], chpcFdgPth); 
            
            chpc.sshMkdir(chpcListmodePth);
            chpc.scpToChpc(sessdr1.tracerListmodeMhdr, chpcListmodePth);           
        end
        function pullData0(datobj)
            import mlraichle.*;
            sessd = SessionData.struct2sessionData(datobj);
            chpc  = CHPC('sessionData', sessd); 
            logs  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, '*.log');
            mats  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, '*.mat');
            figs  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, 'fig*');
            
            chpc.scpFromChpc(logs);
            chpc.scpFromChpc(mats);
            chpc.scpFromChpc(figs);
        end
    end
    
    methods (Hidden)   
        function [s,r] = scpToChpc(this, varargin)
            %% SCPTOCHPC 
            %  @param src is the filename on the local machine.
            %  @param named dest is the f.q. path on the cluster (optional).
            
            dest = sprintf('%s:%s', this.LOGIN_HOSTNAME, this.chpcSessionData.sessionPath);
            ip = inputParser;
            addRequired(ip, 'src', @ischar);
            addOptional(ip, 'dest', dest, @ischar);
            parse(ip, varargin{:});
            
            if (~lstrfind(ip.Results.dest, this.LOGIN_HOSTNAME))
                dest = sprintf('%s:%s', this.LOGIN_HOSTNAME, ip.Results.dest);
            else
                dest = ip.Results.dest;
            end            
            [s,r] = mlbash(sprintf('scp -qr %s %s', ip.Results.src, dest));
        end
        function [s,r] = scpFromChpc(this, varargin)
            %% SCPFROMCHPC 
            %  @param src is the f.q. filename on the cluster.
            %  @param named dest is the path on the local machine (optional).
            
            ip = inputParser;
            addRequired(ip, 'src', @ischar);
            addOptional(ip, 'dest', '.', @ischar);
            parse(ip, varargin{:});
            
            if (~lstrfind(ip.Results.src, this.LOGIN_HOSTNAME))
                src = sprintf('%s:%s', this.LOGIN_HOSTNAME, ip.Results.src);
            else
                src = ip.Results.src;
            end            
            [s,r] = mlbash(sprintf('scp -qr %s %s', src, ip.Results.dest));
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

