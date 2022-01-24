classdef HyperglycemiaBidsDirector < mlpipeline.AbstractBidsDirector
	%% HyperglycemiaBidsDirector orchestrates hyperglycemia studies with Raichle, Hershey and Arbelaez ca. 2016-2019.
    %  BIDS specifications will be attempted whenever reasonable, but efficient interactions with XNAT services
    %  and details of study design take priority.

	%  $Revision$
 	%  was created 08-Apr-2019 23:23:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		
    end
    
    methods (Static)
        function those = migrateResolvedToVallCellArray(varargin)
            %% MIGRATERESOLVEDTOVALLCELLARRAY
            %  @param projectsExp is char, specifying project directories to DirTool.
            %  @param sessionsExp is char, specifying session directories to DirTool.
            %  @param tracer      is char, passed to mlraichle.SessionData.
            %  @return those      is cell-array of objects returned by TracerDirectorBids.
            
            import mlraichle.*;
            factory = @TracerDirectorBids.migrateResolvedToVall;
            those = HyperglycemiaBidsDirector.directCellArray(factory, varargin{:}); 
        end
        function those = directCellArray(varargin)
            %% DIRECTCELLARRAY iterates over project, session and scan directories, calling a factoryMethod for each.
            %  @param factoryMethod is a function_handle.
            %  @param projectsExp   is char, specifying project directories to DirTool.
            %  @param sessionsExp   is char, specifying session directories to DirTool.
            %  @param tracer        is char, passed to mlraichle.SessionData.
            %  @param ac            is logical, passed to mlraichle.SessionData.
            %  @return those        is cell-array of objects returned by factoryMethod.
            
            import mlraichle.* mlsystem.* ;
            import mlraichle.HyperglycemiaBidsDirector.acTag;
            import mlraichle.HyperglycemiaBidsDirector.adjustParameters;
            import mlraichle.HyperglycemiaBidsDirector.constructSessionData;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'factoryMethod', @ischar);
            addParameter(ip, 'projectsExpr', 'CCIR_*');
            addParameter(ip, 'sessionsExpr', 'ses-*');
            addParameter(ip, 'tracer', {'OC' 'OO' 'HO'}, @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', true);
            addParameter(ip, 'fractionalImageFrameThresh', [], @isnumeric);
            addParameter(ip, 'frameAlignMethod', '', @ischar); % align_10243
            addParameter(ip, 'compAlignMethod', '', @ischar); % align_multiSpectral
            parse(ip, varargin{:});
            ipr = adjustParameters(ip.Results);
            tracers = ensureCell(ipr.tracer);         
            
            dtprj = DirTools(fullfile(mlraichle.StudyRegistry.instance.projectsDir, ipr.projectsExpr));
            for iprj = 1:length(dtprj.fqdns)

                dtses = DirTools(fullfile(dtprj.fqdns{iprj}, ipr.sessionsExpr));
                for ises = 1:length(dtses.fqdns)
                    
                    sesd = dtses.fqdns{ises};
                    pwd0 = pushd(sesd);
                    for itra = 1:length(tracers)

                        dtscn = DirTools(fullfile(dtses.fqdns{ises}, ...
                            sprintf('%s_DT*.000000-Converted-%s', upper(tracers{itra}), acTag(ipr.ac))));
                        for iscn = 1:length(dtscn.fqdns)
                            
                            try
                                sesd = constructSessionData(ipr, dtprj.fqdns{iprj}, dtses.dns{ises}, tracers{itra}); %#ok<NASGU>
                                evalee = sprintf('%s(''sessionData'', sesd, varargin{2:end})', char(ipr.factoryMethod));
                                fprintf('mlraichle.HyperglycemiaBidsDirector.directCellArray:\n');
                                fprintf(['\t' evalee '\n']);
                                warning('off', 'MATLAB:subsassigndimmismatch');
                                those{iprj,ises,itra,iscn} = eval(evalee);  %#ok<AGROW>
                                warning('on', 'MATLAB:subsassigndimmismatch');
                            catch ME
                                dispwarning(ME)
                                getReport(ME)
                            end
                        end
                    end                     
                    popd(pwd0);
                end                
            end
        end
        function sesd = constructSessionData(ipr, prjd, sesd, tra)
            import mlraichle.*;
            sesd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', fullfile(prjd, sesd, ''), ...
                'tracer', tra, ...
                'ac', ipr.ac);
            if (~isempty(ipr.fractionalImageFrameThresh))
                sesd.fractionalImageFrameThresh = ipr.fractionalImageFrameThresh;
            end
            if (~isempty(ipr.frameAlignMethod))
                sesd.frameAlignMethod = ipr.frameAlignMethod;
            end
            if (~isempty(ipr.compAlignMethod))
                sesd.compAlignMethod = ipr.compAlignMethod;
            end
        end
    end

	methods		  
 		function this = HyperglycemiaBidsDirector(varargin)
 			%% HYPERGLYCEMIABIDSDIRECTOR
            %  @param required builder is mlpipeline.IBuilder.
 			%  @param sessionData is mlpipeline.ISessionData.
            %  @param xnat is mlxnat.Xnat
 			
            this = this@mlpipeline.AbstractBidsDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

