
# Análise de Risco em Transformadores de Potência com Geração de Dados Sintéticos

Este repositório integra duas abordagens complementares para análise de risco em transformadores de energia. A estrutura está dividida em duas pastas principais:

- **/Python/**: Contém scripts para geração e validação de dados sintéticos utilizando a biblioteca SDV (Synthetic Data Vault).
- **/matlab/**: Contém scripts para análise de risco com lógica fuzzy, cálculo do Índice de Saúde (HI), Fator de Consequência (FC) e Índice de Risco (RI).

---

## Fluxo de Trabalho Geral

1. **Geração de Dados Sintéticos (Python)**  
   Os scripts em `/python` realizam a análise dos dados originais, geração de novos dados sintéticos com SDV, e validações (estatísticas e por classificação) para garantir que os dados simulados sejam confiáveis.

2. **Análise de Risco (MATLAB)**  
   Após a geração dos dados sintéticos, os arquivos resultantes (em `.csv`) são utilizados pelos scripts na pasta `/matlab`. Esses scripts aplicam lógica fuzzy para avaliar o risco de cada ativo da frota de transformadores.

---

## Estrutura do Repositório

```
/mirafel/Analise-Risco-Ativos
├── /python/
│   ├── Analise_Dados_Originais.py
│   ├── Geração_Dados_SDV.py
│   ├── Classificação_Novos_Dados.py
│   └── Validação_Novos_Dados.py   
│
├── /matlab/
│   ├── Cenario_BR.m
│   └── Analise_Ativo_Especifico.m
└── README.md
```

---

## Pré-requisitos

- Python 3.x com bibliotecas: `pandas`, `numpy`, `matplotlib`, `seaborn`, `sdv`, `torch`, `scikit-learn`, `imbalanced-learn`, `scipy`.
- MATLAB R2024a (ou equivalente) com suporte à lógica fuzzy.

---

Este repositório foi desenvolvido com o objetivo de apoiar a modelagem e análise de risco de ativos do setor elétrico, aliando geração de dados sintéticos e inteligência computacional.
