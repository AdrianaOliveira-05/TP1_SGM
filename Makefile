# ===========================================================
# Makefile — Download + QC dos dados públicos
# Projeto: X. arboricola pv. juglandis (montagem e anotação)
# ===========================================================

# Raiz do projeto
PROJECT_ROOT = projeto

# Diretórios principais: dados brutos e dados limpos
RAW = $(PROJECT_ROOT)/raw_data
QC_RAW_BASE = $(PROJECT_ROOT)/qc_reports
QC_ILLUMINA = $(QC_RAW_BASE)/illumina
QC_NANOPORE = $(QC_RAW_BASE)/nanopore
QC_NANOPORE_CLEAN = $(QC_RAW_BASE)/nanopore_clean

CLEAN_NANOPORE = $(PROJECT_ROOT)/clean_nanopore
NANOPORE_TRIMMED = $(CLEAN_NANOPORE)/nanopore_trimmed.fastq.gz
NANOPORE_FILTERED = $(CLEAN_NANOPORE)/nanopore_filtered.fastq.gz

ASSEMBLY_DIR = $(PROJECT_ROOT)/whole_genome
ILLUMINA_ASSEMBLY = $(ASSEMBLY_DIR)/illumina
NANOPORE_ASSEMBLY = $(ASSEMBLY_DIR)/nanopore
NANOPORE_ASSEMBLY_CLEAN = $(ASSEMBLY_DIR)/nanopore_clean
HYBRID_ASSEMBLY_CLEAN = $(ASSEMBLY_DIR)/hybrid_clean
HYBRID_ASSEMBLY_SPADES = $(ASSEMBLY_DIR)/hybrid_spades

QC_ASSEMBLY = $(PROJECT_ROOT)/qc_assembly
QUAST = $(QC_ASSEMBLY)/quast
BUSCO =$(QC_ASSEMBLY)/busco

RESULTS_DIR = $(PROJECT_ROOT)/comparison_results
ANNOTATION_DIR = $(PROJECT_ROOT)/annotation

SUMARIO = $(RESULTS_DIR)/sumario.tsv




$(RAW):
	mkdir -p $(RAW)

$(CLEAN_NANOPORE):
	mkdir -p $(CLEAN_NANOPORE)



$(QC_RAW_BASE):
	mkdir -p $(QC_RAW_BASE)

$(QC_ILLUMINA):
	mkdir -p $(QC_ILLUMINA)

$(QC_NANOPORE):
	mkdir -p $(QC_NANOPORE)

$(QC_NANOPORE_CLEAN):
	mkdir -p $(QC_NANOPORE_CLEAN)


$(ASSEMBLY_DIR):
	mkdir -p $(ASSEMBLY_DIR)

$(ILLUMINA_ASSEMBLY):
	mkdir -p $(ILLUMINA_ASSEMBLY)

$(NANOPORE_ASSEMBLY):
	mkdir -p $(NANOPORE_ASSEMBLY)

$(NANOPORE_ASSEMBLY_CLEAN):
	mkdir -p $(NANOPORE_ASSEMBLY_CLEAN)

$(HYBRID_ASSEMBLY_CLEAN):
	 mkdir -p $(HYBRID_ASSEMBLY_CLEAN)

$(HYBRID_ASSEMBLY_SPADES):
	mkdir -p $(HYBRID_ASSEMBLY_SPADES)




$(QC_ASSEMBLY):
	mkdir -p $(QC_ASSEMBLY)

$(QUAST):
	mkdir -p $(QUAST)

$(BUSCO):
	mkdir -p $(BUSCO)


$(ANNOTATION_DIR):
	mkdir -p $(ANNOTATION_DIR)



$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)


# =========================== 
#       TARGETS
# ===========================
.PHONY: download rename_downloads qc assemble_all qc_quast qc_busco annotate

all: download qc assemble_all qc_quast qc_busco annotate


# =========================== 
#       DOWNLOADS
# ===========================
ILLUMINA_R1_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR276/001/ERR2767971/ERR2767971_1.fastq.gz
ILLUMINA_R2_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR276/001/ERR2767971/ERR2767971_2.fastq.gz
NANOPORE_URL = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/001/ERR4352271/ERR4352271_1.fastq.gz
REFERENCIA = https://www.ebi.ac.uk/ena/browser/api/fasta/GCA_903989475.2?download=true&gzip=true 


download:
	# illumina
#	cd $(RAW) && wget -nc $(ILLUMINA_R1_URL) -O illumina_R1.fastq.gz
#        cd $(RAW) && wget -nc $(ILLUMINA_R2_URL) -O illumina_R2.fastq.gz

	# nanopore
