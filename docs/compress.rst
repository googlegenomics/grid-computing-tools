.. _gzip: http://www.gzip.org/ 
.. _bzip2: http://www.bzip.org/
.. _Google Compute Engine: https://cloud.google.com/compute/
.. _Grid Engine: http://gridengine.info/

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
Running the samples
-------------------
The quickest way to get familiar with the ``compress`` BigTool is by trying one or more
of the samples. Samples are provided for:

* Pull bzip2-compressed files from Cloud Storage, decompress them, and copy the results into Cloud Storage
* Pull decompressed files from Cloud Storage, compress them with bzip2, and copy the results into Cloud Storage
* Pull gzip-compressed files from Cloud Storage, decompress them, and copy the results into Cloud Storage
* Pull decompressed files from Cloud Storage, compress them with gzip, and copy the results into Cloud Storage

The samples provided here each list just 6 files to work on, and the instructions below demonstrate
spreading the processing over 3 worker instances.

1. Create a cluster of Compute Engine instances with Grid Engine installed and configured

Follow the instructions
`here <http://googlegenomics.readthedocs.org/en/staging-2/includes/elasticluster_setup.html>`_
to configure a Grid Engine cluster using Elasticluster.

2. Upload the `src` and `samples` directories to the Grid Engine master instance:

.. code-block:: shell

  elasticluster sftp gridengine << 'EOF'
  mkdir src
  put -r src
  mkdir samples
  put -r samples
  EOF
  
(You can also use `gcloud compute copy-files` if you know the instance name of master instance.)

3. SSH to the master instance
 
.. code-block:: shell

  elasticluster ssh gridengine
  
4. Run the sample

.. code-block:: shell

  ./src/compress/launch_compress.sh ./samples/compress/bzip2_compress_config.sh




