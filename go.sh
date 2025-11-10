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
echo "[Extra] Criação do ambiente BUSCO v10"
echo "========================================"

BUSCO_ENV="BUSCO10_ENV"

if conda info --envs | grep -q "$BUSCO_ENV"; then
    echo "Ambiente '$BUSCO_ENV' já existe. A remover..."
    conda env remove -n "$BUSCO_ENV" -y
fi

echo "A criar ambiente '$BUSCO_ENV'..."
conda env create -f environment_busco.yml -y


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


