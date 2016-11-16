classdef T4ResolveDirector 
	%% T4RESOLVEDIRECTOR  

	%  $Revision$
 	%  was created 11-Nov-2016 13:50:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
    end
    
    methods (Static)
        function parBuildUmaps            
            import mlsystem.*;
            cd(fullfile(getenv('PPG'), 'jjlee', ''));
            dt = DirTool('*');
            dtFqdns = dt.fqdns;
            parfor idt = 1:length(dtFqdns)
                for v = 1:2
                    
                    %% testing
                    %studyd = mlraichle.StudyData;
                    %sessd = mlraichle.SessionData('studyData', studyd,'sessionPath', pwd);
                    %a = mlfourdfp.UmapResolveBuilder('sessionData', sessd); % ctor test
                    %b = mlfourdfp.O15UmapResolveBuilder('sessionData', sessd); % "

                    cd(dtFqdns{idt});
                    mlfourdfp.UmapResolveBuilder.serialBuildUmaps(pwd, 'iVisit', v);
                    cd(dtFqdns{idt});
                    mlfourdfp.O15UmapResolveBuilder.serialBuildO15Umaps(pwd, 'iVisit', v);
                end
            end
        end
    end

	methods 
		  
 		function this = T4ResolveDirector(it4rb)
 			%% T4RESOLVEDIRECTOR
 			%  Usage:  this = T4ResolveDirector(IT4ResolveBuilder_object)

            assert(isa(it4rb, 'mlfourdfp.IT4ResolveBuilder'));
            this.iT4ResolveBuilder_ = it4rb;
 		end
    end 

    properties (Access = private)
        iT4ResolveBuilder_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

