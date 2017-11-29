classdef HyperglycemiaDirector < mlraichle.StudyDirector
	%% HYPERGLYCEMIADIRECTOR is a high-level, study-level director for other directors and builders.

	%  $Revision$
 	%  was created 26-Dec-2016 12:39:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties
        freesurferData = { 'aparc+aseg' 'brainmask' 'T1' }
        umapDirector
        fdgDirector
        hoDirector
        ooDirector
        ocDirector
        trDirectors = {'fdgDirector' 'hoDirector' 'ocDirector' 'ooDirector'}
    end
    
    properties (Dependent)
        sessionData
    end
    
    methods (Static)
        function         cleanConverted(varargin)
            %% cleanConverted
            %  @param named verifyForDeletion must be set to the fully-qualified study directory to clean.
            %  @param works in the pwd which should point to the study directory.
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
            
            ip = inputParser;
            addParameter(ip, 'verifyForDeletion', ['notavalidedirectory_' datestr(now,30)], @isdir);
            parse(ip, varargin{:});            
            pwd0 = pushd(ip.Results.verifyForDeletion);
            fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd);
            import mlsystem.*;
            
            dtsess = DirTools({'HYGLY*' 'NP995*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.HyperglycemiaDirector.cleanConverted:  is cleaning %s\n', pwd); 

                    dtconv = DirTool('*-Converted*');
                    for idtconv = 1:length(dtconv.fqdns)
                        try
                            mlbash(sprintf('rm -rf %s', dtconv.fqdns{idtconv}));
                        catch ME
                            handwarning(ME);
                        end
                    end
                    popd(pwdv);
                end
                popd(pwds);
            end   
            popd(pwd0);
        end
        function         cleanMore(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            tracers = {'OC' 'OO' 'HO' 'FDG'};
            %tracers = {'FDG'};
            import mlraichle.*;
            for t = 1:length(tracers)
                HyperglycemiaDirector.constructCellArrayOfObjects( ...
                    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', false);
                %HyperglycemiaDirector.constructCellArrayOfObjects( ...
                %    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', true);
            end
        end
        function         cleanMoreRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            %tracers = {'OC' 'OO' 'HO' 'FDG'};
            tracers = {'FDG'};
            import mlraichle.*;
            for t = 1:length(tracers)
                HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', false, 'pushData', false);
                %HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                %    'mlraichle.TracerDirector.cleanMore', varargin{:}, 'tracer', tracers{t}, 'ac', true,  'pushData', false);
            end
        end
        function chpc  = cleanSinograms(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            chpc = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanSinograms', varargin{:});
        end
        function chpc  = cleanSinogramsRemotely(varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return chpc, an instance of mlpet.CHPC4TracerDirector.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            try
                chpc = CHPC4TracerDirector([], 'distcompHost', ip.Results.distcompHost, 'wallTime', '2:00:00');
                chpc = chpc.runSerialProgram(@mlraichle.TracerDirector.cleanSinograms, {}, 1);
            catch ME
                handwarning(ME);
            end
        end
        function         cleanTracerRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanTracerRemotely', varargin{:});
        end
        
        function gr    = graphUmapDefects(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listUmapDefects', varargin{:});
            gr = mlraichle.HyperglycemiaDirector.constructGraphOfObjects(those);
        end
        function lst   = listUmapDefects(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listUmapDefects', varargin{:});
        end
        function those = reviewUmaps(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reviewUmaps', 'ac', true, varargin{:});   
        end
        function lst   = listTracersConverted(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listTracersConverted', varargin{:});
        end
        function lst   = listTracersResolved(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.listTracersResolved', varargin{:});
        end
        function lst   = listTracersResolvedRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            import mlraichle.*;
            cellArr = HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.listTracersResolved', varargin{:});
            lst = HyperglycemiaDirector.fetchOutputsCellArrayOfObjectsRemotely( ...
                cellArr);
        end
        
        function lst   = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session & visit-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlraichle.SessionData.
            %  @return 4dfp copies of this.freesurferData in sessionData.vLocation.
            %  @return lst, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.
            
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'));
            parse(ip, varargin{:});
            
            sessd = ip.Results.sessionData;
            pwd0 = pushd(sessd.vLocation);
            fv = mlfourdfp.FourdfpVisitor;
            this = mlraichle.HyperglycemiaDirector(varargin{:});
            fsd = this.freesurferData;
            lst = cell(1, length(fsd));
            for f = 1:length(fsd)
                if (~fv.lexist_4dfp(fsd{f}))
                    try
                        sessd.mri_convert( [fullfile(sessd.mriLocation, fsd{f}) '.mgz'], [fsd{f} '.nii']);
                        sessd.nifti_4dfp_4(fsd{f});
                        if (strcmp(fsd{f}, 'T1'))
                            fv.move_4dfp(fsd{f}, [fsd{f} '001']);
                        end
                        lst = [lst fullfile(pwd, fsd{f})]; %#ok<AGROW>
                    catch ME
                        handexcept(ME);
                    end
                end
            end
            popd(pwd0);
        end
        function this  = sortDownloads(downloadPath, sessionFolder, v, varargin)
            %% SORTDOWNLOADS installs data from rawdata into SUBJECTS_DIR; start here after downloading rawdata.  
            
            ip = inputParser;
            addRequired(ip, 'downloadPath', @isdir);
            addRequired(ip, 'sessionFolder', @ischar);
            addRequired(ip, 'v', @isnumeric);
            addOptional(ip, 'kind', '', @ischar);
            parse(ip, downloadPath, sessionFolder, v, varargin{:});

            pwd0 = pwd;
            import mlraichle.*;
            sessp = fullfile(RaichleRegistry.instance.subjectsDir, sessionFolder, '');
            if (~isdir(sessp))
                mlfourdfp.FourdfpVisitor.mkdir(sessp);
            end
            sessd = SessionData('studyData', StudyData, 'sessionPath', sessp, 'vnumber', v);
            this  = HyperglycemiaDirector('sessionData', sessd);
            switch (lower(ip.Results.kind))
                case 'ct'
                    this  = this.instanceSortDownloadCT(downloadPath);
                case 'freesurfer'
                    this  = this.instanceSortDownloadFreesurfer(downloadPath);
                otherwise
                    this  = this.instanceSortDownloads(downloadPath);
                    this  = this.instanceSortDownloadFreesurfer(downloadPath);
            end
            cd(pwd0);
        end    
        
        function those = constructFreesurfer6(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlsurfer.SurferDirector.constructFreesurfer6', 'wallTime', '47:59:59', varargin{:});
        end
        function those = constructNiftyPETy(varargin)            
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructNiftyPETy', [varargin{:} {'ac' true}]);
        end
        function those = constructUmaps(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.HyperglycemiaDirector.prepareFreesurferData', varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.UmapDirector.constructUmaps', varargin{:});
        end    
        function those = constructResolved(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolved', varargin{:});
        end
        function those = constructResolvedRemotely(varargin)
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructResolved', 'wallTime', '23:59:59', varargin{:});
        end
        function those = constructUmapSynthFull(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructUmapSynthFull', varargin{:});
            
        end
        function those = constructAnatomy(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructAnatomy', 'ac', true, varargin{:});            
        end
        function those = constructAnatomyRemotely(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.constructAnatomy', 'ac', true, varargin{:});            
        end
        function those = constructExports(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructExports', 'ac', true, varargin{:});   
        end
        function those = viewExports(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.viewExports', 'ac', true, varargin{:});   
        end
        function those = reconstituteImgRec(varargin)
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconstituteImgRec', varargin{:});  
        end 
        function those = reconAll(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.reconAll', 'wallTime', '23:59:59', varargin{:});            
        end
        function those = reconAllRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjectsRemotely( ...
                'mlraichle.TracerDirector.reconAll', 'wallTime', '23:59:59', varargin{:});            
        end
        
        function those = constructKinetics(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructKinetics', varargin{:});
        end
        function those = constructResolveReports(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolveReports', varargin{:});
        end
        function those = pullFromRemote(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullFromRemote', varargin{:});
        end     
        function those = pullResolved(varargin)
            %  @param named 'pattern' is given to rsync to match objects to pull
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', varargin{:});
        end  
        function those = pullResolvedAC(varargin)
            %  @param named 'pattern' is given to rsync to match objects to pull
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', '*_op_*_frame*.4dfp.*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'T1001_op_*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'wmparc_op_*.*', varargin{:});
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', 'aparc+aseg_op_*.*', varargin{:});
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', 'ac', true, 'pattern', '*_t4', varargin{:});
        end
        function those = pullResolvedNAC(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            %% pattern matches fullfile(this.sessionData.tracerLocation, pattern);
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', varargin{:}, 'pattern', '*.v');
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', varargin{:}, 'pattern', 'umapSynth.*');
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullPattern', varargin{:}, 'pattern', '*r1.4dfp.*');
        end
        function lst   = repairUmapDefects(varargin)
            lst = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.repairUmapDefects', varargin{:});
        end
        
    end
    
    methods 
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function this = instanceSortDownloads(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.sessionSort(downloadPath, this.sessionData_.vLocation, 'sessionData', this.sessionData);
                rds     = RawDataSorter('sessionData', this.sessionData_);
                rawData = fullfile(downloadPath, 'RESOURCES', 'RawData', '');
                scans   = fullfile(downloadPath, 'SCANS', '');
                rds.dcm_sort_PPG(rawData);
                rds.moveRawData(rawData);
                rds.copyUTE(scans);            
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloads.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end
        function this = instanceSortDownloadCT(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.sessionSort(downloadPath, this.sessionData_.sessionPath, 'sessionData', this.sessionData);
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloadCT.downloadPath->%s may be missing folder SCANS', downloadPath);
            end
        end
        function this = instanceSortDownloadFreesurfer(this, downloadPath)
            try
                [~,downloadFolder] = fileparts(downloadPath);
                dt = mlsystem.DirTool(fullfile(downloadPath, 'ASSESSORS', '*freesurfer*'));
                for idt = 1:length(dt.fqdns)
                    DATAdir = fullfile(dt.fqdns{idt}, 'DATA', '');
                    if (~isdir(this.sessionData.freesurferLocation))
                        if (isdir(fullfile(DATAdir, downloadFolder)))
                            DATAdir = fullfile(DATAdir, downloadFolder);
                        end
                        movefile(DATAdir, this.sessionData.freesurferLocation);
                    end
                end
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloadFreesurfer.downloadPath->%s may be missing folder ASSESSORS', ...
                    downloadPath);
            end
        end
        
        function this = analyzeCohort(this)
        end     
        function this = analyzeSubject(this)
        end   
        function this = analyzeVisit(this, sessp, v)
            import mlraichle.*;
            study = StudyDataSingleton;
            sessd = SessionData('studyData', study, 'sessionPath', sessp);
            sessd.vnumber = v;
            this = this.analyzeTracers('sessionData', sessd);
        end
        function this = analyzeTracers(this)
            this.umapDirector = this.umapDirector.analyze;
            this.fdgDirector  = this.fdgDirector.analyze;
            this.hoDirector   = this.hoDirector.analyze;
            this.ooDirector   = this.ooDirector.analyze;
            this.ocDirector   = this.ocDirector.analyze;
        end
        
        % construct methods are interleaved with JSRecon12 processes
        
        function this = instanceConstructKinetics(this, varargin)
            %% INSTANCECONSTRUCTKINETICS iterates through this.trDirectors.
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            for td = 1:length(this.trDirectors)
                this.(this.trDirectors{td}).roisBuilder = ip.Results.roisBuild;
                this.(this.trDirectors{td}) = this.(this.trDirectors{td}).instanceConstructKinetics(varargin{:});
            end
        end
        function tf   = queryKineticsPassed(this, varargin)
            %% QUERYKINETICSPASSED for all this.trDirectors.
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = true;
            for td = 1:length(this.trDirectors)
                tf = tf && this.(this.trDirectors{td}).queryKineticsPassed(varargin{:});
            end           
        end
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  @param parameter 'sessionData' is a 'mlpipeline.ISessionData'

            this = this@mlraichle.StudyDirector(varargin{:});
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;  
            this = this.assignTracerDirectors;          
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end
    
    methods (Access = private)
        function this = assignTracerDirectors(this)
 			import mlraichle.*;            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

