import pandas as pd
import os
import numpy as np
import torch
# Importante: As bibliotecas sdv e torch já devem estar instaladas.
from sdv.single_table import CTGANSynthesizer
from sdv.metadata import SingleTableMetadata
import warnings

# Ignora avisos comuns da SDV para uma saída mais limpa
warnings.filterwarnings("ignore", message="The 'SingleTableMetadata' is deprecated.*")
warnings.filterwarnings("ignore", message="We strongly recommend saving the metadata.*")

# --- Define a seed para reprodutibilidade dos resultados ---
np.random.seed(42)
if torch.cuda.is_available():
    torch.cuda.manual_seed_all(42)
torch.manual_seed(42)


# --- 1. CONFIGURAÇÃO DE CAMINHOS DINÂMICOS ---
# O caminho base é definido como o diretório onde o script está localizado.
caminho_base = os.path.dirname(os.path.abspath(__file__))

# Nomes dos arquivos de entrada (devem estar na mesma pasta do script)
fc_original_path = os.path.join(caminho_base, 'Dados Fis FC.csv')
hi_original_path = os.path.join(caminho_base, 'Dados Fis HI.csv')

# Nomes dos arquivos de saída que serão gerados na mesma pasta
fc_synthetic_path = os.path.join(caminho_base, 'Dados_FC_Sinteticos_Final.csv')
hi_synthetic_path = os.path.join(caminho_base, 'Dados_HI_Sinteticos_Final.csv')


# --- 2. FUNÇÃO PARA GERAR DADOS SINTÉTICOS ---

def generate_synthetic_data(synthesizer_class, original_file_path, output_file_path, num_rows=215, **kwargs):
    """
    Carrega dados reais, aprende a estrutura com um sintetizador da SDV e gera dados sintéticos.
    """
    dataset_name = os.path.basename(original_file_path)
    model_name = synthesizer_class.__name__
    print(f"\n{'='*20} Processando: {dataset_name} com {model_name} {'='*20}")

    try:
        # Carrega e limpa os dados originais
        real_data = pd.read_csv(original_file_path)
        real_data = real_data.loc[:, ~real_data.columns.str.contains('^Unnamed')]
        print(f"Dados reais carregados com {real_data.shape[0]} linhas e {real_data.shape[1]} colunas.")

        # Lógica para adicionar colunas extras ao dataset FC, se aplicável
        if 'FC' in dataset_name:
            print("Adicionando features extras ao dataset FC original com lógica aprimorada...")
            
            # Identifica as colunas de features existentes (excluindo 'No.')
            feature_cols = [col for col in real_data.columns if col != 'No.']
            
            if len(feature_cols) > 0:
                # Normaliza as features para a escala [0, 1] para combiná-las
                normalized_features = real_data[feature_cols].apply(lambda x: (x - x.min()) / (x.max() - x.min()) if x.max() > x.min() else 0)

                # Cria um "fator de degradação" baseado na média das features normalizadas.
                # Valores mais altos nas features indicam uma condição pior.
                degradation_factor = normalized_features.mean(axis=1)

                # Gera 'Condicao_Corta_Chama' com base na degradação.
                condicao_base = 1.0 - (degradation_factor * 0.8) # Degradação máxima (1.0) -> condição 0.2
                ruido_condicao = np.random.uniform(-0.05, 0.05, size=len(real_data))
                real_data['Condicao_Corta_Chama'] = np.round(np.clip(condicao_base + ruido_condicao, 0.0, 1.0), 2)

                # Gera 'Nivel_Reservatorio_Oleo' com base na degradação.
                nivel_base = 100 - (degradation_factor * 70) # Degradação máxima (1.0) -> nível 30
                ruido_nivel = np.random.uniform(-5, 5, size=len(real_data))
                real_data['Nivel_Reservatorio_Oleo'] = np.round(np.clip(nivel_base + ruido_nivel, 10, 100), 1)
                
                print(f"Novas features lógicas adicionadas. O shape para treino agora é: {real_data.shape}")
            else:
                print("Nenhuma feature encontrada para basear a lógica. Pulando adição de colunas.")

        # Detecção automática de metadados pela SDV
        metadata = SingleTableMetadata()
        metadata.detect_from_dataframe(data=real_data)
        
        # Define a coluna 'No.' como um identificador, se existir
        if 'No.' in real_data.columns:
            metadata.update_column(column_name='No.', sdtype='id')
        
        # Inicialização do Modelo (Sintetizador)
        synthesizer = synthesizer_class(metadata, **kwargs)
        
        print("Iniciando o treinamento do modelo... (Isso pode levar alguns minutos)")
        synthesizer.fit(real_data)
        print("Treinamento concluído.")

        # Geração dos Dados Sintéticos
        print(f"Gerando {num_rows} novas linhas sintéticas...")
        synthetic_data = synthesizer.sample(num_rows=num_rows) 
        print("Geração de dados sintéticos concluída.")

        # Salvando os dados gerados em um arquivo CSV
        synthetic_data.to_csv(output_file_path, index=False, encoding='utf-8-sig')
        print(f"-> Arquivo sintético salvo com sucesso em: '{output_file_path}'")
        
        return synthetic_data

    except FileNotFoundError:
        print(f"ERRO: Arquivo original não encontrado em '{original_file_path}'. Pulando.")
        return None
    except Exception as e:
        print(f"Ocorreu um erro inesperado durante o processamento de {dataset_name}: {e}")
        return None


# --- 3. EXECUÇÃO PRINCIPAL ---

# Usando CTGAN para ambos os datasets com 1000 épocas para melhor qualidade.
generate_synthetic_data(
    synthesizer_class=CTGANSynthesizer,
    original_file_path=fc_original_path,
    output_file_path=fc_synthetic_path,
    epochs=1000
)

generate_synthetic_data(
    synthesizer_class=CTGANSynthesizer,
    original_file_path=hi_original_path,
    output_file_path=hi_synthetic_path,
    epochs=1000
)

print("\n--- Processo de Geração Finalizado ---")
