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
            %  @param  constructFunc     is char, specifying static methods for:  those := constructFunc('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @return those             is a cell-array of objects specified by constructFunc.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'constructFunc', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'tracer', 'FDG', @ischar);
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
                    try
                        sessd = mlraichle.SessionData( ...
                            'studyData', mlraichle.StudyData, ...
                            'sessionPath', sessp, ...
                            'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                            'tracer', ip.Results.tracer, ...
                            'ac', ip.Results.ac); 
                        evalee = sprintf('%s(''sessionData'', sessd)', ip.Results.constructFunc);
                        
                        fprintf('mlraichle.StudyDirector:\n');
                        fprintf(['\t' evalee '\n']);
                        fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                        
                        those{idtsess,idtv} = eval(evalee); %#ok<AGROW>
                    catch ME
                        handwarning(ME);
                    end
                end                        
                popd(pwds);
            end
        end
        function those = constructCellArrayOfObjectsRemotely(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSREMOTELY iterates over session and visit directories, evaluating constructFunc for each.
            %  @param  constructFunc     is char, specifying static methods for:  those := constructFunc('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named nArgout is numeric.
            %  @param  named distcompHost is the hostname or distcomp profile.
            %  @param  named pushData calls mlpet.CHPC4TracerDirector.pushData if its logical value is true.
            %  @param  named pullData calls mlpet.CHPC4TracerDirector.pullData if its logical value is true.
            %  @return those             is a cell-array of objects specified by constructFunc.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'constructFunc', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'tracer', 'FDG', @ischr);
            addParameter(ip, 'ac', false);
            addParameter(ip, 'nArgout', 1, @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'pushData', false, @islogical);
            addParameter(ip, 'pullData', false, @islogical);
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
                    try
                        sessd = mlraichle.SessionData( ...
                            'studyData', mlraichle.StudyData, ...
                            'sessionPath', sessp, ...
                            'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                            'tracer', ip.Results.tracer, ...
                            'ac', ip.Results.ac); 
                        evalee = sprintf(['%s(' ...
                            '''sessionData'',  sessd, ' ...
                            '''nArgout'',      ip.Results.nArgout' ...
                            '''distcompHost'', ip.Results.distcompHost' ...
                            '''pushData'',     ip.Results.pushData' ...
                            '''pullData'',     ip.Results.pullData' ...
                            ')'], ip.Results.constructFunc);
                        
                        fprintf('mlraichle.StudyDirector:\n');
                        fprintf(['\t' evalee '\n']);
                        fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                        
                        those{idtsess,idtv} = eval(evalee); %#ok<AGROW>
                    catch ME
                        handexcept(ME);
                    end
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

