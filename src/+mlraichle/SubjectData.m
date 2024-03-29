classdef SubjectData < mlnipet.SubjectData2022
	%% SUBJECTDATA

	%  $Revision$
 	%  was created 05-May-2019 22:06:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        TRACERS = {'FDG' 'OC' 'OO' 'HO'}
        EXTS = {'.4dfp.hdr' '.4dfp.ifh' '.4dfp.img' '.4dfp.img.rec'};
    end
    
    methods (Static)
        function obj = createProjectData(varargin)
            obj = mlraichle.ProjectData(varargin{:});
        end
        function subf = sesFolder2subFolder(sesf)
            %% requires well-defined cell-array mlraichle.StudyRegistry.instance().subjectsJson.
            %  @param sesf is a session folder.
            %  @returns corresponding subject folder.
            
            import mlraichle.SubjectData
            json = mlraichle.StudyRegistry.instance().subjectsJson;
            subjectsLabel = fields(json);
            ssesf = split(sesf, '-');
            for sL = asrow(subjectsLabel)
                subjectStruct = json.(sL{1});
                if isfield(subjectStruct, 'experiments')
                    for eL = asrow(subjectStruct.experiments)
                        if lstrfind(eL, ssesf{2})
                            ssub = split(subjectStruct.sid, '_');
                            subf = ['sub-' ssub{2}];
                            return
                        end
                    end
                end
                if isfield(subjectStruct, 'aliases')
                    json1 = subjectStruct.aliases;
                    subjectsLabel1 = fields(json1);
                    for sL1 = asrow(subjectsLabel1)                        
                        subjectStruct1 = json1.(sL1{1});
                        if isfield(subjectStruct1, 'experiments')
                            for eL = asrow(subjectStruct1.experiments)
                                if lstrfind(eL, ssesf{2})
                                    ssub = split(subjectStruct1.sid, '_');
                                    subf = ['sub-' ssub{2}];
                                    return
                                end
                            end
                        end
                    end
                end
            end 
            error('mlraichle:ValueError', ...
                'SubjectData.sesFolder2subFolder(%s) found no subject folder', sesf)
        end
        function sesf = subFolder2sesFolder(subf)
            sesf = mlraichle.SubjectData.subFolder2sesFolders(subf);
            if iscell(sesf)
                sesf = sesf{1};
            end
        end
        function sesf = subFolder2sesFolders(subf)
            %% requires well-defined cell-array mlraichle.StudyRegistry.instance().subjectsJson.
            %  @param subf is a subject folder.
            %  @returns first-found non-trivial session folder in the subject folder.
            
            this = mlraichle.SubjectData('subjectFolder', subf);
            subjects = fields(this.subjectsJson_);
            ss = split(subf, '-');
            sesf = {};
            for sL = asrow(subjects)
                subjectStruct = this.subjectsJson_.(sL{1});
                if lstrfind(subjectStruct.id, ss{2}) || lstrfind(subjectStruct.sid, ss{2})
                    sesf = [sesf this.findExperiments(subjectStruct, subf)]; %#ok<AGROW>
                    %disp(sesf)
                end
            end 
        end
    end

	methods
        function tf   = hasScanFolders(this, ~, sesf)
            %% legacy folders CCIR_*/derivatives/nipet/ses-E*/HO_DT*.000000-Converted-*/
            %  @param subf
            %  @param sesf
            
            reg = this.studyRegistry_;
            if ~isfolder(fullfile(reg.sessionsDir, sesf, ''))
                tf = false;
                return
            end
            globbed = globFoldersT( ...
                fullfile(reg.sessionsDir, sesf, '*_DT*.000000-Converted-AC', ''));
            tf = ~isempty(globbed);
        end

 		function this = SubjectData(varargin)
 			%% SUBJECTDATA
 			%  @param .

 			this = this@mlnipet.SubjectData2022(varargin{:});
            
            this.studyRegistry_ = mlraichle.StudyRegistry.instance;
            this.subjectsJson_ = this.studyRegistry_.subjectsJson;
 		end
    end     

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

