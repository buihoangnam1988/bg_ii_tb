# Base image: continuumio/miniconda3:24.9.2-0
# OS: Debian GNU/Linux 12 (bookworm)
# Python: 3.12.7
FROM continuumio/miniconda3:24.9.2-0

RUN cat /etc/*release*
RUN apt update && apt install -y ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && apt install -y docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /home/tbpl/
# Install Nextflow: https://www.nextflow.io/docs/latest/install.html
# Part 1: Install SDKMAN and java
RUN apt update && apt install -y zip unzip git wget && \
    # Install SDKMAN
    /usr/bin/bash -c "curl -s https://get.sdkman.io | bash" && \
    # Install Java 17.0.10-tem
    /usr/bin/bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.10-tem" && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Part 2: Install Nextflow
ENV PATH="${PATH}:/root/.sdkman/candidates/java/17.0.10-tem/bin/"
RUN /usr/bin/bash -c "curl -s https://get.nextflow.io | bash && chmod +x nextflow && mv nextflow /usr/bin" 

# Create new environment
ENV TBPL_ENV_NAME=tbpl
RUN conda create --name ${TBPL_ENV_NAME} python=3.10

# Install python packages
# Install busco
RUN git clone https://gitlab.com/ezlab/busco.git && cd busco && conda run -n ${TBPL_ENV_NAME} python -m pip install . && cd /home/tbpl/ && rm -rf busco

# Install FastQC
RUN mkdir tools && cd tools && wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && chmod +x FastQC/fastqc && ln -s /home/tbpl/tools/FastQC/fastqc /usr/local/bin/fastqc && rm fastqc_v0.11.9.zip

# Install Trimmomatic
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip && \
unzip Trimmomatic-0.39.zip && rm Trimmomatic-0.39.zip && \
mv Trimmomatic-0.39/trimmomatic-0.39.jar /usr/local/bin/trimmomatic.jar && rm -rf Trimmomatic-0.39

# Install snippy, checkm-genome, raxml-ng, tb-profiler
RUN conda run -n ${TBPL_ENV_NAME} pip install snippy checkm-genome && \
    conda run -n ${TBPL_ENV_NAME} conda install -c conda-forge libgcc-ng libzlib && \
    conda run -n ${TBPL_ENV_NAME} conda install -c bioconda raxml-ng tb-profiler && \
    # Clean conda & R temp files
    conda clean --all && rm -Rf /temp/*

# Install anvio8
# Install conda packages
RUN conda run -n ${TBPL_ENV_NAME} conda install -c conda-forge -c bioconda sqlite prodigal idba mcl muscle=3.8.1551 famsa hmmer diamond \
    blast megahit spades bowtie2 bwa graphviz "samtools>=1.9" trimal iqtree trnascan-se fasttree vmatch r-base r-tidyverse \
    r-optparse r-stringi r-magrittr bioconductor-qvalue meme ghostscript nodejs && \
    # Clean conda & R temp files
    conda clean --all && rm -Rf /temp/*
# Install gcc
RUN apt update && apt install gcc -y && apt-get clean && rm -rf /var/lib/apt/lists/*
# Install anvio
RUN curl -L https://github.com/merenlab/anvio/releases/download/v8/anvio-8.tar.gz --output anvio-8.tar.gz && \
    conda run -n ${TBPL_ENV_NAME} pip install anvio-8.tar.gz && rm anvio-8.tar.gz && \
    # Clean conda & R temp files
    conda clean --all && rm -Rf /temp/*

# Install multiqc
RUN conda run -n ${TBPL_ENV_NAME} conda install -c bioconda multiqc mlst && \
    conda run -n ${TBPL_ENV_NAME} pip install docopt && \
    apt update && apt install -y libtiff-dev && cd /usr/lib/x86_64-linux-gnu/ && ln -s libtiff.so.6 libtiff.so.5 && \
    # Clean conda & R temp files
    conda clean --all && rm -Rf /temp/* && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Bacannot pipeline
RUN echo $PATH > /home/tbpl/path1.txt
RUN conda run -n ${TBPL_ENV_NAME} nextflow pull fmalmeida/bacannot
RUN echo $PATH > /home/tbpl/path2.txt
ENV PATH="${PATH}:/root/.nextflow/assets/fmalmeida/bacannot/bin"
RUN echo $PATH > /home/tbpl/path3.txt