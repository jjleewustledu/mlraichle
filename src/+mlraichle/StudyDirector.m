classdef StudyDirector 
	%% STUDYDIRECTOR is a high-level, study-level director for other directors and builders in the package.

	%  $Revision$
 	%  was created 28-Sep-2017 22:19:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
    end

    %% PROTECTED
    
    methods (Static, Access = protected)
        
        function those = constructCellArrayOfObjects(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTS iterates over session and visit directories, evaluating constructFunc for each.
            %  @param  constructFunc is char, specifying static methods for:  those := constructFunc('sessionData', sessionData).
            %  @param  sessionsExp   is char, specifying session directories to match by DirTool.
            %  @param  visitsExp     is char, specifying visit   directories to match by DirTool.
            %  @param  tracer        is char    and passed to SessionData.
            %  @param  ac            is logical and passed to SessionData.
            %  @return those         is a cell-array of objects specified by constructFunc.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'constructFunc', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'tracer', 'FDG', @ischr);
            addParameter(ip, 'ac', false);
            parse(ip, varargin{:});
            
            import mlsystem.*;
            those = {};
            dtsess = DirTool( ...
                fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, ip.Results.sessionsExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                dtv = DirTool(fullfile(sessp, ip.Results.visitsExpr));
                for idtv = 1:length(dtv.fqdns)
                    sessd = mlraichle.SessionData( ...
                        'studyData', mlraichle.StudyData, ...
                        'sessionPath', sessp, ...
                        'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                        'tracer', ip.Results.tracer, ...
                        'ac', ip.Results.ac); %#ok<NASGU>
                    those{idtsess,idtv} = eval(sprintf('%s(''sessionData'', sessd)', ip.Results.constructFunc)); %#ok<AGROW>
                end                        
                popd(pwds);
            end
        end
    end
    
	methods (Access = protected)
		  
 		function this = StudyDirector(varargin)
 			%% STUDYDIRECTOR
 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

