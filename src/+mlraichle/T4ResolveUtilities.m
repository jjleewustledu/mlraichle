classdef T4ResolveUtilities < mlfourdfp.T4ResolveUtilities
	%% T4RESOLVEUTILITIES  

	%  $Revision$
 	%  was created 11-Nov-2016 14:03:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
    end

    methods (Static)
        function tf = hasNACFolder(pth)
            visitPth = fileparts(pth);
            [~,visit] = fileparts(visitPth);
            tf = isdir(fullfile(visitPth, ['FDG_' visit '-NAC'], ''));
        end
        function tf = hasOP(pth)
            visitPth = fileparts(pth);
            [~,visit] = fileparts(visitPth);
            tf = lexist(fullfile(visitPth, ...
                                 ['FDG_' visit '-NAC'],...
                                 sprintf('FDG_%s-LM-00-OP.4dfp.ifh', visit)), 'file');
        end  
        function tf = hasOPV(pth, lastFrame)
            lastFrame = lastFrame - 1; % Siemens tags frames starting with 00
            visitPth = fileparts(pth);
            [~,visit] = fileparts(visitPth);
            tf = lexist(fullfile(visitPth, ...
                                 ['FDG_' visit '-Converted'],...
                                 ['FDG_' visit '-LM-00'], ...
                                 sprintf('FDG_%s-LM-00-OP_%03i_000.v', visit, lastFrame)), 'file');
        end
    end
    
	methods 		  
 		function this = T4ResolveUtilities(varargin)
 			%% T4RESOLVEUTILITIES
 			%  Usage:  this = T4ResolveUtilities()

 			this = this@mlfourdfp.T4ResolveUtilities(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

