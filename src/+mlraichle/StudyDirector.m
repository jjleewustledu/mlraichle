classdef StudyDirector
	%% STUDYDIRECTOR is a high-level, study-level director for other directors and builders in the package.

	%  $Revision$
 	%  was created 28-Sep-2017 22:19:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		SCANS = 1:4
        TRACERS = {'FDG'} % 'HO' 'OC' 'OO'
        AC = false
    end
    
    methods (Static)
        function ipr = adjustParameters(ipr)
            assert(isstruct(ipr));
            results = {'sessionsExpr'};
            for r = 1:length(results)
                if (~lstrfind(ipr.(results{r}), '*'))
                    ipr.(results{r}) = [ipr.(results{r}) '*'];
                end
            end
        end
        
        function [those,dtsess] = constructCellArrayOfObjects(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTS iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', mlraichle.StudyDirector.SCANS);
            addParameter(ip, 'tracer', mlraichle.StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', mlraichle.StudyDirector.AC);
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = mlraichle.StudyDirector.adjustParameters(ip.Results);
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            dtsess = DirTools(fullfile(mlraichle.StudyRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwdsess = pushd(sessp);
                    
                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = mlraichle.StudyDirector.constructSessionData( ...
                                ipr, sessp, iscan, tracers{itrac});
                            evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);
                            fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                            fprintf(['\t' evalee '\n']);
                            fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                            warning('off', 'MATLAB:subsassigndimmismatch');
                            those{idtsess,itrac,iscan} = eval(evalee); 
                            warning('on', 'MATLAB:subsassigndimmismatch');
                        catch ME
                            dispwarning(ME)
                            getReport(ME)
                        end
                    end
                end                     
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjectsParSess(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSPARSESS iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is function_handle, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @(x) isa(x, 'function_handle'));
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', mlraichle.StudyDirector.SCANS);
            addParameter(ip, 'tracer', mlraichle.StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', mlraichle.StudyDirector.AC);
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = mlraichle.StudyDirector.adjustParameters(ip.Results);
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            varargin2 = varargin(2:end);
            
            those = {};
            dtsess = DirTools(fullfile(mlraichle.StudyRegistry.instance.subjectsDir, sessExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess}; %#ok<PFBNS>
                pwdsess = pushd(sessp);
                               
                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList %#ok<PFBNS>
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = mlraichle.StudyDirector.constructSessionData( ...
                                ipr, sessp, iscan, tracers{itrac});
                            fprintf('mlraichle.StudyDirector.constructCellArrayOfObjectsParSess:\n');
                            fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                            factoryMethod('sessionData', sessd, varargin2{:}); %#ok<PFBNS>
                        catch ME
                            dispwarning(ME)
                            getReport(ME)
                        end
                    end
                end                    
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjectsParTrac(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSPARTRACER iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is function_handle, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @(x) isa(x, 'function_handle'));
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'scanList', mlraichle.StudyDirector.SCANS);
            addParameter(ip, 'tracer', mlraichle.StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', mlraichle.StudyDirector.AC);
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = mlraichle.StudyDirector.adjustParameters(ip.Results);
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            varargin2 = varargin(2:end);
            
            those = {};
            dtsess = DirTools(fullfile(mlraichle.StudyRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwdsess = pushd(sessp);
                               
                parfor itrac = 1:length(tracers)
                    for iscan = ipr.scanList %#ok<PFBNS>
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = mlraichle.StudyDirector.constructSessionData( ...
                                ipr, sessp, iscan, tracers{itrac}); 
                            fprintf('mlraichle.StudyDirector.constructCellArrayOfObjectsParTrac:\n');
                            fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                            factoryMethod('sessionData', sessd, varargin2{:}); %#ok<PFBNS>
                        catch ME
                            dispwarning(ME)
                            getReport(ME)
                        end
                    end
                end                
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjectsRemotely(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSREMOTELY iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named nArgout     is numeric.
            %  @param  named distcompHost is the hostname or distcomp profile.
            %  @param  named pushData calls mlpet.CHPC4TracerDirector.pushData if its logical value is true.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'factoryArgs', {}, @iscell);
            addParameter(ip, 'sessionsExpr',  'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'scanList', mlraichle.StudyDirector.SCANS);
            addParameter(ip, 'tracer', mlraichle.StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', mlraichle.StudyDirector.AC);
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'nArgout', 1, @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            addParameter(ip, 'memUsage', '32000', @ischar);
            addParameter(ip, 'wallTime', '12:00:00', @ischar);
            addParameter(ip, 'pushData', false, @islogical);
            addParameter(ip, 'visitsExpr', ''); % legacy
            parse(ip, varargin{:});
            ipr = mlraichle.StudyDirector.adjustParameters(ip.Results);
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            tracers = ensureCell(ipr.tracer);
            wallTime = ipr.wallTime;
            if (ipr.ac)
                wallTime = '23:59:59';
            end
            
            those = {};
            dtsess = DirTools( ...
                fullfile(mlraichle.StudyRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);                  
                for itrac = 1:length(tracers)
                    for iscan = ipr.scanList 
                        if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                            continue
                        end
                        try
                            sessd = mlraichle.StudyDirector.constructSessionData( ...
                                ipr, sessp, iscan, tracers{itrac});  
                            if (mlraichle.StudyDirector.isTracerDir(sessd))
                                % there exist spurious tracerLocations; select those with corresponding raw data

                                csessd = sessd;
                                csessd.sessionPath = mldistcomp.CHPC.repSubjectsDir(sessd.sessionPath);                                
                                chpc = mlpet.CHPC4TracerDirector( ...
                                    [], 'distcompHost', ipr.distcompHost, ...
                                    'sessionData', sessd, ...
                                    'memUsage', ipr.memUsage, ...
                                    'wallTime', wallTime);
                                if (ipr.pushData)
                                    chpc = chpc.pushData; %#ok<NASGU>
                                end
                                evalee = sprintf(['chpc.runSerialProgram(@%s, ' ...
                                    '{''sessionData'', csessd}, ' ...
                                    'ipr.nArgout)'],  ...
                                     ipr.factoryMethod);
                                fprintf('mlraichle.StudyDirector.constructCellArrayOfObjectsRemotely:\n');
                                fprintf(['\t' evalee '\n']);
                                fprintf(['\tcsessd.TracerLocation->' csessd.tracerLocation '\n']);                                    
                                warning('off', 'MATLAB:subsassigndimmismatch');
                                those{idtsess,itrac,iscan} = eval(evalee); 
                                warning('on', 'MATLAB:subsassigndimmismatch');
                            end
                        catch ME
                            dispexcept(ME);
                        end
                    end                    
                end
                popd(pwds);
            end
        end
        
        function gr    = constructGraphOfObjects(varargin)
            %% CONSTRUCTGRAPHOFOBJECTS
            %  @param those is from constructCellArrayOfObjects{,Remotely}.
            %  @return gr is a graph of those sessions, visits, tracers, scan objects specified by constructCellArrayOfObjects{,Remotely}.
            %  See also:  mlraichle.StudyDirector.constructCellArrayOfObjects{,Remotely}
            
            import mlraichle.*;
            ip = inputParser;
            addRequired(ip, 'those', @iscell);
            addRequired(ip, 'dtsess', @(x) isa(x, 'mlsystem.DirTool'));
            parse(ip, varargin{:});
            those = ip.Results.those;
            
            s = [];
            node = 0;
            names = {};
            gr = graph;
            gr = gr.addnode(1);
            gr.Nodes.Name = {'study'};
            for isess = 1:length(those)
                gr = gr.addnode(1);
                for ivisit = 1:length(those{isess})
                    for itracer = 1:length(those{isess,ivisit})
                        for iscan = 1:length(those{isess,ivisit,itracer})
                            
                            th = those{isess, ivisit, itracer};
                            if (~isempty(th))
                                s = [s isess]; %#ok<*AGROW>
                                node = node + 1;
                                names{node} = th; 
                            end
                        end
                    end
                end
            end
            
            %gr = graph(s, t, ones(size(s)), names);
        end        
        function sessd = constructSessionData(ipr, sessp, sc, tracer)
            import mlraichle.*;
            sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', sessp, ...
                'snumber', sc, ...
                'tracer', tracer, ...
                'ac', ipr.ac);
            if (~isempty(ipr.fractionalImageFrameThresh))
                sessd.fractionalImageFrameThresh = ipr.fractionalImageFrameThresh;
            end
            if (~isempty(ipr.frameAlignMethod))
                sessd.frameAlignMethod = ipr.frameAlignMethod;
            end
            if (~isempty(ipr.compAlignMethod))
                sessd.compAlignMethod = ipr.compAlignMethod;
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
        function tf    = isTracerDir(sessd)
            tf = isdir(sessd.tracerLocation) || ...
                 isdir(sessd.tracerConvertedLocation);
        end
    end    
    
    %% PRIVATE
    
	methods (Access = private)		  
 		function this = StudyDirector(varargin)
        end        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

