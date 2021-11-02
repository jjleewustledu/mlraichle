classdef Herscovitch1985Director 
	%% HERSCOVITCH1985DIRECTOR  

	%  $Revision$
 	%  was created 29-May-2018 22:30:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		
 	end

	methods 
        
        %% GET/SET
        
%         function g    = get.(this)
%         end
%         function this = set.(this, s)
%         end

        %% 
        
        function ics = constructAll(this)
            this = this.constructAgi;
            ics = {this.agi_ this.cbf_ this.cbv_ this.cmrglc_ this.cmro2_ this.oef_ this.ogi_};
            for i = 1:length(ics)
                ics{i} = this.constructOnHyglyAtlas(ic);
            end
        end
        
        %% physiological diffs/ratios
        
        function this = constructAgi(this)
            if (isempty(this.agi_))
                this = this.constructCmrglc;
                this = this.constructCmro2;
                this.agi_ = mlfourd.ImagingContext( ...
                    this.cmrglc_.numericalNiftid - this.cmro2_.numericalNiftid/6);
            end
            this.product_ = this.agi_;
        end
        function this = constructOgi(this)
            if (isempty(this.ogi_))
                this = this.constructCmro2;
                this = this.constructCmrglc;
                this.ogi_ = mlfourd.ImagingContext( ...
                    this.cmro2_.numericalNiftid ./ this.cmrglc_.numericalNiftid);
            end
            this.product_ = this.ogi_;
        end
        
        %% traditional physiologicals
        
        function this = constructCmrglc(this)
            if (isempty(this.cmrglc_))
                this = this.constructFdg;
                this = this.constructCbv;
                b = mlpet.Blomqvist1984( ...
                    'tracerContext', mlpet.FdgContext('sessionContext', this.sessionContext_));
                b = b.buildCmrglc( ...
                    'fdg', this.fdg_, 'cbv', this.cbv_, 'labs', this.labs_);
                this.cmrglc_ = b.product;
            end
            this.product_ = this.cmrglc_;
        end
        function this = constructCmro2(this)
            if (isempty(this.cmro2_))
                this = this.constructCbv;
                this = this.constructOef;
                this = this.constructCbf;
                b = mlpet.Mintun1984( ...
                    'tracerContext', mlpet.OoContext('sessionContext', this.sessionContext_));
                b = b.buildCmro2( ...
                    'cbv', this.cbv_, 'oef', this.oef_, 'cbf', this.cbf_, 'labs', this.labs_);
                this.cmro2_ = b.product;
            end
            this.product_ = this.cmro2_;
        end
        function this = constructOef(this)
            if (isempty(this.oef_))
                this = this.constructCbv;
                this = this.constructOo;
                this = this.constructHo;
                b = mlpet.Mintun1984( ...
                    'tracerContext', mlpet.OoContext('sessionContext', this.sessionContext_));
                b = b.buildOef( ...
                    'cbv', this.cbv_, 'oo', this.oo_, 'ho', this.ho_);
                this.oef_ = b.product;
            end
            this.product_ = this.oef_;
        end
        function this = constructCbv(this)
            if (isempty(this.cbv_))
                this = this.constructOc;
                b = mlpet.Martin1987( ...
                    'tracerContext', mlpet.OcContext('sessionContext', this.sessionContext_));
                b = b.buildCbv('oc', this.oc_);
                this.cbv_ = b.product;
            end
            this.product_ = this.cbv_;
        end
        function this = constructCbf(this)
            if (isempty(this.cbf_))
                this = this.constructHo;
                b = mlpet.Raichle1983( ...
                    'tracerContext', mlpet.HoContext('sessionContext', this.sessionContext_));
                b = b.buildCbf('ho', this.ho_);
                this.cbf_ = b.product;
            end
            this.product_ = this.cbf_;
        end
        
        %% tracers aligned to fdg
        
        function this = constructFdg(this)
            if (isempty(this.fdg_))
                c = mlpet.FdgContext('sessionContext', this.sessionContext_);
                this.fdg_ = c.fdg;
            end
            this.product_ = this.fdg_;
        end
        function this = constructOc(this)
            if (isempty(this.oc_))
                c = mlpet.OcContext('sessionContext', this.sessionContext_);
                this.oc_ = c.oc;
            end
            this.product_ = this.oc_;
        end
        function this = constructHo(this)
            if (isempty(this.ho_))
                c = mlpet.HoContext('sessionContext', this.sessionContext_);
                this.ho_ = c.ho;
            end
            this.product_ = this.ho_;
        end
        function this = constructOo(this)
            if (isempty(this.oo_))
                c = mlpet.OoContext('sessionContext', this.sessionContext_);
                this.oo_ = c.oo;
            end
            this.product_ = this.oo_;
        end
        
        %% utilities
        
        function ic = constructOnHyglyAtlas(this, ic)
            fv = mlfourdfp.FourdfpVisitor;
            t4 = '';
            in = '';
            out = '';
            ref = '';
            fv.t4img_4dfp(t4, in, 'out', out, 'options', ['-O' ref]);
            ic = mlfourd.ImagingContext(out);
        end
        function s = summary(this)
        end
        function [s,r] = aview(this, varargin)
            %  @param app is the app name; default := 'freeview'.  Consider 'fslview_deprecated', 'fsleyes'.
            
            v = mlfourdfp.Viewer(varargin{:});
            [s,r] = v.aview(this.product_);
        end
        
        %% ctor
        
 		function this = Herscovitch1985Director(varargin)
 			%% HERSCOVITCH1985DIRECTOR
 			%  @param named sessionContext.

            ip = inputParser;
            addParameter(ip, 'sessionContext', [], @(x) isa(x, 'mlpipeline.ISessionContext'));
            parse(ip, varargin{:});
            
            this.sessionContext_ = ip.Results.sessionContext;
            this.labs_ = [];            
 		end
    end 
    
    methods 
    end
        
    %% PRIVATE
    
    properties (Access = private)
        agi_
        cbf_
        cbv_
        cmrglc_
        cmro2_
        fdg_
        ho_
        labs_
        oef_
        ogi_
        oc_
        oo_
        product_
        sessionContext_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

