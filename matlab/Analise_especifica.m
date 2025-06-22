% SCRIPT DE ANÁLISE DE ATIVO ESPECÍFICO
%
% Instruções:
% 1. Execute o script principal 'Cenario_BR.m' para gerar o arquivo
%    'Resultados_Analise_TCC.mat'.
% 2. Defina o ID do transformador desejado em 'target_asset_id'.
% 3. Execute este script. As figuras serão salvas na pasta 'Figuras_Geradas_TCC'.

%% SETUP INICIAL
clear; clc; close all;

%% 1. CONFIGURAÇÕES
% Defina o ID do ativo para análise
target_asset_id = 6816222; % <<< ALTERE ESTE NÚMERO PARA UM ID VÁLIDO

% Opções para salvar as figuras
save_options.outputDir = 'Figuras_Geradas_TCC';
save_options.format = 'pdf';
save_options.resolution = 300;

%% 2. CARREGAMENTO DOS DADOS E EXECUÇÃO DA ANÁLISE
fprintf('Iniciando análise para o Transformador ID: %d\n', target_asset_id);

% Carrega os dados pré-processados
mat_file = 'Resultados_Analise_TCC.mat';
if ~exist(mat_file, 'file')
    error('Arquivo "%s" não encontrado. Execute o script principal primeiro.', mat_file);
end
load(mat_file, 'analysis_data', 'colors');
disp('Dados da análise carregados com sucesso.');

% Exibe o relatório de texto e gera os gráficos para o ativo
query_asset_status(analysis_data, target_asset_id);

fig14 = generate_figure_14_decision_quadrants(analysis_data, colors, target_asset_id);
save_figure(fig14, sprintf('14_Painel_Decisao_ATIVO_%d', target_asset_id), save_options);

fig15 = generate_figure_15_gauge_hi(analysis_data, target_asset_id);
save_figure(fig15, sprintf('15_Medidor_Saude_ATIVO_%d', target_asset_id), save_options);

fig16 = generate_figure_16_gauge_fc(analysis_data, target_asset_id);
save_figure(fig16, sprintf('16_Medidor_Consequencia_ATIVO_%d', target_asset_id), save_options);

fig17 = generate_figure_17_gauge_ri(analysis_data, target_asset_id);
save_figure(fig17, sprintf('17_Medidor_Risco_ATIVO_%d', target_asset_id), save_options);

disp('----------------------------------------------------');
fprintf('Processo concluído. Figuras salvas em: %s\n', fullfile(pwd, save_options.outputDir));

%% FUNÇÕES LOCAIS DE SUPORTE

