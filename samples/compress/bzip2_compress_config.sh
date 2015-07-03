# bzip2_compress.sh
#
# Configuration for a job which takes in a list of uncompressed
# files in Google Cloud Storage, compresses them using bzip2, and uploads
# the compressed versions to Google Cloud Storage.

export COMPRESS_OPERATION="compress"   # compress | decompress
export COMPRESS_TYPE="bzip2"           # gzip | bzip2
export COMPRESS_EXTENSION=".bz2"       # .gz | .bz2

export INPUT_LIST_FILE=./samples/compress/bzip2_compress_file_list.txt
export OUTPUT_PATH=gs://MY_BUCKET/output_path/compress_bzip2
export OUTPUT_LOG_PATH=gs://MY_BUCKET/log_path/compress_bzip2