#	cd $(RAW) && wget -nc $(NANOPORE_URL) -O nanopore.fastq.gz

	# referencia
#	cd $(RAW) && wget -nc $(REFERENCIA) -O refseq.fastq.gz





# Nomes finais dos ficheiros Illumina/Nanopore/Referência
ILLUMINA_R1 = $(RAW)/illumina_R1.fastq.gz
ILLUMINA_R2 = $(RAW)/illumina_R2.fastq.gz
NANOPORE = $(RAW)/nanopore.fastq.gz

REFSEQ_GZ = $(RAW)/refseq.fasta.gz
REFSEQ     = $(RAW)/refseq.fasta

$(REFSEQ): $(REFSEQ_GZ)
	gunzip -c $(REFSEQ_GZ) > $(REFSEQ)


rename_downloads:
	cd $(RAW) && if [ -f ERR2767971_1.fastq.gz ]; then mv ERR2767971_1.fastq.gz illumina_R1.fastq.gz; fi
	cd $(RAW) && if [ -f ERR2767971_2.fastq.gz ]; then mv ERR2767971_2.fastq.gz illumina_R2.fastq.gz; fi
	cd $(RAW) && if [ -f ERR4352271_1.fastq.gz ]; then mv ERR4352271_1.fastq.gz nanopore.fastq.gz; fi
	cd $(RAW) && if [ -f GCA_903989475.2.fasta.gz ]; then mv GCA_903989475.2.fasta.gz refseq.fasta.gz; fi


# ===========================
#    LIMPEZA NANOPORE
# ===========================

nanopore_trim: $(NANOPORE) | $(CLEAN_NANOPORE)
	cutadapt \
		-a "A{30}" -g "T{30}" \
		--minimum-length 50 \
		--quality-cutoff 6 \
		$(NANOPORE) \
		-o $(NANOPORE_TRIMMED)

nanopore_filter: nanopore_trim | $(CLEAN_NANOPORE)
	gunzip -c $(NANOPORE_TRIMMED) | \
		seqtk seq -l0 - | \
		NanoFilt -q 10 --length 500 | \
		gzip > $(NANOPORE_FILTERED)

clean_nanopore: nanopore_trim nanopore_filter
	@echo ">>> Nanopore limpo criado: $(NANOPORE_FILTERED)"




# ===========================
# 	QC REPORTS	
# ===========================


qc: qc_fastqc qc_falco_raw_nanopore qc_falco_clean_nanopore qc_multiqc qc_fastq_stats_raw



# ---------------------------
# 2.1 FastQC RAW (Illumina)
# ---------------------------
qc_fastqc: $(ILLUMINA_R1) $(ILLUMINA_R2) | $(QC_ILLUMINA)
	@echo ""
	@echo ">>> [QC] FastQC — Illumina (RAW)..."
	fastqc $(ILLUMINA_R1) $(ILLUMINA_R2) \
		-o $(QC_ILLUMINA) \
		--extract \
		--threads 8


# ---------------------------
# 2.3 FALCO (Nanopore)
# ---------------------------
qc_falco_raw_nanopore: $(NANOPORE) |$(QC_NANOPORE)
	@echo ">>> [QC] Falco — Nanopore (RAW)..."
	falco $(NANOPORE) \
		--outdir $(QC_NANOPORE) \
		--threads 8
	@echo ">>> Falco RAW (Nanopore) concluído."


qc_falco_clean_nanopore: $(NANOPORE_FILTERED) | $(QC_NANOPORE_CLEAN)
	@echo ">>> [QC] Falco — Nanopore (CLEAN)..."
	falco $(NANOPORE_FILTERED) \
		--outdir $(QC_NANOPORE_CLEAN) \
		--threads 8
	@echo ">>> Falco CLEAN (Nanopore) concluído."


# ---------------------------
# 2.4 MultiQC RAW
# ---------------------------
qc_multiqc: qc_fastqc qc_falco_raw_nanopore
	@echo ""
	@echo ">>> [QC] MultiQC — consolidado RAW..."
	@if command -v multiqc >/dev/null 2>&1; then \
		multiqc $(QC_RAW_BASE) -o $(QC_RAW_BASE); \
		echo "→ MultiQC RAW em $(QC_RAW_BASE)/multiqc_raw.html"; \
	else \
		echo "[!] multiqc não encontrado — relatório RAW não gerado."; \
	fi