function query_asset_status(data, asset_id_to_find)
    % Localiza o índice do ativo alvo
    idx = find(data.asset_ids == asset_id_to_find);
    if isempty(idx)
        fprintf('ERRO: ID "%s" não encontrado.\n', num2str(asset_id_to_find)); 
        return; 
    end
    idx = idx(1); % Garante que estamos usando apenas um índice
    
    % Extrai os dados do ativo
    hi_value = data.hi(idx);
    fc_value = data.fc(idx);
    ri_value = data.ri(idx);
    risk_cat = data.risk_categories(idx);
    age_value = data.age(idx);
    total_assets = length(data.asset_ids);
    
    % Calcula os rankings (valores altos = pior, logo ranking 1 é o pior)
    [~, sorted_idx_ri] = sort(data.ri, 'descend');
    rank_ri = find(sorted_idx_ri == idx);
    [~, sorted_idx_hi] = sort(data.hi, 'descend'); 
    rank_hi = find(sorted_idx_hi == idx);
    [~, sorted_idx_fc] = sort(data.fc, 'descend');
    rank_fc = find(sorted_idx_fc == idx);
    
    % Determina o quadrante de risco
    hi_thr = mean(data.hi);
    fc_thr = mean(data.fc);
    if hi_value >= hi_thr && fc_value >= fc_thr
        quadrante = 'Risco Crítico (Ação Imediata)';
    elseif hi_value < hi_thr && fc_value >= fc_thr
        quadrante = 'Risco de Consequência (Manutenção Preditiva)';
    elseif hi_value >= hi_thr && fc_value < fc_thr
        quadrante = 'Risco de Condição (Planejar Reforma)';
    else
        quadrante = 'Baixa Prioridade (Monitoramento Padrão)';
    end
    
    % Imprime o relatório de análise no console
    fprintf('\n======================================================================\n');
    fprintf('  RELATÓRIO DE ANÁLISE | ATIVO ID: %s\n', num2str(asset_id_to_find));
    fprintf('======================================================================\n');
    fprintf('\n--- 1. RESUMO ESTRATÉGICO ---\n');
    fprintf('Quadrante de Risco:      %s\n', quadrante);
    fprintf('Índice de Risco (RI):      %.2f (Categoria: %s) -> [Ranking: %dº de %d]\n', ri_value, risk_cat, rank_ri, total_assets);
    fprintf('\n--- 2. ÍNDICES DETALHADOS (Pior=1.0, Melhor=0.0) ---\n');
    fprintf('Índice de Saúde (HI):      %.2f [Ranking: %dº pior] (Média da Frota: %.2f)\n', hi_value, rank_hi, hi_thr);
    fprintf('Fator de Consequência (FC):%.2f [Ranking: %dº pior] (Média da Frota: %.2f)\n', fc_value, rank_fc, fc_thr);
    fprintf('Idade Elétrica Estimada:   %.1f%%\n', age_value);
    fprintf('\n--- 3. FATORES-CHAVE (VARIÁVEIS DE ENTRADA) ---\n');
    
    % Exibe as variáveis de entrada do Índice de Saúde
    fprintf('a) Variáveis do Índice de Saúde:\n');
    row_idx_hi = find(data.hi_table.('No.') == asset_id_to_find);
    if ~isempty(row_idx_hi)
        hi_drivers = data.hi_table(row_idx_hi(1), 2:end);
        for i = 1:width(hi_drivers)
            nome_traduzido = get_translated_name(hi_drivers.Properties.VariableNames{i});
            fprintf('   - %-35s: %g\n', nome_traduzido, hi_drivers.(i));
        end
    end
    
    % Exibe as variáveis de entrada do Fator de Consequência
    fprintf('\nb) Variáveis do Fator de Consequência:\n');
    row_idx_fc = find(data.fc_table.('No.') == asset_id_to_find);
    if ~isempty(row_idx_fc)
        fc_drivers = data.fc_table(row_idx_fc(1), 2:end);
        for i = 1:width(fc_drivers)
            nome_traduzido = get_translated_name(fc_drivers.Properties.VariableNames{i});
            fprintf('   - %-35s: %g\n', nome_traduzido, fc_drivers.(i));
        end
    end
    fprintf('======================================================================\n\n');
end

