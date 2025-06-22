% Script de Análise e Geração de Gráficos para o TCC
%
% Instruções:
% 1. Certifique-se que os arquivos .csv e .fis, e a pasta 'draggable'
%    estão no mesmo diretório deste script.
% 2. Para gerar apenas uma figura, comente as outras chamadas de função
%    na seção "GERAÇÃO E SALVAMENTO DAS FIGURAS".
% 3. Execute o script. As figuras serão salvas na pasta 'Figuras_Geradas_TCC'.

%% SETUP INICIAL
clear; clc; close all;
addpath('draggable'); % Adiciona a pasta de funções 'draggable'

%% 1. CONFIGURAÇÕES GERAIS
% Opções para salvar as figuras
save_options.outputDir = 'Figuras_Geradas_TCC';
save_options.format = 'png';   % Formato: 'png', 'pdf', 'eps'
save_options.resolution = 300; % Resolução em DPI

disp('Iniciando análise com dados sintéticos completos...');

%% 2. EXECUÇÃO DOS CÁLCULOS E PREPARAÇÃO
colors = get_color_palette();
analysis_data = calculate_indices();

disp('Cálculos concluídos. Iniciando geração de figuras...');

% Salva os resultados para uso posterior ou análise manual
disp('Salvando resultados da análise em arquivo .mat...');
save('Resultados_Analise_TCC.mat', 'analysis_data', 'colors');
disp('Arquivo Resultados_Analise_TCC.mat salvo com sucesso.');
disp('----------------------------------------------------');

%% 3. GERAÇÃO E SALVAMENTO DAS FIGURAS
% Comente as linhas abaixo para não gerar figuras específicas.

% --- Figuras de Análise Geral ---
fig1 = generate_figure_01_heatmap(analysis_data);
save_figure(fig1, '01_Heatmap_Densidade_Risco', save_options);

fig2a = generate_figure_02a_dist_hi(analysis_data, colors);
save_figure(fig2a, '02a_Distribuicao_HI', save_options);

fig2b = generate_figure_02b_dist_fc(analysis_data, colors);
save_figure(fig2b, '02b_Distribuicao_FC', save_options);

fig2c = generate_figure_02c_dist_ri(analysis_data, colors);
save_figure(fig2c, '02c_Distribuicao_RI', save_options);

fig2d = generate_figure_02d_dist_idade(analysis_data, colors);
save_figure(fig2d, '02d_Distribuicao_Idade', save_options);

fig3 = generate_figure_03_correlacao(analysis_data, colors);
save_figure(fig3, '03_Correlacao_Idade_vs_Saude', save_options);

fig4 = generate_figure_04_classificacao(analysis_data, colors);
save_figure(fig4, '04_Classificacao_Risco_Frota', save_options);

fig5 = generate_figure_05_bubble_matrix(analysis_data);
save_figure(fig5, '05_Matriz_Risco_Ponderada_Idade', save_options);

% --- Figuras de Superfície de Controle ---
fig6 = generate_figure_06_surf_sobrecarga_oleo(analysis_data);
save_figure(fig6, '06_Superficie_FC_Sobrecarga_Oleo', save_options);

fig7 = generate_figure_07_surf_corta_chama_local(analysis_data);
save_figure(fig7, '07_Superficie_FC_CortaChama_Local', save_options);

fig8 = generate_figure_08_surf_risco(analysis_data);
save_figure(fig8, '08_Superficie_Indice_Risco', save_options);

% --- Figuras de Análise Estratégica ---
fig9 = generate_figure_09_pareto(analysis_data, colors);
save_figure(fig9, '09_Analise_Pareto_Risco', save_options);

fig10a = generate_figure_10a_boxplot_hi(analysis_data, colors);
save_figure(fig10a, '10a_Boxplot_HI_por_Risco', save_options);

fig10b = generate_figure_10b_boxplot_idade(analysis_data, colors);
save_figure(fig10b, '10b_Boxplot_Idade_por_Risco', save_options);

fig11 = generate_figure_11_risk_drivers(analysis_data, colors);
save_figure(fig11, '11_Fatores_Contribuintes_Risco', save_options);

