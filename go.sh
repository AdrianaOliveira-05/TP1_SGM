!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

BUSCO_ENV="BUSCO10_ENV"
ENV_NAME="TP1_AO_GC"

echo ""
echo "======================================"
echo " LIMPAR AMBIENTES ANTIGOS "
echo "======================================"

if conda env list | grep -qx "$BUSCO_ENV"; then
   conda env remove -n "$BUSCO_ENV" -y
fi

if conda env list | grep -qx "$ENV_NAME"; then
    conda env remove -n "$ENV_NAME" -y
fi


echo ""
echo "======================================"
echo " [A] CRIAR AMBIENTE BUSCO10_ENV "
echo "======================================"

# Verificar SSL antes de criar
echo "→ Testar acesso aos canais Conda..."
if ! conda search -c bioconda busco --info > /dev/null 2>&1; then
    echo "[!] SSL falhou — a desativar verificação"
    conda config --set ssl_verify false
    SSL_TEMP_DISABLED=true
else
    SSL_TEMP_DISABLED=false
fi

echo "→ A criar ambiente BUSCO..."
if ! conda env create -f environment_busco.yml -y; then
    echo "Primeira tentativa falhou — a limpar cache"
    conda clean -a -y
    conda env create -f environment_busco.yml -y || {
        echo "[X] ERRO a criar BUSCO_ENV"
        exit 1
    }
fi

# Reativar SSL
if [ "$SSL_TEMP_DISABLED" = true ]; then
    conda config --set ssl_verify true
fi

echo "✓ Ambiente BUSCO criado."

echo "→ Testar BUSCO..."
conda run -n "$BUSCO_ENV" busco --version || {
    echo "[!] BUSCO não funciona"
    exit 1
}

echo "→ Download das lineages..."
for odb in bacteria_odb10; do
    conda run -n "$BUSCO_ENV" busco --download $odb || echo "[Aviso] Falhou $odb"
done


echo ""
echo "======================================"
echo " [B] CRIAR AMBIENTE PRINCIPAL "
echo "======================================"

conda env remove -n "$ENV_NAME" -y 2>/dev/null
conda env create -f environment.yml -y

conda activate "$ENV_NAME"

# Injetar busco no PATH
export PATH="$HOME/miniconda3/envs/$BUSCO_ENV/bin:$PATH"
export BUSCO_DOWNLOADS="$HOME/busco_downloads"

echo "→ BUSCO em uso: $(which busco)"



echo ""
echo "======================================"
echo " EXECUTAR MAKEFILE "
echo "======================================"

make all




echo ""
echo "======================================"
echo " CRIAR sumario.tsv "
echo "======================================"

QUAST="projeto/qc_assembly/quast/report.tsv"
BUSCO_DIR="projeto/busco"
ANNOT_DIR="projeto/annotation"

OUT_SUM="sumario.tsv"

# Cabeçalho do sumário
echo -e "Parâmetro\tIllumina-only\tNanopore-only\tNanopore-limpo\tHybrid\tReferencia_Publicada" > "$OUT_SUM"


# Função para extrair valores do report.tsv pela linha e coluna
get_quast() {
    key="$1"
    col="$2"
    awk -F '\t' -v k="$key" -v c="$col" '
        $1 == k {print $c}
    ' "$QUAST"
}


##################################
# TAMANHO DO GENOMA
##################################
ILL=$(get_quast "Total length (>= 0 bp)" 2)
RAW=$(get_quast "Total length (>= 0 bp)" 3)
CLN=$(get_quast "Total length (>= 0 bp)" 4)
HSP=$(get_quast "Total length (>= 0 bp)" 5)

echo -e "Tamanho_Genoma_bp\t$ILL\t$RAW\t$CLN\t$HSP\t5228174" >> "$OUT_SUM"


