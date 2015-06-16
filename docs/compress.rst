.. _gzip: http://www.gzip.org/ 
.. _bzip2: http://www.bzip.org/
.. _Google Compute Engine: https://cloud.google.com/compute/
.. _Grid Engine: http://gridengine.info/
.. _Elasticluster: https://elasticluster.readthedocs.org
.. _gsutil: https://cloud.google.com/storage/docs/gsutil
.. _crcmod python module: https://cloud.google.com/storage/docs/gsutil/addlhelp/CRC32CandInstallingcrcmod

=================================================
Compress/Decompress files in Google Cloud Storage
=================================================

Suppose you have thousands of VCFs, which you have stored *compressed* in Google Cloud Storage,
and you need to perform some operation on them in their *decompressed* state.

A few examples:

* You want to run a check on all of the headers
* You want to import them into Google Genomics

Or suppose you have thousands of VCFs, and you did not compress them when originally
copying them to Google Cloud Storage, but these VCFs can now be compressed and archived.

The ``compress`` BigTool can be used for any of these situations if your compression
scheme is either gzip or bzip2.

--------------------------------
Overview of the compress BigTool
--------------------------------

The `compress` BigTool takes advantage of two key technologies to quickly compress
or decompress a large number of files:

* `Google Compute Engine`_
* `Grid Engine`_ (SGE)

Google Compute Engine provides virtual machines in the cloud. With sufficient quota
in your Google Cloud project, you can start dozens or hundreds of instances concurrently.
The more instances you add to your cluster, the more quickly you can process your files.

Grid Engine is used by the ``compress`` BigTool to distribute the compress tasks across
all of the instances such that each instance takes the responsibility to download a
single file, (de)compress it, and upload it back to Cloud Storage.

-------------------
Directory structure
-------------------
To use the ``compress`` sample, you will need to download both the ``bigtools`` repository
and the repository for `Elasticluster`_ to your local workstation or laptop. No specific
relationship exists between these two repositories. But in the following instructions, it is
assumed that the ``bigtools`` and ``elasticluster`` directories are siblings under a
``BIGTOOLS_ROOT`` directory.

-------------------
Running the samples
-------------------
The quickest way to get familiar with the ``compress`` BigTool is by trying one or more
of the samples. Samples are provided for the following uses:

* Download bzip2-compressed files from Cloud Storage, decompress them, and upload the results into Cloud Storage
* Download decompressed files from Cloud Storage, compress them with bzip2, and upload the results into Cloud Storage
* Download gzip-compressed files from Cloud Storage, decompress them, and upload the results into Cloud Storage
* Download decompressed files from Cloud Storage, compress them with gzip, and upload the results into Cloud Storage

The samples provided here each list just 6 files to work on, and the instructions below demonstrate
spreading the processing over 3 worker instances.

1. Create a cluster of Compute Engine instances with Grid Engine installed and configured

In your current shell, set your directory to your selected ``BIGTOOLS_ROOT`` and then
follow the instructions
`here <http://googlegenomics.readthedocs.org/en/staging-2/includes/elasticluster_setup.html>`_
to configure a Grid Engine cluster using Elasticluster.

2. Download the ``bigtools`` repository (if you have not already done so)

   a. cd $BIGTOOLS_ROOT
   b. git clone https://github.com/googlegenomics/bigtools.git
   c. cd bigtools

3. Install crcmod on each ``compute`` node

For `gsutil`_ to download and verify multi-component objects, the `crcmod python module`_ must be installed
on each of the ``compute`` nodes.

The ``bigtools`` repository contains a utility script which can be used to do this.
The script uses the Elasticluster Python API to list the nodes in the ``gridengine`` cluster
and then ``elasticluster ssh gridengine -n <node>`` to connect to each node in the cluster and
issue the necessary ``crcmod`` install commands.

Running this script requires that ``elasticluster`` be in your ``PATH``. This will be true if your
``elasticluster`` virtualenv is active. Otherwise you can set the ``PATH`` explicitly:

.. code-block:: shell

  export PATH=${PATH}:${BIGTOOLS_ROOT}/elasticluster/bin

To run the ``install_crcmod.sh`` script:

.. code-block:: shell

  ./bin/install_crcmod.sh gridengine

4. Upload the `src` and `samples` directories to the Grid Engine master instance:

.. code-block:: shell

  elasticluster sftp gridengine << 'EOF'
  mkdir src
  put -r src
  mkdir samples
  put -r samples
  EOF

5. SSH to the master instance
 
.. code-block:: shell

  elasticluster ssh gridengine
  
6. Set up the configuration files for the samples

The syntax for running each of the samples is the same:

.. code-block:: shell

  ./src/compress/launch_compress.sh [config_file]

The ``config_file`` lists two sets of key parameters:

* What operation to perform
* What are the source and destination locations

The operation to perform is controlled by the following:

.. code-block:: shell

* COMPRESS_OPERATION: ``compress`` or ``decompress``
* COMPRESS_TYPE: ``bzip2`` or ``gzip``
* COMPRESS_EXTENSION: Typically ``.bz2`` or ``.gz``

The locations are determined by:

* INPUT_LIST_FILE: file containing a list of GCS paths to the input files to process
* OUTPUT_PATH: GCS path indicating where to upload the output files
* OUTPUT_LOG_PATH: (optional) GCS path indicating where to upload log files

To use the samples, you must update the ``OUTPUT_PATH`` and ``OUTPUT_LOG_PATH`` to
contain a valid GCS bucket name. Each of the sample config files sets a placeholder
for the ``OUTPUT_PATH`` and ``OUTPUT_LOG_PATH`` such as:

.. code-block:: shell

  export OUTPUT_PATH=gs://MY_BUCKET/output_path/bzip2
  export OUTPUT_LOG_PATH=gs://MY_BUCKET/log_path/bzip2

You can do this manually with the editor of your choice or you can change all of the
``config`` files at once with the command:

.. code-block:: shell

  sed --in-place -e 's#MY_BUCKET#your_bucket#' samples/compress/*_config.sh

Where ``your_bucket`` should be replaced with the name of a GCS bucket in your
Cloud project to which you have write access.

7. Run the sample:

You can run all of the samples, or the just those that model your particular use-case.

* Compress a list of files using bzip2

.. code-block:: shell

  ./src/compress/launch_compress.sh ./samples/compress/bzip2_compress_config.sh

* Decompress a list of files using bzip2

.. code-block:: shell

  ./src/compress/launch_compress.sh ./samples/compress/bzip2_decompress_config.sh

* Compress a list of files using gzip

.. code-block:: shell

  ./src/compress/launch_compress.sh ./samples/compress/gzip_compress_config.sh

* Decompress a list of files using gzip

.. code-block:: shell

  ./src/compress/launch_compress.sh ./samples/compress/gzip_decompress_config.sh

When successfully launched, Grid Engine should emit a message such as:

Your job-array 1.1-6:1 ("compress") has been submitted

8. Monitoring the status of your job

.. code-block:: shell

  $ qstat
  job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID 
  -----------------------------------------------------------------------------------------------------------------
  11      0.00000 compress   mbookman     qw    06/16/2015 18:03:32                                    1 1-6:1



9. Checking the output of tasks

10. Viewing the results of the jobs

11. Viewing log files











