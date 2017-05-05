classdef F18DeoxyGlucoseFigures < mlkinetics.AbstractGlucoseFigures
	%% F18DEOXYGLUCOSEFIGURES  

	%  $Revision$
 	%  was created 09-Apr-2017 04:11:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	properties
        useAxes2 = false
        dataRows = [2 9]
    end    
    
    properties (Dependent)
        %xlsx = '/Volumes/nil/raichle/PPGdata/jjlee/mlraiche_FDGKineticsParc_goWritetable_N4.xlsx'
        %xlsx = '/Volumes/nil/raichle/PPGdata/jjlee/mlraiche_FDGKineticsWholebrain_goWritetable_N4.xlsx'
        xlsx
    end
    
    methods %% GET/SET
        function g = get.xlsx(this)
            if (~isempty(this.xlsx_))
                g = this.xlsx_;
                return
            end
            if (all(this.dataRows == [2 9]))
                g = '/Users/jjlee/Box Sync/Raichle/2017apr10/wholebrain/mlraiche_FDGKineticsWholebrain_goWritetable_N4.xlsx';
            else
                g = '/Users/jjlee/Box Sync/Raichle/2017apr10/regional/mlraiche_FDGKineticsParc_goWritetable_N4.xlsx';
            end
        end
        function this = set.xlsx(this, s)
            this.xlsx_ = s;
        end
    end
    
	methods
 		function this = F18DeoxyGlucoseFigures(varargin) 
 			%% F18DeoxyGlucoseFigures 
 			%  Usage:  this = F18DeoxyGlucoseFigures() 

            this = this@mlkinetics.AbstractGlucoseFigures(varargin{:});
            
