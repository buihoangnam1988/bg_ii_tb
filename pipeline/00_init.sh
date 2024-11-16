# Pull bacannot pipeline, stored in /root/.nextflow/assets/fmalmeida/bacannot
nextflow pull fmalmeida/bacannot
# Allow calling .py script directly for bacannot pipelines
export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
# Pull Zenodo database (Prebuilt)
nextflow run fmalmeida/bacannot --get_zenodo_db --output /home/tbpl/omicsdata/zenodo/ -profile docker
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

# Run FastQC
mkdir -p /home/tbpl/output/01_QC/preqc
fastqc -o /home/tbpl/output/01_QC/preqc /home/tbpl/input/*.fastq.gz
# Run MultiQC
cd /home/tbpl/output/01_QC/preqc && multiqc .

# Run trimmomatic (Dr Michael will prepare)
mkdir -p /home/tbpl/output/01_QC/postqc
declare -a SAMPLES=( "29" )
for i in "${SAMPLES[@]}"; do 
    echo $i;
    trimmomatic PE -threads 80 -phred33 -trimlog ${i}_trim.log ${i}_1.fq.gz \
    ${i}_2.fq.gz ${i}_R1_paired.fastq.gz ${i}_R1_unpaired.fastq.gz \
    ${i}_R2_paired.fastq.gz ${i}_R2_unpaired.fastq.gz ILLUMINACLIP:/home/ec2- \
    user/data/trimmomatic/adapters/Aviti.fa:2:30:10 LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:15 MINLEN:36;
done;

for i in "${SAMPLES[@]}"; do echo $i; done;


# Run Bacannot pipeline
# Prepare the samplesheet.yaml
# samplesheets:
#   - id: sample_1
#     illumina:
#       - /home/tbpl/input/29_R1_paired.fastq.gz
#       - /home/tbpl/input/29_R2_paired.fastq.gz
#export BACANOTDB=/home/tbpl/omicsdata/zenodo/bacannot_dbs_2024_jul_05 # Zenodo
export BACANOTDB=/home/tbpl/output/bacannot_dbs
#export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
# Run Bacannot pipeline
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
nextflow run fmalmeida/bacannot --input /home/tbpl/output/samplesheet.yaml --output /home/tbpl/output/2_Assembly --bacannot_db $BACANOTDB --resfinder_species "Mycobacterium tuberculosis" --max_cpus 10 -profile docker -resume

