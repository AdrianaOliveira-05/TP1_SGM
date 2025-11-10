# ================================================
# Makefile — Etapa 1: Download dos dados públicos
# ================================================
# Este ficheiro descarrega os ficheiros FASTQ e o genoma de referência
# e guarda tudo dentro de projeto/raw_data/



# Diretório de destino
RAW = projeto/raw_data
QC = projeto/cleaned_data/qc_reports

# Links dos dados
ILLUMINA_R1 = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR276/001/ERR2767971/ERR2767971_1.fastq.gz
ILLUMINA_R2 = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR276/001/ERR2767971/ERR2767971_2.fastq.gz
NANOPORE = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/001/ERR4352271/ERR4352271_1.fastq.gz
REF = https://www.ebi.ac.uk/ena/browser/api/fasta/GCA_903989475.1?download=true



# =====================
# 	Target principal
# =====================

all: download qc



# ==========================================================================================
#  DOWNLOAD — descarregar dados Illumina, Nanopore e referência e guarda na pasta raw_data
# ==========================================================================================

download:
	@echo ">>> [1/3] A descarregar ficheiros Illumina..."
	mkdir -p $(RAW)
	cd $(RAW) && curl -L -O $(ILLUMINA_R1) && curl -L -O $(ILLUMINA_R2)

	@echo ">>> [2/3] A descarregar ficheiro Nanopore..."
	cd $(RAW) && curl -L -O $(NANOPORE)

	@echo ">>> [3/3] A descarregar genoma de referência..."
	cd $(RAW) && curl -L -o reference_genome.fna.gz "$(REF)"

	@echo ""
	@echo "------------------------------------------"
	@echo "Todos os ficheiros foram descarregados para $(RAW)/"
	@ls -lh $(RAW)
	@echo "------------------------------------------"


# ==================================================
# QC — Controlo de Qualidade dos ficheiros FASTQ
# ==================================================

qc:
	@echo "=================================================="
	@echo ">>> [QC] Iniciar controlo de qualidade — Etapa 1"
	@echo "=================================================="
	mkdir -p $(QC)

	@echo ""
	@echo ">>> [1/3] Validação da integridade dos dados (fastq_utils)..."
	@if command -v fastq_utils >/dev/null 2>&1; then \
		fastq_utils check $(RAW)/*.fastq.gz > $(QC)/fastq_utils_check.log 2>&1; \
		echo "→ Relatório guardado em $(QC)/fastq_utils_check.log"; \
	else \
		echo '[!] fastq_utils não encontrado — a saltar esta verificação.'; \
	fi

	@echo ""
	@echo ">>> [2/3] Diagnóstico de qualidade (FastQC)..."
	@if ls $(RAW)/*.fastq.gz 1> /dev/null 2>&1; then \
		fastqc $(RAW)/*.fastq.gz -o $(QC) --extract; \
		echo "→ Relatórios FastQC criados em $(QC)/"; \
	else \
		echo '[!] Nenhum ficheiro FASTQ encontrado em $(RAW)/'; \
	fi

	@echo ""
	@echo ">>> [3/3] Relatório consolidado (MultiQC)..."
	@if [ -d $(QC) ]; then \
		multiqc $(QC) -o $(QC); \
		echo "→ Relatório MultiQC criado em $(QC)/multiqc_report.html"; \
	else \
		echo '[!] Pasta $(QC) não encontrada.'; \
	fi

	@echo ""
	@echo "=================================================="
	@echo "Relatórios de QC disponíveis em: $(QC)/"
	@ls -lh $(QC) || true
	@echo "=================================================="
