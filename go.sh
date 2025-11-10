#!/bin/bash
# ====================================
# go.sh — Script principal do projeto
# ====================================

# 1) Cria o ambiente Conda e o ambiente para o BUSCO
# 2) Cria a estrutura do projeto
# 3) Invoca o Makefile com todos os targets

# "=========================================="
# "Verificação e criação dos ambientes Conda"
# "=========================================="

echo "=========================================="
echo "Verificação e criação dos ambientes Conda"
echo "=========================================="

set -e
ENV_NAME="TP1_AO_GC"

# Verifica se o conda está instalado
if ! command -v conda &> /dev/null; then
    echo "Conda não encontrado!"
    exit 1
fi

# Recriar ambiente (reprodutibilidade)
if conda info --envs | grep -q "$ENV_NAME"; then
    echo "Ambiente '$ENV_NAME' já existe. A remover..."
    conda env remove -n "$ENV_NAME" -y
fi


echo "A criar o ambiente Conda, usando o ficheiro: environment.yml ..."
conda env create -f environment.yml -y

# === Ativar Conda corretamente no script ===
eval "$($(conda info --base)/bin/conda shell.bash hook)"
conda activate "$ENV_NAME"
echo "Ambiente '$ENV_NAME' ativo."


# =========================================
# Criação do ambiente BUSCO separado (v10)
# =========================================


echo "========================================"
echo "Criação do ambiente BUSCO v10"
echo "========================================"

echo ">>> A apontar o QUAST para o BUSCO v10 (ambiente BUSCO10_ENV)..."

# Substitui o caminho conforme o local da tua instalação Miniconda:
export PATH="$HOME/miniconda3/envs/BUSCO10_ENV/bin:$PATH"

# Verifica se o BUSCO correto está a ser reconhecido
BUSCO_PATH=$(which busco)
BUSCO_VERSION=$(busco --version 2>/dev/null || echo "não encontrado")

echo "→ BUSCO usado pelo QUAST: $BUSCO_PATH"
echo "→ Versão BUSCO: $BUSCO_VERSION"

# =============================
# Cria estrutura de diretórios
# =============================

echo ""
echo "=============================="
echo "Criar estrutura de diretórios"
echo "=============================="

mkdir -p projeto/{raw_data,cleaned_data,whole_genome,comparison_results}
echo "Estrutura criada:"
tree -d projeto 2>/dev/null || find projeto -type d


# ==================
# Invocar Makefile
# ==================
echo ""
echo "======================"
echo "A executar o Makefile"
echo "======================"

make all

echo ""
echo "=============="
echo "Pipeline lido"
echo "=============="


