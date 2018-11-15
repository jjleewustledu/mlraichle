classdef Herscovitch1985 < mlsiemens.Herscovitch1985_FDG
	%% HERSCOVITCH1985  

	%  $Revision$
 	%  was created 31-May-2017 14:20:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = Herscovitch1985(varargin)
 			%% HERSCOVITCH1985
            %  @param named scanData is an mlpipeline.IScanData
            %  @param named roisBuild is an mlrois.IRoisBuilder

%             ip = inputParser;
%             addParameter(ip, 'scanData',  [], @(x) isa(x, 'mlpipeline.IScanData'));
%             addParameter(ip, 'roisBuild', [], @(x) isa(x, 'mlrois.IRoisBuilder'));
%             parse(ip, varargin{:});
            
 			this = this@mlsiemens.Herscovitch1985_FDG(varargin{:});
%                 'scanner',      ip.Results.scanData.scannerData, ...
%                 'aif',          ip.Results.scanData.aifData, ...
%                 'timeWindow', ip.Results.scanData.scannerData.timeWindow, ...
%                 'mask',         ip.Results.roisBuild.product);
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