% --- Figuras de Análise de Sensibilidade ---
fig12 = generate_figure_12_sensitivity_hi(analysis_data, colors);
save_figure(fig12, '12_Sensibilidade_HI', save_options);

fig13 = generate_figure_13_sensitivity_fc(analysis_data, colors);
save_figure(fig13, '13_Sensibilidade_FC', save_options);

% --- Figura de Decisão Estratégica ---
fig14 = generate_figure_14_decision_quadrants(analysis_data, colors);
save_figure(fig14, '14_Painel_Decisao_Estrategica', save_options);

disp('----------------------------------------------------');
disp('Processo concluído. Todas as figuras foram salvas na pasta:');
disp(fullfile(pwd, save_options.outputDir));


%% FUNÇÕES LOCAIS
% O código de suporte para os cálculos e geração de gráficos está
% organizado abaixo como funções locais.

function save_figure(fig_handle, base_filename, options)
    % Salva uma figura com configurações padronizadas de alta qualidade.
    if ~exist(options.outputDir, 'dir'), mkdir(options.outputDir); end
    fullFilePath = fullfile(options.outputDir, [base_filename, '.', options.format]);
    set(fig_handle, 'Color', 'w');
    fprintf('Salvando: %s ...\n', fullFilePath);
    exportgraphics(fig_handle, fullFilePath, 'Resolution', options.resolution);
    close(fig_handle);
end

function colors = get_color_palette()
    % Centraliza a paleta de cores do projeto em uma struct.
    colors.primary    = '#003366'; 
    colors.secondary  = '#6699CC'; 
    colors.highlight  = '#D55E00'; 
    colors.text       = '#000000'; 
    colors.grey       = '#666666';
    colors.risk.low      = '#009E73'; 
    colors.risk.moderate = '#56B4E9';
    colors.risk.high     = '#D55E00'; 
    colors.risk.critical = '#CC3333';
end

function data = calculate_indices()
    % Carrega dados brutos e realiza todos os cálculos dos índices fuzzy.
    read_options = {'VariableNamingRule', 'preserve'};
    data.fc_table = readtable('Dados_FC_Sinteticos_Final.csv', read_options{:});
    data.hi_table = readtable('Dados_HI_Sinteticos_Final.csv', read_options{:});
    
    % Adiciona os IDs dos ativos à estrutura de dados para consulta posterior
    data.asset_ids = data.hi_table{:, 1}; 
    
    data.fis_hi = readfis('Indice_Saude_BR.fis');
    data.hi_inputs = table2array(data.hi_table(:, 2:7)); 
    saidas_hi = evalfis(data.fis_hi, data.hi_inputs);
    data.hi = saidas_hi(:, 1); 
    data.age = saidas_hi(:, 2);
    
    data.fis_fc = readfis('Fator_Consequencia_BR.fis');
    entradas_fc = table2array(data.fc_table(:, 2:9));
    for i = 1:numel(data.fis_fc.Inputs)
        entradas_fc(:, i) = rescale(entradas_fc(:, i), data.fis_fc.Inputs(i).Range(1), data.fis_fc.Inputs(i).Range(2));
    end
    data.fc_inputs = entradas_fc;
    data.fc = evalfis(data.fis_fc, data.fc_inputs);
    
    data.fis_risk = readfis('Indice_Risco_BR.fis');
    data.ri = evalfis(data.fis_risk, [data.hi, data.fc]);
    
    bins = [0, 0.25, 0.5, 0.75, 1.0];
    cats = discretize(data.ri, bins, 'categorical', {'Baixo', 'Moderado', 'Alto', 'Crítico'});
    data.risk_categories = removecats(cats, setdiff({'Baixo', 'Moderado', 'Alto', 'Crítico'}, cellstr(unique(cats))));
end

function style_boxplot(ax, box_color, median_color, outlier_color)
    % Função auxiliar para estilizar boxplots de forma consistente
    box_rgb = sscanf(box_color(2:end),'%2x',[1 3])/255;
    outlier_rgb = sscanf(outlier_color(2:end),'%2x',[1 3])/255;
    if median_color == 'w' || median_color == 'k'
        median_rgb = median_color;
    else
        median_rgb = sscanf(median_color(2:end),'%2x',[1 3])/255;
    end
    set(findobj(ax, 'Tag', 'Box'), 'Color', box_rgb, 'LineWidth', 1.5);
    set(findobj(ax, 'Tag', 'Median'), 'Color', median_rgb, 'LineWidth', 2);
    set(findobj(ax, 'Tag', 'Outliers'), 'MarkerEdgeColor', outlier_rgb, 'LineWidth', 1.5);
