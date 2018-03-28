classdef StudyDirector 
	%% STUDYDIRECTOR is a high-level, study-level director for other directors and builders in the package.

	%  $Revision$
 	%  was created 28-Sep-2017 22:19:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
 		SCANS = 1:3
        SUP_EPOCH = 3
        TRACERS = {'FDG' 'OC' 'OO' 'HO'}
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
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'alignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            parse(ip, varargin{:});
            sessExpr = ip.Results.sessionsExpr;
            if (~isempty(ip.Results.sesssionsExpr))
                sessExpr = ip.Results.sesssionsExpr;
            end
            tracers = ensureCell(ip.Results.tracer);
            factoryMethod = ip.Results.factoryMethod;
            
            dtsess = DirTools( ...
                fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
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
                                sessd = SessionData( ...
                                    'studyData', StudyData, ...
                                    'sessionPath', sessp, ...
                                    'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                                    'snumber', iscan, ...
                                    'tracer', tracers{itrac}, ...
                                    'ac', ip.Results.ac, ...
                                    'supEpoch', ip.Results.supEpoch);
                                if (ip.Results.ac && strcmp(sessd.sessionFolder, 'HYGLY25') && sessd.vnumber == 1)
                                    sessd.tauIndices = 1:65;
                                end
                                if (~isempty(ip.Results.tauIndices))
                                    sessd.tauIndices = ip.Results.tauIndices;
                                end
                                if (~isempty(ip.Results.fractionalImageFrameThresh))
                                    sessd.fractionalImageFrameThresh = ip.Results.fractionalImageFrameThresh;
                                end
                                if (~isempty(ip.Results.alignMethod))
                                    sessd.alignMethod = ip.Results.alignMethod;
                                end
                                if (~isempty(ip.Results.compAlignMethod))
                                    sessd.compAlignMethod = ip.Results.compAlignMethod;
                                end
                                
                                if (isdir(sessd.tracerRawdataLocation))
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\t' evalee '\n']);
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    warning('off', 'MATLAB:subsassigndimmismatch');
                                    those(idtsess,idtv,itrac,iscan) = eval(evalee); %#ok<AGROW>
                                    warning('on', 'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end                        
                popd(pwds);
            end
        end
        function [those,dtSessp] = constructCellArrayOfObjectsPar(varargin)
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
            addParameter(ip, 'sesssionsExpr', '');
            addParameter(ip, 'visitsExpr', 'V*');
            addParameter(ip, 'scanList', StudyDirector.SCANS);
            addParameter(ip, 'tracer', StudyDirector.TRACERS, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', StudyDirector.AC);
            addParameter(ip, 'supEpoch', StudyDirector.SUP_EPOCH, @isnumeric); % KLUDGE
            addParameter(ip, 'alignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            addParameter(ip, 'tauIndices', [], @isnumeric);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessExpr = ipr.sessionsExpr;
            if (~isempty(ipr.sesssionsExpr))
                sessExpr = ipr.sesssionsExpr;
            end
            tracers = ensureCell(ipr.tracer);
            factoryMethod = ipr.factoryMethod;
            
            those = [];
            dtSessp = DirTools(fullfile(RaichleRegistry.instance.subjectsDir, sessExpr));
            
            %%%%%%
            parfor isessp = 1:length(dtSessp.fqdns)
                sessp_i = dtSessp.fqdns{isessp};
                pwdsess = pushd(sessp_i);
                dtVisits = DirTools(fullfile(sessp_i, ipr.visitsExpr));     
                for iv = 1:length(dtVisits.fqdns)   
                    visits_i = dtVisits.dns{iv};
                    for itr = 1:length(tracers)
                        tracer_i = tracers{itr};
                        for isc = ipr.scanList
                            if (isc > 1 && strcmpi(tracer_i, 'FDG'))
                                continue
                            end
                            try
                                sessd = SessionData( ...
                                    'studyData', StudyData, ...
                                    'sessionPath', sessp_i, ...
                                    'vnumber', str2double(visits_i(2:end)), ...
                                    'snumber', isc, ...
                                    'tracer', tracer_i, ...
                                    'ac', ipr.ac, ...
                                    'supEpoch', ipr.supEpoch);
                                if (ipr.ac && strcmp(sessd.sessionFolder, 'HYGLY25') && sessd.vnumber == 1)
                                    sessd.tauIndices = 1:65;
                                end
                                if (~isempty(ipr.tauIndices))
                                    sessd.tauIndices = ipr.tauIndices;
                                end
                                if (~isempty(ipr.fractionalImageFrameThresh))
                                    sessd.fractionalImageFrameThresh = ipr.fractionalImageFrameThresh;
                                end
                                if (~isempty(ipr.alignMethod))
                                    sessd.alignMethod = ipr.alignMethod;
                                end
                                if (~isempty(ipr.compAlignMethod))
                                    sessd.compAlignMethod = ipr.compAlignMethod;
                                end
                                
                                if (isdir(sessd.tracerRawdataLocation))
                                    % there exist spurious tracerLocations; select those with corresponding raw data
                                    
                                    evalee = sprintf('%s(''sessionData'', sessd, varargin{2:end})', factoryMethod);
                                    fprintf('mlraichle.StudyDirector.constructCellArrayOfObjects:\n');
                                    fprintf(['\t' evalee '\n']);
                                    fprintf(['\tsessd.TracerLocation->' sessd.tracerLocation '\n']);
                                    eval(evalee);
                                end
                            catch ME
                                dispwarning(ME);
                            end
                        end                        
                    end
                end                        
                popd(pwdsess);
            end
            %%%
            
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
            addParameter(ip, 'alignMethod', '', @ischar); % align_10243
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
                                sessd = mlraichle.SessionData( ...
                                    'studyData', mlraichle.StudyData, ...
                                    'sessionPath', sessp, ...
                                    'vnumber', str2double(dtv.dns{idtv}(2:end)), ...
                                    'snumber', iscan, ...
                                    'tracer', tracers{itrac}, ...
                                    'ac', ip.Results.ac, ...
                                    'supEpoch', ip.Results.supEpoch); 
                                if (ip.Results.ac && strcmp(sessd.sessionFolder, 'HYGLY25') && sessd.vnumber == 1)
                                    sessd.tauIndices = 1:65;
                                end
                                if (~isempty(ip.Results.tauIndices))
                                    sessd.tauIndices = ip.Results.tauIndices;
                                end
                                if (~isempty(ip.Results.fractionalImageFrameThresh))
                                    sessd.fractionalImageFrameThresh = ip.Results.fractionalImageFrameThresh;
                                end
                                if (~isempty(ip.Results.alignMethod))
                                    sessd.alignMethod = ip.Results.alignMethod;
                                end
                                if (~isempty(ip.Results.compAlignMethod))
                                    sessd.compAlignMethod = ip.Results.compAlignMethod;
                                end
                                
                                if (isdir(sessd.tracerRawdataLocation))
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
                                    those(idtsess,idtv,itrac,iscan) = eval(evalee); %#ok<AGROW>
                                    warning('on', 'MATLAB:subsassigndimmismatch');
                                end
                            catch ME
                                handexcept(ME);
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
            t = [];
            node = 0;
            names = {};
            len = length(dtsess);
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
                                s = [s isess];
                                t = [t ];
                                node = node + 1;
                                names{node} = th; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
            
            %gr = graph(s, t, ones(size(s)), names);
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