# ---------------------------
# 2.5 fastq_stats RAW
# ---------------------------
qc_fastq_stats_raw:
	@echo ">>> [QC] fastq_stats — RAW..."

	fastq-stats $(ILLUMINA_R1) > $(QC_ILLUMINA)/illumina_R1_raw_stats.txt
	fastq-stats $(ILLUMINA_R2) > $(QC_ILLUMINA)/illumina_R2_raw_stats.txt
	fastq-stats $(NANOPORE)    > $(QC_NANOPORE)/nanopore_raw_stats.txt
	fastq-stats $(NANOPORE_CLEAN ) > $(QC_NANOPORE_CLEAN)/nanopore_clean_stats.txt
	@echo "→ fastq_stats RAW concluído."




# =========================== 
#       MONTAGEM      
# ===========================

assemble_illumina: $(ILLUMINA_R1) $(ILLUMINA_R2) | $(ILLUMINA_ASSEMBLY)
	spades.py \
		-1 $(ILLUMINA_R1) \
		-2 $(ILLUMINA_R2) \
		-o $(ILLUMINA_ASSEMBLY) \
		--only-assembler \
		-k 21,33,55,77 \
		--threads 16


assemble_nanopore: $(NANOPORE) | $(NANOPORE_ASSEMBLY)
	flye \
		--nano-raw $(NANOPORE) \
		--out-dir $(NANOPORE_ASSEMBLY) \
		--meta \
		--genome-size 5m \
		--threads 16


assemble_nanopore_clean: $(NANOPORE_FILTERED) | $(NANOPORE_ASSEMBLY_CLEAN)
	flye \
		--nano-raw $(NANOPORE_FILTERED) \
		--out-dir $(NANOPORE_ASSEMBLY_CLEAN) \
		--meta \
		--genome-size 5m \
		--threads 16


assemble_hybrid_clean: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FILTERED) | $(HYBRID_ASSEMBLY_CLEAN)
	@echo ">>> [ASM] Montagem híbrida com Unicycler (Nanopore limpo)..."
	unicycler \
		-1 $(ILLUMINA_R1) \
		-2 $(ILLUMINA_R2) \
		-l $(NANOPORE_FILTERED) \
		-o $(HYBRID_ASSEMBLY_CLEAN) \
		--mode bold \
		--threads 16
	@echo ">>> Unicycler (Hybrid assembly usando nanopore limpo) concluído."

assemble_hybrid_spades_clean: $(ILLUMINA_R1) $(ILLUMINA_R2) $(NANOPORE_FILTERED) | $(HYBRID_ASSEMBLY_SPADES)
	spades.py \
		-1 $(ILLUMINA_R1) \
		-2 $(ILLUMINA_R2) \
		--nanopore $(NANOPORE_FILTERED) \
		-o $(HYBRID_ASSEMBLY_SPADES) \
		--only-assembler \
		-k 21, 33, 55 \
		--threads 16


assemble_all: assemble_illumina assemble_nanopore assemble_nanopore_clean assemble_hybrid_clean assemble_hybrid_spades_clean



# =========================== 
#       QUAST + BUSCO
# ===========================

#               $(HYBRID_ASSEMBLY_CLEAN)/assembly.fasta \

qc_quast: | $(QUAST)
	@echo ">>> [QC ASM] QUAST — Avaliação das montagens..."

	quast \
		$(ILLUMINA_ASSEMBLY)/contigs.fasta \
		$(NANOPORE_ASSEMBLY)/assembly.fasta \
		$(NANOPORE_ASSEMBLY_CLEAN)/assembly.fasta \
		$(HYBRID_ASSEMBLY_SPADES)/scaffolds.fasta \
		-R $(REFSEQ) \
		-o $(QUAST) \
		--threads 8

	@echo ">>> QUAST concluído."
BUSCO_DB = bacteria_odb10
BUSCO_MODE = genome

qc_busco: qc_busco_illumina qc_busco_nanopore_raw qc_busco_nanopore_clean qc_busco_hybrid_unicycler qc_busco_hybrid_spades
	@echo ">>> [QC ASM] BUSCO — todas as avaliações concluídas."


# Illumina-only
qc_busco_illumina:
	@echo ">>> [BUSCO] Illumina..."
	conda run -n BUSCO10_ENV busco \
		-i $(ILLUMINA_ASSEMBLY)/contigs.fasta \
		-l $(BUSCO_DB) \
		-o busco_illumina \
		-m $(BUSCO_MODE) \
		--out_path $(BUSCO)