end

% --- Funções Geradoras de Figuras ---

function fig = generate_figure_01_heatmap(data)
    fig = figure('Position', [100 200 700 600], 'Visible', 'off');
    h = histogram2(data.hi, data.fc, 10, 'FaceColor', 'flat', 'ShowEmptyBins', 'off', 'DisplayStyle', 'tile');
    xlabel('Índice de Saúde (HI)');
    ylabel('Fator de Consequência (FC)');
    
    num_transformadores = height(data.fc_table);
    title(sprintf('Densidade de Ativos na Matriz de Risco (%d Transformadores)', num_transformadores));
    
    grid on;
    axis square;
    colormap(jet);
    colorbar;
    ax = gca;
    ax.Position = [0.13, 0.2, 0.7, 0.76];
end

function fig = generate_figure_02a_dist_hi(data, colors)
    fig = figure('Position', [200 200 600 450], 'Visible', 'off');
    histogram(data.hi, 25, 'FaceColor', colors.primary);
    title('Distribuição do Índice de Saúde (HI)');
    xlabel('Índice de Saúde (HI)'); 
    ylabel('Contagem de Ativos'); 
    grid on; box on;
end

function fig = generate_figure_02b_dist_fc(data, colors)
    fig = figure('Position', [200 200 600 450], 'Visible', 'off');
    histogram(data.fc, 25, 'FaceColor', colors.secondary);
    title('Distribuição do Fator de Consequência (FC)');
    xlabel('Fator de Consequência (FC)'); 
    ylabel('Contagem de Ativos'); 
    grid on; box on;
end

function fig = generate_figure_02c_dist_ri(data, colors)
    fig = figure('Position', [200 200 600 450], 'Visible', 'off');
    histogram(data.ri, 25, 'FaceColor', colors.highlight);
    title('Distribuição do Índice de Risco (RI)');
    xlabel('Índice de Risco (RI)'); 
    ylabel('Contagem de Ativos'); 
    grid on; box on;
end

function fig = generate_figure_02d_dist_idade(data, colors)
    fig = figure('Position', [200 200 600 450], 'Visible', 'off');
    histogram(data.age, 25, 'FaceColor', colors.grey);
    title('Distribuição da Idade Elétrica Estimada');
    xlabel('Idade Elétrica Estimada (%)'); 
    ylabel('Contagem de Ativos'); 
    grid on; box on;
end

function fig = generate_figure_03_correlacao(data, colors)
    fig = figure('Position', [200 200 700 500], 'Visible', 'off');
    scatter(data.age, data.hi, 30, 'filled', 'MarkerFaceColor', colors.primary, 'MarkerFaceAlpha', 0.6);
    hold on; 
    lsline;
    set(findobj(gca, 'Type', 'Line'), 'Color', colors.highlight, 'LineWidth', 2);
    xlabel('Idade Elétrica Estimada (%)'); 
    ylabel('Índice de Saúde (HI)');
    title('Correlação entre Idade Elétrica e Índice de Saúde');
    grid on; 
    legend('Transformadores', 'Linha de Tendência', 'Location', 'northeast'); 
    box on;
end

