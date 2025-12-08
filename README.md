# TP1_SGM
# Projeto_SGM  
## Trabalho 1 — Sequenciação da bactéria *Xanthomonas arboricola* pv. *juglandis*

### Autores
- **Adriana Oliveira** — up202307136@edu.fc.up.pt  
- **Gonçalo Cruz** — up202304593@up.pt

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

├── qc_assembly/ → relatórios de qualidade das montagens

├── whole_genome/ → genomas montados

└── annotation/ → anotação


#### 5. Invocar o **`Makefile`**, que orquestra o pipeline completo (download → QC → limpeza nanopore → montagem → avaliação → anotação).

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
- **SPAdes** — montagem Illumina e Hibrida
- **Flye** — montagem Nanopore
- **Unycicler** — montagem Hibrida  

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

A execução demora alguns minutos, principalmente se os pacotes não estiverem instalados. 

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

- Durante a instalação do ambiente Conda, o QUAST tenta descarregar automaticamente as bases de dados antigas do BUSCO (odb9), que foram descontinuadas. Para resolvermos isto, adicionou-se isto no go.sh, pelo que não é preciso realizar no terminal. Se não funcionar, pode sempre fazer o mesmo no terminal.

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

#### Nanopore — *Cutadapt + NanoFilt* (única limpeza realizada)

A única etapa de limpeza efetuada no pipeline é aplicada às leituras **Nanopore**, uma vez que as leituras Illumina foram usadas tal como descarregadas (sem trimming adicional).

A limpeza Nanopore decorre em **dois passos complementares**:

1. **Cutadapt** — remoção de artefactos e extremidades ruidosas  
   Este passo elimina:
   - poliações longas (ex.: “A{30}”, “T{30}”),
   - bases de baixa qualidade,
   - fragmentos demasiado curtos.

   *Cutadapt foi escolhido em vez de Porechop* porque:
   - Porechop está descontinuado,
   - apresenta problemas de compatibilidade com versões recentes de Conda,
   - Cutadapt é atualmente a solução mais estável e suportada para trimming de Nanopore.

2. **NanoFilt** — filtragem suave por qualidade e comprimento  
   NanoFilt aplica:
   - limiar mínimo de qualidade,
   - remoção de leituras demasiado curtas,
   - normalização leve das extremidades.

   *NanoFilt foi preferido a Filtlong* porque:
   - o objetivo **não** era enriquecer para “melhores” leituras,
   - queríamos preservar a diversidade natural do conjunto de reads,
   - o foco era evitar enviesamento que pudesse comprometer a cobertura do genoma.

Os dados resultantes da limpeza são armazenados em: projeto/clean_nanopore/



---

### 4. Controlo de qualidade pós-limpeza (QC2)

Após a limpeza aplicada exclusivamente às leituras **Nanopore**, é realizado um segundo controlo de qualidade para verificar o impacto do trimming + filtragem e garantir que os dados estão prontos para montagem.

As ferramentas utilizadas foram:

- **FastQC (Illumina)**  
  Usado apenas para confirmar a integridade das leituras Illumina tal como descarregadas,  
  **não** para validar trimming (uma vez que não foi aplicada limpeza Illumina).

- **Falco (Nanopore – pós-limpeza)**  
  Permite avaliar como o processo *Cutadapt + NanoFilt* melhorou:
  - distribuição de qualidade,
  - tamanho das leituras,
  - presença de contaminantes ou artefactos.

- **fastq-stats**  
  Para métricas quantitativas simples (número de leituras, tamanho médio, N content, etc.).

- **MultiQC**  
  Gera um relatório consolidado dos resultados obtidos nas etapas anteriores.

Os relatórios do QC2 encontram-se em: projeto/qc_reports/nanopore_clean/ 





---

### 5. Montagem do genoma

O pipeline gera **cinco montagens independentes**, permitindo comparar o efeito do tipo de leitura e do pré-processamento na qualidade final do genoma reconstruído.

---

#### 1. Montagem Illumina-only — *SPAdes*

**Motivação**
- Tira partido da elevada precisão base-a-base das leituras Illumina.
- SPAdes é o montador de referência para genomas bacterianos.
- O uso de múltiplos *k-mers* melhora a resolução de regiões repetidas.

*Foi escolhido em vez de Velvet*, que se encontra obsoleto e com pior desempenho em datasets modernos.

---

#### 2. Montagem Nanopore-only (RAW) — *Flye*

**Motivação**
- Flye é optimizado para as características das leituras longas de Nanopore.
- A opção `--meta` lida bem com coberturas irregulares e estruturas genómicas complexas.
- Produz contigs mais longos e contínuos do que montadores tradicionais baseados em *k-mers*.

*Foi escolhido em vez de Canu* por ser muito mais rápido e computacionalmente eficiente.

---

#### 3. Montagem Nanopore CLEAN — *Flye*

**Objectivo**
- Avaliar o impacto da limpeza (*Cutadapt + NanoFilt*) na qualidade da montagem.
- Verificar melhorias em métricas como N50, número total de contigs e completude BUSCO.
- Comparar diretamente com a montagem Nanopore RAW, isolando o efeito da filtragem.

---

#### 4. Montagem híbrida (Unicycler — versão anterior)

A montagem híbrida com **Unicycler** combina leituras Illumina (alta precisão) com leituras Nanopore (grande continuidade), reconstruindo genomas bacterianos de forma altamente completa.  

**Características principais**
- Integra ambas as tecnologias de forma otimizada num único grafo de montagem.  
- É particularmente eficaz para genomas circulares, como muitos genomas bacterianos.  
- Resolve repetições e ligações ambíguas usando as leituras longas Nanopore como suporte.

---

#### 5. Montagem híbrida CLEAN — *SPAdes híbrido*

Esta é a **montagem híbrida principal do projeto**, a que realmente corre no pipeline.

**Motivação**
- Combina a precisão Illumina com a continuidade de Nanopore filtrado.
- SPAdes híbrido integra-se facilmente no workflow.
- Oferece scaffolds mais completos e menos fragmentados.
- Mantém consistência com o montador Illumina escolhido (SPAdes), reduzindo variabilidade metodológica.

---

As montagens são guardadas em: projeto/whole_genome/


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

Os resultados ficam em `qc_assembly/quast/` e `qc_assembly/busco/`.

---

### 7. Relatório final integrado

O Makefile gera automaticamente um ficheiro:

```
qc_assembly/summary_report.txt
```

Este relatório contém:
- resumo do QUAST,  
- resultados BUSCO das cinco montagens,  
- comparação objetiva entre abordagens.

---


### Funcionalidades específicas implementadas no projeto

Além da execução padrão das ferramentas bioinformáticas, o projeto inclui um conjunto de funcionalidades implementadas manualmente no `Makefile` que reforçam a organização, a robustez e a reprodutibilidade da análise.

#### • Criação automática e estruturada de diretórios
O Makefile cria todos os diretórios necessários antes de cada tarefa (raw, clean, QC, trimmed, filtrados, etc.).  
Isto garante que o pipeline pode ser executado num sistema vazio, sem passos manuais, reduzindo falhas por inexistência de caminhos.

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















