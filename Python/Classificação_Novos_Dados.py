import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score
# Importante: A biblioteca imbalanced-learn já deve estar instalada.
from imblearn.over_sampling import SMOTE
import matplotlib.pyplot as plt
import seaborn as sns
import os
import warnings

# Ignora avisos para uma saída mais limpa
warnings.simplefilter(action='ignore', category=FutureWarning)

# --- 1. CONFIGURAÇÃO DE CAMINHOS DINÂMICOS ---
# O caminho base é definido como o diretório onde o script está localizado
caminho_base = os.path.dirname(os.path.abspath(__file__))

# Dicionário para definir os pares de arquivos (real vs. sintético) a serem processados
datasets_to_process = {
    'FC': {
        'real': 'Dados Fis FC.csv',
        'synthetic': 'Dados_FC_Sinteticos_Final.csv'
    },
    'HI': {
        'real': 'Dados Fis HI.csv',
        'synthetic': 'Dados_HI_Sinteticos_Final.csv'
    }
}

# --- 2. FUNÇÕES AUXILIARES ---

def load_data(file_path):
    """Carrega um arquivo CSV, tratando possíveis erros."""
    if not os.path.exists(file_path):
        print(f"ERRO: Arquivo não encontrado em '{file_path}'. Pulando.")
        return None
    try:
        return pd.read_csv(file_path)
    except Exception as e:
        print(f"ERRO: Falha ao ler o arquivo '{file_path}'. Erro: {e}")
        return None

def preprocess_dataframe(df):
    """Prepara o DataFrame removendo colunas não numéricas e a coluna 'No.'."""
    df_copy = df.copy()
    if 'No.' in df_copy.columns:
        df_copy = df_copy.drop(columns=['No.'])
    return df_copy.select_dtypes(include=np.number)

# --- 3. LOOP PRINCIPAL DE PROCESSAMENTO ---

for dataset_name, files in datasets_to_process.items():
    print(f"\n{'='*20} Processando Conjunto de Dados: {dataset_name} {'='*20}")

    # Constrói os caminhos completos dos arquivos usando o caminho base dinâmico
    real_file_path = os.path.join(caminho_base, files['real'])
    sint_file_path = os.path.join(caminho_base, files['synthetic'])

    # Carrega os dados reais e sintéticos
    df_real = load_data(real_file_path)
    df_sint = load_data(sint_file_path)

    if df_real is None or df_sint is None:
        continue

    # Pré-processa os dataframes
    df_real_proc = preprocess_dataframe(df_real)
    df_sint_proc = preprocess_dataframe(df_sint)

    # Garante que ambos os dataframes tenham as mesmas colunas para a análise
    common_cols = list(set(df_real_proc.columns) & set(df_sint_proc.columns))
    df_real_proc = df_real_proc[common_cols]
    df_sint_proc = df_sint_proc[common_cols]
    print(f"Analisando {len(common_cols)} colunas em comum.")

    # Cria os rótulos (0 para real, 1 para sintético)
    df_real_proc['label'] = 0
    df_sint_proc['label'] = 1

    # Junta os dados em um único dataframe
    df_total = pd.concat([df_real_proc, df_sint_proc], ignore_index=True, sort=False)

    # Preenche valores nulos com a média da coluna, se houver
    if df_total.isnull().sum().sum() > 0:
        print("Atenção: Valores nulos detectados. Preenchendo com a média da coluna.")
        df_total = df_total.fillna(df_total.mean())

    # Separa as features (X) e o alvo (y)
    X = df_total.drop(columns=['label'])
    y = df_total['label']

    # Divide em treino e teste (estratificado para manter a proporção de classes)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.3, random_state=42, stratify=y
    )

    # Aplica a técnica de oversampling SMOTE apenas nos dados de TREINO para evitar vazamento de dados
    print(f"Distribuição original de classes no treino: \n{y_train.value_counts().to_string()}")
    smote = SMOTE(random_state=42)
    X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)
    print(f"\nDistribuição de classes após SMOTE: \n{y_train_resampled.value_counts().to_string()}")
    
    # Treina o classificador RandomForest com os dados de treino balanceados
    clf = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
    clf.fit(X_train_resampled, y_train_resampled)

    # Faz previsões no conjunto de teste original
    y_pred = clf.predict(X_test)
    y_proba = clf.predict_proba(X_test)[:, 1]

    # --- APRESENTAÇÃO DOS RESULTADOS ---
    print(f"\n--- Relatório de Classificação Final: {dataset_name} ---")
    print(classification_report(y_test, y_pred, target_names=['Real', 'Sintético']))
    
    auc_score = roc_auc_score(y_test, y_proba)
    print(f"--> Pontuação AUC ROC: {auc_score:.4f}")
    
    # Interpretação da qualidade dos dados sintéticos com base na pontuação AUC
    distance_from_half = abs(auc_score - 0.5)
    if distance_from_half < 0.15: # AUC entre 0.35 e 0.65
        print("--> Interpretação: Excelente! O modelo tem dificuldade em distinguir os dados, sugerindo alta qualidade dos dados sintéticos.")
    elif distance_from_half < 0.25: # AUC entre 0.25-0.35 ou 0.65-0.75
        print("--> Interpretação: Bom. Os dados são muito semelhantes, embora o modelo tenha alguma capacidade de distingui-los.")
    else: # AUC < 0.25 ou > 0.75
        print("--> Interpretação: Atenção. O modelo consegue distinguir os dados, indicando que podem não ser uma boa imitação dos reais.")

    # Plota a importância das features para o modelo
    feat_importances = pd.Series(clf.feature_importances_, index=X.columns).sort_values(ascending=False)
    
    plt.figure(figsize=(12, 8))
    sns.barplot(x=feat_importances.values, y=feat_importances.index, palette='viridis', hue=feat_importances.index, legend=False, dodge=False)
    plt.title(f'Importância das Features ({dataset_name}) para Distinguir Real vs. Sintético', fontsize=16)
    plt.xlabel('Nível de Importância', fontsize=12)
    plt.ylabel('Feature', fontsize=12)
    plt.tight_layout()
    
    # Salva o gráfico no mesmo diretório do script
    plot_path = os.path.join(caminho_base, f'importancia_features_{dataset_name}.png')
    plt.savefig(plot_path)
    print(f"--> Gráfico de importância salvo em: {plot_path}")
    plt.close()

print(f"\n{'='*25} Análise Final Concluída {'='*25}")
