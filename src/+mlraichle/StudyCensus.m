classdef StudyCensus < mlio.AbstractXlsxIO
	%% STUDYCENSUS  

	%  $Revision$
 	%  was created 29-Mar-2018 14:45:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		censusTable
        row
        seriesForFreesurfer
        sessionData
 	end

	methods        
        
        %% GET
        
        function g = get.censusTable(this)
            g = this.censusTable_;
        end  
        function g = get.row(this)
            sdate_ = this.sessionData.sessionDate;
            [~,g] = max(this.censusTable.date == datetime(sdate_.Year, sdate_.Month, sdate_.Day) > 0);
            assert(strcmpi(this.censusTable.subjectID(g), this.sessionData.sessionFolder));
            if (~isempty(this.censusTable.v_(g)))
                assert(str2double(this.censusTable.v_(g)) == this.sessionData.vnumber);
            end
        end
        function g = get.seriesForFreesurfer(this)
            g = this.censusTable_.seriesForFreesurfer(this.row);
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
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
            addRequired( ip, 'fqfilename', @(x) lexist(x, 'file'));
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
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

