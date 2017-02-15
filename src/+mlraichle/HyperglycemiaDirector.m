classdef HyperglycemiaDirector 
	%% HYPERGLYCEMIADIRECTOR  

	%  $Revision$
 	%  was created 26-Dec-2016 12:39:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        sessionData
 		visitDirector
        umapDirector
        fdgDirector
        hoDirector
        ooDirector
        ocDirector
    end
    
    methods %% GET
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
    end

    methods (Static)
        
    end
    
	methods 
        function this = analyzeCohort(this)
        end     
        function this = analyzeSubject(this)
        end   
        function this = analyzeVisit(this, sessp, v)
            import mlraichle.*;
            study = StudyData;
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
        
        function this = constructUmaps(this)
            mlfourdfp.CarneyUmapBuilder.buildUmapAll;
            mmrb = mlsiemens.MMRBuilder('sessionData', this.sessionData);
        end
        function this = sortDownloads(this, downloadPath)
            import mlfourdfp.*;
            DicomSorter.sessionSort(downloadPath, this.sessionData_.vLocation);
            
            rds = RawDataSorter( ...
                'studyData',   this.sessionData_.studyData, ...
                'sessionData', this.sessionData_);
            RawData = fullfile(downloadPath, 'RESOURCES', 'RawData', '');
            SCANS   = fullfile(downloadPath, 'SCANS', '');
            rds.dcm_sort_PPG(RawData);
            rds.moveRawData(RawData);
            rds.copyUTE(SCANS);            
        end
        function this = sortDownloadCT(this, downloadPath)
            import mlfourdfp.*;
            DicomSorter.sessionSort(downloadPath, this.sessionData_.sessionPath);
            
%             cd(this.sessionData_.rawdataDir);
%             [~,downloadFold] = fileparts(downloadPath);
%             ds = DicomSorter( ...
%                 'studyData', this.sessionData_.studyData, ...
%                 'sessionData', this.sessionData_);
%             ds.sessions_to_4dfp( ...
%                 'sessionFilter', downloadFold, ...
%                 'seriesFilter', {'AC_CT'}, ...
%                 'studyData', this.sessionData_.studyData, ...
%                 'preferredName', 'AC_CT');
        end
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  Usage:  this = HyperglycemiaDirector()

            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;
            
 			import mlraichle.*;
%             this.visitDirector = VisitDirector(varargin{:});
%             this.umapDirector  = UmapDirector( UmapBuilder(varargin{:}));
%             this.fdgDirector   = FdgDirector(  FdgBuilder(varargin{:}));
%             this.hoDirector    = HoDirector(   HoBuilder(varargin{:}));
%             this.ooDirector    = OoDirector(   OoBuilder(varargin{:}));
%             this.ocDirector    = OcDirector(   OcBuilder(varargin{:}));
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

