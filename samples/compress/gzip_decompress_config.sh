# gzip_decompress.sh
#
# Configuration for a job which takes in a list of gzip compressed
# files in Google Cloud Storage, decompresses them, and uploads
# the decompressed versions to Google Cloud Storage.

export COMPRESS_OPERATION="decompress" # compress | decompress
export COMPRESS_TYPE="gzip"            # gzip | bzip2
export COMPRESS_EXTENSION=".gz"        # .gz | .bz2

export INPUT_LIST_FILE=./samples/compress/gzip_decompress_file_list.txt
export OUTPUT_PATH=gs://MY_BUCKET/output_path/compress_gzipd
export OUTPUT_LOG_PATH=gs://MY_BUCKET/log_path/compress_gzipd
