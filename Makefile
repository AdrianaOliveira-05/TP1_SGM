# ===========================================================
# Makefile — Download + QC dos dados públicos
# Projeto: X. arboricola pv. juglandis (montagem e anotação)
# ===========================================================

# Raiz do projeto
PROJECT_ROOT = TP1_AO_GC

# Diretórios principais
RAW = $(PROJECT_ROOT)/raw_data
QC  = $(PROJECT_ROOT)/cleaned_data/qc_reports

# -----------------------------------------------------------
# Dados públicos
# -----------------------------------------------------------
# Experimentos (IDs do enunciado)
ILLUMINA_EXPERIMENT  = ERX2788812
NANOPORE_EXPERIMENT  = ERX4286810

# Runs usados (ERX -> ERR, conforme ENA)
ILLUMINA_RUN   = ERR2776735          # ERX2788812 → ERR2776735
NANOPORE_RUN   = ERR4352271         # ERX4286810 → ERR4352271 (MinION)

# URLs dos ficheiros FASTQ
ILLUMINA_R1_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR277/005/ERR2776735/ERR2776735_1.fastq.gz
ILLUMINA_R2_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR277/005/ERR2776735/ERR2776735_2.fastq.gz
NANOPORE_URL    = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/001/ERR4352271/ERR4352271_1.fastq.gz

# Caminhos locais esperados
ILLUMINA_R1     = $(RAW)/$(ILLUMINA_RUN)_1.fastq.gz
ILLUMINA_R2     = $(RAW)/$(ILLUMINA_RUN)_2.fastq.gz
NANOPORE_FASTQ  = $(RAW)/$(NANOPORE_RUN)_1.fastq.gz

# Genoma de referência (Unicycler, Illumina + MinION)
REF_ACCESSION   = GCA_903989475.2
REF_URL         = https://www.ebi.ac.uk/ena/browser/api/fasta/GCA_903989475.2?download=true&gzip=true
REF_FASTA       = $(RAW)/$(REF_ACCESSION)_reference.fna.gz

# -----------------------------------------------------------
# Targets "lógicos"
# -----------------------------------------------------------

.PHONY: all download qc qc_fastq_utils qc_fastqc qc_multiqc clean

# Target principal: download + QC dos dados brutos
all: download qc

# --------------------------
# 1) DOWNLOAD DOS DADOS
# --------------------------

download: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FASTQ) $(REF_FASTA)
	@echo ""
	@echo "------------------------------------------"
	@echo "Todos os ficheiros foram descarregados para $(RAW)/"
	@ls -lh $(RAW)
	@echo "------------------------------------------"

$(RAW):
	mkdir -p $(RAW)

# Illumina R1
$(ILLUMINA_R1): | $(RAW)
	cd $(RAW) && curl -L -O $(ILLUMINA_R1_URL)

# Illumina R2
$(ILLUMINA_R2): | $(RAW)
	cd $(RAW) && curl -L -O $(ILLUMINA_R2_URL)

# Nanopore (MinION)
$(NANOPORE_FASTQ): | $(RAW)
	cd $(RAW) && curl -L -O $(NANOPORE_URL)

# Genoma de referência (já comprimido em .gz)
$(REF_FASTA): | $(RAW)
	curl -L "$(REF_URL)" -o "$@"

# --------------------------
# 2) QC DOS DADOS BRUTOS
# --------------------------

qc: qc_fastq_utils qc_fastqc qc_multiqc

$(QC):
	mkdir -p $(QC)/illumina $(QC)/nanopore

# 2.1) Verificação de integridade com fastq_utils
qc_fastq_utils: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FASTQ) | $(QC)
	@echo ""
	@echo ">>> [QC] Verificação de integridade com fastq_utils..."
	@if command -v fastq_utils >/dev/null 2>&1; then \
		fastq_utils check $(RAW)/*.fastq.gz > $(QC)/fastq_utils_check.log 2>&1; \
		echo "→ Relatório fastq_utils guardado em $(QC)/fastq_utils_check.log"; \
	else \
		echo "[!] fastq_utils não encontrado — a saltar esta etapa."; \
	fi

# 2.2) FastQC separado para Illumina e Nanopore
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

# 2.3) Relatório global com MultiQC
qc_multiqc: | $(QC)
	@echo ""
	@echo ">>> [QC] MultiQC — relatório consolidado..."
	@if command -v multiqc >/dev/null 2>&1; then \
		multiqc $(QC) -o $(QC); \
		echo "→ Relatório MultiQC criado em $(QC)/multiqc_report.html"; \
	else \
		echo "[!] multiqc não encontrado — sem relatório consolidado."; \
	fi

# Limpar tudo (cuidado!)
clean:
	rm -rf $(RAW) $(QC)
	@echo "Diretórios $(RAW) e $(QC) removidos."

