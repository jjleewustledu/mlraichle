classdef HoBuilder < mlfourdfp.AbstractTracerBuilder
	%% HOBUILDER  

	%  $Revision$
 	%  was created 09-Mar-2017 20:57:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		Nepochs = 10
        resolveTag = 'op_epoch1'
 	end

	methods 
		  
 		function this = HoBuilder(varargin)
 			%% HOBUILDER
 			%  Usage:  this = HoBuilder()
 			
 			this = this@mlfourdfp.AbstractTracerBuilder(varargin{:});
            this.sessionData.tracer = 'HO';
            %this.finished = mlpipeline.Finished( ...
            %    this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
        
        function this = buildHoAC(this)
            
            import mlsystem.* mlfourdfp.*;
            sessd = this.sessionData;
            trLoc = sessd.tracerLocation; 
            if (isdir(trLoc))
                movefile(trLoc, [trLoc '-Backup-' datestr(now, 30)]);
            end
            ensuredir(trLoc);
            
            trRev = sessd.tracerRevision('typ', 'fp');
            trLM = sprintf('%s_V%i-LM-00-OP', sessd.tracer, sessd.vnumber);
            bv = this.buildVisitor;
            for ie = 1:this.Nepochs
                try
                    sessd.epoch = ie; 
                    pwd0 = pushd(sessd.tracerConvertedLocation);
                    bv.sif_4dfp(trLM);
                    tracerT4 = sprintf('%s_%s_t4', sessd.tracerRevision('typ', 'fp'), this.resolveTag);
                    sessdNac = sessd;
                    sessdNac.attenuationCorrected = false;
                    fqTracerT4 = fullfile(sessdNac.fdgT4Location, tracerT4);
                    bv.cropfrac_4dfp(0.5, trLM, trRev);
                    if (lexist(fqTracerT4, 'file'))
                        bv.lns(fqTracerT4);
                        bv.t4img_4dfp(tracerT4, trRev, 'options', ['-O' trRev]);
                        bv.move_4dfp([trRev '_' this.resolveTag], ...
                            fullfile(trLoc, [sessd.tracerRevision '_' this.resolveTag]));
                    else
                        bv.move_4dfp(trRev, ...
                            fullfile(trLoc, [sessd.tracerRevision '_' this.resolveTag]));
                    end
                    %delete('*.4dfp.*')
                    %delete([trRev '_epoch*_to_' this.resolveTag '_t4']);
                    popd(pwd0);
                catch ME
                    handwarning(ME);
                end
            end
            pwd1 = pushd(fullfile(trLoc, ''));
            ipr.dest = trRev;
            ipr.frames = ones(1, this.Nepochs);
            this.pasteFrames(ipr, this.resolveTag);
            bv.imgblur_4dfp([trRev '_' this.resolveTag], 5.5);
            %delete(fullfile(trLoc, [trRev '_epoch*_' this.resolveTag '.4dfp.*']));
            popd(pwd1);
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

