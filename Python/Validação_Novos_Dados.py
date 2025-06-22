import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import os

# --- 1. CONFIGURAÇÃO DE PALETA DE CORES E CAMINHOS ---
cor_primaria = '#003366'  # Azul UNIFEI
cor_texto = '#000000'  # Preto

# --- CAMINHOS DINÂMICOS ---

caminho_base = os.path.dirname(os.path.abspath(__file__))

# O diretório para as visualizações será criado dentro do caminho base.
caminho_visualizacoes = os.path.join(caminho_base, 'visualizacoes_pt')
os.makedirs(caminho_visualizacoes, exist_ok=True)

# Os caminhos dos arquivos de dados apontam para o mesmo diretório do script.
caminho_dados_fc = os.path.join(caminho_base, 'Dados_FC_Sinteticos_Final.csv')
caminho_dados_hi = os.path.join(caminho_base, 'Dados_HI_Sinteticos_Final.csv')

# --- 2. CARREGAMENTO E LIMPEZA DOS DADOS ---
try:
    # Remove espaços em branco dos nomes das colunas ao carregar
    dados_fc = pd.read_csv(caminho_dados_fc).rename(columns=lambda x: x.strip())
    dados_hi = pd.read_csv(caminho_dados_hi).rename(columns=lambda x: x.strip())
    print("Arquivos de dados sintéticos finais carregados com sucesso.")
    print(f"Dados carregados de: {caminho_base}")
except FileNotFoundError as e:
    print(f"Erro: Arquivo não encontrado. Verifique se os arquivos CSV estão na mesma pasta do script. Detalhes: {e}")
    exit()

# --- 3. FUNÇÃO DE ANÁLISE E VISUALIZAÇÃO ---
def analisar_e_salvar_plots_individuais(df, nome_dataset, caminho_viz):
    """
    Gera e salva cada gráfico de distribuição como um arquivo PDF separado.
    """
    print(f"\n--- Gerando gráficos individuais para: {nome_dataset} ---")

    # Remove a coluna 'No.' se ela existir, para não gerar gráfico para ela
    if 'No.' in df.columns:
        df_caracteristicas = df.drop(columns=['No.'])
    else:
        df_caracteristicas = df.copy()

    # Mapa para traduzir os nomes das colunas para os gráficos
    mapa_traducao = {
        'Overload level': 'Nível de Sobrecarga',
        'Mean Load (MVA)': 'Carga Média (MVA)',
        'Critical Loads': 'Cargas Críticas',
        'Oil Volume (L)': 'Volume de Óleo (L)',
        'Proximity of other buildings (m)': 'Proximidade de Edifícios (m)',
        'Penalties (MVA)': 'Penalidades (MVA)',
        'Nivel_Reservatorio_Oleo': 'Nível do Reservatório de Óleo',
        'Condicao_Corta_Chama': 'Condição do Corta-Chama',
        'Humidity [ppm]': 'Umidade [ppm]',
        'Acidity [mg KOH/g]': 'Acidez [mg KOH/g]',
        'Dielectric Strength [kV]': 'Rigidez Dielétrica [kV]',
        'Dissipation factor  [%]': 'Fator de Dissipação [%]', 
        'Dissolved gases [ppm]': 'Gases Dissolvidos [ppm]',
        'DP': 'Grau de Polimerização',
        'HI': 'Índice de Integridade'
    }
    
    # Renomeia as colunas para usar nos plots
    df_caracteristicas_renamed = df_caracteristicas.rename(columns=mapa_traducao)

    for col_original in df_caracteristicas.columns:
        # Verifica se a coluna tem uma tradução correspondente
        if col_original in mapa_traducao:
            col_traduzida = mapa_traducao[col_original]
            
            plt.figure(figsize=(6, 4))
            sns.histplot(df_caracteristicas[col_original], kde=True, bins=20, color=cor_primaria)
            
            # plt.title(f'Distribuição de {col_traduzida}', color=cor_texto)
            
            plt.xlabel(col_traduzida)
            plt.ylabel('Frequência')
            plt.tight_layout()
            
            # Cria um nome de arquivo seguro para evitar erros
            nome_arquivo_seguro = col_original.replace('[','').replace(']','').replace('%','').replace('/','').split(" ")[0].lower()
            nome_arquivo_plot = f'dist_{nome_dataset.lower()}_{nome_arquivo_seguro}.pdf'
            caminho_plot = os.path.join(caminho_viz, nome_arquivo_plot)
            
            plt.savefig(caminho_plot, format='pdf', bbox_inches='tight')
            plt.close()
            print(f" → Gráfico salvo em: {caminho_plot}")

# --- 4. EXECUÇÃO DA ANÁLISE ---
analisar_e_salvar_plots_individuais(dados_fc, 'FC_Final', caminho_visualizacoes)
analisar_e_salvar_plots_individuais(dados_hi, 'HI_Final', caminho_visualizacoes)

print(f"\n--- Geração de gráficos individuais concluída ---")
print(f"Todos os arquivos .pdf foram salvos em: {caminho_visualizacoes}")
