classdef HyperglycemiaDirector
	%% HYPERGLYCEMIADIRECTOR  

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
        trDirectors = {'hoDirector'} %%%'fdgDirector' 'ocDirector' 'ooDirector'}
    end
    
    properties (Dependent)
        sessionData
    end
    
    methods (Static)
        function this = goSortDownloads(downloadPath, sessionFolder, v, varargin)
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
                mkdir(sessp);
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
    end
    
    methods 
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
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
        
        function this = constructNac(this)
            this.sessionData_.attenuationCorrected = false;
            
            this.fdgDirector.constructNac;
            this.hoDirector.constructNac;
            this.ooDirector.constructNac;
            this.ocDirector.constructNac;        
            this.fdgDirector.prepareJSRecon;
            this.hoDirector.prepareJSRecon;
            this.ooDirector.prepareJSRecon;
            this.ocDirector.prepareJSRecon;
        end
        function this = constructUmap(this)
            this.umapDirector = this.umapDirector.constructUmap;
        end
        function this = constructAc(this)
            tracerNames = {'fdg' 'ho' 'oc' 'oo'};
            for tn = 1:length(tracerNames)
                this.(tracerNames{tn}) = this.(tracerNames{tn}).resolveNac;
                this.(tracerNames{tn}) = this.(tracerNames{tn}).resolveUmaps;
                this.(tracerNames{tn}) = this.(tracerNames{tn}).prepareJSReconAc;
            end
        end
        function this = constructKinetics(this, varargin)
            %% CONSTRUCTKINETICS iterates through this.trDirectors.
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            for td = 1:length(this.trDirectors)
                this.(this.trDirectors{td}).roisBuilder = ip.Results.roisBuild;
                this.(this.trDirectors{td}) = this.(this.trDirectors{td}).constructKinetics(varargin{:});
            end
        end
        function tf   = constructKineticsPassed(this, varargin)
            %% CONSTRUCTKINETICSPASSED
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = true;
            for td = 1:length(this.trDirectors)
                tf = tf && this.(this.trDirectors{td}).constructKineticsPassed(varargin{:});
            end           
        end
        
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
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  @param parameter 'sessionData' is a 'mlpipeline.ISessionData'

 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;  
            %this = this.assignTracerDirectors;          
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end
    
    methods (Access = private)
        function this = assignTracerDirectors(this)
 			import mlraichle.*;
            
            %this.umapDirector = UmapDirector(UmapBuilder('sessionData', this.sessionData));
            %this.fdgDirector  = FdgDirector( FdgBuilder( 'sessionData', this.sessionData));
            this.hoDirector   = HoDirector(  HoBuilder(  'sessionData', this.sessionData));
            %this.ooDirector   = OoDirector(  OoBuilder(  'sessionData', this.sessionData));
            %this.ocDirector   = OcDirector(  OcBuilder(  'sessionData', this.sessionData));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