##################################
# NÚMERO DE CONTIGS
##################################
ILL=$(get_quast "# contigs (>= 0 bp)" 2)
RAW=$(get_quast "# contigs (>= 0 bp)" 3)
CLN=$(get_quast "# contigs (>= 0 bp)" 4)
HSP=$(get_quast "# contigs (>= 0 bp)" 5)

echo -e "Num_Contigs\t$ILL\t$RAW\t$CLN\t$HSP\t1" >> "$OUT_SUM"


##################################
# N50
##################################
ILL=$(get_quast "N50" 2)
RAW=$(get_quast "N50" 3)
CLN=$(get_quast "N50" 4)
HSP=$(get_quast "N50" 5)

echo -e "N50_bp\t$ILL\t$RAW\t$CLN\t$HSP\t5228174" >> "$OUT_SUM"


##################################
# GC%
##################################
ILL=$(get_quast "GC (%)" 2)
RAW=$(get_quast "GC (%)" 3)
CLN=$(get_quast "GC (%)" 4)
HSP=$(get_quast "GC (%)" 5)

echo -e "GC_percent\t$ILL\t$RAW\t$CLN\t$HSP\t65.38" >> "$OUT_SUM"


##################################
# BUSCO (% completo)
##################################

extract_busco() {
    f=$1
    if [ -f "$f" ]; then
        grep "C:" "$f" 2>/dev/null | awk -F '[,:%]' '{print $2}'
    else
        echo "---"
    fi
}

# Caminhos reais (conforme as tuas pastas)
BUSCO_ILLUMINA="projeto/qc_assembly/busco/busco_illumina/short_summary.specific.bacteria_odb10.busco_illumina.txt"
BUSCO_NANO_RAW="projeto/qc_assembly/busco/busco_nanopore_raw/short_summary.specific.bacteria_odb10.busco_nanopore_raw.txt"
BUSCO_NANO_CLEAN="projeto/qc_assembly/busco/busco_nanopore_clean/short_summary.specific.bacteria_odb10.busco_nanopore_clean.txt"
BUSCO_HYBRID="projeto/qc_assembly/busco/busco_hybrid_spades/short_summary.specific.bacteria_odb10.busco_hybrid_spades.txt"


# Extrair valores (ou ---)
VAL_ILL=$(extract_busco "$BUSCO_ILLUMINA")
VAL_RAW=$(extract_busco "$BUSCO_NANO_RAW")
VAL_CLEAN=$(extract_busco "$BUSCO_NANO_CLEAN")
VAL_HYB=$(extract_busco "$BUSCO_HYBRID")

# Se algum valor vier vazio, substituir por ---
[ -z "$VAL_ILL" ] && VAL_ILL="---"
[ -z "$VAL_RAW" ] && VAL_RAW="---"
[ -z "$VAL_CLEAN" ] && VAL_CLEAN="---"
[ -z "$VAL_HYB" ] && VAL_HYB="---"

# Escrever no sumário
echo -e "BUSCO_Completo_percent\t$VAL_ILL\t$VAL_RAW\t$VAL_CLEAN\t$VAL_HYB\t99.8" >>"$OUT_SUM"

##################################
# CDS (Prokka)
##################################
ILL=$(grep -c "CDS" "$ANNOT_DIR/illumina/illumina.gff" 2>/dev/null)
RAW=$(grep -c "CDS" "$ANNOT_DIR/nanopore_raw/nanopore_raw.gff" 2>/dev/null)
CLN=$(grep -c "CDS" "$ANNOT_DIR/nanopore_clean/nanopore_clean.gff" 2>/dev/null)
HSP=$(grep -c "CDS" "$ANNOT_DIR/hybrid_spades/hybrid_spades.gff" 2>/dev/null)

echo -e "Num_CDSs\t${ILL:----}\t${RAW:----}\t${CLN:----}\t${HSP:----}\t4367" >> "$OUT_SUM"

echo "✓ sumario.tsv criado na raiz."
 
