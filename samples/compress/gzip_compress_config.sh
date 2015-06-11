# gzip_compress.sh
#
# Configuration for a job which takes in a list of uncompressed
# files in Google Cloud Storage, compresses them using gzip, and uploads
# the compressed versions to Google Cloud Storage.

export INPUT_LIST_FILE=./samples/compress/gzip_compress_file_list.txt
export OUTPUT_PATH=gs://MY_BUCKET/output_path/gzip
export OUTPUT_LOG_PATH=gs://MY_BUCKET/log_path/gzip

export COMPRESS_OPERATION="compress"   # compress | decompress
export COMPRESS_TYPE="gzip"            # gzip | bzip2
export COMPRESS_EXTENSION=".gz"        # .gz | .bz2
