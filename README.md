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

#### 1. Criar o ambiente Conda chamado **`TP1_AO_GC`** (Trabalho Prático 1 — Adriana Oliveira e Gonçalo Cruz) e o ambiente **`BUSCO10_ENV`** (criado para as incompatibilidades do BUSCO com as outras ferramentas)/
#### 2. Instalar automaticamente todas as ferramentas necessárias como: FastQC (QC), SPAdes/Flye/Unicycler (Montadores), QUAST/BUSCO (Avaliação), Prokka (Anotação).
#### 3. Corrige certos problemas na instalação.
#### 4. Criar a estrutura de diretórios do projeto, nomeadamente:

projeto/

├── raw_data/ → dados originais (Illumina e Nanopore)

├── clean_nanopore/ → dados nanopore limpos

├── qc_reports/ → relatórios de qualidade após QC (Quality Control)

├── assembly_qc/ → relatórios de qualidade das montagens

├── whole_genome/ → genomas montados

└── annotation/ → anotação


#### 5. Invocar o **`Makefile`**, que orquestra o pipeline completo (download → QC → limpeza nanopore → montagem → avaliação2 → anotação).

---

### Ferramentas utilizadas

As ferramentas bioinformáticas utilizadas no projeto são geridas pelo **Conda** e definidas no ficheiro `environment.yml`.  
Foram organizadas em dois ambientes: **TP1_AO_GC** (pipeline principal) e **BUSCO10_ENV** (compatibilidade com bases de dados BUSCO).

#### **Ambiente TP1_AO_GC**

##### **Base**
- `python=3.10` — linguagem base  
- `pip` — gestor de pacotes Python  
- `make` — orquestração do pipeline  
- `wget`, `unzip` — descarregamento e extração de arquivos  

##### **Controlo de Qualidade (QC)**
- **FastQC** — controlo de qualidade das leituras brutas  
- **MultiQC** — integração e sumarização de relatórios QC  
- **ea-utils** — manipulação de ficheiros FASTQ  
- **fastp** — filtragem e trimming das leituras  
- **cutadapt** — remoção de adaptadores  
- `seqtk=1.4` — utilitários FASTA/FASTQ  
- `nanofilt=2.8` — filtragem de leituras Nanopore  
- `falco=1.2.1` — avaliação de qualidade Nanopore  

##### **Montagem**
- **SPAdes** — montagem Illumina  
- **Flye** — montagem Nanopore  

##### **Polishing**
- `bwa=0.7.17` — alinhamento das leituras Illumina  
- `samtools=1.17` — manipulação de SAM/BAM  
- `openjdk=11` — requisito para o Pilon  
- **Pilon** — correção de erros após a montagem  

##### **Avaliação da Montagem**
- **QUAST** — métricas e relatórios das montagens  

##### **Anotação**
- **Prokka** — anotação automática do genoma  
 

---

#### **Ambiente BUSCO10_ENV**

Criado separadamente devido a incompatibilidades de versões:

- `busco=5.7.1` — avaliação de completude do genoma  
- `python=3.10`


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
  

---

### Reprodutibilidade da análise

Toda a análise do projeto pode ser integralmente reproduzida executando apenas o comando:

```bash
./go.sh
```

Este script cria os ambientes Conda necessários, instala todas as ferramentas definidas em `environment.yml`, gera a estrutura de diretórios e invoca automaticamente o **Makefile**, que coordena cada etapa do pipeline. Abaixo descreve-se, de forma clara e justificada, o que acontece em cada fase e porque foram escolhidas estas abordagens.

---

### 1. Download dos dados públicos

O pipeline começa por descarregar automaticamente os dados Illumina (paired-end) e Nanopore, bem como o genoma de referência.  
A escolha por **dados reais do ENA** assegura reprodutibilidade universal: qualquer utilizador pode repetir o processo a partir das mesmas fontes controladas.

---

### 2. Controlo de qualidade dos dados brutos (QC1)

São aplicados vários métodos complementares:

- **FastQC** para Illumina  
  *Escolha justificada:* FastQC é o padrão na avaliação de sequenciação curta, fornece métricas essenciais (qualidade por posição, conteúdo de GC, duplicação, overrepresented sequences).  
  *Alternativas como o fastp-QC ou ngsQC não foram escolhidas* por serem menos interpretáveis no contexto académico do projeto.

- **Falco** para Nanopore  
  *Escolha justificada:* Falco é específico para leituras longas e permite identificar rapidamente problemas estruturais (indels, distribuição de comprimentos).  
  *Foi escolhido em vez de NanoPlot*, que gera visualizações mais complexas mas menos úteis para inspeção rápida.

- **MultiQC**  
  Consolida relatórios múltiplos, facilitando a leitura e comparação entre linhas.

- **fastq-stats**  
  Acrescenta métricas adicionais muito leves e rápidas.

Os relatórios são guardados em `qc_reports/raw/`.

---

### 3. Limpeza e filtragem das leituras

#### Illumina — *fastp*
Utilizamos **fastp** para limpeza (trimming, correção de erros e remoção de adaptadores).  
*Foi escolhido em vez de Trimmomatic*, porque:
- é mais rápido e multithreaded,
- produz relatórios HTML integrados,
- integra deteção automática de adaptadores,
- aplica correção de erros para paired-end.

#### Nanopore — *Cutadapt + NanoFilt*
A limpeza Nanopore é dividida em dois passos:

1. **Cutadapt** remove artefactos, poliações e bases erradas no início/fim das leituras.  
   *Foi escolhido em vez de Porechop*, que está descontinuado e incompatível com versões recentes do Conda.

2. **NanoFilt** aplica uma filtragem suave por qualidade e comprimento.  
   *Foi escolhido em vez de Filtlong*, porque o objetivo do projeto não era enriquecer para melhores reads, mas sim manter a representação completa do genoma.

