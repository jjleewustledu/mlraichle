classdef TracerKineticsBuilder < mlpet.TracerKineticsBuilder
	%% TRACERKINETICSBUILDER  

	%  $Revision$
 	%  was created 05-Jul-2017 21:24:57 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function viewResolvedFinal(varargin)
            %% VIEWSTUDYCONVERTED sequentially displays tracer data from available sessions and visits.
            
            ip = inputParser;
            addParameter(ip, 'ac', false, @islogical);
            addParameter(ip, 'tracer', 'FDG', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            parse(ip, varargin{:});
            
            studyd = mlraichle.StudyData;
            pwd0 = pushd(studyd.subjectsDir);
            import mlsystem.* mlraichle.*;
            sesss  = DirTool(ip.Results.sessionsExpr);
            for is = 1:length(sesss)                
                visits = DirTool(fullfile(sesss.fqdns{is}, ip.Results.visitsExpr));
                for iv = 1:length(visits)
                    try
                        sessd = SessionData( ...
                            'studyData', studyd, ...
                            'sessionPath', sesss.fqdns{is}, ...
                            'vnumber', SessionData.visit2double(visits.fqdns{iv}), ...
                            'tracer', ip.Results.tracer, ...
                            'ac', ip.Results.ac);
                        if (~lexist(sessd.tracerResolvedFinal, 'file'))
                            warning('mlraichle:missingImage', 'TracerKineticsBuilder.viewResolvedFinal');
                            continue
                        end
                        mlbash('fslview %s', sessd.tracerResolvedFinal);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
            popd(pwd0);
        end
    end
    
	methods      
		  
 		function this = TracerKineticsBuilder(varargin)
 			%% TRACERKINETICSBUILDER
 			%  Usage:  this = TracerKineticsBuilder()

 			this = this@mlpet.TracerKineticsBuilder(varargin{:});
            
            import mlraichle.*;
            switch (this.sessionData.tracer)
                case 'FDG'
                    this.kinetics_ = FdgKinetics;
                case 'OC'
                    this.kinetics_ = OcKinetics;
                case 'OO'
                    this.kinetics_ = OoKinetics;
                case 'HO'
                    this.kinetics_ = HoKinetics;
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                        'TracerKineticsBuilder.ctor.this.sessionData.tracer->%s', this.sessionData.tracer);
            end            
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

