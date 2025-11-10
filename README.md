# TP1_SGM
# Projeto_SGM  
## Trabalho 1 — Sequenciação da bactéria *Xanthomonas arboricola* pv. *juglandis*

### Autores
- **Adriana Oliveira**
- **Gonçalo Cruz**

### Descrição
Este repositório contém o primeiro trabalho prático da unidade curricular de Sequenciação de Genomas e Metagenómica (SGM).  
O objetivo é realizar o processo de **sequenciação, montagem e anotação genómica** da bactéria *Xanthomonas arboricola* pv. *juglandis*, de forma reprodutível e automatizada através de scripts e ferramentas de bioinformática.

---

### Estrutura e Planeamento
Para preparar o ambiente de trabalho, foi desenvolvido o script **`go.sh`**, que funciona como o **ponto de entrada principal** do projeto.  
Este script é responsável por:

#### 1. Criar o ambiente Conda chamado **`TP1_ao_gc`** (Trabalho Prático 1 — Adriana Oliveira e Gonçalo Cruz) e o ambiente **`BUSCO10_ENV`** (criado para as incompatibilidades do BUSCO com as outras ferramentas)/
#### 2. Instalar automaticamente todas as ferramentas necessárias como: FastQC (QC), SPAdes/Flye/Unicycler (Montadores), QUAST/BUSCO (Avaliação), Prokka (Anotação).
#### 3. Corrige certos problemas na instalação.
#### 4. Criar a estrutura de diretórios do projeto, nomeadamente:

projeto/

├── raw_data/ → dados originais (Illumina e Nanopore)

├── cleaned_data/ → dados após controlo de qualidade

├── whole_genome/ → genomas montados

└── comparison_results/ → resultados de comparação e anotação


#### 5. Invocar o **`Makefile`**, que orquestra o pipeline completo (download → QC → avaliação1 → montagem → avaliação2 → anotação → sumário final).

---

### Ferramentas utilizadas
As ferramentas bioinformáticas são geridas pelo Conda e defininas no ficheiro `environment.yml`. 

Incluem:
- **FastQC** e **MultiQC** — controlo de qualidade das leituras  
- **SPAdes**, **Flye**, **Unicycler** — montagem Illumina, Nanopore e híbrida  
- **QUAST** e **BUSCO** — avaliação de qualidade das montagens  
- **Prokka** — anotação do genoma  
- **wget** e **unzip** — descarregamento e manipulação de ficheiros  
- **make** — orquestração do pipeline  

---

### Reprodutibilidade
O pipeline é automatizado. A execução do script go.sh garante que o ambiente é recriado de raiz e que os passos são feitos ordenadamente. Todos estes dados serão guardados dentro da pasta projeto.


---

### Como executar

A execução demorara alguns minutos, principalmente se os pacotes não estiverem instalados. 

1. Dar permissão de execução ao script:
```bash
chmod +x go.sh
```
2. Correr o pipeline completo:
```bash
./go.sh
```

- Possível Problema caso o BUSCO não tenha a atualização correta:
        ERROR! Failed downloading bacteria database (url: https://busco-archive.ezlab.org/v3/datasets/bacteria_odb9.tar.gz),
        QUAST functionality will be limited! Exception caught: HTTP Error 404: Not Found

- Durante a instalação do ambiente Conda, o QUAST tenta descarregar automaticamente as bases de dados antigas do BUSCO (odb9), que foram descontinuadas. Para resolvermos isto, adicionou-se isto no go.sh, pelo que não é preciso realizar no temrinal. Se não funcionar, pode sempre fazer o mesmo no terminal.

```bash
conda activate TP1_AO_GC

busco --download bacteria_odb10
busco --download fungi_odb10
busco --download eukaryota_odb10

```
- Durante a criação do ambiente Conda, o OpenMPI emite um aviso relacionado com suporte CUDA (“Open MPI is built with CUDA awareness…”).
- Este aviso é inofensivo, pois as ferramentas utilizadas (FastQC, SPAdes, QUAST, BUSCO, Prokka) não utilizam processamento gráfico (GPU).
- A mensagem pode ser ignorada sem impacto na execução do pipeline.
  
















