import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import unicodedata
import warnings

# Ignora avisos para uma saída mais limpa
warnings.simplefilter(action='ignore', category=FutureWarning)

# --- 1. CONFIGURAÇÃO DE CORES E CAMINHOS DINÂMICOS ---
cor_primaria = '#003366'  # Azul UNIFEI
cor_texto = '#000000'    # Preto

# O caminho base é definido como o diretório onde o script está localizado
caminho_base = os.path.dirname(os.path.abspath(__file__))
caminho_visualizacoes = os.path.join(caminho_base, 'visualizacoes')
os.makedirs(caminho_visualizacoes, exist_ok=True)

# Nomes dos arquivos que devem estar na mesma pasta do script
arquivo_dados_fc = 'Dados Fis FC.csv'
arquivo_dados_hi = 'Dados Fis HI.csv'
caminho_dados_fc = os.path.join(caminho_base, arquivo_dados_fc)
caminho_dados_hi = os.path.join(caminho_base, arquivo_dados_hi)

# --- 2. FUNÇÃO PARA CARREGAR E PREPARAR OS DADOS ---
def carregar_arquivo_csv(caminho, nome_arquivo):
    """Carrega um arquivo CSV, remove colunas desnecessárias e trata erros."""
    try:
        dados = pd.read_csv(caminho)
        # Remove colunas 'Unnamed' que podem ser criadas pelo pandas
        dados = dados.loc[:, ~dados.columns.str.contains('^Unnamed')]
        # Remove a coluna de índice 'No.' se ela existir
        if 'No.' in dados.columns:
            dados = dados.drop(columns=['No.'])
        print(f"✓ Arquivo '{nome_arquivo}' carregado com sucesso.")
        return dados
    except FileNotFoundError:
        print(f"✗ ERRO: O arquivo '{nome_arquivo}' não foi encontrado em '{caminho_base}'.")
        return None
    except Exception as e:
        print(f"✗ ERRO ao ler '{nome_arquivo}': {e}")
        return None

# Carrega os datasets
dados_fc = carregar_arquivo_csv(caminho_dados_fc, arquivo_dados_fc)
dados_hi = carregar_arquivo_csv(caminho_dados_hi, arquivo_dados_hi)

# --- 3. MAPEAMENTO DE NOMES DE COLUNAS PARA PORTUGUÊS ---
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
    'Dissipation factor  [%]': 'Fator de Dissipação [%]', # Corrigido espaço duplo
    'Dissolved gases [ppm]': 'Gases Dissolvidos [ppm]',
    'DP': 'Grau de Polimerização',
    'HI': 'Índice de Integridade'
}

# --- 4. FUNÇÕES PARA GERAR GRÁFICOS ---
def normalizar_nome_arquivo(texto):
    """Remove acentos e caracteres especiais para criar um nome de arquivo seguro."""
    sem_acentos = ''.join(c for c in unicodedata.normalize('NFD', texto) if unicodedata.category(c) != 'Mn')
    return sem_acentos.lower().replace('[','').replace(']','').replace('%','').replace('/','').replace(' ','_')

def gerar_graficos_individuais(df, nome_dataset, caminho_saida):
    """Gera e salva histogramas e boxplots para cada coluna do dataframe."""
    if df is None:
        print(f"\n--- Geração de gráficos para '{nome_dataset}' pulada (dados não carregados).")
        return

    print(f"\n--- Gerando gráficos individuais para o dataset: {nome_dataset} ---")
    
    for col in df.columns:
        dados_coluna = df[col].dropna()
        if dados_coluna.empty:
            continue

        nome_exibicao = mapa_traducao.get(col, col)
        nome_seguro = normalizar_nome_arquivo(nome_exibicao)

        # --- Histograma ---
        plt.figure(figsize=(6, 4), constrained_layout=True)
        sns.histplot(dados_coluna, kde=True, bins=20, color=cor_primaria)
        plt.xlabel(nome_exibicao, color=cor_texto)
        plt.ylabel('Frequência', color=cor_texto)
        caminho_hist = os.path.join(caminho_saida, f'{nome_dataset.lower()}_hist_{nome_seguro}.png')
        plt.savefig(caminho_hist, format='png', dpi=300)
        plt.close()

        # --- Boxplot ---
        plt.figure(figsize=(6, 4), constrained_layout=True)
        sns.boxplot(y=dados_coluna, color=cor_primaria)
        plt.ylabel(nome_exibicao, color=cor_texto)
        caminho_box = os.path.join(caminho_saida, f'{nome_dataset.lower()}_box_{nome_seguro}.png')
        plt.savefig(caminho_box, format='png', dpi=300)
        plt.close()

        print(f" ✓ Gráficos para '{nome_exibicao}' salvos.")

# --- 5. EXECUÇÃO ---
gerar_graficos_individuais(dados_fc, 'FC', caminho_visualizacoes)
gerar_graficos_individuais(dados_hi, 'HI', caminho_visualizacoes)

print(f"\n--- Processo finalizado. Figuras salvas em: '{caminho_visualizacoes}' ---")
