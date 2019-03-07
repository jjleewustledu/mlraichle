classdef HyperglycemiaDirector2
	%% HYPERGLYCEMIADIRECTOR2  
    %  support reconstructions and analysis using NiftyPET as replacement for Siemens e7 tools.

	%  $Revision$
 	%  was created 15-Nov-2018 15:25:48 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)  
        function those = constructGlucoseMetab(varargin)
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mlglucose.MetabDirector.constructHuang', varargin{:}); 
        end
        function those = constructOxygenMetab(varargin)
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mloxygen.MetabDirector.constructAll', varargin{:}); 
        end
        
        function those = cleanResolved(varargin)
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector2.cleanResolved', varargin{:}); 
        end 
        function those = constructResolved(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'parSession', false, @islogical);
            addParameter(ip, 'parTracer',  false, @islogical);
            parse(ip, varargin{:});
            
            if (ip.Results.parSession)                
                those = mlraichle.StudyDirector.constructCellArrayOfObjectsParSess( ...
                    @mlraichle.TracerDirector2.constructResolved, varargin{:}); 
                return
            end
            if (ip.Results.parTracer)                
                those = mlraichle.StudyDirector.constructCellArrayOfObjectsParTrac( ...
                    @mlraichle.TracerDirector2.constructResolved, varargin{:}); 
                return
            end
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector2.constructResolved', varargin{:}); 
        end 
        function those = constructResolvedAC(varargin)
            those = mlraichle.HyperglycemiaDirector2.constructResolved(varargin{:}, 'ac', true);
        end
        function those = constructResolvedNAC(varargin)
            those = mlraichle.HyperglycemiaDirector2.constructResolved(varargin{:}, 'ac', false);
        end
        function those = constructUmaps(varargin)
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mlraichle.UmapDirector2.constructUmaps', 'ac', false, varargin{:});
        end         
        function those = migrateResolvedToVall(varargin)
            those = mlraichle.StudyDirector.constructCellArrayOfObjects( ...
                'mlraichle.TracerDirector2.migrateResolvedToVall', varargin{:}); 
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
            this  = HyperglycemiaDirector2('sessionData', ...
                SessionData('studyData', StudyData, 'sessionPath', sessp, 'vnumber', v));
            switch (lower(ip.Results.kind))
                case 'ct'
                    this  = this.instanceSortDownloadCT(downloadPath);
                case 'freesurfer'
                    this  = this.instanceSortDownloadFreesurfer(downloadPath);
                case 'rawdata'
                    this  = this.instanceSortDownloadRawdata(downloadPath);
                otherwise
                    this  = this.instanceSortDownloads(downloadPath);
            end
            cd(pwd0);
        end             
    end
    
    methods        
 		function this = HyperglycemiaDirector2(varargin)
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;   
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end
    
	methods (Access = private)		
        function this = instanceSortDownloads(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData_);          
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector2.instanceSortDownloads.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end
        function this = instanceSortDownloadCT(this, downloadPath)
            try
                mlfourdfp.DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData_);
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector2.instanceSortDownloadCT.downloadPath->%s may be missing folder SCANS', downloadPath);
            end
        end
        function this = instanceSortDownloadFreesurfer(this, downloadPath)
            try
                [~,downloadFolder] = fileparts(downloadPath);
                dt = mlsystem.DirTool(fullfile(downloadPath, 'ASSESSORS', '*freesurfer*'));
                for idt = 1:length(dt.fqdns)
                    DATAdir = fullfile(dt.fqdns{idt}, 'DATA', '');
                    if (~isdir(this.sessionData_.freesurferLocation))
                        if (isdir(fullfile(DATAdir, downloadFolder)))
                            DATAdir = fullfile(DATAdir, downloadFolder);
                        end
                        movefile(DATAdir, this.sessionData_.freesurferLocation);
                    end
                end
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector2.instanceSortDownloadFreesurfer.downloadPath->%s may be missing folder ASSESSORS', ...
                    downloadPath);
            end
        end
        function this = instanceSortDownloadsRawdata(this, downloadPath)
            import mlfourdfp.*;
            try
                RawDataSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData_);            
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector2.instanceSortDownloadsRawdata.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

