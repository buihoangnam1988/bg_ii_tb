# Run FastQC ==========================================================================================================
mkdir -p /home/tbpl/output/01_QC/preqc
fastqc -o /home/tbpl/output/01_QC/preqc /home/tbpl/input/*.fastq.gz
# Run MultiQC
cd /home/tbpl/output/01_QC/preqc && multiqc .

# Run trimmomatic (Dr Michael will prepare) =============================================================================
mkdir -p /home/tbpl/output/01_QC/postqc
export INPDIR=/home/tbpl/input
export OUTDIR=/home/tbpl/output/01_QC/postqc
declare -a SAMPLES=( "29" )
for i in "${SAMPLES[@]}"; do 
    echo "Processing sample $i";
    mkdir $OUTDIR/$i/;
    trimmomatic PE -threads 48 -phred33 -trimlog $OUTDIR/${i}/${i}_trim.log $INPDIR/${i}_R1_paired.fastq.gz $INPDIR/${i}_R2_paired.fastq.gz $OUTDIR/${i}/${i}_R1_trimmed_paired.fastq.gz $OUTDIR/${i}/${i}_R2_trimmed_paired.fastq.gz $OUTDIR/${i}/${i}_R1_trimmed_unpaired.fastq.gz $OUTDIR/${i}/${i}_R2_trimmed_unpaired.fastq.gz \
    ILLUMINACLIP:/home/tbpl/omicsdata/adapters/Aviti.fa:2:30:10 LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:15 MINLEN:36;
done;

for i in "${SAMPLES[@]}"; do echo $i; done;

# Run Bacannot pipeline ===============================================================================================
# Prepare the samplesheet.yaml
# samplesheets:
#   - id: sample_1
#     illumina:
#       - /home/tbpl/input/29_R1_paired.fastq.gz
#       - /home/tbpl/input/29_R2_paired.fastq.gz

# Pull bacannot pipeline, stored in /root/.nextflow/assets/fmalmeida/bacannot
nextflow pull fmalmeida/bacannot
# Allow calling .py script directly for bacannot pipelines
#export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
# Pull Zenodo database (Prebuilt)
#nextflow run fmalmeida/bacannot --get_zenodo_db --output /home/tbpl/omicsdata/zenodo/ -profile docker
# Build my own database
cd /home/tbpl/output
nextflow run fmalmeida/bacannot --get_dbs --output bacannot_dbs -profile docker
# Process files
# Note:
# 1. The input files are stored in /home/tbpl/input/
# 2. The output files are stored in /home/tbpl/output/
# 3. The zenodo database files are stored in /home/tbpl/omicsdata/zenodo/
# 4. Nextflow pipelines are stored in /root/.nextflow/assets/
#     * fmalmeida/bacannot
# 5. Static files are stored in /home/tbpl/static/
# 6. The pipeline is stored in /home/tbpl/pipeline/
#     * 00_init.sh
# 7. Base folder for Nextflow execution should be the output folder /home/tbpl/output/

#export BACANOTDB=/home/tbpl/omicsdata/zenodo/bacannot_dbs_2024_jul_05 # Zenodo
export BACANOTDB=/home/tbpl/output/bacannot_dbs
#export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
# Run Bacannot pipeline
# For running
nextflow run fmalmeida/bacannot --input /home/tbpl/output/samplesheet.yaml --output /home/tbpl/output/2_Assembly --bacannot_db $BACANOTDB --resfinder_species "Mycobacterium tuberculosis" --max_cpus 10 -profile docker

# Resume Bacannot pipeline
# Fix 'command not found' error: https://github.com/nextflow-io/nextflow/discussions/4783
# * Method 1: export NXF_VER=21.10.6 before running the pipeline: --> does not work,
#             new error: Nextflow version 21.10.6 does not match workflow required version: >=22.10.1
#             Note 1: This is runnable      NXF_VER=21.10.6 nextflow run ...
#             Note 2: This is not           nextflow run -v 21.10.6 ...
#             Note 3: If you change the nextflow running session, old session will be lost, you cannot resume it
# * Method 2: Since nextflow=22.08.0-edge it requires to set conda.enabled = true in your nextflow.config
#             Note 1: I did this            nano /root/.nextflow/assets/fmalmeida/bacannot/nextflow.config
#nextflow run fmalmeida/bacannot --input /home/tbpl/output/samplesheet.yaml --output /home/tbpl/output/2_Assembly --bacannot_db $BACANOTDB --resfinder_species "Mycobacterium tuberculosis" --max_cpus 10 -profile docker -resume

# Run BUSCO ===============================================================================
nextflow pull metashot/busco
export INPDIR=/home/tbpl/output/2_Assembly
export OUTDIR=/home/tbpl/output/2_Assembly
declare -a SAMPLES=( "29" "31" )
for i in "${SAMPLES[@]}"; do 
    echo "Processing BUSCO for sample $i"
    nextflow run metashot/busco --genomes $INPDIR/${i}/assembly/assembly.fasta --outdir $OUTDIR/${i}/assembly/${i}.busco
done;

# Run CHECKM ==============================================================================
# Note: -x [fasta/faa/fa/fna]
#       * There must be prepared data, downloaded at https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
#         Saved path: /home/tbpl/omicsdata/checkm_db
#         Load to checkm by command `checkm data setRoot /home/tbpl/omicsdata/checkm_db`
export INPDIR=/home/tbpl/output/2_Assembly
export OUTDIR=/home/tbpl/output/2_Assembly/checkm/
declare -a SAMPLES=( "29" "31" )
mkdir -p $INPDIR/bin/
mkdir -p $OUTDIR
for i in "${SAMPLES[@]}"; do 
    echo "Copy input file for sample $i to the bin folder";
    cp $INPDIR/${i}/assembly/assembly.fasta $INPDIR/bin/${i}.fasta
done;
# Set the root of DB folder
checkm data setRoot /home/tbpl/omicsdata/checkm_db
# Run checkm
checkm lineage_wf -t 48 -x fasta $INPDIR/bin/ $OUTDIR --reduced_tree

# Troika ============================================================================
# Generate input file # tab-delimited file 3 columns isolate_id path_to_r1 path_to_r2
#declare -a SAMPLES=( "29" "31" )
#export INPDIR=/home/tbpl/input
#for i in "${SAMPLES[@]}"; do 
#    echo -e "$i\t$INPDIR/${i}_R1_paired.fastq.gz\t$INPDIR/${i}_R2_paired.fastq.gz" >> $INPDIR/inputfile.tsv
#done;
## Run Troika
#mkdir -p /home/tbpl/output/04_AMR/tb-profiler
#export OUTDIR=/home/tbpl/output/04_AMR/tb-profiler
#troika --input_file  $INPDIR/inputfile.tsv \
#    --workdir $OUTDIR \
#    --profiler_threads 48 \
#    --kraken_threads 48 \
#    --snippy_threads 48 --mode normal \
#    --db_version TBProfiler-20190820 --min_cov 40 \
#    --min_aln 80

# Run SNIPPY ==============================================================================
export OUTDIR=/home/tbpl/output/04_AMR/snippy
mkdir -p $OUTDIR
for i in "${SAMPLES[@]}"; do 
    echo "Run snippy for sample $i";
    snippy --force --cpus 16 --outdir $OUTDIR --ref /home/tbpl/omicsdata/snippy_db/H37Rv.gbk --R1 $INPDIR/${i}_R1_paired.fastq.gz --R2 $INPDIR/${i}_R2_paired.fastq.gz
done;

# Run RAxML ==============================================================================

# Run TB-Profiler ==============================================================================
export OUTDIR=/home/tbpl/output/04_AMR/tb-profiler
mkdir -p $OUTDIR
for i in "${SAMPLES[@]}"; do 
    echo "Run tb-profiler for sample $i"; 
    tb-profiler profile -1 $INPDIR/${i}_R1_paired.fastq.gz -2 $INPDIR/${i}_R2_paired.fastq.gz -p $i --txt -t 16
done;
#tb-profiler collate