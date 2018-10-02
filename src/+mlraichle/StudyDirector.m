classdef StudyDirector 
	%% STUDYDIRECTOR is a high-level, study-level director for other directors and builders in the package.

	%  $Revision$
 	%  was created 28-Sep-2017 22:19:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		SCANS = 1:4
        SUP_EPOCH = 3
        TRACERS = {'FDG' 'HO' 'OC' 'OO'}
        AC = true
    end
    
    methods (Static)
        function [those,dtsess] = constructCellArrayOfObjects(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTS iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'index0Forced', [], @isnumeric);
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            dtsess = DirTools(fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwdsess = pushd(sessp);
                dtv = DirTools(fullfile(sessp, ipr.visitsExpr));     
                for idtv = 1:length(dtv.fqdns)
                    
                    for itrac = 1:length(tracers)
                        for iscan = ipr.scanList
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try
                                sessd = StudyDirector.constructSessionData( ...
                                    ipr, sessp, str2double(dtv.dns{idtv}(2:end)), iscan, tracers{itrac});
                                if (isprop(sessd, 'index0Forced'))
                                    sessd.index0Forced = ipr.index0Forced;
                                end
                                if (isdir(sessd.tracerLocation)) %#ok<*ISDIR>
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\t' evalee '\n']);
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    those{idtsess,idtv,itrac,iscan} = eval(evalee); 
                                    warning('on', 'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                dispwarning(ME);
                            end
                        end
                    end
                end                        
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjects2(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTS2 iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'index0Forced', [], @isnumeric);
            addParameter(ip, 'hoursOffsetForced', [], @isnumeric); 
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            dtsess = DirTools(fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwdsess = pushd(sessp);
                dtv = DirTools(fullfile(sessp, ipr.visitsExpr));     
                for idtv = 1:length(dtv.fqdns)
                    
                    for itrac = 1:length(tracers)
                        for iscan = ipr.scanList
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try
                                sessd = StudyDirector.constructSessionData2( ...
                                    ipr, sessp, str2double(dtv.dns{idtv}(2:end)), iscan, tracers{itrac});
                                if (isprop(sessd, 'index0Forced'))
                                    sessd.index0Forced = ipr.index0Forced;
                                end
                                if (isprop(sessd, 'hoursOffsetForced'))
                                    sessd.hoursOffsetForced = ipr.hoursOffsetForced;
                                end
                                if (isdir(sessd.tracerLocation)) %#ok<*ISDIR>
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\t' evalee '\n']);
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    those{idtsess,idtv,itrac,iscan} = eval(evalee); 
                                    warning('on', 'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                dispwarning(ME);
                            end
                        end
                    end
                end                        
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjectsParSess(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSPARSESS iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @(x) isa(x, 'function_handle'));
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_2051
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            those = {};
            dtsess = DirTools(fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
            parfor idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess}; %#ok<PFBNS>
                pwdsess = pushd(sessp);
                dtv = DirTools(fullfile(sessp, ipr.visitsExpr)); %#ok<PFBNS>
                for idtv = 1:length(dtv.fqdns)                   
                    for itrac = 1:length(tracers)                        
                        for iscan = ipr.scanList                            
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try                                
                                sessd = StudyDirector.constructSessionData( ...
                                    ipr, sessp, str2double(dtv.dns{idtv}(2:end)), iscan, tracers{itrac});                                
                                if (isdir(sessd.tracerLocation))
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    %those{idtsess,idtv,itrac,iscan} = % unclassifiable within parfor
                                    factoryMethod('sessionData', sessd, varargin{2:end}); %#ok<PFBNS>
                                    warning('on',  'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                dispwarning(ME);
                            end
                        end                        
                    end
                end                        
                popd(pwdsess);
            end
        end
        function [those,dtsess] = constructCellArrayOfObjectsParTrac(varargin)
            %% CONSTRUCTCELLARRAYOFOBJECTSPARTRAC iterates over session and visit directories, 
            %  tracers and scan-instances, evaluating factoryMethod for each.
            %  @param  factoryMethod     is char, specifying static methods for:  those := factoryMethod('sessionData', sessionData).
            %  @param  named sessionsExp is char, specifying session directories to match by DirTool.
            %  @param  named visitsExp   is char, specifying visit   directories to match by DirTool.
            %  @param  named scanList    is numeric := trace scan indices.
            %  @param  named tracer      is char    and passed to SessionData.
            %  @param  named ac          is logical and passed to SessionData.
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @(x) isa(x, 'function_handle'));
            addParameter(ip, 'sessionsExpr', 'HYGLY*');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_2051
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            those = {};
            dtsess = DirTools(fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess}; 
                pwdsess = pushd(sessp);
                dtv = DirTools(fullfile(sessp, ipr.visitsExpr));
                for idtv = 1:length(dtv.fqdns)                   
                    parfor itrac = 1:length(tracers)                        
                        for iscan = ipr.scanList %#ok<PFBNS>
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try                                
                                sessd = StudyDirector.constructSessionData( ...
                                    ipr, sessp, str2double(dtv.dns{idtv}(2:end)), iscan, tracers{itrac}); %#ok<PFBNS>
                                if (isdir(sessd.tracerLocation))
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    %those{idtsess,idtv,itrac,iscan} = % unclassifiable within parfor 
                                    factoryMethod('sessionData', sessd, varargin{2:end}); %#ok<PFBNS>
                                    warning('on',  'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                dispwarning(ME);
                            end
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
            %  @param  named supEpoch    is numeric; KLUDGE to pass parameter to mlraichle.SessionData.tracerResolvedFinal.
            %  @return those             is a cell-array of objects specified by factoryMethod.
            %  @return dtsess            is an mlsystem.DirTool for sessions.
            
            import mlsystem.* mlraichle.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'factoryArgs', {}, @iscell);
            addParameter(ip, 'sessionsExpr',  'HYGLY*');
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'nArgout', 1, @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            addParameter(ip, 'memUsage', '32000', @ischar);
            addParameter(ip, 'wallTime', '12:00:00', @ischar);
            addParameter(ip, 'pushData', false, @islogical);
            parse(ip, varargin{:});
            sessExpr = ip.Results.sessionsExpr;
            if (~isempty(ip.Results.sesssionsExpr))
                sessExpr = ip.Results.sesssionsExpr;
            end
            tracers = ensureCell(ip.Results.tracer);
            wallTime = ip.Results.wallTime;
            if (ip.Results.ac)
                wallTime = '23:59:59';
            end
            
            dtsess = DirTools( ...
                fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, sessExpr));
            for idtsess = 1:length(dtsess.fqdns)
                sessp = dtsess.fqdns{idtsess};
                pwds = pushd(sessp);
                dtv = DirTools(fullfile(sessp, ip.Results.visitsExpr));
                for idtv = 1:length(dtv.fqdns)                    
                    for itrac = 1:length(tracers)
                        for iscan = ip.Results.scanList 
                            if (iscan > 1 && strcmpi(tracers{itrac}, 'FDG'))
                                continue
                            end
                            try
                                sessd = StudyDirector.constructSessionData( ...
                                    ip.Results, sessp, str2double(dtv.dns{idtv}(2:end)), iscan, tracers{itrac});  
                                if (isdir(sessd.tracerLocation))
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
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
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    those{idtsess,idtv,itrac,iscan} = eval(evalee); 
                                    warning('on', 'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                dispexcept(ME);
                            end
                        end                    
                    end
                end                        
                popd(pwds);
            end
        end
        function gr = constructGraphOfObjects(varargin)
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
        function sessd = constructSessionData(ipr, sessp, v, sc, tracer)
            import mlraichle.*;
            sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', sessp, ...
                'vnumber', v, ...
                'snumber', sc, ...
                'tracer', tracer, ...
                'ac', ipr.ac, ...
                'supEpoch', ipr.supEpoch);
            if (~isempty(ipr.tauIndices))
                sessd.tauIndices = ipr.tauIndices;
            end
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
        function sessd = constructSessionData2(ipr, sessp, v, sc, tracer)
            import mlraichle.*;
            sessd = HerscovitchContext( ...
                'studyData', StudyData, ...
                'sessionPath', sessp, ...
                'vnumber', v, ...
                'snumber', sc, ...
                'tracer', tracer, ...
                'ac', ipr.ac, ...
                'supEpoch', ipr.supEpoch);
            if (~isempty(ipr.tauIndices))
                sessd.tauIndices = ipr.tauIndices;
            end
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
    end    

    %% PROTECTED
    
	methods (Access = protected)
		  
 		function this = StudyDirector(varargin)
 			%% STUDYDIRECTOR
 			
        end        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