function fig = generate_figure_04_classificacao(data, colors)
    fig = figure('Position', [250 250 700 500], 'Visible', 'off');
    [counts, names] = groupcounts(data.risk_categories);
    mapa = containers.Map(...
        {'Baixo', 'Moderado', 'Alto', 'Crítico'}, ...
        {colors.risk.low, colors.risk.moderate, colors.risk.high, colors.risk.critical});
    
    num_categorias = length(names);
    cores_barras_rgb = zeros(num_categorias, 3);
    for i = 1:num_categorias
        categoria_atual = char(names(i));
        hex_color = mapa(categoria_atual);
        cores_barras_rgb(i, :) = sscanf(hex_color(2:end), '%2x', [1 3]) / 255;
    end
    
    b = bar(names, counts, 'FaceColor', 'flat');
    b.CData = cores_barras_rgb;
    
    ylabel('Número de Transformadores');
    title('Contagem de Ativos por Categoria de Risco');
    grid on; 
    box on;
    
    y_offset = max(counts) * 0.03;
    for i = 1:length(counts)
        text(i, counts(i) + y_offset, num2str(counts(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    ylim([0, max(counts) * 1.15]);
end

function fig = generate_figure_05_bubble_matrix(data)
    fig = figure('Position', [300 100 850 700], 'Visible', 'off');
    bubblechart(data.hi, data.fc, data.age, data.age, 'LineWidth', 1, 'MarkerFaceAlpha', 0.65);
    
    axis tight;
    lims = axis;
    x_padding = (lims(2) - lims(1)) * 0.10;
    y_padding = (lims(4) - lims(3)) * 0.10;
    axis([lims(1)-x_padding, lims(2)+x_padding, lims(3)-y_padding, lims(4)+y_padding]);
    
    bubblelim([5 80]);
    colormap('jet');
    blgd = bubblelegend('Idade Elétrica Estimada (%)', 'Location', 'eastoutside');
    blgd.FontSize = 10;
    
    c = colorbar;
    c.Label.String = 'Idade (%)';
    
    xlabel('Índice de Saúde (HI)', 'FontSize', 12);
    ylabel('Fator de Consequência (FC)', 'FontSize', 12);
    title('Análise Estratégica: Risco vs. Idade Elétrica', 'FontSize', 14, 'FontWeight', 'bold');
    grid on; box on; axis square;
end

function fig = generate_figure_06_surf_sobrecarga_oleo(data)
    fig = figure('Position', [300 100 850 700], 'Visible', 'off');
    gensurf(data.fis_fc, [1 7], 1);  % Gera a superfície fuzzy
    colormap(jet);
    title('FC: Nível de Sobrecarga vs. Nível do Reservatório de Óleo');
    xlabel('Nível de Sobrecarga');
    ylabel('Nível do Reservatório de Óleo');
    zlabel('Fator de Criticidade');
    ax = gca;
    ax.Position = [0.13, 0.2, 0.75, 0.74];
end

function fig = generate_figure_07_surf_corta_chama_local(data)
    fig = figure('Position', [300 100 850 700], 'Visible', 'off');
    gensurf(data.fis_fc, [8 4], 1);
    colormap(jet);
    title('FC: Condição do Corta-Chama vs. Proximidade');
    xlabel('Condição do Corta-Chama'); 
    ylabel('Proximidade outros edificios'); 
    zlabel('Fator de Consequência');
    ax = gca;
    ax.Position = [0.13, 0.2, 0.75, 0.74];
end

function fig = generate_figure_08_surf_risco(data) 
    fig = figure('Position', [300 100 850 700], 'Visible', 'off'); 
    gensurf(data.fis_risk); 
    colormap(jet);
    title('Superfície do Índice de Risco'); 
    xlabel('Índice de Saúde (HI)'); 
    ylabel('Fator de Consequência (FC)'); 
    zlabel('Índice de Risco (RI)'); 
    ax = gca; 
    ax.Position = [0.13, 0.2, 0.75, 0.74]; 
 end
 
function fig = generate_figure_09_pareto(data, colors)
    fig = figure('Position', [350 150 800 550], 'Visible', 'off');
    [sorted_ri, ~] = sort(data.ri.^3, 'descend');
    pareto_data = cumsum(sorted_ri) / sum(sorted_ri) * 100;
    percent_ativos = (1:length(sorted_ri)) / length(sorted_ri) * 100;
    
    yyaxis left;
    b = bar(percent_ativos, sorted_ri, 'FaceColor', colors.primary, 'EdgeColor', 'none', 'BarWidth', 1);
    ylabel('Contribuição Individual ao Risco'); 
    ax = gca; 
    ax.YColor = colors.primary; 
    ax.XTick = [];
    
    yyaxis right;
    p = plot(percent_ativos, pareto_data, '-', 'Color', colors.highlight, 'LineWidth', 2.5);
    ylabel('Risco Acumulado (%)'); 
    ylim([0 101]); 
    ax = gca; 
    ax.YColor = colors.highlight;
    
    hold on;
    idx_80 = find(pareto_data >= 80, 1, 'first');
    if ~isempty(idx_80)
        percent_80 = percent_ativos(idx_80);
        plot([0 percent_80], [80 80], 'k--', 'LineWidth', 1);
        plot([percent_80 percent_80], [0 80], 'k--', 'LineWidth', 1);
        text(percent_80 + 3, 75, sprintf('%.1f%% dos ativos = 80%% do risco', percent_80), 'FontWeight', 'bold');
    end
    
    title('Análise de Pareto do Risco da Frota (Calibrado)');
    xlabel('Percentual de Ativos (Ordenados por Risco)');
    legend([b, p], 'Contribuição Individual', 'Risco Acumulado', 'Location', 'southeast');
    grid on; 
    box on; 
    ax.GridLineStyle = ':';
end

function fig = generate_figure_10a_boxplot_hi(data, colors)
    fig = figure('Position', [400 200 600 500], 'Visible', 'off');
    boxplot(data.hi, data.risk_categories); 
    ylabel('Índice de Saúde (HI)'); 
    grid on; 
    box on;
    title('Distribuição do Índice de Saúde por Categoria de Risco');
    style_boxplot(gca, colors.primary, 'k', colors.risk.critical);
end

function fig = generate_figure_10b_boxplot_idade(data, colors)
    fig = figure('Position', [400 200 600 500], 'Visible', 'off');
    boxplot(data.age, data.risk_categories);
    ylabel('Idade Elétrica Estimada (%)'); 
    grid on; 
    box on;
    title('Distribuição da Idade Elétrica por Categoria de Risco');
    style_boxplot(gca, colors.secondary, 'k', colors.risk.critical); 
end

function fig = generate_figure_11_risk_drivers(data, colors)
    fig = figure('Position', [450 250, 800, 550], 'Visible', 'off');
    idx_alto = data.risk_categories == 'Alto';
    idx_critico = data.risk_categories == 'Crítico';
    
    drivers_alto = [
        mean(data.fc_inputs(idx_alto, 1) > 0.9) * 100;   % Sobrecarga Crítica
        mean(data.fc_inputs(idx_alto, 2) > 50) * 100;    % Carga Média Alta
        mean(data.fc_inputs(idx_alto, 3) > 0.75) * 100;  % Cargas Críticas
        mean(data.fc_inputs(idx_alto, 4) < 150) * 100;   % Próximo de Edifícios
        mean(data.fc_inputs(idx_alto, 5) < 1.0) * 100;   % Volume de Óleo Pequeno
        mean(data.fc_inputs(idx_alto, 6) > 2.5) * 100;   % Penalidades Altas
        mean(data.fc_inputs(idx_alto, 7) < 35) * 100;    % Nível de Óleo Baixo
        mean(data.fc_inputs(idx_alto, 8) < 0.3) * 100    % Corta-Chama Inadequada
    ];
    
    drivers_critico = [
        mean(data.fc_inputs(idx_critico, 1) > 0.9) * 100;
        mean(data.fc_inputs(idx_critico, 2) > 50) * 100;
        mean(data.fc_inputs(idx_critico, 3) > 0.75) * 100;
        mean(data.fc_inputs(idx_critico, 4) < 150) * 100;
        mean(data.fc_inputs(idx_critico, 5) < 1.0) * 100;
        mean(data.fc_inputs(idx_critico, 6) > 2.5) * 100;
        mean(data.fc_inputs(idx_critico, 7) < 35) * 100;
        mean(data.fc_inputs(idx_critico, 8) < 0.3) * 100
    ];
    
    b = bar([drivers_alto, drivers_critico]);
    b(1).FaceColor = sscanf(colors.risk.high(2:end), '%2x', [1 3]) / 255;
    b(2).FaceColor = sscanf(colors.risk.critical(2:end), '%2x', [1 3]) / 255;
    
    ylabel('Prevalência da Condição (%)');
    title('Principais Fatores Contribuintes para Risco Alto e Crítico');
    set(gca, 'XTickLabel', {
        'Sobrecarga Crítica', 'Carga Média Alta', 'Cargas Críticas', ...
        'Próximo de Edifícios', 'Volume de Óleo Pequeno', ...
        'Penalidades Altas', 'Nível de Óleo Baixo', 'Corta-Chama Inadequada'
    });
    set(gca, 'XTickLabelRotation', 30);
    legend('Grupo de Risco Alto', 'Grupo de Risco Crítico', 'Location', 'northeast');
    grid on; 
    ylim([0 105]);
end

function fig = generate_figure_12_sensitivity_hi(data, colors)
    fig = figure('Position', [500 300 800 500], 'Visible', 'off');
    num_inputs = size(data.hi_inputs, 2);
    influencia = zeros(1, num_inputs);
    baseline = mean(data.hi_inputs, 1);
    
    for i = 1:num_inputs
        range_val = linspace(data.fis_hi.Inputs(i).Range(1), data.fis_hi.Inputs(i).Range(2), 50);
        temp_inputs = repmat(baseline, 50, 1); 
        temp_inputs(:, i) = range_val';
        output = evalfis(data.fis_hi, temp_inputs);
        influencia(i) = range(output(:, 1));
    end
    
    bar(influencia, 'FaceColor', colors.primary);
    title('Sensibilidade: Influência de Cada Variável no HI');
    ylabel('Variação Máxima do HI'); 
    xticklabels({data.fis_hi.Inputs.Name}); 
    set(gca, 'TickLabelInterpreter', 'none'); 
    xtickangle(45); 
    grid on;
end

function fig = generate_figure_13_sensitivity_fc(data, colors)
    fig = figure('Position', [550 350 900 500], 'Visible', 'off');
    num_inputs = size(data.fc_inputs, 2);
    influencia = zeros(1, num_inputs);
    baseline = mean(data.fc_inputs, 1);
    
    for i = 1:num_inputs
        range_val = linspace(data.fis_fc.Inputs(i).Range(1), data.fis_fc.Inputs(i).Range(2), 50);
        temp_inputs = repmat(baseline, 50, 1); 
        temp_inputs(:, i) = range_val';
        influencia(i) = range(evalfis(data.fis_fc, temp_inputs));
    end
    
    bar(influencia, 'FaceColor', colors.secondary);
    title('Sensibilidade: Influência de Cada Variável no FC');
    ylabel('Variação Máxima do FC'); 
    xticklabels({data.fis_fc.Inputs.Name});
    set(gca, 'TickLabelInterpreter', 'none'); 
    xtickangle(45); 
    grid on;
end

function fig = generate_figure_14_decision_quadrants(data, colors)
    fig = figure('Position', [600 200 850 700], 'Visible', 'off');
    hi_thr = mean(data.hi); 
    fc_thr = mean(data.fc);
    
    scatter(data.hi, data.fc, 50, data.ri, 'filled', 'MarkerEdgeColor', '#444444', 'MarkerFaceAlpha', 0.8);
    hold on;
    
    xline(hi_thr, '--', 'Média HI', 'Color', colors.text, 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 10);
    yline(fc_thr, '--', 'Média FC', 'Color', colors.text, 'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'FontSize', 10);
    
    ax_limits = [0 1 0 1];
    axis(ax_limits);
    padding = 0.04;
    
    text(ax_limits(2) - padding, ax_limits(4) - padding, {'Risco Crítico', 'Ação Imediata'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.critical, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    text(ax_limits(1) + padding, ax_limits(4) - padding, {'Risco de Consequência', 'Manutenção Preditiva'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.high, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(ax_limits(2) - padding, ax_limits(1) + padding, {'Risco de Condição', 'Planejar Reforma'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', sscanf(colors.secondary(2:end),'%2x',[1 3])/255, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
    text(ax_limits(1) + padding, ax_limits(1) + padding, {'Baixa Prioridade', 'Monitoramento Padrão'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.low, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    
    hold off;
    
    xlabel('Índice de Saúde (HI)'); 
    ylabel('Fator de Consequência (FC)');
    title('Painel de Decisão Estratégica por Quadrantes de Risco');
    
    colormap('jet'); 
    c = colorbar; 
    c.Label.String = 'Índice de Risco (RI)';
    
    grid on;
    box on;
    set(gca, 'FontSize', 11);
end
