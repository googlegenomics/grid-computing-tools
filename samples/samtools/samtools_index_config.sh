# samtools_index_config.sh
#
# Configuration for a job which takes in a list of BAM files
# in Google Cloud Storage, uses "samtools index" to create a
# a BAM index file, and pushes the index to Google Cloud Storage.

export SAMTOOLS_OPERATION="index"

export INPUT_LIST_FILE=./samples/samtools/samtools_index_input_list_file.txt
export OUTPUT_PATH=gs://MY_BUCKET/output_path/samtools_index
export OUTPUT_LOG_PATH=gs://MY_BUCKET/log_path/samtools_index