%             ip = inputParser;
%             addParameter(ip, 'xlsx', this.xlsx, @(x) lexist(x, 'file'));
%             parse(ip, varargin{:});
%             
%             if (~isempty(ip.Results.xlsx))
%                 this.xlsx = ip.Results.xlsx; 
%             end
%             this = this.xlsRead;
            this.registry_ = mlarbelaez.ArbelaezRegistry.instance;
        end 
        function cftool(this, yLabel)
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(yLabel);            
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            
            glu = this.plasma_glu;          
            cftool(glu,y);
        end
        function [figure0,x,y] = createScatter(this, yLabel, varargin)
            %% CREATESCATTER
            %  e.g., glutf = F18DeoxyGlucoseFigures;
            %        f = glutf.createScatterCTXandCMR(yLabel[, 'yInf', yInf value, 'ySup', ySup value])

            markSize = 220;
            markShape = 's';
            
            ip = inputParser;
            addRequired( ip, 'yLabel', @ischar);
            addParameter(ip, 'yInf', 0,  @isnumeric);
            addParameter(ip, 'ySup', [], @isnumeric);
            addParameter(ip, 'figure', figure, @(x) isa(x, 'matlab.graphics.chart.primitive.Scatter'));
            addParameter(ip, 'markerFaceColor', [1 1 1], @isnumeric);
            parse(ip, yLabel, varargin{:});
            
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(ip.Results.yLabel);   
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('Nominal arterial plasma glucose');
            x = this.plasma_glu;             

            % Create figure
            figure0 = ip.Results.figure;
            newFigure = any(ismember(ip.UsingDefaults, 'figure'));

            if (newFigure)
                
                % Create axes2, in back
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');

                xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);
                if (conversionFactor2 ~= 1)
                    ylabel(axes2, yLabel2, 'FontSize', this.axesLabelFontSize); end

                xlim(axes2,this.axesLimXBar(x*conversionFactor1)); 
                ylim(axes2,this.axesLimYBar(y*conversionFactor2, ip.Results.yInf*conversionFactor2, ip.Results.ySup*conversionFactor2));
                set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRisingSI,'XAxisLocation','top','YAxisLocation','right','TickDir','out');
                axes2Position = axes2.Position;
                set(axes2,'Position',[axes2Position(1) axes2Position(2) 1.002*axes2Position(3) 1.001*axes2Position(4)]);

                % Create axes1, in front
                axes1 = axes('Parent',figure0);
                hold(axes1,'on');

                xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
                ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

                xlim(axes1,this.axesLimXBar(x));        
                ylim(axes1,this.axesLimYBar(y, ip.Results.yInf, ip.Results.ySup));
                set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRising,'XAxisLocation','bottom','YAxisLocation','left','Position',axes2Position);
            else
                hold(figure0.CurrentAxes, 'all');
            end
            
            % Create scatter
            figure0 = scatter(x,y,markSize,markShape,'MarkerEdgeColor',this.markerEdgeColor,'MarkerFaceColor',ip.Results.markerFaceColor,'LineWidth',this.markerLineWidth);
        end
        function figure0 = createScatterCTXandCMR(this, varargin)
            %% CREATESCATTERCTXANDCMR
            %  e.g., glutf = F18DeoxyGlucoseFigures;
            %        f = glutf.createScatterCTXandCMR

            ip = inputParser;
            addParameter(ip, 'dataRows', [2 9], @isnumeric);
            addParameter(ip, 'title', '', @ischar);
            addParameter(ip, 'ylim', [], @isnumeric);
            parse(ip, varargin{:});
            this.useAxes2 = true;
            this.dataRows = ip.Results.dataRows;
            this = this.xlsRead;
            
            y1      = this.CTXglu;
            y2      = this.CMRglu;
            yLabel1 = 'CTX_{glu} (\mumol/100 g/min)';
            yLabel2 = 'CMR_{glu} (\mumol/100 g/min)';
            [glu,xLabel1,xLabel2,conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            conversionFactor2 = 1;
            mark1   = 's';
            mark2   = 'o';

            % Create figure
            figure0 = figure;

            % Create axes2
            if (this.useAxes2)
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');

                xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);
                ylabel(axes2, yLabel2, 'FontSize', this.axesLabelFontSize, 'Color', this.cyan);

                xlim(axes2,[0 400]*conversionFactor1);
                if (~isempty(ip.Results.ylim))
                    ylim(axes2,ip.Results.ylim);
                else         
                    ylim(axes2,this.axesLimY(y1*conversionFactor2));
                end
                set(axes2,'FontSize',this.axesFontSize,'XAxisLocation','top','YAxisLocation','right');
                %xticks(axes2, [2.2 2.8 3.3 3.9 4.4 5.0 5.5]);
            end
            
            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize, 'Color', this.navy);

            xlim(axes1,[0 400]);  
            if (~isempty(ip.Results.ylim))
                ylim(axes1,ip.Results.ylim);
            else                  
                ylim(axes1,this.axesLimY(y1));
            end
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XAxisLocation','bottom','YAxisLocation','left');
            
            % Create scatter
            scatter(glu,y1,this.markerSize,mark1,'MarkerEdgeColor',this.navy,'MarkerFaceColor','none','LineWidth',this.markerLineWidth);
            scatter(glu,y2,this.markerSize,mark2,'MarkerEdgeColor',this.cyan,'MarkerFaceColor','none','LineWidth',this.markerLineWidth);
            legend( 'CTX_{glu}', 'CMR_{glu}', 'Location', this.legendLocation, 'Box', 'on' );  
            this.title(ip.Results.title);
        end
        function figure0 = createScatterFreeGlucose(this, varargin)

            ip = inputParser;
            addParameter(ip, 'dataRows', [2 9], @isnumeric);
            addParameter(ip, 'title', '', @ischar);
            addParameter(ip, 'ylim', [], @isnumeric);
            parse(ip, varargin{:});
            this.dataRows = ip.Results.dataRows;
            this = this.xlsRead;
            
            y1      = this.free_glu;
            yLabel1 = 'Brain free glucose (\mumol/g)';
            [glu,xLabel1,xLabel2,conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            conversionFactor2 = 1;
            mark1   = '+';

            % Create figure
            figure0 = figure;

            % Create axes2
            if (this.useAxes2)
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');

                xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);

                xlim(axes2,[0 400]*conversionFactor1);
                if (~isempty(ip.Results.ylim))
                    ylim(axes2,ip.Results.ylim);
                else
                    ylim(axes2,this.axesLimY(y1*conversionFactor2));
                end
                set(axes2,'FontSize',this.axesFontSize,'XAxisLocation','top','YAxisLocation','right');
                %xticks(axes2, [2.2 2.8 3.3 3.9 4.4 5.0 5.5]);
            end
            
            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

            xlim(axes1,[0 400]); 
            if (~isempty(ip.Results.ylim))
                ylim(axes1,ip.Results.ylim);
            else          
                ylim(axes1,this.axesLimY(y1));
            end
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XAxisLocation','bottom','YAxisLocation','left');
            
            % Create scatter
            scatter(glu,y1,this.markerSize,mark1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 1 1],'LineWidth',this.markerLineWidth);
            legend('Brain free glucose', 'Location', this.legendLocation, 'Box', 'on' ); 
            this.title(ip.Results.title);
        end
        function figure0 = createScatterK12(this, varargin)

            ip = inputParser;
            addParameter(ip, 'dataRows', [2 9], @isnumeric);
            addParameter(ip, 'title', 'k_2', @ischar);
            addParameter(ip, 'ylim', [], @isnumeric);
            parse(ip, varargin{:});
            this.dataRows = ip.Results.dataRows;
            this = this.xlsRead;
            
            y1      = this.k12;
            yLabel1 = 'k_2 (1/min)';
            [glu,xLabel1,xLabel2,conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            conversionFactor2 = 1;
            mark1   = 'x';

            % Create figure
            figure0 = figure;

            % Create axes2
            if (this.useAxes2)
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');

                xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);

                xlim(axes2,[0 400]*conversionFactor1);
                if (~isempty(ip.Results.ylim))
                    ylim(axes2,ip.Results.ylim);
                else
                    ylim(axes2,this.axesLimY(y1*conversionFactor2));
                end
                set(axes2,'FontSize',this.axesFontSize,'XAxisLocation','top','YAxisLocation','right');
                %xticks(axes2, [2.2 2.8 3.3 3.9 4.4 5.0 5.5]);
            end
            
            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

            xlim(axes1,[0 400]); 
            if (~isempty(ip.Results.ylim))
                ylim(axes1,ip.Results.ylim);
            else          
                ylim(axes1,this.axesLimY(y1));
            end
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XAxisLocation','bottom','YAxisLocation','left');
            
            % Create scatter
            scatter(glu,y1,this.markerSize,mark1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 1 1],'LineWidth',this.markerLineWidth);
            legend( 'k_2', 'Location', this.legendLocation, 'Box', 'on' ); 
            ti = this.title(ip.Results.title);            
            print(ti, '-dpng', '-r300');
        end
        function figure0 = createScatterK21(this, varargin)

            ip = inputParser;
            addParameter(ip, 'dataRows', [2 9], @isnumeric);
            addParameter(ip, 'title', 'k_1', @ischar);
            addParameter(ip, 'ylim', [], @isnumeric);
            parse(ip, varargin{:});
            this.dataRows = ip.Results.dataRows;
            this = this.xlsRead;
            
            y1      = this.k21;
            yLabel1 = 'k_1 (1/min)';
            [glu,xLabel1,xLabel2,conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            conversionFactor2 = 1;
            mark1   = '*';

            % Create figure
            figure0 = figure;

            % Create axes2
            if (this.useAxes2)
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');

                xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);

                xlim(axes2,[0 400]*conversionFactor1);
                if (~isempty(ip.Results.ylim))
                    ylim(axes2,ip.Results.ylim);
                else
                    ylim(axes2,this.axesLimY(y1*conversionFactor2));
                end
                set(axes2,'FontSize',this.axesFontSize,'XAxisLocation','top','YAxisLocation','right');
                %xticks(axes2, [2.2 2.8 3.3 3.9 4.4 5.0 5.5]);
            end
            
            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

            xlim(axes1,[0 400]); 
            if (~isempty(ip.Results.ylim))
                ylim(axes1,ip.Results.ylim);
            else          
                ylim(axes1,this.axesLimY(y1));
            end
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XAxisLocation','bottom','YAxisLocation','left');
            
            % Create scatter
            scatter(glu,y1,this.markerSize,mark1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 1 1],'LineWidth',this.markerLineWidth);
            legend( 'k_2', 'Location', this.legendLocation, 'Box', 'on' ); 
            ti = this.title(ip.Results.title);
            print(ti, '-dpng', '-r300');
        end
        function           createBarErrWholebrain(this)
            this.useAxes2 = false;
            this.axesFontSize = 11;
            this.axesLabelFontSize = 12;
            this.barWidth = 160;
            this.boxFontSize = 11;
            this.capLineWidth = 1;
            this.capSize = 10;
            
            titles = {'whole brain'};
            dataInterval = [2 11];
            figures = cell(size(titles));
            t = 1;
            figures{t} = figure;
            p = uipanel('Parent', figures{t}, 'BorderType', 'none');
            p.Title = [titles{t} ' N = 4'];
            p.TitlePosition = 'centertop';
            p.FontSize = 16;
            p.FontWeight = 'bold';
            di = dataInterval+(t-1)*8;
            this.dataRows = di;
            this = this.xlsRead;                            

            ax = subplot(1,4,1, 'Parent', p);
            this.createBarErr('Art. plasma glu.',   'dataRows', di, 'axes', ax, 'ylim', [0 350]);
            pbaspect([1 2 1]);
            ax = subplot(1,4,2, 'Parent', p);
            this.createBarErr('CTX_{glu}',          'dataRows', di, 'axes', ax, 'ylim', [0 400]);
            pbaspect([1 2 1]);
            ax = subplot(1,4,4, 'Parent', p);
            this.createBarErr('CMR_{glu}',          'dataRows', di, 'axes', ax, 'ylim', [0 60]);
            pbaspect([1 2 1]);
            ax = subplot(1,4,3, 'Parent', p);
            this.createBarErr('Brain free glucose', 'dataRows', di, 'axes', ax, 'ylim', [0 10]);
            pbaspect([1 2 1]);
            %saveas(figures{t}, [titles{t} '.png']);
            print(titles{t}, '-dpng', '-r300');
        end
        function           createBarErrRegions(this)
            this.useAxes2 = false;
            this.axesFontSize = 11;
            this.axesLabelFontSize = 12;
            this.barWidth = 160;
            this.boxFontSize = 11;
            this.capLineWidth = 1;
            this.capSize = 10;
            
            titles = { ...
                'striatum' ...
                'thalamus' ...
                'cerebellum' ...
                'brainstem' ...
                'hypothalamus' ...
                'cerebral white' ...
                'amygdala' ...
                'hippocampus' ...
                'visual' ...
                'somatomotor' ...
                'dorsal attention' ...
                'ventral attention' ...
                'limbic' ...
                'frontoparietal' ...
                'default'};
            dataInterval = [2 9];
            figures = cell(size(titles));
            for t = 1:length(titles)
                figures{t} = figure;
                p = uipanel('Parent', figures{t}, 'BorderType', 'none');
                p.Title = [titles{t} ' N = 4'];
                p.TitlePosition = 'centertop';
                p.FontSize = 16;
                p.FontWeight = 'bold';
                di = dataInterval+(t-1)*8;
                this.dataRows = di;
                this = this.xlsRead;                            
                            
                %ax = subplot(1,4,1, 'Parent', p);
                %this.createBarErr('Art. plasma glu.',   'dataRows', di, 'axes', ax, 'ylim', [0 350]);
                %pbaspect([1 2 1]);
                ax = subplot(1,4,1, 'Parent', p);
                this.createBarErr('CTX_{glu}',          'dataRows', di, 'axes', ax, 'ylim', [0 400]);
                pbaspect([1 2 1]);
                ax = subplot(1,4,2, 'Parent', p);
                this.createBarErr('Brain free glucose', 'dataRows', di, 'axes', ax, 'ylim', [0 10]);
                pbaspect([1 2 1]);
                ax = subplot(1,4,3, 'Parent', p);
                this.createBarErr('CMR_{glu}',          'dataRows', di, 'axes', ax, 'ylim', [0 60]);
                pbaspect([1 2 1]);
                ax = subplot(1,4,4, 'Parent', p);
                this.createBarErr('k_2',                'dataRows', di, 'axes', ax, 'ylim', [0 1.8]);
                pbaspect([1 2 1]);
                %saveas(figures{t}, [titles{t} '.png']);
                print(titles{t}, '-dpng', '-r300');
            end
        end
        function           createBarErrRegions2(this)
            this.useAxes2 = false;
            this.axesFontSize = 8;
            this.axesLabelFontSize = 8;
            this.barWidth = 160;
            this.boxFontSize = 8;
            this.capLineWidth = 0.5;
            this.capSize = 10;
            
            titles = { ...
                'striatum' ...
                'thalamus' ...
                'cerebellum' ...
                'brainstem' ...
                'hypothalamus' ...
                'cerebral white' ...
                'amygdala' ...
                'hippocampus' ...
                'visual' ...
                'somatomotor' ...
                'dorsal attention' ...
                'ventral attention' ...
                'limbic' ...
                'frontoparietal' ...
                'default mode' ...
                };
            dataInterval = [2 9];
            labels = {'CTX_{glu}' 'CMR_{glu}' 'Brain free glucose' 'k_2' 'k_1'};
            ylims = {[0 200] [0 50] [0 7] [0 1.8] [0 7]};
            figures = cell(size(labels));
            for s = 1:length(labels)
                figures{s} = figure;
                p = uipanel('Parent', figures{s}, 'BorderType', 'none');
                p.Title = [labels{s} ' N = 4'];
                p.TitlePosition = 'centertop';
                p.FontSize = 14;
                p.FontWeight = 'bold';
                for t = 1:length(titles)
                    di = dataInterval+(t-1)*8;
                    this.dataRows = di;
                    this = this.xlsRead;                            

                    ax = subplot(3,5,t, 'Parent', p);
                    this.createBarErr(labels{s}, 'dataRows', di, 'axes', ax, 'ylim', ylims{s}, 'title', titles{t}, 'axesLabels', t ==1);
                    pbaspect([1 2 1]);
                end
                %saveas(labels{s}, [titles{t} '.png']);
                print(labels{s}, '-dpng', '-r300');
            end
        end
        function figure0 = createBarErr(this, varargin)

            ip = inputParser;
            addRequired( ip, 'yLabel', @ischar);
            addParameter(ip, 'dataRows', [2 9], @isnumeric);
            addParameter(ip, 'title', '', @ischar);
            addParameter(ip, 'ylim', [], @isnumeric);
            addParameter(ip, 'axes', []);
            addParameter(ip, 'axesLabels', true, @islogical);
            parse(ip, varargin{:});
            this.dataRows = ip.Results.dataRows;
            this = this.xlsRead;
            
            [y1,  yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(ip.Results.yLabel);   
            [glu, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');                        
            yEu        = y1(glu <= 200);
            yHyper     = y1(glu >  200);
            xEu        = mean(glu(glu <= 200));
            xHyper     = mean(glu(glu >  200));
            meanYHyper = mean(yHyper);
            meanYEu    = mean(yEu);
            nominal    = floor([xEu xHyper]);
            
            % Create figure
            if (isempty(ip.Results.axes))
                figure0 = figure;
                axes1 = axes('Parent',figure0);
            else
                figure0 = [];
                axes1 = ip.Results.axes;
            end

            % Create axes2, in back
            if (false) %(this.useAxes2)
                axes2 = axes('Parent',figure0);
                hold(axes2,'on');
                
                if (ip.Results.axesLabels)
                    xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);
                    if (conversionFactor2 ~= 1)
                        ylabel(axes2, yLabel2, 'FontSize', this.axesLabelFontSize); 
                    end
                end
                
                %xlim(axes2,this.axesLimXBar(glu*conversionFactor1));
                if (~isempty(ip.Results.ylim))
                    ylim(axes1,ip.Results.ylim);
                else
                    ylim(axes2,this.axesLimYBar(y1*conversionFactor2));
                end
                set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRisingSI,'XAxisLocation','top','YAxisLocation','right','TickDir','out');
                axes2Position = axes2.Position;
                set(axes2,'Position',[axes2Position(1) axes2Position(2) 1.002*axes2Position(3) 1.001*axes2Position(4)]);
            end
            
            % Create axes1, in front
            hold(axes1,'on');

            if (ip.Results.axesLabels)
                xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
                ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);
            end

            %xlim(axes1,this.axesLimXBar(glu));
            if (~isempty(ip.Results.ylim))
                ylim(axes1,ip.Results.ylim);
            else          
                ylim(axes1,this.axesLimYBar(y1));
            end      
            box(axes1,'on');      
            set(axes1,'FontSize',this.axesFontSize,'XTick',nominal,'XAxisLocation','bottom','YAxisLocation','left');

            % Create bar
            bar(xEu,    meanYEu,    this.barWidth, 'FaceColor', [0 0.1 0.8], 'FaceAlpha', 0.6);
            bar(xHyper, meanYHyper, this.barWidth, 'FaceColor', [0.7 0 0.1], 'FaceAlpha', 0.6);
            this.title(ip.Results.title);
            
            % Create errorbar
            xe = [     xEu       xHyper];
            ye = [mean(yEu) mean(yHyper)];
            se = [ std(yEu)  std(yHyper)] ./ sqrt([length(yEu) length(yHyper)]);
            errorbar(xe,ye,se,'Parent',axes1,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0], ...
                              'LineStyle','none','CapSize',this.capSize,'LineWidth',this.capLineWidth,'Color',[0 0 0]);
        end  
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        registry_
        xlsx_
    end
    
    methods (Access = 'private')
        function t     = title(this, t)
            %if (all(this.dataRows == [2 9]))
            %    t = [t ' (whole brain)'];
            %end
            title(t,'FontSize',this.axesFontSize,'FontWeight','bold');
        end
        function this  = xlsRead(this)
            [~,~,kinetics_] = xlsread(this.xlsx); %, this.xlsxSheet);
            this.mapKinetics = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapKinetics(uint32(idx-this.dataRows(1)+1)) = ...
                    struct( ...
                        'subject',    kinetics_{idx, 1}, ...
                        'visit',      kinetics_{idx, 2}, ...
                        'ROI',        kinetics_{idx, 3}, ...
                        'plasma_glu', kinetics_{idx, 4}, ...
                        'Hct',        kinetics_{idx, 5}, ...
                        'WB_glu',     kinetics_{idx, 6}, ...
                        'CBV',        kinetics_{idx, 7}, ...
                        'k21',        kinetics_{idx, 8}, ...
                        'std_k21',    kinetics_{idx, 9}, ...
                        'k12',        kinetics_{idx,10}, ...
                        'std_k12',    kinetics_{idx,11}, ...
                        'k32',        kinetics_{idx,12}, ...
                        'std_k32',    kinetics_{idx,13}, ...
                        'k23',        kinetics_{idx,14}, ...
                        'std_k23',    kinetics_{idx,15}, ...
                        't0',         kinetics_{idx,16}, ...
                        'std_t0',     kinetics_{idx,17}, ...
                        'chi',        kinetics_{idx,18}, ...
                        'Kd',         kinetics_{idx,19}, ...
                        'CTXglu',     kinetics_{idx,20}, ...
                        'CMRglu',     kinetics_{idx,21}, ...
                        'free_glu',   kinetics_{idx,22});
            end
            this.subject     = this.cellulize(kinetics_, 1);
            this.visit       = this.vectorize(kinetics_, 2);
            this.ROI         = this.cellulize(kinetics_, 3);
            this.plasma_glu  = this.vectorize(kinetics_, 4);
            this.Hct         = this.vectorize(kinetics_, 5);
            this.WB_glu      = this.vectorize(kinetics_, 6);
            this.CBV         = this.vectorize(kinetics_, 7);
            this.k21         = this.vectorize(kinetics_, 8);
            this.std_k21     = this.vectorize(kinetics_, 9);
            this.k12         = this.vectorize(kinetics_,10);
            this.std_k12     = this.vectorize(kinetics_,11);
            this.k32         = this.vectorize(kinetics_,12);
            this.std_k32     = this.vectorize(kinetics_,13);
            this.k23         = this.vectorize(kinetics_,14);
            this.std_k23     = this.vectorize(kinetics_,15);
            this.t0          = this.vectorize(kinetics_,16);
            this.std_t0      = this.vectorize(kinetics_,17);
            this.chi         = this.vectorize(kinetics_,18);
            this.Kd          = this.vectorize(kinetics_,19);
            this.CTXglu      = this.vectorize(kinetics_,20);
            this.CMRglu      = this.vectorize(kinetics_,21);
            this.free_glu    = this.vectorize(kinetics_,22);
        end
        function c     = cellulize(this, arr, col)
            clen = this.dataRows(2) - this.dataRows(1) + 1;
            D = this.dataRows(1) - 1;
            c = cell(1, clen);
            for ic = 1:clen
                c{ic} = arr{ic+D, col};
            end
        end
        function v     = vectorize(this, arr, col)
            vlen = this.dataRows(2) - this.dataRows(1) + 1;
            D = this.dataRows(1) - 1;
            v = zeros(vlen, 1);
            for iv = 1:vlen
                v(iv) = arr{iv+D, col};
            end
        end
        function range = axesLimY(~, dat)
            Delta = (max(dat) - min(dat))*0.25;        
            low   = min(dat) - Delta;
            low   = max(low, 0);
            high  = max(dat) + Delta;
            range = [low high];
        end
        function range = axesLimX(~, dat)
            Delta = (max(dat) - min(dat))*0.25;        
            low   = min(dat) - Delta;
            high  = max(dat) + Delta;
            range = [low high];
        end
        function range = axesLimYBar(~, varargin)
            ip = inputParser;
            addRequired(ip, 'dat', @isnumeric);
            addOptional(ip, 'yInf', 0, @isnumeric);
            addOptional(ip, 'ySup', [], @isnumeric);
            parse(ip, varargin{:});
            ySup = ip.Results.ySup;
            if (isempty(ySup))
                ySup = max(ip.Results.dat);
            end
            range = [ip.Results.yInf ySup];
        end
        function range = axesLimXBar(~, dat)
            Delta = (max(dat) - min(dat))*0.333;        
            low   = min(dat) - Delta;
            high  = max(dat) + Delta*0.666;
            range = [low high];
        end
        function [s,l] = boxPrintMean(this, m, frmt)
            if (isempty(frmt))
                frmt = this.guessFloatFormat(m); end
            s = sprintf(frmt, m);
            l = (length(s) - 1)*this.dx/2;
        end
        function [s,l] = boxPrintSE(this, se, frmt)
            if (isempty(frmt))
                frmt = this.guessFloatFormat(se); end
            s = sprintf(['\\pm ' frmt], se);
            l = (length(s) - 2)*this.dx/2;
        end
        function frmt  = guessFloatFormat(~, f)
            frmt = sprintf('%%.%ig',max(ceil(log10(f)), 2));
        end
        function [x,xLabel1,xLabel2,conversionFactor1] = xLabelLookup(this, xLabel)
            x       = this.plasma_glu;  
            xLabel1 = 'glu. (mg/dL)';
            xLabel2 =      '(mmol/L)';
            conversionFactor1 = 0.05551;
        end
        function [y,yLabel1,yLabel2,conversionFactor2] = yLabelLookup(this, yLabel)
            conversionFactor2 = 1;
            yLabel2 = '';
            switch (yLabel)
                case 'CTX_{glu}/CMR_{glu}'
                    y = this.CTXglu ./ this.CMRglu;
                    yLabel1 = [yLabel ''];
                case 'CMR_{glu}/CTX_{glu}'
                    y = this.CMRglu ./ this.CTXglu;
                    yLabel1 = [yLabel ''];
                case 'CTX_{glu} - CMR_{glu}'
                    y = this.CTXglu - this.CMRglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CMR_{glu}'
                    y = this.CMRglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CTX_{glu}'
                    y = this.CTXglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'Brain free glucose'
                    y = this.free_glu;                   
                    yLabel1 = [yLabel ' (\mumol/g)'];
                case 'CBV'
                    y = this.CBV;
                    yLabel1 = [yLabel ' (mL/100 g)'];
                case 'k_1'
                    y = this.k21*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{21}'
                    y = this.k21*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'std(k_{21})'
                    y = this.std_k21*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_2'
                    y = this.k12*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{12}'
                    y = this.k12*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'std(k_{12})'
                    y = this.std_k12*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{32}'
                    y = this.k32*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'std(k_{32})'
                    y = this.std_k32*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{23}'
                    y = this.k23*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'std(k_{23})'
                    y = this.std_k23*60;
                    yLabel1 = [yLabel ' (1/min)'];
                case 't_0'
                    y = this.t0;
                    yLabel1 = [yLabel ' (s)'];
                case 'std(t_0)'
                    y = this.std_t0;
                    yLabel1 = [yLabel ' (s)'];
                case 'k_{21} k_{32} / (k_{12} + k_{32}) (1/min)'
                    y = 60*this.k21 .* this.k32 ./ (this.k12 + this.k32);
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{32} / (k_{12} + k_{32})'
                    y = 60*this.k32 ./ (this.k12 + this.k32);
                    yLabel1 = [yLabel ' (1/min)'];
                case 'Arterial plasma glucose'    
                    y = this.plasma_glu;
                    yLabel1 = [yLabel ' (mg/dL)'];
                    yLabel2 =          '(mmol/L)';
                    conversionFactor2 = 0.05551;  
                case 'Art. plasma glu.'    
                    y = this.plasma_glu;
                    yLabel1 = [yLabel ' (mg/dL)'];
                    yLabel2 =          '(mmol/L)';
                    conversionFactor2 = 0.05551;                  
                otherwise
                    error('mlarbelaez:unsupportedSwitchCase', 'yLabel was %s', yLabel);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

