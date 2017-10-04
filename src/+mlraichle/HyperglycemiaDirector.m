classdef HyperglycemiaDirector < mlraichle.StudyDirector
	%% HYPERGLYCEMIADIRECTOR is a high-level, study-level director for other directors and builders.

	%  $Revision$
 	%  was created 26-Dec-2016 12:39:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties
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
        function         cleanSinograms(varargin)
            %% cleanSinograms
            %  @param named verifyForDeletion must be set to the fully-qualified study directory to clean.
            %  @param works in the pwd which should point to the study directory.
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
            
            ip = inputParser;
            addParameter(ip, 'verifyForDeletion', ['notavalidedirectory_' datestr(now,30)], @isdir);
            parse(ip, varargin{:});            
            pwd0 = pushd(ip.Results.verifyForDeletion);
            fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd);
            import mlsystem.*;
            
            dtsess = DirTools({'HYGLY*' 'NP995*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 

                    dtconv = DirTool('*-Converted*');
                    for idtconv = 1:length(dtconv.fqdns)
                        pwdc = pushd(dtconv.fqdns{idtconv});
                        fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 

                        dt00 = DirTool('*-00');
                        for idt00 = 1:length(dt00.fqdns)
                            pwd00 = pushd(dt00.fqdns{idt00});
                            fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd);   
                            deleteExisting('*-00-sino*');  
                            popd(pwd00);
                        end
                        popd(pwdc);

                    end
                    popd(pwdv);
                end
                popd(pwds);
            end
            popd(pwd0);
        end
        function this  = goSortDownloads(downloadPath, sessionFolder, v, varargin)
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
                    this  = this.sortDownloadCT(downloadPath);
                case 'freesurfer'
                    this  = this.sortDownloadFreesurfer(downloadPath);
                otherwise
                    this  = this.sortDownloads(downloadPath);
                    this  = this.sortDownloadFreesurfer(downloadPath);
            end
            cd(pwd0);
        end
        
        function those = constructResolved(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolved', varargin{:});
        end
        function those = constructResolvedRemotely(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructResolvedRemotely', varargin{:});
        end
        function those = constructKinetics(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.constructKinetics', varargin{:});
        end
        function those = constructUmaps(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.UmapDirector.constructUmaps', varargin{:});
        end
        function those = pullFromRemote(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            those = mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.pullFromRemote', varargin{:});
        end     
        function         cleanRemote(varargin)
            %  See also:   mlraichle.StudyDirector.constructCellArrayObjects            
            
            mlraichle.HyperglycemiaDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector.cleanRemote', varargin{:});
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        % sort downloads
        
        function this = sortDownloads(this, downloadPath)
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
                    'HyperglycemiaDirector.sortDownloads.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end
        function this = sortDownloadCT(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.sessionSort(downloadPath, this.sessionData_.sessionPath, 'sessionData', this.sessionData);
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.sortDownloadCT.downloadPath->%s may be missing folder SCANS', downloadPath);
            end
        end
        function this = sortDownloadFreesurfer(this, downloadPath)
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
                    'HyperglycemiaDirector.sortDownloadFreesurfer.downloadPath->%s may be missing folder ASSESSORS', ...
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

