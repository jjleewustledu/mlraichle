classdef AerobicGlycolysisKit < handle & mlpet.AerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 10:54:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
    
	properties
        regionTag = '_wmparc1'
    end
    
	methods (Static)
        function constructKsByVoxels(varargin)
            %% CONSTRUCTKSBYVOXELS 
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param useParfor is logical with default := ~ifdeployed().
            %  @param assemble is logical with default := false.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addRequired(ip, 'cpuIndex', @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'roisExpr', 'brain', @ischar)
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'voxelTime', 180, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'wallClockLimit', 168*3600, @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'useParfor', ~isdeployed(), @islogical)
            addParameter(ip, 'assemble', false, @islogical)
            addParameter(ip, 'doStaging', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if ischar(ipr.cpuIndex)
                ipr.cpuIndex = str2double(ipr.cpuIndex);
            end
            if ischar(ipr.voxelTime)
                ipr.voxelTims = str2double(ipr.voxelTime);
            end
            if ischar(ipr.wallClockLimit)
                ipr.wallClockLimit = str2double(ipr.wallClockLimit);
            end            
    
            % update registry with passed parameters
            registry = mlraichle.StudyRegistry.instance();
            registry.voxelTime = ipr.voxelTime;
            registry.wallClockLimit = ipr.wallClockLimit;   
            registry.useParfor = ipr.useParfor || ipr.assemble;
            
            % estimate num nodes or build Ks  
            ss = strsplit(ipr.foldersExpr, '/');          
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true); 
                kit = AerobicGlycolysisKit.createFromSession(sesd);
                sstr = split(sesd.tracerOnAtlas('typ', 'fqfn'), ['Singularity' filesep]);
                kit.estimateNumNodes(sstr{2}, ipr.roisExpr)
                
                if ipr.doStaging
                    sesd.jitOn222(sesd.tracerOnAtlas());
                    continue
                end
                if ipr.assemble
                    kit.ensureCompleteSubjectsStudy(varargin{:})
                    kit.assembleSubjectsStudy(varargin{:})
                else
                    kit.buildKs( ...
                        'filesExpr', sstr{2}, ...
                        'cpuIndex', ipr.cpuIndex, ...
                        'roisExpr', ipr.roisExpr, ...
                        'averageVoxels', false)
                end
            end
            popd(pwd0)
        end        
        function [kss,msk] = constructKsByWmparc(varargin)
            %% CONSTRUCTKSBYWMPARC
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param required cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return kss as mlfourd.ImagingContext2 or cell array.
            %  @return msk, the mask of kss, as mlfourd.ImagingContext2 or cell array.
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'useParfor', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            % update registry with passed parameters
            registry = mlraichle.StudyRegistry.instance();
            registry.useParfor = ipr.useParfor;
            
            % build Ks and their masks
            ss = strsplit(ipr.foldersExpr, '/');           
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            msk = {};
            kss = {};
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true); 
                this = AerobicGlycolysisKit.createFromSession(sesd);
                fdgstr = split(sesd.tracerOnAtlas('typ', 'fqfn'), ['Singularity' filesep]);
                sesd.jitOn222(sesd.wmparcOnAtlas(), '-n -O222');
                this.constructWmparc1OnAtlas(sesd)
                
                kss_ = this.buildKsByWmparc1('filesExpr', fdgstr{2}); 
                kss_.save()
                kss = [kss kss_]; %#ok<AGROW>
                
                msk_ = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                msk_ = msk_.binarized();
                msk_.fileprefix = [sesd.maskOnAtlas('typ', 'fp') '_b43_wmparc1'];
                msk_.save()
                msk = [msk msk_]; %#ok<AGROW>
            end
            popd(pwd0)
        end
        function [pred,resid,nmae,chi,cmrglc] = constructKsDx(varargin)
            %% CONSTRUCTKSDX
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param regionTag is char, e.g., '_brain' | '_wmparc1'
            %  @param lastKsTag is char and used by this.ksOnAtlas, e.g., '', '_b43'
            %  @return pred as mlfourd.ImagingContext.
            %  @return resid as mlfourd.ImagingContext.
            %  @return mae as mlfourd.ImagingContext.
            %  @return chi in (s^{-1}) as mlfourd.ImagingContext.
            %  @return cmrglc in mumoles/hg/min as mlfourd.ImagingContext.
            
            import mlfourd.ImagingContext2
            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            cbv222 = ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            ks222 = this.ksOnAtlasTagged('');
            mask222 = this.maskOnAtlasTagged('');

            % prep Huang model
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);
            huang = mlglucose.ImagingHuang1980.createFromDeviceKit( ...
                devkit, 'cbv', cbv222, 'roi', mask222, 'regionTag', this.regionTag);
            huang.ks = ks222;

            % do Dx
            pred = huang.buildPrediction(); pred.save(); 
            resid = huang.buildResidual(); resid.save(); 
            [mae,nmae] = huang.buildMeanAbsError(); mae.save(); nmae.save();
            chi = this.ks2chi(ks222, cbv222); chi.save(); 
            cmrglc = this.ks2cmrglc(ks222, cbv222, devkit.radMeasurements); cmrglc.save();
            popd(pwd0)
        end
        function ic = constructRegularizedSolution(varargin)
            %% CONSTRUCTSOLUTIONCHOICE
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return mlfourd.ImagingContext2 contains lowest mean abs error solutions drawn from
            %          ksdt*_222_b43_brain and ksdt*_222_b43_wmparc.
            
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2            
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            
            % expand choice to [128 128 75 4]
            choice = this.constructSolutionChoice(varargin{:});
            choice = choice.fourdfp;
            img = choice.img;
            for ik = 1:4
                choice.img(:,:,:,ik) = img;
            end
            
            % construct regularized ks & save
            ksbrain = ImagingFormatContext([this.sessionData.ksOnAtlas('typ', 'fqfp') '_b43_brain.4dfp.hdr']);
            kswmparc1 = ImagingFormatContext([this.sessionData.ksOnAtlas('typ', 'fqfp') '_b43_wmparc1.4dfp.hdr']);            
            ks = copy(ksbrain);
            ks.fileprefix = strrep(ks.fileprefix, 'brain', 'regular');
            ks.img(logical(choice.img)) = kswmparc1.img(logical(choice.img));
            ks.save() % 4dfp
            sz = size(ks);
            img = reshape(ks.img, [sz(1) sz(2) sz(3) 4]);
            save([ks.fileprefix '.mat'], 'img') % Patrick's mat
            
            % construct chi & save
            cbv = ImagingFormatContext(this.sessionData.cbvOnAtlas('dateonly', true));
            chi = this.ks2chi(ks, cbv);
            chi.save()
            chi = chi.blurred(4.3);
            chi.save()
            
            % return ImagingContext2
            ic = ImagingContext2(ks);
        end
        function ic = constructSolutionChoice(varargin)
            %% CONSTRUCTSOLUTIONCHOICE
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @return mlfourd.ImagingContext2 chooses the solution that has lower mean abs error:
            %          0 -> brain has lower error;
            %          1 -> wmparc1 has lower error.
            
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            this = mlraichle.AerobicGlycolysisKit.createFromSubjectSession(varargin{:});
            pwd0 = pushd(this.sessionData.tracerOnAtlas('typ', 'filepath'));
            
            brainMAE = ImagingFormatContext([this.sessionData.fdgOnAtlas('typ', 'fqfp') '_b43_brain_meanAbsError.4dfp.hdr']);
            wmparc1MAE = ImagingFormatContext([this.sessionData.fdgOnAtlas('typ', 'fqfp') '_b43_wmparc1_meanAbsError.4dfp.hdr']);
            wmparc1MAE.img(wmparc1MAE.img == 0) = inf;
            choice = copy(brainMAE);
            choice.fileprefix = strrep(choice.fileprefix, 'brain_meanAbsError', 'choice');
            choice.img = single(wmparc1MAE.img < brainMAE.img);
            ic = ImagingContext2(choice);
            ic.save()
            
            popd(pwd0)
        end
        function constructSubjectByWmparc(varargin)   
            %% CONSTRUCTSUBJECTBYWMPARC constructs in parallel the sessions of a subject.
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            
            import mlraichle.*
            import mlraichle.AerobicGlycolysisKit.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ss = strsplit(ipr.foldersExpr, '/');           
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, '')); 
            subd = mlraichle.SubjectData('subjectFolder', ss{2});             
            sesfs = subd.subFolder2sesFolders(ss{2});
            foldersExpr = ipr.foldersExpr;
            
