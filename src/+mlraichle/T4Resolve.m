classdef T4Resolve 
	%% T4RESOLVE  

	%  $Revision$
 	%  was created 28-Feb-2016 12:20:59
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties (Dependent)
        curves
        etas
        frameLength
        imgregLog
        sessionData
    end
    
    methods %% GET
        function g = get.curves(this)
            assert(~isempty(this.curves_));
            g = this.curves_;
        end
        function g = get.etas(this)
            assert(~isempty(this.etas_));
            g = this.etas_;
        end
        function g = get.frameLength(this)
            assert(~isempty(this.frameLength_));
            g = this.frameLength_;
        end
        function g = get.imgregLog(this)
            assert(~isempty(this.imgregLog_));
            g = this.imgregLog_;
        end
        function g = get.sessionData(this)
            assert(~isempty(this.sessionData_));
            g = this.sessionData_;
        end
    end

	methods 		
 		function this = T4Resolve(varargin)
 			%% T4RESOLVE
 			%  @params 'sessionData' obj is an instance of mlraichle.SessionData

            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlraichle.SessionData'));
            addParameter(ip, 'frameLength', [], @isnumeric);
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.frameLength_ = ip.Results.frameLength;
        end
        
        function this = parseLog(this, fqfn)
            assert(lexist(fqfn, 'file'));
            this.imgregLog_ = mlio.LogParser.load(fqfn);
            
            idx = 1;
            this.etas_   = cell(this.frameLength, this.frameLength);
            this.curves_ = cell(this.frameLength, this.frameLength);
            while (idx < this.imgregLog_.length)
                try
                    [fr1,idx] = this.frameNum(idx);
                    [fr2,idx] = this.frameNum(idx+1);
                    
                    this.etas_{fr1,fr2}        = this.parseEtas(  idx+1);
                    [this.curves_{fr1,fr2},idx] = this.parseCurves(idx+1);
                catch ME
                    if (~strcmp(ME.identifier, 'mlio:endOfFile'))
                        handerror(ME);
                    end
                    return
                end
            end
        end
        function [fr,idx] = frameNum(this, idx)   
            [str,idx] = this.imgregLog_.rightSideChar('Reading image:', idx);
            names = regexp(str, '\S+frame(?<fr>\d+)\S+', 'names');
            fr    = str2double(names.fr);
        end
        function [e,idx]  = parseEtas(this, idx)
            % @params idx is the starting line from this.imgregLog from which to parse curvature numbers.
            % @returns c contains the eta cost for image intensity gradients; 
            % only the last cost for the image frame is returned.
            % @returns idx is the end of reading of the current image frame.
            
            [~,ilast] = this.imgregLog_.rightSideChar('Reading image:', idx);
            e = nan;
            while (idx < ilast)
                elast = e;
                [e,idx] = this.imgregLog_.rightSideNumeric('eta,q', idx+1);
            end
            e   = elast;
            idx = ilast;
        end
        function [c,idx]  = parseCurves(this, idx)
            % @params idx is the starting line from this.imgregLog from which to parse curvature numbers.
            % @returns c contains the curvature numbers in R^6; 
            % only the last curvature numbers for the image frame are returned.
            % @returns idx is the end of reading of the current image frame.
            
            [~,ilast] = this.imgregLog_.rightSideChar('Reading image:', idx);
            c = nan;
            while (idx < ilast)
                clast = c;
                [c,idx] = this.imgregLog_.nextLineNNumeric('100000*second partial in parameter space', 6, idx+1);
            end
            c   = clast;
            idx = ilast;
        end
        function t4r      = report(this)
            t4r = mlraichle.T4ResolveReport(this);
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
        imgregLog_
        frameLength_
        etas_
        curves_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

