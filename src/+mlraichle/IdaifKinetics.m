classdef IdaifKinetics 
	%% IDAIFKINETICS  

	%  $Revision$
 	%  was created 10-Feb-2016 16:44:51
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		
    end

    methods (Static)
        function prodMap = quickLookWB()
            prodMap = containers.Map('UniformValues', false);
            visits = {'V1' 'V2'};
            studyDat = mlpipeline.StudyDataSingletons.instance('raichle');
            iter = studyDat.createIteratorForSessionData;
            while (iter.hasNext)
                sessData = iter.next;
                if (lstrfind(sessData.sessionFolder, 'NP'))
                    for v = 1:2
                        cd(fullfile(sessData.sessionPath, visits{v}, 'fdg', 'pet_proc', ''));
                        dt = mlsystem.DirTool('NP*.mat');
                        for dtidx = 1:length(dt.fqfns)
                            
                            fprintf('working with %s\n', dt.fqfns{dtidx});
                            load(dt.fqfns{dtidx});
                            assert(logical(exist('AIF1', 'var')));
                            assert(logical(exist('WB',   'var')));
                            assert(logical(exist('t',    'var')));
                            figure;
                            plot(WB);
                            title(dt.fqfns{dtidx});
                        end   
                    end
                end
            end
        end
        function prodMap = quickLookNP995()
            prodMap = containers.Map('UniformValues', false);
            visits = {'V1' 'V2'};
            studyDat = mlpipeline.StudyDataSingletons.instance('raichle');
            iter = studyDat.createIteratorForSessionData;
            while (iter.hasNext)
                sessData = iter.next;
                if (lstrfind(sessData.sessionFolder, 'NP'))
                    for v = 1:2
                        cd(fullfile(sessData.sessionPath, visits{v}, 'fdg', 'pet_proc', ''));
                        dt = mlsystem.DirTool('NP*.mat');
                        for dtidx = 1:length(dt.fqfns)
                            
                            fprintf('working with %s\n', dt.fqfns{dtidx});
                            load(dt.fqfns{dtidx});
                            assert(logical(exist('AIF1', 'var')));
                            assert(logical(exist('WB',   'var')));
                            assert(logical(exist('t',    'var')));
                            [kminutes,k1k3overk2k3,fdgk] = mlkinetics.F18DeoxyGlucoseKinetics.runYi(AIF1, t, WB, dt.fns{dtidx});
                            
                            matfile = strtok(dt.fns{dtidx}, '.');
                            session.(visits{v}).(matfile).kminutes     = kminutes;
                            session.(visits{v}).(matfile).k1k3overk2k3 = k1k3overk2k3;
                            session.(visits{v}).(matfile).fdgk         = fdgk;                            
                        end   
                    end
                    prodMap(sessData.sessionFolder) = session;
                    
                    return
                    
                end
            end
        end
    end
    
	methods 
		  
 		function this = IdaifKinetics(varargin)
 			%% IDAIFKINETICS
 			%  Usage:  this = IdaifKinetics()

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

