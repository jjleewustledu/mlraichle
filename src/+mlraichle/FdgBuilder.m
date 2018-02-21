classdef FdgBuilder < mlraichle.TracerKineticsBuilder
	%% FDGBUILDER  

	%  $Revision$
 	%  was created 11-Dec-2016 22:13:25
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	
    methods (Static)
        function staticAssembleFdgAfterAC
            import mlsystem.* mlfourdfp.*;
            studyd = mlraichle.StudyData;            
            eSess = DirTool(fullfile(studyd.subjectsDir, 'HYGLY*'));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    if (~isempty(regexp(eVisit.dns{iVisit}, '^V[1-2]$', 'match')))
                        fdgRawdata = sprintf('FDG_%s', eVisit.dns{iVisit});
                        pthAC = fullfile(eVisit.fqdns{iVisit}, [fdgRawdata '-AC'], '');
                        
                        if (isdir(pthAC))
                            rmdir(pthAC, 's');
                        end
                        
                        ensuredir(pthAC);
                        fprintf('FDGResolveBuilder.assembleFdgAfterAC:  working in -> %s\n', pthAC);                            
                        sessd = mlraichle.SessionData('studyData', studyd, ...
                                                      'sessionPath', eSess.fqdns{iSess}, ...
                                                      'tracer', 'FDG', ...
                                                      'vnumber', T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FDGResolveBuilder('sessionData', sessd);  
                        firstFortranTimeFrame_ = this.firstFortranTimeFrame;                          
                        fdgACRevision = sessd.fdgACRevision('typ', 'fp');
                        fdgPrefix = sprintf('FDG_%s-LM-00-OP', eVisit.dns{iVisit});
                        fv = FourdfpVisitor;
                        eFrame = DirTool(fullfile(eVisit.fqdns{iVisit}, sprintf('%s-Converted-Frame*', fdgRawdata), ''));
                        for iFrame = 1:length(eFrame.fqdns)
                            try
                                pwd0 = pushd(eFrame.fqdns{iFrame});
                                fortranNumFrame = T4ResolveBuilder.frameNumber(eFrame.dns{iFrame}, 1);
                                fdgFramename = this.fileprefixIndexed(fdgACRevision, fortranNumFrame);
                                fv.sif_4dfp(fdgPrefix);
                                fdgT4 = sprintf('%s_frame%i_to_resolved_t4', ...
                                                sessd.fdgNACRevision('typ', 'fp'), fortranNumFrame);
                                fqFdgT4 = fullfile(sessd.fdgT4Location, fdgT4);
                                fv.cropfrac_4dfp(0.5, fdgPrefix, fdgACRevision);
                                if (fortranNumFrame >= firstFortranTimeFrame_ && ...
                                    lexist(fqFdgT4, 'file'))
                                    fv.lns(fqFdgT4);
                                    fv.t4img_4dfp(fdgT4, fdgACRevision, 'options', ['-O' fdgACRevision]);                            
                                    fv.move_4dfp([fdgACRevision '_on_resolved'], ...                                
                                                 fullfile(pthAC, [fdgFramename '_on_resolved']));
                                else                           
                                    fv.move_4dfp(fdgACRevision, ...                                
                                                 fullfile(pthAC, [fdgFramename '_on_resolved']));
                                end
                                delete('*.4dfp.*')
                                delete([fdgACRevision '_frame*_to_resolved_t4']);
                                popd(pwd0);
                            catch ME
                                handwarning(ME);
                            end
                        end
                        pwd0 = pushd(fullfile(pthAC, ''));
                        ipr.dest = fdgACRevision;
                        ipr.indicesLogical = ones(1, length(eFrame.fqdns));
                        this.pasteImageIndices(ipr, 'on_resolved');
                        fv.imgblur_4dfp([fdgACRevision '_on_resolved'], 5.5);
                        delete(fullfile(pthAC, [fdgACRevision '_frame*_on_resolved.4dfp.*']));
                        popd(pwd0);
                    end
                end                
            end
        end
        function extractFramesResolveSequenceAll(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            fv = mlfourdfp.FourdfpVisitor;
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth  = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        v    = lower(eVisit.dns{iVisit});
                        pwd0 = pushd(fullfile(pth, ['ResolveSequence' v], ''));
                        FdgBuilder.printv('extractFramesResolveSequenceAll:  try pwd->%s\n', pwd);
                        for fr = 1:3
                            fv.extract_frame_4dfp(sprintf('resolveSequence%sr2_%s', v, this.resolveTag), fr);
                        end
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
        function resolveRevisionAll(varargin)
            ip = inputParser;
            addParameter(ip, 'rnumber', nan, @(x) isnumeric(x) && ~isnan(x));
            addParameter(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            import mlraichle.* mlsystem.*;
            setenv('PRINTV', '1');
            studyd = SynthStudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-NAC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('resolvePartition:  try pwd->%s\n', pwd);
                        sessd = SynthSessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          false, ...
                            'tracer',      'FDG', ...
                            'rnumber',     ip.Results.rnumber, ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        sessd0 = sessd; 
                        sessd0.rnumber = max(ip.Results.rnumber - 1, 1);
                        this = FdgBuilder('sessionData', sessd);
                        this.pushFilesToCluster( ...
                            T4ResolveUtilities.cell_4dfp( ...
                                sessd0.fdgNACResolved('typ', 'fqfp')));
                        this.resolveOnCluster;
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
        function resolveRevisionOnCluster
            
            import mlraichle.*;
            sessp = fullfile('/scratch/jjlee/raichle/PPGdata/jjleeSynth/HYGLY00');
            sessd = SynthSessionData( ...
                    'studyData',   SynthStudyData, ...
                    'sessionPath', sessp, ...
                    'ac',          false, ...
                    'tracer',      'FDG', ...
                    'rnumber',     2, ...
                    'vnumber',     1);            
            c = myparcluster;
            for fss = 1:3
                c.batch(FdgBuilder.resolveFrameSubset, 1, {sessd, fss});
            end
        end 
        function test(varargin)
            ip = inputParser;
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'useTracerResolvedSumtAC', false, @islogical);
            parse(ip, varargin{:});

            import mlfourdfp.* mlsystem.* mlraichle.*;
            setenv('PRINTV', '1');
            studyd = StudyData;            
            if (isempty(ip.Results.tag))
                tagString = 'HYGLY*';
            else                
                tagString = [ip.Results.tag '*'];
            end
            
            eSess = DirTool(fullfile(studyd.subjectsDir, tagString));
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(fullfile(eSess.fqdns{iSess}, 'V*'));
                for iVisit = 1:length(eVisit.fqdns)

                    try
                        pth = fullfile(eVisit.fqdns{iVisit}, sprintf('FDG_%s-AC', eVisit.dns{iVisit}));
                        pwd0 = pushd(pth);
                        FdgBuilder.printv('testT4ResolveFdgAC:  try pwd->%s\n', pwd);
                        sessd = SessionData( ...
                            'studyData',   studyd, ...
                            'sessionPath', eSess.fqdns{iSess}, ...
                            'ac',          true, ...
                            'tracer',      'FDG', ...
                            'vnumber',     T4ResolveUtilities.visitNumber(eVisit.dns{iVisit}));
                        this = FdgBuilder('sessionData', sessd);
                        mprT = sessd.mpr('typ', 'fp', 'orientation', 'transverse');
                        tracerResSumt = mybasename(this.fileprefixSumt(this.sessionData.tracerResolved));
                        this.buildVisitor.t4img_4dfp( ...
                            fullfile(this.t4Path, [tracerResSumt '_to_' mprT '_t4']), ...
                            tracerResSumt, 'out', 'test', 'options', ['-O' mprT]);
                        this.buildVisitor.t4img_4dfp( ...
                            fullfile(this.t4Path, [mprT '_to_' tracerResSumt '_t4']), ...
                            mprT, 'out', 'test2', 'options', ['-O' tracerResSumt]);
                        mlbash(sprintf('fslview test.4dfp.img -l Cool %s.4dfp.img -t 0.5',    mprT));
                        mlbash(sprintf('fslview %s.4dfp.img   -l Cool test2.4dfp.img -t 0.5', tracerResSumt));
                        delete('test.4dfp.*');
                        delete('test2.4dfp.*');
                        popd(pwd0);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end 
    end
    
	methods 
        
 		function this = FdgBuilder(varargin)
 			%% FDGBUILDER
 			%  Usage:  this = FdgBuilder()

 			this = this@mlraichle.TracerKineticsBuilder(varargin{:});
            this.sessionData_.tracer = 'FDG';
            %this.kinetics_ = mlraichle.FdgKinetics('sessionData', this.sessionData);            
            %this.finished = mlpipeline.Finished( ...
            %    this, 'path', this.logPath, 'tag', lower(this.sessionData.tracer));
        end
        
        function this = buildFdgAC(this)
            
            import mlsystem.* mlfourdfp.*;
            sessd = this.sessionData;
            Fdg = sprintf('FDG_V%i', sessd.vnumber);
            pthFdgAC = fullfile(sessd.vLocation, [Fdg '-AC'], '');     
            if (isdir(pthFdgAC))
                movefile(pthFdgAC, [pthFdgAC '-Backup-' datestr(now, 30)]);
            end
            ensuredir(pthFdgAC);
            
            firstFortranFrame_ = 1;
            fdgACRevision = sessd.fdgACRevision('typ', 'fp');
            fdgLMPrefix = sprintf('FDG_%s-LM-00-OP', sessd.vLocation('typ','folder'));
            bv = this.buildVisitor;
            eFrame = DirTool(fullfile(sessd.vLocation, sprintf('%s-Converted-Frame*', Fdg), ''));
            for iFrame = 1:length(eFrame.fqdns)
                try
                    pwd0 = pushd(eFrame.fqdns{iFrame});
                    fortranFrame = this.frameNumber(eFrame.dns{iFrame}, 1);
                    fdgFramename = this.frameFileprefix(fdgACRevision, fortranFrame);
                    bv.sif_4dfp(fdgLMPrefix);
                    fdgT4 = sprintf('%s_frame%i_to_resolved_t4', ...
                        sessd.fdgNACRevision('typ', 'fp'), fortranFrame);
                    sessdNac = sessd;
                    sessdNac.attenuationCorrected = false;
                    fqFdgT4 = fullfile(sessdNac.fdgT4Location, fdgT4);
                    bv.cropfrac_4dfp(0.5, fdgLMPrefix, fdgACRevision);
                    if (fortranFrame >= firstFortranFrame_ && lexist(fqFdgT4, 'file'))
                        bv.lns(fqFdgT4);
                        bv.t4img_4dfp(fdgT4, fdgACRevision, 'options', ['-O' fdgACRevision]);
                        bv.move_4dfp([fdgACRevision '_on_resolved'], ...
                            fullfile(pthFdgAC, [fdgFramename '_on_resolved']));
                    else
                        bv.move_4dfp(fdgACRevision, ...
                            fullfile(pthFdgAC, [fdgFramename '_on_resolved']));
                    end
                    delete('*.4dfp.*')
                    delete([fdgACRevision '_frame*_to_resolved_t4']);
                    popd(pwd0);
                catch ME
                    handwarning(ME);
                end
            end
            pwd1 = pushd(fullfile(pthFdgAC, ''));
            ipr.dest = fdgACRevision;
            ipr.frames = ones(1, length(eFrame.fqdns));
            this.pasteFrames(ipr, 'on_resolved');
            bv.imgblur_4dfp([fdgACRevision '_on_resolved'], 5.5);
            delete(fullfile(pthFdgAC, [fdgACRevision '_frame*_on_resolved.4dfp.*']));
            popd(pwd1);
        end
        function        printSessionData(this)
            mlraichle.FdgBuilder.printv('FdgBuilder.printSessionData -> \n');
            disp(this.sessionData);
        end   
    end 

    %% PROTECTED
    
    methods (Access = protected)
        function fr   = firstFortranTimeFrame(this)
            NNativeFrames = this.resolveBuilder.imageFrames.readLength(this.sessionData.tracerRevision('typ', 'fqfp'));
            NUmapFrames   = this.resolveBuilder.imageFrames.readLength(this.sessionData.tracerResolved('typ', 'fqfp'));
            fr = NNativeFrames - NUmapFrames + 1;
        end
        function fp   = frameFileprefix(~, fp, fr)
            fp = sprintf('%s_frame%i', fp, fr);
        end
        function f    = frameNumber(~, str, offset)
            names = regexp(str, '\w+(-|_)(F|f)rame(?<f>\d+)', 'names');
            f = str2double(names.f) + offset;
        end
        function this = pasteFrames(this, varargin)
            %  @deprecated; prefer assigning mlfourd.INIfTI.img
            
            ip = inputParser;
            addRequired(ip, 'ipr', @isstruct);
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            ipr = ip.Results.ipr;
            tag = mybasename(ip.Results.tag);
            
            assert(isfield(  ipr, 'dest'));
            assert(ischar(   ipr.dest));
            assert(isfield  (ipr, 'frames'));
            assert(isnumeric(ipr.frames));
            
            pasteList = sprintf('%s_%s_paste.lst', ipr.dest, tag);
            if (lexist(pasteList)); delete(pasteList); end
            
            fid = fopen(pasteList, 'w');
            for f = 1:length(ipr.frames)
                if (ipr.frames(f))
                    fqfp = this.frameFileprefix(ipr.dest, f);
                    fprintf(fid, '%s_%s.4dfp.img\n', fqfp, tag);
                end
            end
            fclose(fid);
            this.buildVisitor.paste_4dfp(pasteList, [ipr.dest '_' tag], 'options', '-a ');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

