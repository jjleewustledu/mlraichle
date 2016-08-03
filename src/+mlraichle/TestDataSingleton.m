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
                case {'innominate' 'innominate.local'}
                    this.raichleTrunk = fullfile(getenv('UNITTESTS'), 'raichle/PPGdata', '');
                    this.subjectsDir  = fullfile(this.raichleTrunk, 'jjlee');
                case {'touch3' 'william' 'maulinux1'}
                    this.raichleTrunk = fullfile(getenv('PPG'), '');
                    this.subjectsDir  = fullfile(this.raichleTrunk, 'jjlee');
                case 'vertebral'
                    this.raichleTrunk = fullfile(getenv('UNITTESTS'), 'raichle/PPGdata', '');
                    this.subjectsDir  = fullfile(this.raichleTrunk, 'jjlee');
                otherwise
                    error('mlraichle:unsupportedSwitchCase', 'TestDataSingleton.ctor.hn->%s is not supported', hn);
            end
 		end
        function registerThis(this)
            mlpipeline.StudyDataSingletons.register('test_raichle', this);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

