# Pull bacannot pipeline, stored in /root/.nextflow/assets/fmalmeida/bacannot
nextflow pull fmalmeida/bacannot
# Allow calling .py script directly for bacannot pipelines
export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
# Pull database
nextflow run fmalmeida/bacannot --get_zenodo_db --output /home/tbpl/omicsdata/zenodo/ -profile docker
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
export BACANOTDB=/home/tbpl/omicsdata/zenodo/bacannot_dbs_2024_jul_05
export PATH=$PATH:/root/.nextflow/assets/fmalmeida/bacannot/bin
nextflow run fmalmeida/bacannot --input /home/tbpl/output/samplesheet.yaml --output /home/tbpl/output/2_Assembly --bacannot_db $BACANOTDB --resfinder_species "Mycobacterium tuberculosis" --max_cpus 10 -profile docker




