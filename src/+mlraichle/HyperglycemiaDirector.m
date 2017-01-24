classdef HyperglycemiaDirector 
	%% HYPERGLYCEMIADIRECTOR  

	%  $Revision$
 	%  was created 26-Dec-2016 12:39:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		visitDirector
        umapDirector
        fdgDirector
        hoDirector
        ooDirector
        ocDirector
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
        
 		function this = HyperglycemiaDirector(varargin)
 			%% HYPERGLYCEMIADIRECTOR
 			%  Usage:  this = HyperglycemiaDirector()

 			import mlraichle.*;
            this.visitDirector = VisitDirector(varargin{:});
            this.umapDirector  = UmapDirector( UmapBuilder(varargin{:}));
            this.fdgDirector   = FdgDirector(  FdgBuilder(varargin{:}));
            this.hoDirector    = HoDirector(   HoBuilder(varargin{:}));
            this.ooDirector    = OoDirector(   OoBuilder(varargin{:}));
            this.ocDirector    = OcDirector(   OcBuilder(varargin{:}));
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

