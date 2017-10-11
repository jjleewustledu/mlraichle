classdef UmapDirector < mlpipeline.AbstractDataDirector
	%% UMAPDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 01:52:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    
    methods (Static)
        function this = constructUmaps(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            sessd = ip.Results.sessionData;
            pwd0 = pushd(sessd.vLocation);
            fv = mlfourdfp.FourdfpVisitor;
            fv.lns_4dfp(sessd.T1('typ','fqfp'));            
            fv.lns_4dfp(sessd.t2('typ','fqfp'));  
            if (fv.lexist_4dfp(sessd.tof('typ','fqfp')))
                fv.lns_4dfp(sessd.tof('typ','fqfp'));
            end
            popd(pwd0);
            
            this = mlraichle.UmapDirector( ...
                mlfourdfp.CarneyUmapBuilder(varargin{:}));              
            this = this.instanceConstructUmaps;
        end
    end

	methods 
        function [this,umap] = instanceConstructUmaps(this)
            pwd0 = pushd(this.sessionData.vLocation);
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            [umap,this.builder_] = this.builder_.buildUmap;
            popd(pwd0);
        end
		  
 		function this = UmapDirector(varargin)
 			%% UMAPDIRECTOR
 			%  Usage:  this = UmapDirector()

            this = this@mlpipeline.AbstractDataDirector(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

