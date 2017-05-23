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
    end
    
    properties (Dependent)
        sessionData
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
        
        function this = constructNac(this)
            this.sessionData_.attenuationCorrected = false;
            this = this.assignTracerDirectors;
            
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
        function this = constructKinetics(this)
            tracerNames = {'fdg' 'ho' 'oc' 'oo'};
            for tn = 1:length(tracerNames)
                this.(tracerNames{tn}) = this.(tracerNames{tn}).gatherConvertedAc;
                this.(tracerNames{tn}) = this.(tracerNames{tn}).resolveTof;
                this.(tracerNames{tn}) = this.(tracerNames{tn}).constructKinetics;
            end           
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
        end
        function this = sortDownloadFreesurfer(this, downloadPath)
        end
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  Usage:  this = HyperglycemiaDirector('sessionData', theSessionData)

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
        function this = assignTracerDirectors(this)
 			import mlraichle.*;
            if (~this.sessionData.attenuationCorrected)
                this.umapDirector = UmapDirector(UmapBuilder('sessionData', this.sessionData));
            end
            this.fdgDirector  = FdgDirector( FdgBuilder( 'sessionData', this.sessionData));
            this.hoDirector   = HoDirector(  HoBuilder(  'sessionData', this.sessionData));
            this.ooDirector   = OoDirector(  OoBuilder(  'sessionData', this.sessionData));
            this.ocDirector   = OcDirector(  OcBuilder(  'sessionData', this.sessionData));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

