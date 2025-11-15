# ===========================================================
# Makefile — Download + QC dos dados públicos
# Projeto: X. arboricola pv. juglandis (montagem e anotação)
# ===========================================================

# Raiz do projeto
PROJECT_ROOT = projeto

# Diretórios principais
RAW = $(PROJECT_ROOT)/raw_data
QC  = $(PROJECT_ROOT)/cleaned_data/qc_reports

# -----------------------------------------------------------
# Dados públicos
# -----------------------------------------------------------
# Experimentos (IDs do enunciado)
ILLUMINA_EXPERIMENT = ERX2788812
NANOPORE_EXPERIMENT = ERX4286810

# Runs usados (ERX -> ERR)
ILLUMINA_RUN  = ERR2776735          # ERX2788812 → ERR2776735
NANOPORE_RUN  = ERR4352271         # ERX4286810 → ERR4352271 (MinION)


# URLs - Illumina (paired-end)
ILLUMINA_R1_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR277/005/ERR2776735/ERR2776735_1.fastq.gz
ILLUMINA_R2_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR277/005/ERR2776735/ERR2776735_2.fastq.gz

# URL - Nanopore
NANOPORE_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/001/ERR4352271/ERR4352271_1.fastq.gz

# Genoma de referência
REF_ACCESSION = GCA_903989475.2
REF_URL = https://www.ebi.ac.uk/ena/browser/api/fasta/GCA_903989475.2?download=true&gzip=true

# Caminhos locais esperados
ILLUMINA_R1 = $(RAW)/$(ILLUMINA_RUN)_1.fastq.gz
ILLUMINA_R2 = $(RAW)/$(ILLUMINA_RUN)_2.fastq.gz
NANOPORE_FASTQ = $(RAW)/$(NANOPORE_RUN)_1.fastq.gz
REF_FASTA = $(RAW)/$(REF_ACCESSION)_reference.fna.gz

# ---------
# Targets 
# ---------

.PHONY: all download qc clean
all: download qc

# --------------------------
# 1. DOWNLOAD DOS DADOS
# --------------------------

$(RAW):
	mkdir -p $(RAW)

# Illumina R1
$(ILLUMINA_R1): | $(RAW)
	cd $(RAW) && curl -L -O $(ILLUMINA_R1_URL)

# Illumina R2
$(ILLUMINA_R2): | $(RAW)
	cd $(RAW) && curl -L -O $(ILLUMINA_R2_URL)

# Nanopore
$(NANOPORE_FASTQ): | $(RAW)
	cd $(RAW) && curl -L -O $(NANOPORE_URL)

# Genoma de referência 
$(REF_FASTA): | $(RAW)
	cd $(RAW) && curl -L -O $@ "$(REF_URL)"
	
download: $(ILLUMINA_R1) $(ILLIMINA_R2) $(NANOPORE_FASTQ) $(REF_FASTA)
	@echo ""
	@echo "------------------------------------------"
	@echo"DOWNLOAD CONCLUIDO - ficheiros em: $(RAW)"
	@ls -lh $(RAW)
	@echo "------------------------------------------"
	@echo ""
	
	

# --------------------------
# 2) QC DOS DADOS BRUTOS
# --------------------------

$(QC):
	mkdir -p $(QC)/illumina $(QC)/nanopore


# 2.1 fastq_utils
qc_fastq_utils: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FASTQ) | $(QC)
	@echo ""
	@echo ">>> [QC] Verificação de integridade com fastq_utils..."
	@if command -v fastq_utils >/dev/null 2>&1; then \
		fastq_utils check $(RAW)/*.fastq.gz > $(QC)/fastq_utils_check.log 2>&1; \
		echo "→ Relatório fastq_utils guardado em $(QC)/fastq_utils_check.log"; \
	else \
		echo "[!] fastq_utils não encontrado — a saltar esta etapa."; \
	fi

# 2.2 FastQC (Illumina + Nanopore)
qc_fastqc: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FASTQ) | $(QC)
	@echo ""
	@echo ">>> [QC] FastQC — Illumina..."
	@if command -v fastqc >/dev/null 2>&1; then \
		fastqc $(ILLUMINA_R1) $(ILLUMINA_R2) -o $(QC)/illumina --extract; \
		echo "→ Relatórios FastQC (Illumina) em $(QC)/illumina"; \
		echo ">>> [QC] FastQC — Nanopore..."; \
		fastqc $(NANOPORE_FASTQ) -o $(QC)/nanopore --extract; \
		echo "→ Relatórios FastQC (Nanopore) em $(QC)/nanopore"; \
	else \
		echo "[!] fastqc não encontrado — a saltar esta etapa."; \
	fi

# 2.3 Relatório global com MultiQC
qc_multiqc: | $(QC)
	@echo ""
	@echo ">>> [QC] MultiQC — relatório consolidado..."
	@if command -v multiqc >/dev/null 2>&1; then \
		multiqc $(QC) -o $(QC); \
		echo "→ Relatório MultiQC criado em $(QC)/multiqc_report.html"; \
	else \
		echo "[!] multiqc não encontrado — sem relatório consolidado."; \
	fi


# -----------
# Limpeza
# -----------

clean:
	rm -rf $(RAW) $(QC)
	@echo "Diretórios $(RAW) e $(QC) removidos."
