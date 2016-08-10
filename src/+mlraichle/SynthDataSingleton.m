classdef SynthDataSingleton < mlpipeline.StudyDataSingleton
	%% SYNTHDATASINGLETON  

	%  $Revision$
 	%  was created 09-Aug-2016 21:23:34
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	

    properties (SetAccess = protected)
        raichleTrunk = fullfile(getenv('RAICHLE'), 'PPGdata', 'jjleeSynth', '')
        tracerPrefixes = { 'FDG' 'HO' 'OO' 'OC' }
    end
    
	properties (Dependent)
        subjectsDir
    end
    
    methods %% GET/SET
        function g = get.subjectsDir(this)
            g = this.subjectsDir_;
        end
        function this = set.subjectsDir(this, sd)
            assert(isdir(sd));
            this.subjectsDir_ = sd;
        end
    end

    methods (Static)
        function this = instance(qualifier)
            persistent instance_            
            if (exist('qualifier','var'))
                assert(ischar(qualifier));
                if (strcmp(qualifier, 'initialize'))
                    instance_ = [];
                end
            end            
            if (isempty(instance_))
                instance_ = mlraichle.SynthDataSingleton();
            end
            this = instance_;
        end
    end
    
    methods
        function loc  = loggingLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'type', 'path', @(x) this.isLocationType(x));
            parse(ip, varargin{:});
            
            switch (ip.Results.type)
                case 'folder'
                    [~,loc] = fileparts(this.raichleTrunk);
                case 'path'
                    loc = this.raichleTrunk;
                otherwise
                    error('mlpipeline:insufficientSwitchCases', ...
                          'SynthDataSingleton.loggingLocation.ip.Results.type->%s not recognized', ip.Results.type);
            end
        end   
        function sess = sessionData(this, varargin)
            %% SESSIONDATA
            %  @param parameter names and values expected by mlraichle.SessionData;
            %  'studyData' and this are implicitly supplied.
            %  @returns mlraichle.SessionData object
            
            sess = mlraichle.SessionData('studyData', this, varargin{:});
        end 
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        subjectsDir_
    end
    
	methods (Access = protected)
		  
 		function this = SynthDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:});
            
            this.subjectsDir_ = this.raichleTrunk;
            dt = mlsystem.DirTools(this.subjectsDir);
            fqdns = {};
            for di = 1:length(dt.dns)
                if (strcmp(dt.dns{di}(1),   'p')  || ...
                    strcmp(dt.dns{di}(1:2), 'NP') || ...
                    strcmp(dt.dns{di}(1:2), 'TW') || ...
                    strcmp(dt.dns{di}(1:5), 'HYGLY'))
                    fqdns = [fqdns dt.fqdns(di)];
                end
            end
            this.sessionDataComposite_ = ...
                mlpatterns.CellComposite( ...
                    cellfun(@(x) mlraichle.SessionData('studyData', this, 'sessionPath', x), ...
                    fqdns, 'UniformOutput', false));            
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