function fig = generate_figure_14_decision_quadrants(data, colors, varargin)
    fig = figure('Position', [600 200 850 700], 'Visible', 'off');
    p = inputParser; addOptional(p, 'id_to_highlight', 0, @isnumeric); parse(p, varargin{:}); 
    id_to_highlight = p.Results.id_to_highlight;
    
    hi_thr = mean(data.hi); fc_thr = mean(data.fc);
    
    scatter(data.hi, data.fc, 50, data.ri, 'filled', 'MarkerEdgeColor', '#444444', 'MarkerFaceAlpha', 0.8);
    hold on;
    
    xline(hi_thr, '--', 'Média HI', 'Color', colors.text, 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 10);
    yline(fc_thr, '--', 'Média FC', 'Color', colors.text, 'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'FontSize', 10);
    axis([0 1 0 1]);
    
    padding = 0.04;
    text(1 - padding, 1 - padding, {'Risco Crítico', 'Ação Imediata'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.critical, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    text(0 + padding, 1 - padding, {'Risco de Consequência', 'Manutenção Preditiva'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.high, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(1 - padding, 0 + padding, {'Risco de Condição', 'Planejar Reforma'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', sscanf(colors.secondary(2:end),'%2x',[1 3])/255, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
    text(0 + padding, 0 + padding, {'Baixa Prioridade', 'Monitoramento Padrão'}, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.risk.low, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    
    % Destaca o ativo selecionado
    if id_to_highlight ~= 0
        idx = find(data.asset_ids == id_to_highlight);
        if ~isempty(idx)
            idx = idx(1);
            plot(data.hi(idx), data.fc(idx), 'o', 'MarkerSize', 15, 'MarkerEdgeColor', colors.highlight, 'LineWidth', 3);
            text(data.hi(idx) + 0.02, data.fc(idx), sprintf('TR %d', id_to_highlight), 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
        end
    end
    hold off;
    
    xlabel('Índice de Saúde (HI)'); 
    ylabel('Fator de Consequência (FC)'); 
    title('Painel de Decisão Estratégica por Quadrantes de Risco');
    colormap('jet'); 
    c = colorbar; 
    c.Label.String = 'Índice de Risco (RI)';
    grid on; box on; set(gca, 'FontSize', 11);
end

function save_figure(fig_handle, base_filename, options)
    if ~exist(options.outputDir, 'dir'), mkdir(options.outputDir); end
    fullFilePath = fullfile(options.outputDir, [base_filename, '.', options.format]);
    set(fig_handle, 'Color', 'w');
    fprintf('Salvando: %s ...\n', fullFilePath);
    exportgraphics(fig_handle, fullFilePath, 'Resolution', options.resolution);
    close(fig_handle);
end

function translated_name = get_translated_name(english_name)
    % Centraliza a tradução dos nomes das variáveis
    switch english_name
        case 'Humidity [ppm]';            translated_name = 'Umidade [ppm]';
        case 'Acidity [mg KOH/g]';        translated_name = 'Acidez [mg KOH/g]';
        case 'Dielectric Strength [kV]';  translated_name = 'Rigidez Dielétrica [kV]';
        case 'Dissipation factor [%]';    translated_name = 'Fator de Dissipação [%]';
        case 'Dissolved gases [ppm]';     translated_name = 'Gases Dissolvidos [ppm]';
        case 'DP';                        translated_name = 'Grau de Polimerização (GP)';
        case 'Overload level';            translated_name = 'Nível de Sobrecarga';
        case 'Mean Load (MVA)';           translated_name = 'Carga Média (MVA)';
        case 'Critical Loads';            translated_name = 'Cargas Críticas';
        case 'Oil Volume (L)';            translated_name = 'Volume de Óleo (L)';
        case 'Proximity of other buildings (m)'; translated_name = 'Proximidade de Edifícios (m)';
        case 'Penalties (MVA)';           translated_name = 'Penalidades (MVA)';
        case 'Condicao_Corta_Chama';      translated_name = 'Condição do Corta-Chama';
        case 'Nivel_Reservatorio_Oleo';   translated_name = 'Nível do Reservatório de Óleo';
        otherwise;                        translated_name = strrep(english_name, '_', ' '); % Default
    end
end

function fig = generate_figure_15_gauge_hi(data, asset_id)
    fig = figure('Position', [200, 200, 500, 400], 'Visible', 'off', 'Color', 'w');
    ax = gca;
    hold(ax, 'on');
    idx = find(data.asset_ids == asset_id);
    if isempty(idx), close(fig); return; end
    value = data.hi(idx(1));
    
    colors = [0 159 115; 86 180 233; 240 228 66; 213 94 0; 204 51 51] / 255;
    limits = [0, 0.175, 0.425, 0.675, 0.875, 1.0]; 
    labels = {'Ótimo', 'Satisfatório', 'Moderado', 'Crítico', 'Muito Crítico'};
    
    draw_gauge(ax, value, labels, limits, colors);
    
    title(sprintf('Medidor de Saúde (HI) | Ativo ID: %d', asset_id), 'FontSize', 14);
    text(ax, 0, -0.3, sprintf('%.2f', value), 'FontSize', 36, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    ylim(ax, [-0.4, 1.3]);
    axis(ax, 'equal', 'off');
    hold(ax, 'off');
end

function fig = generate_figure_16_gauge_fc(data, asset_id)
    fig = figure('Position', [200, 200, 500, 400], 'Visible', 'off', 'Color', 'w');
    ax = gca;
    hold(ax, 'on');
    idx = find(data.asset_ids == asset_id);
    if isempty(idx), close(fig); return; end
    value = data.fc(idx(1));
    
    colors = [0 159 115; 86 180 233; 240 228 66; 213 94 0; 204 51 51] / 255;
    limits = [0, 0.175, 0.425, 0.675, 0.875, 1.0];
    labels = {'Muito Baixa', 'Baixa', 'Moderada', 'Alta', 'Crítica'};
    
    draw_gauge(ax, value, labels, limits, colors);

    title(sprintf('Medidor de Consequência (FC) | Ativo ID: %d', asset_id), 'FontSize', 14);
    text(ax, 0, -0.3, sprintf('%.2f', value), 'FontSize', 36, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    ylim(ax, [-0.4, 1.3]);
    axis(ax, 'equal', 'off');
    hold(ax, 'off');
end

function fig = generate_figure_17_gauge_ri(data, asset_id)
    fig = figure('Position', [200, 200, 500, 400], 'Visible', 'off', 'Color', 'w');
    ax = gca;
    hold(ax, 'on');
    idx = find(data.asset_ids == asset_id);
    if isempty(idx), close(fig); return; end
    value = data.ri(idx(1));
    
    colors = [0 159 115; 86 180 233; 240 228 66; 213 94 0; 204 51 51] / 255;
    limits = [0, 0.175, 0.425, 0.675, 0.875, 1.0];
    labels = {'Muito Baixo', 'Baixo', 'Moderado', 'Alto', 'Crítico'};
    
    draw_gauge(ax, value, labels, limits, colors);
    
    title(sprintf('Medidor de Risco (RI) | Ativo ID: %d', asset_id), 'FontSize', 14);
    text(ax, 0, -0.3, sprintf('%.2f', value), 'FontSize', 36, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        
    ylim(ax, [-0.4, 1.3]);
    axis(ax, 'equal', 'off');
    hold(ax, 'off');
end

function draw_gauge(ax, value, labels, limits, colors)
    % Função genérica para desenhar um medidor completo (arcos, rótulos e ponteiro)
    r_inner = 0.8;
    r_outer = 1.0;
    
    % Desenha os arcos coloridos e seus rótulos
    for i = 1:numel(labels)
        angle_start_deg = (1 - limits(i)) * 180;
        angle_end_deg = (1 - limits(i+1)) * 180;
        
        % Desenha o arco
        theta_deg = linspace(angle_end_deg, angle_start_deg, 25);
        patch(ax, [r_outer * cosd(theta_deg), r_inner * cosd(fliplr(theta_deg))], ...
                  [r_outer * sind(theta_deg), r_inner * sind(fliplr(theta_deg))], ...
                  colors(i,:), 'EdgeColor', 'none');
              
        % Adiciona rótulo da categoria
        angle_text = (angle_start_deg + angle_end_deg) / 2;
        text(ax, 1.15 * cosd(angle_text), 1.15 * sind(angle_text), labels{i}, ...
             'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    % Desenha o ponteiro
    angle_pointer_deg = (1 - value) * 180;
    pointer_coords = [0, 0; r_outer * cosd(angle_pointer_deg), r_outer * sind(angle_pointer_deg)];
    plot(ax, pointer_coords(:,1), pointer_coords(:,2), 'k-', 'LineWidth', 3);
    plot(ax, 0, 0, 'o', 'MarkerSize', 20, 'MarkerFaceColor', '#4D4D4D', 'MarkerEdgeColor', 'k');
end
