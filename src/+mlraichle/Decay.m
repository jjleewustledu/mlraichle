classdef Decay < mlpet.Decay
	%% DECAY  

	%  $Revision$
 	%  was created 18-Oct-2018 12:39:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function this = CreateFromScanId(varargin)
            %% CREATEFROMSCANID
            %  @param scid is mlpet.IScanIdentifier.
            
            ip = inputParser;
            addRequired(ip, 'scid', @(x) isa(x, 'mlpet.IScanIdentifier'));
            parse(ip, varargin{:});
            
            error('mlpet:NotImplementedError');
        end
    end
    
	methods 
		  
 		function this = Decay(varargin)
 			%% DECAY
 			%  @param .

 			this = this@mlpet.Decay(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

