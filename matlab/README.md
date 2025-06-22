# Análise de Risco de Ativos com Lógica Fuzzy em MATLAB

## Visão Geral

Este projeto consiste em um conjunto de scripts MATLAB para realizar a análise de risco de uma frota de transformadores, utilizando lógica fuzzy para calcular:

- Índice de Saúde (HI)  
- Fator de Consequência (FC)  
- Índice de Risco (RI)  

A análise é dividida em duas etapas principais:
1. Análise geral de toda a frota
2. Análise detalhada de um ativo específico

---

## Scripts do Projeto

### 1. `Cenario_BR.m` — Script Principal

Executa a análise completa da frota.

**Funcionalidades:**
- Carrega dados brutos (.csv) e arquivos de lógica fuzzy (.fis)
- Calcula HI, Idade Elétrica, FC e RI para todos os ativos
- Gera gráficos analíticos: heatmaps, distribuições, matriz de risco, Pareto, superfícies fuzzy
- Salva os resultados em `Resultados_Analise_TCC.mat`

---

### 2. `Analise_Ativo_Especifico.m` — Análise Individual

Analisa em detalhe um ativo específico (via ID).

**Funcionalidades:**
- Carrega `Resultados_Analise_TCC.mat`
- Gera relatório no console com índices, ranking e fatores críticos
- Cria gráficos específicos (painel de decisão e medidores de HI, FC, RI)
- Salva visualizações em `Figuras_Geradas_TCC/`

---

## Como Usar

### 1. Preparar Ambiente

Certifique-se de que os seguintes arquivos estão no mesmo diretório:

- `Cenario_BR.m`  
- `Analise_Ativo_Especifico.m`  
- Arquivos de dados (.csv)  
- Arquivos FIS (.fis)  
- Pasta `draggable/`

### 2. Executar a Análise Geral

Abra e execute o script `Cenario_BR.m`.  
> *Este passo é obrigatório para gerar o arquivo `.mat` usado na próxima etapa.*

### 3. Executar a Análise Específica

- Abra `Analise_Ativo_Especifico.m`
- Defina o ID do transformador em `target_asset_id`
- Execute o script. O relatório será exibido no console, e os gráficos serão salvos automaticamente.

---

## Requisitos e Compatibilidade

- **Versão testada:** MATLAB R2024a  
- **Observações:** Algumas funções (ex: `exportgraphics`) podem não funcionar corretamente em versões mais antigas do MATLAB.

---

## Contato

Dúvidas sobre o código, metodologia ou execução podem ser direcionadas ao autor.