%           TESTING

            for p = 3 % length(sesfs)
                try
                    sesd = SessionData( ...
                        'studyData', StudyData(), ...
                        'projectData', ProjectData('sessionStr', sesfs{p}), ...
                        'subjectData', subd, ...
                        'sessionFolder', sesfs{p}, ...
                        'tracer', 'FDG', ...
                        'ac', true); 
                    fdg = sesd.fdgOnAtlas('typ', 'mlfourd.ImagingContext2');
                    AerobicGlycolysisKit.ic2mat(fdg)
                    
                    [ks, msk] = AerobicGlycolysisKit.constructKsByWmparc(foldersExpr, [], 'sessionsExpr', sesfs{p}); % memory ~ 5.5 GB
                    ks = ks.blurred(4.3);
                    ks.save()
                    AerobicGlycolysisKit.ic2mat(ks)
                    AerobicGlycolysisKit.ic2mat(msk)
                    
                    [~,~,~,chi,cmrglc] = AerobicGlycolysisKit.constructKsDx(foldersExpr, [], 'sessionsExpr', sesfs{p});
                    chi = chi.blurred(4.3);
                    chi.save()
                    AerobicGlycolysisKit.ic2mat(chi)
                    cmrglc = cmrglc.blurred(4.3);
                    cmrglc.save()
                    AerobicGlycolysisKit.ic2mat(cmrglc)
                catch ME
                    handwarning(ME)
                end
            end            
            popd(pwd0)            
        end
        function this = createFromSession(varargin)
            this = mlraichle.AerobicGlycolysisKit('sessionData', varargin{:});
        end
        function these = createFromSubjectSession(varargin)
            %% CREATEFROMSUBJECTSESSION
            %  @param required foldersExpr is char, e.g., 'subjects/sub-S12345'.
            %  @param optional cpuIndex is char or is numeric. 
            %  @param sessionsExpr is char, e.g., 'ses-E67890'.
            %  @param regionTag is char, e.g., '_brain' | '_wmparc'
            %  @return these is {mlraichle.AerobicGlycolysisKit, ...}
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'foldersExpr', @ischar)
            addOptional(ip, 'cpuIndex', [], @(x) isnumeric(x) || ischar(x))
            addParameter(ip, 'sessionsExpr', 'ses-E', @ischar)
            addParameter(ip, 'regionTag', '_wmparc1', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ss = strsplit(ipr.foldersExpr, '/');         
            pwd0 = pushd(fullfile(getenv('PROJECTS_DIR'), ss{1}, ss{2}, ''));            
            subd = SubjectData('subjectFolder', ss{2}); 
            sesfs = subd.subFolder2sesFolders(ss{2});
            these = {};
            for s = sesfs(contains(sesfs, ipr.sessionsExpr))
                sesd = SessionData( ...
                    'studyData', StudyData(), ...
                    'projectData', ProjectData('sessionStr', s{1}), ...
                    'subjectData', subd, ...
                    'sessionFolder', s{1}, ...
                    'tracer', 'FDG', ...
                    'ac', true); 
                this = AerobicGlycolysisKit.createFromSession(sesd);
                this.regionTag = ipr.regionTag;
                these = [these this]; %#ok<AGROW>
            end
            popd(pwd0)
        end      
        function msk = ks2mask(ic)
            %% @param required ic is mlfourd.ImagingContext2 | cell
            
            if iscell(ic)
                msk = {};
                for anic = ic
                    msk = [msk mlraichle.AerobicGlycolysisKit.ks2mask(anic)]; %#ok<AGROW>
                end
                return
            end
            
            assert(isa(ic, 'mlfourd.ImagingContext2'))            
            assert(length(size(ic)) == 4)
            cache = copy(ic.fourdfp);
            cache.fileprefix = strrep(ic.fileprefix, 'ks', 'mask');
            cache.img = single(cache.img(:,:,:,1) > 0);
            msk = mlfourd.ImagingContext2(cache);
        end
        function matfn = ic2mat(ic)
            %% @param required ic is mlfourd.ImagingContext2 | cell
            
            if isempty(ic) % for unit testing
                matfn = '';
                return
            end
            
            if iscell(ic)
                matfn = {};
                for anic = ic
                    matfn = [matfn mlraichle.AerobicGlycolysisKit.ic2mat(anic)]; %#ok<AGROW>
                end
                return
            end
            
            assert(isa(ic, 'mlfourd.ImagingContext2'))
            sz = size(ic);
            assert(length(sz) >= 3)
            if length(sz) == 3
                sz = [sz 1];
            end
            img = reshape(ic.fourdfp.img, [sz(1)*sz(2)*sz(3) sz(4)]);
            matfn = [ic.fqfileprefix '.mat'];
            save(matfn, 'img')
        end
    end

	methods
        function assembleSubjectsStudy(this, varargin)
            %% ASSEMBLESUBJECTSSTUDY 
            
            % create union of inferences   
            
            sesd = this.sessionData;
            fqfp1 = [sesd.ksOnAtlas('typ', 'fqfp') this.blurTag '_brain_part1'];
            ifc1 = mlfourd.ImagingFormatContext([fqfp1 '.4dfp.hdr']);
            assert(~isempty(ifc1))
            ifc1.img = zeros(size(ifc1.img));
            ifc1.fileprefix = sprintf('%s%s_brain', sesd.ksOnAtlas('typ', 'fp'), this.blurTag);
            N = this.sessionData.registry.numberNodes;
            for n = 1:N
                fqfp = [sesd.ksOnAtlas('typ', 'fqfp') sprintf('%s_brain_part%i', this.blurTag, n)];
                try
                    ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                    assert(dipisfinite(ic))
                    assert(dipsum(ic) > 0)
                    patch = ic.fourdfp.img ~= 0;
                    if dipsum(ifc1.img(patch)) == 0
                        ifc1.img(patch) = ic.fourdfp.img(patch);
                    end
                catch ME
                    handwarning(ME)
                end                
            end
            ifc1.save()
            
            % write mat-files of inferences for use in training deep models
            
            sz1 = size(ifc1.img);
            img = reshape(ifc1.img, [sz1(1)*sz1(2)*sz1(3) sz1(4)]);
            save([ifc1.fqfileprefix '.mat'], 'img', '-v7.3');
            
            fdg = mlfourd.ImagingFormatContext(sesd.fdgOnAtlas('typ', 'fqfn'));
            sz1 = size(fdg.img);
            img = reshape(fdg.img, [sz1(1)*sz1(2)*sz1(3) sz1(4)]);
            save([fdg.fqfileprefix '.mat'], 'img', '-v7.3');   
            
            cbv = mlfourd.ImagingFormatContext(sesd.cbvOnAtlas('typ', 'fqfn', 'dateonly', true));
            sz1 = size(cbv.img);
            img = reshape(cbv.img, [sz1(1)*sz1(2)*sz1(3) 1]);
            save([cbv.fqfileprefix '.mat'], 'img', '-v7.3');
            
            % create mask of reasonable model inferences
            
            img = ifc1.img;
            img = img ~= 0;
            img = img(:,:,:,1) | img(:,:,:,2) | img(:,:,:,3) | img(:,:,:,4);
            sz1 = size(img);
            img = reshape(img, [sz1(1)*sz1(2)*sz1(3) 1]);
            save(fullfile(ifc1.filepath, [strrep(ifc1.fileprefix, 'ks', 'mask') '.mat']), 'img', '-v7.3');
        end
        function ensureCompleteSubjectsStudy(this, varargin)
            %% ENSURECOMPLETESUBJECTSSTUDY
            
            import mlraichle.*
            sesd = this.sessionData;
            N = this.sessionData.registry.numberNodes;
            for n = 1:N
                fqfp = [sesd.ksOnAtlas('typ', 'fqfp') sprintf('%s_brain_part%i', this.blurTag, n)];
                try
                    ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                    assert(dipisfinite(ic))
                    assert(dipsum(ic) > 0)
                catch ME
                    handwarning(ME)
                    
                    % param assemble := false
                    vararg2pass = varargin;
                    for vi = 1:length(vararg2pass)
                        if ischar(vararg2pass{vi}) && strcmp(vararg2pass{vi}, 'assemble')
                            if vi < length(vararg2pass)
                                vararg2pass{vi+1} = false;
                            end
                        end
                    end
                    AerobicGlycolysisKit.constructKsByVoxels(vararg2pass{:})
                end
            end
        end        
        function ic = ksOnAtlasTagged(this, varargin)
            %% @param lasttag := {'' '_b43'}
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'lastKsTag', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fqfp = [this.sessionData.ksOnAtlas('typ', 'fqfp') this.blurTag this.regionTag ipr.lastKsTag];
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                ks = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(ks.img), [128 128 75 4]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.ksOnAtlas')
        end
        function ic = maskOnAtlasTagged(this, varargin)
            %% @param lasttag := {'' '_b43'}
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'lastKsTag', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fqfp = [this.sessionData.maskOnAtlas('typ', 'fqfp') this.blurTag this.regionTag ipr.lastKsTag];
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                msk = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(msk.img), [128 128 75]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.maskOnAtlasTagged')
        end
    end
		
    %% PROTECTED
    
    methods (Access = protected)
 		function this = AerobicGlycolysisKit(varargin)
 			this = this@mlpet.AerobicGlycolysisKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
