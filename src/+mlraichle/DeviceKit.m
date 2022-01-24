classdef DeviceKit < handle & mlpet.DeviceKit
	%% INSTRUMENTKIT is a concrete factory for projects packaged by mlraichle.  It is part of the 
    %  abstract factory pattern of mlpet.DeviceKit and manages instances of mlpet.CCIRRadMeasurements and
    %  mlpet.ReferenceSource.

	%  $Revision$
 	%  was created 18-Oct-2018 13:49:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/raichle/src/+raichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)		
        PREFERRED_TIMEZONE = mlraichle.StudyRegistry.PREFERRED_TIMEZONE
 	end

	methods (Static)
        function rm = CreateRadMeasurements(varargin)
            %% CREATERADMEASUREMENTS
 			%  @param session is mlraichle.Session.
            %  @return mlraichle.RadMeasurements.
            
            ip = inputParser;
            addParameter(ip, 'session', [], @(x) isa(x, 'mlraichle.Session'));
            parse(ip, varargin{:});
            rm = mlpet.CCIRRadMeasurements.CreateBySession(ip.Results.session);
        end
        function rs = CreateReferenceSources(varargin)
            %% CREATEREFERENCESOURCES
 			%  @param session is mlraichle.Session.
            %  @return mlpet.ReferenceSource.
            
            ip = inputParser;
            addParameter(ip, 'session', [], @(x) isa(x, 'mlraichle.Session'));
            parse(ip, varargin{:});
            
            import mlpet.ReferenceSource;
            import mlraichle.DeviceKit;
            rs(1) = ReferenceSource( ...
                'isotope', '137Cs', ...
                'activity', 500, ...
                'activityUnits', 'nCi', ...
                'sourceId', '1231-8-87', ...
                'refDate', datetime(2007,4,1, 'TimeZone', DeviceKit.PREFERRED_TIMEZONE));
            if (datetime(ip.Results.session) > datetime(2016,4,7, 'TimeZone', 'America/Chicago'))
                rs(2) = ReferenceSource( ...
                    'isotope', '22Na', ...
                    'activity', 101.4, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1382-54-1', ...
                    'refDate', datetime(2009,8,1, 'TimeZone', DeviceKit.PREFERRED_TIMEZONE));
            end
            if (datetime(ip.Results.session) > datetime(2018,10,4, 'TimeZone', 'America/Chicago'))
                rs(3) = ReferenceSource( ...
                    'isotope', '68Ge', ...
                    'activity', 101.3, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1932-53', ...
                    'refDate', datetime(2017,11,1, 'TimeZone', DeviceKit.PREFERRED_TIMEZONE), ...
                    'productCode', 'MGF-068-R3');
            end
            for irs = 1:length(rs)
                assert(datetime(ip.Results.session) > rs(irs).refDate);
            end
        end
        function obj = PrepareCapracDevice(varargin)
 			%% PREPARECAPRACDEVICE instantiates the DeviceKit with the device then calibrates the device.
 			%  @param session is mlraichle.Scan.
            
            import mlraichle.*;
            this = DeviceKit(varargin{:});
            obj  = CapracDevice( ...
                'radMeasurements',  this.CreateRadMeasurements( 'session', this.session_), ...
                'referenceSources', this.CreateReferenceSources('session', this.session_));
            try
                obj = obj.calibrateDevice;
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'DeviceKit.PrepareCapracDevice could not calibrate the device');
            end
        end
        function obj = PrepareTwiliteDevice(varargin)
            import mlraichle.*;
            this = DeviceKit(varargin{:});
            obj  = TwiliteDevice('radMeasurements', this.CreateRadMeasurements('session', this.session_));
            try
                obj = obj.calibrateDevice(this.twiliteCalMeasurements);
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'DeviceKit.PrepareTwiliteDevice could not calibrate the device');
            end
        end
        function obj = PrepareBiographMMRDevice(varargin)
            import mlraichle.*;
            this = DeviceKit(varargin{:});
            obj  = BiographMMRDevice('radRadMeasurements', this.CreateRadMeasurements('session', this.session_));
            try
                obj = obj.calibrateDevice(this.biographMMRCalMeasurements);
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'DeviceKit.PrepareBiographMMRDevice could not calibrate the device');
            end
        end
    end
    
    methods
        
        %% GET
        
        
        %% 
        
        function m  = twiliteCalMeasurements(this)
        end
        function m  = biographMMRCalMeasurements(this)
        end
        function dt = datetime(this)
            dt = datetime(this.session_);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        radMeasurements_
        session_
    end
    
    methods (Access = private)
 		function this = DeviceKit(varargin)
 			%% INSTRUMENTKIT
 			%  @param session is mlraichle.Session.
            
            ip = inputParser;
            addParameter(ip, 'session', [], @(x) isa(x, 'mlraichle.Session'));
            parse(ip, varargin{:});
            this.session_ = ip.Results.session;
            this.radMeasurements_ = mlpet.CCIRRadMeasurements.CreateBySession(this.session_);
 		end	   
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

