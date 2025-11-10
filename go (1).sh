#!/bin/bash
# ===================================
# go.sh — Script principal do projeto
# ===================================

# 1) Cria o ambiente Conda
# 2) Cria a estrutura do projeto
# 3) Invoca o Makefile com todos os targets


set -e
ENV_NAME="TP1_AO_GC"

echo "==============================================="
echo "[1/3] Verificação e criação do ambiente Conda"
echo "==============================================="

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



# ==========================================
# Problema do BUSCO
    # Atualizar base de dados BUSCO (odb10)
# ==========================================
hash -r

if command -v busco &> /dev/null; then
    echo "A descarregar base BUSCO: bacteria_odb10..."
    busco --download bacteria_odb10 || echo "[!] Falha ao descarregar bacteria_odb10."
    echo "A descarregar base BUSCO: fungi_odb10..."
    busco --download fungi_odb10 || echo "[!] Falha ao descarregar fungi_odb10."
    echo "A descarregar base BUSCO: eukaryota_odb10..."
    busco --download eukaryota_odb10 || echo "[!] Falha ao descarregar eukaryota_odb10."
    echo "Bases BUSCO descarregadas em ~/busco_downloads/lineages/"
else
    echo "[!] BUSCO não encontrado no ambiente. As bases odb10 não foram descarregadas."
fi



# ==========================================
# [2/3] Cria estrutura de diretórios
# ==========================================

echo ""
echo "=========================================="
echo "[2/3] Criar estrutura de diretórios"
echo "=========================================="

mkdir -p projeto/{raw_data,cleaned_data,whole_genome,comparison_results}
echo "Estrutura criada:"
tree -d projeto 2>/dev/null || find projeto -type d


# ========================
# [3/3] Invocar Makefile
# ========================
echo ""
echo "=============================="
echo "[3/3] A executar o Makefile"
echo "=============================="

make all

echo ""
echo "===================="
echo "Pipeline concluído"
echo "===================="


