classdef NiftyPET_vs_e7 
	%% NIFTYPET_VS_E7  

	%  $Revision$
 	%  was created 06-Aug-2019 21:55:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.6.0.1135713 (R2019a) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
        blur = 4.3
 		listOfScans
        supEpoch
        tracer
        unique_wmparc_indices
        unique_sub_indices
        unique_gm_indices
        unique_wm_indices
    end
    
    methods (Static)
        function [mdl,nifty_data,e7_data] = correlate_recons1(varargin)
            %% @param tracer := 'oc', 'oo', etc.
            %  @return scatter plot of point cloud of activities_{nifty} vs. activities_{e7}.
            %  @return mdl from fitlm.
            %  @return nifty_data.scn_id := Map: wmparc_index -> activity.
            %  @return e7_data:  ".
            
            import mlraichle.NiftyPET_vs_e7.*
            ip = inputParser;
            addParameter(ip, 'tracer', 'oc', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            load('NiftyPET_vs_e7.mat')            
            [x,y] = gscatter(e7_data, nifty_data);
            mdl = get_stats(x, y);
        end
        function [mdl,nifty_data,e7_data] = correlate_recons(varargin)
            %% @param tracer := 'oc', 'oo', etc.
            %  @return scatter plot of point cloud of activities_{nifty} vs. activities_{e7}.
            %  @return mdl from fitlm.
            %  @return nifty_data.scn_id := Map: wmparc_index -> activity.
            %  @return e7_data:  ".
            
            import mlraichle.NiftyPET_vs_e7.*
            ip = inputParser;
            addParameter(ip, 'tracer', 'oc', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            pwd0 = pushd(getenv('PROJECTS_DIR'));
            this = mlraichle.NiftyPET_vs_e7( ...
                fullfile(getenv('SUBJECTS_DIR'), 'list_of_CO_scans.csv'), 'tracer', ipr.tracer);
            for m = 1:size(this.listOfScans, 1)
                try
                    tic
                    item = this.listOfScans(m, :);
                    nifty_map = containers.Map('KeyType', 'double', 'ValueType', 'double');  
                    e7_map = containers.Map('KeyType', 'double', 'ValueType', 'double');   
                    nifty_ifc = this.tracerAveraged(item, 'nifty');  
                    nifty_ifc.save;
                    e7_ifc = this.tracerAveraged(item, 'e7');
                    e7_ifc.save;
                    wmp_ifc = mlfourd.ImagingFormatContext([this.wmparc_on_tracer_fqfp(item) '.4dfp.hdr']);
                    %wmp_ifc.fsleyes([nifty_ifc.fqfileprefix '.4dfp.img'], [e7_ifc.fqfileprefix '.4dfp.img'])
                    for wmp = asrow(this.unique_wmparc_indices)
                        wmpLogic = wmp_ifc.img == wmp;
                        nifty_map(wmp) = this.sample_wmparc(nifty_ifc, wmpLogic);
                        e7_map(wmp) = this.sample_wmparc(e7_ifc, wmpLogic);
                    end
                    nifty_data.(this.traid(item)) = nifty_map;
                    e7_data.(this.traid(item)) = e7_map;
                    %figure
                    %scatter(cell2mat(e7_map.values), cell2mat(nifty_map.values));
                    toc
                catch ME
                    handwarning(ME)
                    disp(item)
                end
            end 
            popd(pwd0);
            save('NiftyPET_vs_e7.mat')   
            
            [x,y] = gscatter(e7_data, nifty_data);
            mdl = get_stats(x, y);
        end
        
        function [x,y,g] = gscatter(d1, d2)
            traids = fields(d1);
            x = [];
            y = [];
            g = [];
            for t = asrow(traids)
                x = [x cell2mat(asrow(d1.(t{1}).values))];
                y = [y cell2mat(asrow(d2.(t{1}).values))];
                g = [g keys2groups(cell2mat(asrow(d1.(t{1}).keys)))];
            end
            figure
            gscatter(x', y', g')
            
            function g = keys2groups(k)
                g = cell(size(k));
                g(:) = {'unclassified'};
                g(k < 1000) = {'subcortical'};
                g(1000 <= k & k <  3000) = {'gray'};
                g(3000 <= k & k <= 5000) = {'white'};
            end
        end
        function mdl = get_stats(x, y)
            tbl = table(x', y', 'VariableNames', {'e7', 'nifty'});
            mdl = fitlm(tbl, 'RobustOpts', 'on');
            disp(mdl)
            figure
            plotResiduals(mdl)
            figure
            plotDiagnostics(mdl)
        end
    end

	methods         
        function ic   = imagingContext(this, varargin)
            %% @param required item is table.
            %  @param required reconType := 'nifty', 'e7'
            %  @param frame is char | double
            %  @param suffix is char, e.g., '_avgt'
            
            ip = inputParser;
            addRequired(ip, 'item', @istable)
            addRequired(ip, 'reconType', @ischar)
            addParameter(ip, 'frame', '*', @(x) ischar(x) || isnumeric(x))
            addParameter(ip, 'suffix', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if isnumeric(ipr.frame)
                ipr.frame = num2str(ipr.frame);
            end
            it = ipr.item;
            tra = lower(this.tracer);
            TRA = upper(this.tracer);
            
            switch ipr.reconType
                case 'nifty'
                    pth = fullfile(getenv('PROJECTS_DIR'), ...
                        it.prjid{1}, this.sesid_to_sesfold(it.sesid), sprintf('%s_DT%i.000000-Converted-AC', TRA, it.dt), '');
                    fqfps = glob(fullfile(pth, sprintf('%sr2_op_%sr1_frame%s%s', tra, tra, ipr.frame, ipr.suffix)));
                    fqfp = fqfps{1};
                case 'e7'
                    fqfp = fullfile(getenv('PPG'), 'restore', 'jjlee2', it.name{1}, [it.e7fileprefix{1} ipr.suffix]);
                otherwise
                    error('mlraichle:RuntimeError', 'NiftyPET_vs_e7:imagingContext')
            end
            ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
        end
        function tra  = tracerAveraged(this, item, reconType)
            tra = this.imagingContext(item, reconType);
            switch reconType
                case 'nifty'
                    switch this.tracer
                        case 'fdg'
                            interval = 59:62;
                        case 'ho'
                            interval = 1:18;
                        case 'oo'
                            interval = 1:11;
                        case {'oc' 'co'}
                            interval = 25:30;
                    end
                case 'e7'
                    switch this.tracer
                        case 'fdg'
                            interval = 53:73; % last 20 m
                        case 'ho'
                            interval = 1:20; % 60 s
                        case 'oo'
                            interval = 1:20;
                        case {'oc' 'co'}
                            interval = 48:58; % 100 - 200 s
                    end
                otherwise
                    error('mlraichle:RuntimeError', 'NiftyPET_vs_e7.sample_wmparc')
            end 
            tra = tra.timeAveraged(interval);
            tra = tra.blurred(this.blur);
            tra = tra.fourdfp;
        end
        function s    = sample_wmparc(~, tra, wmpLogic)
            s = tra.img(wmpLogic);
            s = sum(sum(s)) / numel(s);
        end
        function fold = sesid_to_sesfold(~, sid)
            s = split(sid, '_');
            fold = ['ses-' s{2}];
        end
        function fn   = T1001_to_op_tra_t4(this)
            fn = sprintf('T1001r1_to_op_%se1to%ir1_frame%i_t4', lower(this.tracer), this.supEpoch, this.supEpoch);
        end
        function fold = trafold(this, dt)
            fold = sprintf('%s_DT%i.000000-Converted-AC', upper(this.tracer), dt);
        end
        function id   = traid(this, item)
            id = sprintf('%sdt%i', this.tracer, item.dt);
        end
        function pth  = trapath(this, item)
            assert(istable(item))
            pth = fullfile( ...
                getenv('PROJECTS_DIR'), ...
                item.prjid{1}, ...
                this.sesid_to_sesfold(item.sesid), ...
                this.trafold(item.dt), '');
        end
        function fqfp = wmparc_on_tracer_fqfp(this, item)
            assert(istable(item));
            fp = sprintf('wmparc_op_%se1to%ir1_frame%i', lower(this.tracer), this.supEpoch, this.supEpoch);
            fqfp = fullfile(this.trapath(item), fp);
            if ~isfile([fqfp '.4dfp.hdr'])
                pwd0 = pushd(this.trapath(item));
                assert(isfile('../wmparc.nii'))
                mlbash('nifti_4dfp -4 -N ../wmparc.nii wmparc.4dfp.hdr');
                mlbash(sprintf('t4img_4dfp -n %s wmparc %s -O%sr1_avgt', this.T1001_to_op_tra_t4, fp, this.tracer));
                popd(pwd0)
            end
        end
        		  
 		function this = NiftyPET_vs_e7(varargin)
 			%% NIFTYPET_VS_E7
 			%  @param required listOfScans := filename
            %  @param tracer := 'oc', 'oo', 'ho', 'fdg'
            %  @param supEpoch := double

 			ip = inputParser;
            addRequired(ip, 'listOfScans', @isfile)
            addParameter(ip, 'tracer', 'oc', @ischar)
            addParameter(ip, 'supEpoch', 3, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.supEpoch = ipr.supEpoch;
            this.tracer = ipr.tracer;
            this.listOfScans = readtable(ipr.listOfScans);            
            
            % load unique_wmparc_indices
            item = this.listOfScans(1,:);
            pwd0 = pushd(this.trapath(item));
            assert(isfile([this.wmparc_on_tracer_fqfp(item) '.4dfp.hdr']))
            wmparc = mlfourd.ImagingFormatContext([this.wmparc_on_tracer_fqfp(item) '.4dfp.hdr']);
            this.unique_wmparc_indices = unique(wmparc.img);
            this.unique_wmparc_indices = this.unique_wmparc_indices(this.unique_wmparc_indices > 0);
            this.unique_sub_indices = this.unique_wmparc_indices(this.unique_wmparc_indices < 1000); 
            this.unique_gm_indices = this.unique_wmparc_indices(this.unique_wmparc_indices >= 1000 & this.unique_wmparc_indices < 3000); 
            this.unique_wm_indices = this.unique_wmparc_indices(this.unique_wmparc_indices >= 3000 & this.unique_wmparc_indices <= 5000);
            popd(pwd0)
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

