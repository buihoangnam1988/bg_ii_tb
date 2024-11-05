# Pull bacannot pipeline, stored in /root/.nextflow/assets/fmalmeida/bacannot
nextflow pull fmalmeida/bacannot
# Pull database
nextflow run fmalmeida/bacannot --get_zenodo_db --output /home/dbpl/omicsdata/ -profile docker