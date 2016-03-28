classdef TestDataSingleton < mlraichle.StudyDataSingleton
	%% TESTDATASINGLETON  

	%  $Revision$
 	%  was created 30-Jan-2016 18:11:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

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
                instance_ = mlraichle.TestDataSingleton();
            end
            this = instance_;
        end
        function        register(varargin)
            %% REGISTER
            %  @param []:  if this class' persistent instance
            %  has not been registered, it will be registered via instance() call to the ctor; if it
            %  has already been registered, it will not be re-registered.
            %  @param ['initialize']:  any registrations made by the ctor will be repeated.
            
            mlraichle.TestDataSingleton.instance(varargin{:});
        end
    end  

    %% PROTECTED
    
	methods (Access = protected)
 		function this = TestDataSingleton(varargin)
 			this = this@mlraichle.StudyDataSingleton(varargin{:});
            
            [~,hn] = mlbash('hostname');
            switch (strtrim(hn))
                case 'innominate.local'
                    this.raichleTrunk = '/Volumes/InnominateHD3/Local/test/raichle/PPGdata';
                case 'touch3'
                    this.raichleTrunk = '/data/nil-bluearc/raichle/PPGdata';
                otherwise
                    error('mlraichle:unsupportedSwitchCase', 'TestDataSingleton.ctor.hn->%s is not supported', hn);
            end
            
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
            this.registerThis;
 		end
        function registerThis(this)
            mlpipeline.StudyDataSingletons.register('test_raichle', this);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

