classdef StudyDirector 
	%% STUDYDIRECTOR is a high-level, study-level director for other directors and builders in the package.

	%  $Revision$
 	%  was created 28-Sep-2017 22:19:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		NSCANS = 2
    end

    %% PROTECTED
    
    methods (Static, Access = protected)
        
        function those = constructCellArrayOfObjects(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTS iterates over session and visit directories, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'tracer', {'OC' 'OO' 'HO'}, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', false);
            parse(ip, varargin{:});
            tracers = ensureCell(ip.Results.tracer);
            factoryMethod = ip.Results.factoryMethod;
            
            import mlsystem.* mlraichle.*;
            those = {};
            dtsess = DirTool( ...
                fullfile(RaichleRegistry.instance.subjectsDir, ip.Results.sessionsExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                dtv = DirTool(fullfile(sessp, ip.Results.visitsExpr));
                for idtv = 1:length(dtv.fqdns)
                    
                    if (lstrfind(dtv.dns{idtv}, 'HYGLY25'))
                        factoryMethod = [factoryMethod '_HYGLY25']; %#ok<AGROW>
                    end
                    
                    for iscan = 1:StudyDirector.NSCANS
                        for itrac = 1:length(tracers)
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try
                                sessd = SessionData( ...
                                    'studyData', StudyData, ...
                                    'sessionPath', sessp, ...
                                    'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                                    'snumber', iscan, ...
                                    'tracer', tracers{itrac}, ...
                                    'ac', ip.Results.ac); 
                                evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);

                                fprintf('mlraichle.StudyDirecto.constructCellArrayOfObjectsr:\n');
                                fprintf(['\t' evalee '\n']);
                                fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                those{idtsess,idtv} = eval(evalee); %#ok<AGROW>
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end                        
                popd(pwds);
            end
        end
        function those = constructCellArrayOfObjectsRemotely(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSREMOTELY iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named nArgout is numeric.
            %  @param  named distcompHost is the hostname or distcomp profile.
            %  @param  named pushData calls mlpet.CHPC4TracerDirector.pushData if its logical value is true.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'factoryArgs', {}, @iscell);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'tracer', {'OC' 'OO' 'HO'}, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', false);
            addParameter(ip, 'nArgout', 1, @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'memUsage', '32000', @ischar);
            addParameter(ip, 'wallTime', '12:00:00', @ischar);
            addParameter(ip, 'pushData', true, @islogical);
            parse(ip, varargin{:});
            tracers = ensureCell(ip.Results.tracer);
            wallTime = ip.Results.wallTime;
            if (ip.Results.ac)
                wallTime = '23:59:59';
            end
            
            import mlsystem.*;
            those = {};
            dtsess = DirTool( ...
                fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, ip.Results.sessionsExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                dtv = DirTool(fullfile(sessp, ip.Results.visitsExpr));
                for idtv = 1:length(dtv.fqdns)                    
                    for itrac = 1:length(tracers)
                        for iscan = 1:mlraichle.StudyDirector.NSCANS
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try
                                sessd = mlraichle.SessionData( ...
                                    'studyData', mlraichle.StudyData, ...
                                    'sessionPath', sessp, ...
                                    'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                                    'snumber', iscan, ...
                                    'tracer', tracers{itrac}, ...
                                    'ac', ip.Results.ac); 
                                csessd = sessd;
                                csessd.sessionPath = mldistcomp.CHPC.repSubjectsDir(sessd.sessionPath);                                
                                chpc = mlpet.CHPC4TracerDirector( ...
                                    [], 'distcompHost', ip.Results.distcompHost, ...
                                    'sessionData', sessd, ...
                                    'memUsage', ip.Results.memUsage, ...
                                    'wallTime', wallTime);
                                if (ip.Results.pushData)
                                    chpc = chpc.pushData; %#ok<NASGU>
                                end
                                evalee = sprintf(['chpc.runSerialProgram(@%s, ' ...
                                    '{''sessionData'', csessd}, ' ...
                                    'ip.Results.nArgout)'],  ...
                                     ip.Results.factoryMethod);

                                fprintf('mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely:\n');
                                fprintf(['\t' evalee '\n']);
                                fprintf(['\tcsessd.TracerLocation->' csessd.tracerLocation '\n']);
                                those{idtsess,idtv,itrac,iscan} = eval(evalee); %#ok<AGROW>
                            catch ME
                                handexcept(ME);
                            end
                        end                    
                    end
                end                        
                popd(pwds);
            end
        end
        function those = fetchOutputsCellArrayOfObjectsRemotely(cellArr)
            %% FETCHOUTPUTSCELLARRAYOFOBJECTSREMOTELY iterates over session and visit directories, 
            
            import mlsystem.*;
            sz = size(cellArr);
            those = cell(sz);
            assert(length(sz) == 4);
            for a = 1:sz(1)
                for b = 1:sz(2)
                    for c = 1:sz(3)
                        for d = 1:sz(4)
                            those{a,b,c,d} = cellArr{a,b,c,d}.fetchOutputsSerialProgram;
                        end
                    end
                end
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

