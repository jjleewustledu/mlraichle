classdef T4ResolveReport 
	%% T4RESOLVEREPORT  

	%  $Revision$
 	%  was created 28-Feb-2016 15:06:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties 		
 	end

	methods 
        
        function b = bar3(this, choice)
            switch (choice)
                case 'etas'
                    Z  = nan(size(this.t4resolve_.etas));
                    e  = this.t4resolve_.etas;
                    Ee = dipmean(cell2mat(e));
                    Se = dipstd( cell2mat(e));
                    for m = 1:size(Z,1)
                        for n = 1:size(Z,2)
                            if (~isempty(e{m,n}))
                                Z(m,n) = (e{m,n} - Ee)/Se;
                            end
                        end
                    end
                case 'curves'
                    choice = sprintf('norm_2(%s)', choice);
                    Z  = nan(size(this.t4resolve_.curves));
                    c  = this.t4resolve_.curves;
                    Ec = dipmean(cell2mat(c));
                    Sc = dipstd( cell2mat(c));
                    for m = 1:size(Z,1)
                        for n = 1:size(Z,2)
                            if (~isempty(c{m,n}))
                                Z(m,n) = (norm(c{m,n}) - Ec)/Sc;
                            end
                        end
                    end
                otherwise
                    error('mlraichle:unsupportedSwitchCase', 'T4ResolveReport.bar3.choice->%s is not supported', choice);
            end
            
            figure;
            b = bar3(Z);
            title(sprintf('%s: z(%s)', this.t4resolve_.sessionData.sessionFolder, choice), ...
                  'Interpreter', 'none');
            this.colorbar(b);
        end
        function colorbar(~, b)
            colorbar;
            for k = 1:length(b)
                zdata = b(k).ZData;
                b(k).CData = zdata;
                b(k).FaceColor = 'interp';
            end
        end
		  
 		function this = T4ResolveReport(t4r)
 			%% T4RESOLVEREPORT
 			%  @param t4r is an instance of mlraichle.T4Resolve

            assert(isa(t4r, 'mlraichle.T4Resolve'));
            this.t4resolve_ = t4r;
 		end
    end 

    %% PROTECTED
    
    properties (Access = protected)
        t4resolve_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

