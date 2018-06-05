classdef StudyCensus < mlio.AbstractXlsxIO & mlpipeline.IStudyCensus
	%% STUDYCENSUS
    %     c.censusTable
    %     ans =
    %        date        subjectID     v_     ready    control    hypergly    hyperins    x_15O_TwiliteSamplingComplete
    %        FDGFastArt_SamplingComplete    Var10    Var11                                     missingImaging_KeyData                                        a_K_A_            comments                          t4ResolvedCompleteWithUmap                        t4ResolvedCompleteWithAC                                   computationNotes                                 seriesForFreesurfer    Var19    Var20    CBFDone    CBVDone    OEFDone    CMRO2Done    CMRglcDone    Var26    Var27         x_HO         x_OC    x_FDG    x_CMRO2    x_OEF       x_OGI     
    %     ___________    __________    ___    _____    _______    ________    ________    _____________________________    ___________________________    _____    _____    ________________________________________________________________________________________    _____________    ________________    ______________________________________________________________    _____________________________    _________________________________________________________________________    ___________________    _____    _____    _______    _______    _______    _________    __________    _____    _____    ______________    ____    _____    _______    _____    ____________
    %     05-Sep-2012    'HYGLY09'     NaN    NaN      0.5        NaN         NaN         ''                               ''                             NaN      NaN      ''                                                                                          'p8079, TJ01'    'pilot study'       'n.a.'                                                            'converted to nii'               ''                                                                             4                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     07-Sep-2012    'LJ02'        NaN    NaN      NaN        NaN           1         ''                               ''                             NaN      NaN      ''                                                                                          'p8080'          'pilot study'       'n.a.'                                                            'converted to nii'               ''                                                                             2                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     13-Sep-2012    'HYGLY09'     NaN    NaN      NaN        NaN           1         ''                               ''                             NaN      NaN      'FDG late arterial samples missing'                                                         'p8085'          'pilot study'       'n.a.'                                                            'converted to nii'               ''                                                                             3                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     18-Sep-2012    'LJ02'        NaN    NaN        1        NaN         NaN         ''                               ''                             NaN      NaN      'OO1, HO1 missing'                                                                          'p8089'          'pilot study'       'n.a.'                                                            'converted to nii'               ''                                                                             4                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     27-Mar-2014    'TW03'          1      1      0.5        NaN         NaN         ''                               ''                             NaN      NaN      'OC2 has no counts'                                                                         'HYGLY11'        '2 control days'    'f,c3,o2,h1,h2,[[o1]],[[c1]]'                                     'f,c3,o2,h1,h2'                  ''                                                                           108                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     15-Apr-2014    'DT04'          1      1        1        NaN         NaN         ''                               ''                             NaN      NaN      'e7 fails on HO2; listmode integrity?'                                                      ''               ''                  'f,c1,c2,o1,o2,h1; frame error h2'                                'f,c1,c2,o1,o2,h1'               ''                                                                           106                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %     30-Apr-2014    'TW03'          2    NaN      NaN        NaN           1         ''                               ''                             NaN      NaN      ''                                                                                          'HYGLY11'        ''                  'f,[c1],[c2],o1,[o2],h1,h2'                                       'f,o1,h1,h2'                     'AC e7 c @nilpc304; t4++ @william'                                           100                    NaN      NaN      ''         ''         ''         ''           ''            NaN      NaN      ''                NaN     NaN      NaN        NaN      ''          
    %   
	%  $Revision$
 	%  was created 29-Mar-2018 14:45:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties         
        fqfilenameDefault = mlraichle.SessionData.STUDY_CENSUS_XLSX;
    end
    
	properties (Dependent)
 		censusTable
        row % requires assigned sessionData
        sessionData
 	end

	methods        
        
        %% GET
        
        function g = get.censusTable(this)
            g = this.censusTable_;
        end  
        function g = get.row(this)
            assert(~isempty(this.sessionData), 'please assign sessionData before requesting a row');
            sdate_ = this.sessionData.sessionDate;
            [~,g] = max(this.censusTable.date == datetime(sdate_.Year, sdate_.Month, sdate_.Day) > 0);
            assert(strcmpi(this.censusTable.subjectID(g), this.sessionData.sessionFolder));
            if (~isempty(this.censusTable.v_(g)))
                assert(this.censusTable.v_(g) == this.sessionData.vnumber);
            end
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function obj  = arterialSamplingCrv(this,varargin)
            fqfn = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), ...
               this.censusTable_.humanCrv(this.row)); 
            obj  = this.fqfilenameObject(fqfn{1}, varargin{:});
        end
        function obj  = calibrationCrv(this, varargin)
            fqfn = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), ...
               this.censusTable_.phantomCrv(this.row)); 
            obj  = this.fqfilenameObject(fqfn{1}, varargin{:});
        end
        function s = seriesForFreesurfer(this)
            s = this.censusTable_.seriesForFreesurfer(this.row);
        end
        function obj  = t1MprageSagSeriesForReconall(this, sessd, varargin)
            assert(isa(sessd, 'mlpipeline.SessionData'));
            fqfn = fullfile(sessd.vLocation, ...
                sprintf('t1_mprage_sag_series%i.4dfp.ifh', this.seriesForFreesurfer));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            warning('off', 'MATLAB:table:ModifiedDimnames');            
            try
                this.censusTable_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Scan-Day Details', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false));
            catch ME
                dispwarning(ME);
            end            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames'); 
            warning('on', 'MATLAB:table:ModifiedDimnames');  
        end
		  
 		function this = StudyCensus(varargin)
            %% STUDYCENSUS
            %  @param fqfilename.
            %  @param named sessionData is an mlpipeline.SessionData.

 			ip = inputParser;
            addOptional( ip, 'fqfilename', this.fqfilenameDefault, @(x) lexist(x, 'file'));
            addParameter(ip, 'sessionData', []);
            parse(ip, varargin{:});              
            
            this.sessionData_ = ip.Results.sessionData;
            this.fqfilename = ip.Results.fqfilename;
 			this = this.readtable;      
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        censusTable_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

