classdef TestDataSingleton < mlraichle.StudyDataSingleton
	%% TESTDATASINGLETON  

	%  $Revision$
 	%  was created 30-Jan-2016 18:11:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    methods (Static)
        function this = instance(varargin)
            persistent instance_
            if (~isempty(varargin))
                instance_ = [];
            end
            if (isempty(instance_))
                instance_ = mlraichle.TestDataSingleton(varargin{:});
            end
            this = instance_;
        end
        function d    = subjectsDir
            d = fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, 'Test', '');
        end
    end
    
    methods        
        function register(this, varargin)
            %% REGISTER this class' persistent instance with mlpipeline.StudyDataSingletons
            %  using the latter class' register methods.
            %  @param key is any registration key stored by mlpipeline.StudyDataSingletons; default 'synth_raichle'.
            
            ip = inputParser;
            addOptional(ip, 'key', 'test_raichle', @ischar);
            parse(ip, varargin{:});
            mlpipeline.StudyDataSingletons.register(ip.Results.key, this);
        end
    end
    
    %% PROTECTED
    
	methods (Access = protected)
 		function this = TestDataSingleton(varargin)
 			this = this@mlraichle.StudyDataSingleton(varargin{:}); 
 		end
        function this = assignSessionDataCompositeFromPaths(this, varargin)
            if (isempty(this.sessionDataComposite_))
                for v = 1:length(varargin)
                    if (ischar(varargin{v}) && isdir(varargin{v}))                    
                        this.sessionDataComposite_ = ...
                            this.sessionDataComposite_.add( ...
                                mlraichle.SessionTestData('studyData', this, 'sessionPath', varargin{v}));
                    end
                end
            end
        end
 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