# Nanopore raw
qc_busco_nanopore_raw:
	@echo ">>> [BUSCO] Nanopore RAW..."
	conda run -n BUSCO10_ENV busco \
		-i $(NANOPORE_ASSEMBLY)/assembly.fasta \
		-l $(BUSCO_DB) \
		-o busco_nanopore_raw \
		-m $(BUSCO_MODE) \
		--out_path $(BUSCO)


# Nanopore clean
qc_busco_nanopore_clean:
	@echo ">>> [BUSCO] Nanopore CLEAN..."
	conda run -n BUSCO10_ENV busco \
		-i $(NANOPORE_ASSEMBLY_CLEAN)/assembly.fasta \
		-l $(BUSCO_DB) \
		-o busco_nanopore_clean \
		-m $(BUSCO_MODE) \
		--out_path $(BUSCO)


# Hybrid Unicycler
qc_busco_hybrid_unicycler:
	@echo ">>> [BUSCO] Hybrid UNICYCLER..."
	conda run -n BUSCO10_ENV busco \
		-i $(HYBRID_ASSEMBLY_CLEAN)/assembly.fasta \
		-l $(BUSCO_DB) \
		-o busco_hybrid_unicycler \
		-m $(BUSCO_MODE) \
		--out_path $(BUSCO)


# Hybrid SPAdes
qc_busco_hybrid_spades:
	@echo ">>> [BUSCO] Hybrid SPADES..."
	conda run -n BUSCO10_ENV busco \
		-i $(HYBRID_ASSEMBLY_SPADES)/scaffolds.fasta \
		-l $(BUSCO_DB) \
		-o busco_hybrid_spades \
		-m $(BUSCO_MODE) \
		--out_path $(BUSCO)




# ===============================
#     7. ANOTAÇÃO COM PROKKA
# ===============================

annotate: annotate_illumina annotate_nanopore annotate_nanopore_clean annotate_hybrid_unicycler annotate_hybrid_spades
	@echo ">>> [PROKKA] Anotação concluída para todas as montagens."


annotate_illumina: $(ILLUMINA_ASSEMBLY)/contigs.fasta | $(ANNOTATION_DIR)
	@echo ">>> [PROKKA] Anotação — Illumina"
	prokka \
		$(ILLUMINA_ASSEMBLY)/contigs.fasta \
		--outdir $(ANNOTATION_DIR)/illumina \
		--prefix illumina \
		--locustag XAJILL \
		--cpus 8
	@echo "→ Prokka Illumina concluído."


annotate_nanopore: $(NANOPORE_ASSEMBLY)/assembly.fasta | $(ANNOTATION_DIR)
	@echo ">>> [PROKKA] Anotação — Nanopore RAW"
	prokka \
		$(NANOPORE_ASSEMBLY)/assembly.fasta \
		--outdir $(ANNOTATION_DIR)/nanopore_raw \
		--prefix nanopore_raw \
		--locustag XAJNRAW \
		--cpus 8
	@echo "→ Prokka Nanopore RAW concluído."


annotate_nanopore_clean: $(NANOPORE_ASSEMBLY_CLEAN)/assembly.fasta | $(ANNOTATION_DIR)
	@echo ">>> [PROKKA] Anotação — Nanopore CLEAN"
	prokka \
		$(NANOPORE_ASSEMBLY_CLEAN)/assembly.fasta \
		--outdir $(ANNOTATION_DIR)/nanopore_clean \
		--prefix nanopore_clean \
		--locustag XAJNCLEAN \
		--cpus 8
	@echo "→ Prokka Nanopore CLEAN concluído."


annotate_hybrid_unicycler: $(HYBRID_ASSEMBLY_CLEAN)/assembly.fasta | $(ANNOTATION_DIR)
	@echo ">>> [PROKKA] Anotação — Hybrid Unicycler"
	prokka \
		$(HYBRID_ASSEMBLY_CLEAN)/assembly.fasta \
		--outdir $(ANNOTATION_DIR)/hybrid_unicycler \
		--prefix hybrid_unicycler \
		--locustag XAJHUN \
		--cpus 8
	@echo "→ Prokka Hybrid Unicycler concluído."


annotate_hybrid_spades: $(HYBRID_ASSEMBLY_SPADES)/contigs.fasta | $(ANNOTATION_DIR)
	@echo ">>> [PROKKA] Anotação — Hybrid SPAdes"
	prokka \
		$(HYBRID_ASSEMBLY_SPADES)/contigs.fasta \
		--outdir $(ANNOTATION_DIR)/hybrid_spades \
		--prefix hybrid_spades \
		--locustag XAJHSP \
		--cpus 8
	@echo "→ Prokka Hybrid SPAdes concluído."
