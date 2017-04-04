classdef CHPC < mldistcomp.CHPC
	%% CHPC  

	%  $Revision$
 	%  was created 13-Mar-2017 18:04:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
    end

    methods (Static)        
        function sessd = staticSessionData(datobj)
            import mlraichle.*;
            if (isa(datobj, 'mlpipeline.SessionData'))
                sessd = datobj;
                return
            end
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, datobj.sessionFolder, '');
            sessd = SessionData('studyData', studyd, 'sessionPath', sessp, ...
                                'tracer', 'FDG', 'ac', true, 'vnumber', datobj.vnumber);  
            if (isfield(datobj, 'parcellation') && ~isempty(datobj.parcellation))
                sessd.parcellation = datobj.parcellation;
            end
            if (isfield(datobj, 'hct') && ~isempty(datobj.hct))
                sessd.hct = datobj.hct;
            end
        end
        function c = staticChpc(datobj)
            c = mldistcomp.CHPC( ...
                mlraichle.CHPC.staticSessionData(datobj));
        end
        function pushToChpc(datobj)
            import mlraichle.*;
            sessd           = CHPC.staticSessionData(datobj);
            chpc            = CHPC(sessd); 
            chpcVPth        = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, '');
            chpcFdgPth      = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, ...
                              sessd.tracerLocation('typ', 'folder'), '');
            chpcListmodePth = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, ...
                              sessd.tracerConvertedLocation('typ','folder'), ...
                              sessd.tracerListmodeLocation('typ','folder'), '');
            chpcMriPth      = fullfile(chpc.freesurferLocation, ...
                              sprintf('%s_%s', sessd.sessionFolder, sessd.vfolder), 'mri', '');
            
            chpc.scpToChpc(sessd.CCIRRadMeasurementsTable, chpcVPth);
            
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
        function pullFromChpc(datobj)
            import mlraichle.*;
            sessd = CHPC.staticSessionData(datobj);
            chpc  = CHPC(sessd); 
            logs  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, '*.log');
            mats  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, '*.mat');
            figs  = fullfile(chpc.chpcSubjectsDir, sessd.sessionFolder, sessd.vfolder, 'fig*');
            
            chpc.scpFromChpc(logs);
            chpc.scpFromChpc(mats);
            chpc.scpFromChpc(figs);
        end
    end
    
    methods
        function this = CHPC(varargin)
            this = this@mldistcomp.CHPC(varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

