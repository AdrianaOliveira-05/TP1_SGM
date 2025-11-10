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
echo "[A] Criar/renovar ambiente BUSCO v10"
echo "=========================================="
# (re)criar BUSCO10_ENV
if conda info --envs | grep -q "^$BUSCO_ENV "; then
  conda env remove -n "$BUSCO_ENV" -y
fi
conda env create -f environment_busco.yml -y

# Pré-download das lineages odb10 com o BUSCO do próprio ambiente
echo "→ A descarregar BUSCO odb10 lineages (bacteria, eukaryota, fungi)..."
conda run -n "$BUSCO_ENV" busco --version || fail "busco não corre dentro de $BUSCO_ENV"
conda run -n "$BUSCO_ENV" busco --download bacteria_odb10 || echo "[!] Falha a bacteria_odb10"
conda run -n "$BUSCO_ENV" busco --download eukaryota_odb10 || echo "[!] Falha a eukaryota_odb10"
conda run -n "$BUSCO_ENV" busco --download fungi_odb10 || echo "[!] Falha a fungi_odb10"

# Caminho onde o BUSCO guarda por defeito
BUSCO_DL_DIR="$HOME/busco_downloads/lineages"
echo "→ Lineages (se existirem) em: $BUSCO_DL_DIR"

echo ""
echo "=========================================="
echo "[B] Criar/renovar ambiente principal"
echo "=========================================="
# (re)criar principal
if conda info --envs | grep -q "^$ENV_NAME "; then
  conda env remove -n "$ENV_NAME" -y
fi
conda env create -f environment.yml -y

# Ativar principal
conda activate "$ENV_NAME"
echo "→ Ambiente principal ativo: $ENV_NAME"

# >>> FORÇAR quast a usar o busco v10 do outro ambiente
export PATH="$HOME/miniconda3/envs/$BUSCO_ENV/bin:$PATH"
# (opcional) indicar ao BUSCO onde estão os downloads (algumas instalações respeitam esta var)
export BUSCO_DOWNLOADS="$HOME/busco_downloads"

echo "→ which busco: $(which busco)"
echo "→ busco --version:"
busco --version || echo "[!] busco não acessível no PATH"






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


