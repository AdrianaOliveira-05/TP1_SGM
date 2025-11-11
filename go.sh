#!/bin/bash

BUSCO_ENV="BUSCO10_ENV"
ENV_NAME="TP1_AO_GC"

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
echo "[A] Criar/renovar ambiente BUSCO"
echo "=========================================="

# Remover o ambiente antigo se existir
if conda info --envs | grep -q "$BUSCO_ENV"; then
  echo "→ A remover ambiente anterior $BUSCO_ENV ..."
  conda env remove -n "$BUSCO_ENV" -y
fi

# Testar se o conda consegue aceder à internet (verifica canal bioconda)
echo "→ A verificar ligação Conda/SSL..."
if ! conda search -c bioconda busco --info > /dev/null 2>&1; then
  echo "[!] Problema de SSL ou rede detetado — a desativar verificação de certificados temporariamente"
  conda config --set ssl_verify false
  SSL_TEMP_DISABLED=true
else
  SSL_TEMP_DISABLED=false
fi

# Tentar criar o ambiente BUSCO
echo "→ A criar ambiente $BUSCO_ENV ..."
if ! conda env create -f environment_busco.yml -y; then
  echo "[!] Primeira tentativa falhou — a tentar novamente após limpar cache..."
  conda clean -a -y
  conda env create -f environment_busco.yml -y || { echo "[X] ERRO: Falha a criação do ambiente BUSCO"; exit 1; }
fi

# Reativar SSL se tiver sido desativado
if [ "$SSL_TEMP_DISABLED" = true ]; then
  echo "→ A reativar verificação SSL..."
  conda config --set ssl_verify true
fi

echo "✓ Ambiente $BUSCO_ENV criado com sucesso."


# Pré-download das lineages odb10 com o BUSCO do próprio ambiente

echo "→ A descarregar BUSCO odb10 lineages..."

# Primeiro testar se o BUSCO corre dentro do ambiente
conda run -n "$BUSCO_ENV" busco --version || { 
  echo "[!] ERRO: BUSCO não corre dentro de $BUSCO_ENV"; 
  exit 1; 
}

# Fazer o download das lineages principais (sem parar se uma falhar)
for odb in bacteria_odb10 eukaryota_odb10 fungi_odb10; do
  echo "→ Download de $odb ..."
  conda run -n "$BUSCO_ENV" busco --download $odb || echo "[!] Falha a $odb — a ignorar"
done

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
