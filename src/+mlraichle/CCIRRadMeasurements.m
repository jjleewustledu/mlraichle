classdef CCIRRadMeasurements < handle & mlpet.CCIRRadMeasurements
	%% CCIRRADMEASUREMENTS

	%  $Revision$
 	%  was created 19-Jan-2018 17:16:28 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	    
    methods (Static)
        function this = createByDate(aDate, varargin)
            import mlraichle.CCIRRadMeasurements.*;
            this = createByFilename(date2filename(aDate), varargin{:});
        end
        function this = createByFilename(fqfn, varargin)
            this = mlraichle.CCIRRadMeasurements(varargin{:});
            this = this.readtables(fqfn);
        end
        function this = createBySession(sess, varargin)
            this = mlraichle.CCIRRadMeasurements('session', sess, varargin{:});
        end
    end

    %% PROTECTED
    
	methods (Access = protected)
        function this = CCIRRadMeasurements(varargin)
            %% CCIRRADMEASUREMENTS reads tables from measurement files specified by env var CCIR_RAD_MEASUREMENTS_DIR
            %  and a datetime for the measurements.
            %  @param session is mlraichle.Session; default := trivial ctor.
            %  @param alwaysUseReferenceDate is logical; default := true.
            
            this = this@mlpet.CCIRRadMeasurements(varargin{:});            
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

