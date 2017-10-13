classdef TracerDirector < mlpet.TracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 27-Sep-2017 02:38:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	methods (Static)
        
        %% factory methods        
        
        function out   = cleanTracerRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this.instanceCleanTracerRemotely('distcompHost', ip.Results.distcompHost);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        function out   = cleanSinograms
            %% cleanSinograms
            %  @param works in mlraichle.RaichleRegistry.instance.subjectsDir
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
                      
            pwd0 = pushd(mlraichle.RaichleRegistry.instance.subjectsDir);
            assert(isdir(pwd0));
            
            fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd);
            import mlsystem.*;            
            dtsess = DirTools({'HYGLY*' 'NP995*' 'TW0*' 'DT*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 

                    dtconv = DirTool('*-Converted*');
                    for idtconv = 1:length(dtconv.fqdns)
                        pwdc = pushd(dtconv.fqdns{idtconv});
                        fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 
                        mlbash(sprintf('rm -r *_%s-00', dtv{idtv}));
                        mlbash(sprintf('rm -r *_%s-WB', dtv{idtv}));
                        mlbash(sprintf('rm -r *_%s-WB-LM', dtv{idtv}));                        
                        
                        dt00 = DirTool('*-00');
                        for idt00 = 1:length(dt00.fqdns)
                            pwd00 = pushd(dt00.fqdns{idt00});
                            fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd);   
                            deleteExisting('*-00-sino*');  
                            popd(pwd00);
                        end
                        popd(pwdc);

                    end
                    popd(pwdv);
                end
                popd(pwds);
            end
            popd(pwd0);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        function out   = cleanMore
            %% cleanMore
            %  @param works in mlraichle.RaichleRegistry.instance.subjectsDir
            %  @return deletes from the filesystem:  *-sino.s[.hdr]
                      
            pwd0 = pushd(mlraichle.RaichleRegistry.instance.subjectsDir);
            assert(isdir(pwd0));
            
            fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd);
            import mlsystem.*;            
            dtsess = DirTools({'HYGLY*' 'NP995*' 'TW0*' 'DT*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd); 

                    dtconv = DirTools('*-AC', '*-NAC');
                    for idtconv = 1:length(dtconv.fqdns)
                        pwdc = pushd(dtconv.fqdns{idtconv});
                        fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd); 
                        deleteExisting('umap*_frame*.4dfp.*');
                        deleteExisting('umap*.log');
                        
                        dtE = DirTool('E*');
                        for idtE = 1:length(dtE.fqdns)
                            fprintf('mlraichle.TracerDirector.cleanMore:  is cleaning %s\n', pwd);
                            deleteExisting();
                            
                        end                        
                        popd(pwdc);
                    end
                    popd(pwdv);
                end
                popd(pwds);
            end
            popd(pwd0);
            out = []; % for use with mlraichle.StudyDirector.constructCellArrayOfObjects
        end
        function out   = cleanSinograms2(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});                    
                    
            import mlsystem.*;
            pwd0 = pushd(ip.Results.sessionData.vLocation);
            dtconv = DirTool('*-Converted*');
            for idtconv = 1:length(dtconv.fqdns)
                pwdc = pushd(dtconv.fqdns{idtconv});
                fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd); 

                dt00 = DirTool('*-00');
                for idt00 = 1:length(dt00.fqdns)
                    pwd00 = pushd(dt00.fqdns{idt00});
                    fprintf('mlraichle.TracerDirector.cleanSinograms:  is cleaning %s\n', pwd);   
                    deleteExisting('*-00-sino*');  
                    popd(pwd00);
                end
                popd(pwdc);
            end
            popd(pwd0);                  
            out = sprintf('mlraichle.TracerDirector.cleanSinogram cleaned->%s\n', ip.Results.sessionData.sessionPath);
        end
        function out   = cleanSinogramsRemotely2(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            addParameter(ip, 'nArgout', 1,   @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            addParameter(ip, 'pushData', false, @islogical);
            addParameter(ip, 'pullData', false, @islogical);
            parse(ip, varargin{:});
            
            out = mlraichle.TracerDirector.constructRemotely2( ...
                 @mlraichle.TracerDirector.cleanSinograms, ...
                 'sessionData',  ip.Results.sessionData, ...
                 'nArgout',      ip.Results.nArgout, ...
                 'distcompHost', ip.Results.distcompHost, ...
                 'pushData',     ip.Results.pushData, ...
                 'pullData',     ip.Results.pullData);
        end
        
        function this  = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return umap files generated per motionUncorrectedUmap ready for use by TriggeringTracers.js.
            %  @return this.sessionData.attenuationCorrection == false.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));              
            this = this.instanceConstructResolved;
        end 
        function this  = constructResolvedRemotely(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instanceConstructResolvedRemotely( ...
                @mlraichle.SessionData, @mlraichle.TracerDirector.constructResolved);
        end 
        function rpts  = constructResolveReports(varargin)
            %  @param  varargin for mlfourdfp.T4ResolveReporter.
            %  @return saved *.fig, *.png, *.mat.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerReportsBuilder(varargin{:}));          
            rpts = this.instanceMakeReports;
        end
        function this  = constructKinetics(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlraichle.TracerKineticsBuilder(varargin{:}));              
            this = this.instanceConstructKinetics;
            
        end
        
        function lst   = listUmaps(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            lst = this.instanceListUmaps;
        end
        function lst   = listTracersConverted(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});

            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            lst = this.instanceListTracersConverted;
        end
        function lst   = listTracersResolved(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});

            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));
            lst = this.instanceListTracersResolved;      
        end
        function this  = pullFromRemote(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'))
            parse(ip, varargin{:});
            
            this = mlraichle.TracerDirector( ...
                mlpet.TracerResolveBuilder(varargin{:}));          
            this = this.instancePullFromRemote;
        end 
    end
    
    methods
        
        %%
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector()

 			this = this@mlpet.TracerDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

