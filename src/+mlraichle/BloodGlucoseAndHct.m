classdef BloodGlucoseAndHct 
	%% BLOODGLUCOSEANDHCT  

	%  $Revision$
 	%  was created 08-Apr-2017 23:39:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	
	methods 		  
 		function this = BloodGlucoseAndHct(varargin)
 			%% BLOODGLUCOSEANDHCT
 			%  Usage:  this = BloodGlucoseAndHct(xlsx_filename)

            ip = inputParser;
            addRequired(ip, 'xlsx', @(x) lexist(x,'file'));
            parse(ip, varargin{:});
 			
            warning('off', 'MATLAB:table:ModifiedVarnames');
            this.table_ = readtable(ip.Results.xlsx);
            warning('on', 'MATLAB:table:ModifiedVarnames');
        end
        
        function bg = plasmaGlucose(this, subj, v)
            ip = inputParser;
            addRequired(ip, 'subj', @ischar);
            addRequired(ip, 'v', @isnumeric);
            parse(ip, subj, v);
            
            bg = this.table_(strcmp(this.table_.subject, ip.Results.subj) & ...
                                   (this.table_.visit == ip.Results.v), 'BG').BG;
        end
        function hct = Hct(this, subj, v)
            ip = inputParser;
            addRequired(ip, 'subj', @ischar);
            addRequired(ip, 'v', @isnumeric);
            parse(ip, subj, v);
            
            hct = this.table_(strcmp(this.table_.subject, ip.Results.subj) & ...
                                   (this.table_.visit == ip.Results.v), 'Hct___').Hct___;
            assert(hct > 1  && hct < 100);
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        table_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