Os dados limpos são guardados em `cleaned_data/`.

---

### 4. Controlo de qualidade pós-limpeza (QC2)

Repetimos o QC para confirmar a melhoria obtida:

- FastQC para Illumina (validação do trimming)
- Falco para Nanopore
- fastq-stats para métricas quantitativas
- MultiQC para relatório consolidado

Estas análises encontram-se em `qc_reports/clean/`.

---

### 5. Montagem do genoma

O pipeline produz **três montagens independentes** — cada uma escolhida por motivos técnicos distintos:

1. **Illumina-only (SPAdes)**  
   - Excelente fidelidade base-a-base (alta qualidade Illumina).  
   - SPAdes é particularmente robusto para pequenas bactérias.  
   *Foi escolhido em vez de Velvet*, que está obsoleto e tem pior desempenho em datasets modernos.

2. **Nanopore-only (Flye)**  
   - Ideal para leituras longas e coberturas variáveis.  
   - Capaz de gerar contigs mais contínuos.  
   *Foi escolhido em vez de Canu*, que tem tempos de execução significativamente maiores.

3. **Montagem híbrida (SPAdes híbrido)**  
   - Combina a precisão Illumina com a continuidade Nanopore.  
   - Tende a produzir scaffolds melhores do que qualquer montagem isolada.  
   *Foi escolhido em vez de Unicycler*, que também é excelente, mas o enunciado sugere SPAdes como montador principal.

As montagens são guardadas em `whole_genome/`.

---

### 6. Avaliação das montagens

Para garantir rigor na comparação entre métodos, são utilizadas duas métricas complementares:

#### **QUAST — avaliação estrutural**
- calcula N50, número de contigs, extensão total, erros de alinhamento, etc.
- permite comparação direta entre Illumina, Nanopore e híbrido.  
*Foi escolhido em vez de MetaQUAST*, porque estamos a montar uma única bactéria, não um metagenoma.

#### **BUSCO — completude genética**
- avalia a percentagem de genes conservados no conjunto *bacteria_odb10*.  
*Foi escolhido em vez de CheckM*, que exige workflows mais pesados e destinam-se mais a metagenomas ou múltiplos bins.

Os resultados ficam em `assembly_qc/quast/` e `assembly_qc/busco/`.

---

### 7. Relatório final integrado

O Makefile gera automaticamente um ficheiro:

```
assembly_qc/summary_report.txt
```

Este relatório contém:
- resumo do QUAST,  
- resultados BUSCO das três montagens,  
- comparação objetiva entre abordagens.

---


### Funcionalidades específicas implementadas no projeto

Além da execução padrão das ferramentas bioinformáticas, o projeto inclui um conjunto de funcionalidades implementadas manualmente no `Makefile` que reforçam a organização, a robustez e a reprodutibilidade da análise.

#### • Criação automática e estruturada de diretórios
O Makefile cria todos os diretórios necessários antes de cada tarefa (raw, clean, QC, trimmed, filtrados, etc.).  
Isto garante que o pipeline pode ser executado num sistema vazio, sem passos manuais, reduzindo falhas por inexistência de caminhos.

#### • Limpeza Illumina otimizada (fastp executado apenas uma vez)
A limpeza paired-end é feita com uma única chamada a `fastp`, que gera simultaneamente os ficheiros limpos R1 e R2 e os relatórios associados.  
Foi ainda implementada uma regra "falsa" para impedir a execução duplicada do fastp, garantindo eficiência e consistência entre os pares.

#### • Pipeline Nanopore em duas etapas complementares: Cutadapt → NanoFilt
A limpeza das leituras longas foi separada em dois passos distintos:
- **Cutadapt** remove caudas, poliações e artefactos frequentes em Nanopore.  
- **NanoFilt** aplica filtragem suave baseada em qualidade e comprimento.  

Esta abordagem modular dá mais controlo sobre o processo e evita filtragens demasiado agressivas, mantendo a representação do genoma.

#### • Controlo de qualidade completo antes e depois da limpeza
O pipeline inclui dois níveis de QC:
- **QC1 (raw):** FastQC, Falco, fastq-stats, MultiQC  
- **QC2 (cleaned):** FastQC, Falco, fastq-stats, MultiQC  

Ao separar QC inicial e final, o utilizador consegue verificar objetivamente o impacto da limpeza e validar a melhoria real da qualidade das leituras.

#### • Integração de métricas complementares através de ferramentas diferentes
A utilização simultânea de FastQC, Falco, fastq-stats e MultiQC foi programada de forma coordenada.  
Isto fornece:
- métricas visuais e estatísticas,  
- comparação entre Illumina e Nanopore,  
- integração automática de relatórios,  
- separação clara entre dados brutos e limpos.

#### • Ambiente BUSCO isolado para garantir estabilidade
Devido a incompatibilidades frequentes na instalação do BUSCO, o pipeline cria e utiliza um ambiente Conda exclusivo (`BUSCO10_ENV`), assegurando que a ferramenta funciona independentemente das restantes dependências do projeto.

Estas funcionalidades tornam o pipeline mais estável, reprodutível e acessível a qualquer utilizador, sem necessidade de configuração manual adicional.


---



### Conclusão

Executar `./go.sh` permite reproduzir **todo o pipeline**, desde o download dos dados, QC, limpeza e montagem, até à avaliação e criação do relatório final.  
A escolha de cada ferramenta foi deliberada, tendo em conta:
- compatibilidade com o tipo de dados,  
- robustez dos resultados,  
- eficiência computacional,  
- práticas atuais em bioinformática.

Desta forma, o projeto garante **reprodutibilidade total**, transparência e fundamentação técnica em todas as decisões.















