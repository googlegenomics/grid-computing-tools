.. _samtools: http://www.htslib.org/
.. _Google Compute Engine: https://cloud.google.com/compute/
.. _Grid Engine: http://gridengine.info/
.. _Elasticluster: https://elasticluster.readthedocs.org
.. _gsutil: https://cloud.google.com/storage/docs/gsutil
.. _gridengine array job: http://wiki.gridengine.info/wiki/index.php/Simple-Job-Array-Howto

=============================================
Run Samtools on files in Google Cloud Storage
=============================================

Suppose you have thousands of BAMs, which you have stored in Google Cloud Storage,
and you need to create index files (BAI) for them.

The ``samtools`` BigTool can be used to create those index files using `samtools`_.

--------------------------------
Overview of the samtools BigTool
--------------------------------

This BigTool takes advantage of two key technologies to quickly run `samtools`
operations over a large number of files:

* `Google Compute Engine`_
* `Grid Engine`_ (SGE)

Google Compute Engine provides virtual machines in the cloud. With sufficient quota
in your Google Cloud project, you can start dozens or hundreds of instances concurrently.
The more instances you add to your cluster, the more quickly you can process your files.

Grid Engine is used to distribute the file operation tasks across
all of the instances such that each instance takes the responsibility to download a
single file, run the operation, and upload it back to Cloud Storage.

-------------------
Directory structure
-------------------
To use the BigTool, you will need to download both the ``bigtools`` repository
and the repository for `Elasticluster`_ to your local workstation or laptop. No specific
relationship exists between these two repositories. But in the following instructions, it is
assumed that the ``bigtools`` and ``elasticluster`` directories are siblings under a
workspace root (``WS_ROOT``) directory.

-------------------
Running the samples
-------------------
The quickest way to get familiar with the ``samtools`` BigTool is by trying the sample.

The sample provided here lists just 6 files to work on, and the instructions below demonstrate
spreading the processing over 3 worker instances.

1. **Create a cluster of Compute Engine instances running Grid Engine**

   In your current shell:

   a. ``cd ${WS_ROOT}``
   b. Follow the instructions to
      `configure a Grid Engine cluster using Elasticluster
      <http://googlegenomics.readthedocs.org/en/staging-2/includes/elasticluster_setup.html>`_

2. **Download the** ``bigtools`` **repository (if you have not already done so)**

.. code-block:: shell

   cd ${WS_ROOT}
   git clone https://github.com/googlegenomics/bigtools.git

3. **Upload the** ``src`` **and** ``samples`` **directories to the Grid Engine master instance:**

.. code-block:: shell

  cd bigtools
  
  elasticluster sftp gridengine << 'EOF'
  mkdir src
  put -r src
  mkdir samples
  put -r samples
  EOF

4. **SSH to the master instance**
 
.. code-block:: shell

  elasticluster ssh gridengine
  
5. **Set up the configuration files for the samples**

The syntax for running the sample is:

.. code-block:: shell

  ./src/samtools/launch_samtools.sh [config_file]

The ``config_file`` lists two sets of key parameters:

* What operation to perform
* What are the source and destination locations

The operation to perform is controlled by the following:

.. code-block:: shell

* SAMTOOLS_OPERATION: ``index``

The locations are determined by:

* INPUT_LIST_FILE: file containing a list of GCS paths to the input files to process
* OUTPUT_PATH: GCS path indicating where to upload the output files
* OUTPUT_LOG_PATH: (optional) GCS path indicating where to upload log files

To use the samples, you must update the ``OUTPUT_PATH`` and ``OUTPUT_LOG_PATH`` to
contain a valid GCS bucket name. The sample config file sets a placeholder
for the ``OUTPUT_PATH`` and ``OUTPUT_LOG_PATH`` such as:

.. code-block:: shell

  export OUTPUT_PATH=gs://MY_BUCKET/bigtools/output_path/samtools_index
  export OUTPUT_LOG_PATH=gs://MY_BUCKET/bigtools/log_path/samtools_index

You can do this manually with the editor of your choice or you can change the
``config`` file with the command:

.. code-block:: shell

  sed --in-place -e 's#MY_BUCKET#your_bucket#' samples/samtools/*_config.sh

Where ``your_bucket`` should be replaced with the name of a GCS bucket in your
Cloud project to which you have write access.

6. **Run the sample:**

* Index a list of files using ``samtools index`` [ Estimated time to complete: 5 minutes ]

.. code-block:: shell

  ./src/samtools/launch_samtools.sh ./samples/samtools/samtools_index_config.sh

When successfully launched, Grid Engine should emit a message such as:

.. code-block:: shell

  Your job-array 1.1-6:1 ("samtools") has been submitted

This message tells you that the submitted job is a `gridengine array job`_.
The above message indicates that the job id is **1** and that the tasks are numbered **1** through **6**.
The name of the job **samtools** is also indicated.

7. **Monitoring the status of your job**

Grid Engine provides the ``qstat`` command to get the status of the execution queue.

While the job is in the queue, the `state` column will indicate the status of each task.
Tasks not yet allocated to a ``compute`` node will be collapsed into a single row as in the following output:

.. code-block:: shell

  $ qstat
  job-ID  prior   name       user      state submit/start at     queue            slots ja-task-ID 
  ------------------------------------------------------------------------------------------------
       1  0.00000 samtools   janedoe   qw    06/16/2015 18:03:32                      1 1-6:1

The above output indicates that tasks **1-6** of job **1** are all in a ``qw`` (queue waiting) state.

When tasks get allocated, the output will look something like:

.. code-block:: shell

  $ qstat
  job-ID  prior   name       user      state submit/start at     queue            slots ja-task-ID 
  ------------------------------------------------------------------------------------------------
       1  0.50000 samtools   janedoe   r     06/16/2015 18:03:45 all.q@compute002     1 1
       1  0.50000 samtools   janedoe   r     06/16/2015 18:03:45 all.q@compute001     1 2
       1  0.50000 samtools   janedoe   r     06/16/2015 18:03:45 all.q@compute003     1 3
       1  0.00000 samtools   janedoe   qw    06/16/2015 18:03:32                      1 4-6:1

which indicates tasks **1-3** are all in the ``r`` (running) state, while tasks **4-6** remain in a waiting state.

When all tasks have completed ``qstat`` will produce no output.

8. **Checking the logging output of tasks**

Each gridengine task will write to an "output" file and an "error" file.
These files will be located in the directory the job was launched from (the ``HOME`` directory).
The files will be named *job_name*.\ **o**\ *job_id*.\ *task_id* and
*job_name*.\ **e**\ *job_id*.\ *task_id* respectively.

The error file will contain any unexpected error output, but will also contain the download and upload
logging output from ``gsutil``.

9. **Viewing the results of the jobs**

When tasks complete, the result files are uploaded to GCS. You can view the list of output files
with ``gsutil ls``, such as:

.. code-block:: shell

  gsutil ls OUTPUT_PATH

Where the ``OUTPUT_PATH`` should be the value you specified in the job config file (step 6 above).

10. **Viewing log files**

When tasks complete, the result log files are uploaded to GCS if ``OUTPUT_LOG_PATH`` was set
in the job config file. The log files can be of value both to verify success/failure of all
tasks, as well as to gather some performance statistics before starting a larger job.

* Count number of successful tasks

.. code-block:: shell

  gsutil cat OUTPUT_LOG_PATH/* | grep SUCCESS | wc -l

Where the ``OUTPUT_LOG_PATH`` should be the value you specified in the job config file (step 6 above).

* Count number of failed tasks

.. code-block:: shell

  gsutil cat OUTPUT_LOG_PATH/* | grep FAILURE | wc -l

Where the ``OUTPUT_LOG_PATH`` should be the value you specified in the job config file (step 6 above).

* Compute total task time

.. code-block:: shell

  gsutil cat OUTPUT_LOG_PATH/* | \
    sed -n -e 's#^Task time.*: \([0-9]*\) seconds#\1#p' | \
    awk '{ sum += $1; } END { print sum/NR " seconds"}'

* Compute average task time

.. code-block:: shell

  gsutil cat OUTPUT_LOG_PATH/* | \
    sed -n -e 's#^Task time.*: \([0-9]*\) seconds#\1#p' | \
    awk '{ sum += $1; } END { print sum " seconds"}'

11. **Destroying the cluster**

When you are finished running the samples, disconnect from the master instance and
from your workstation shut down the gridengine cluster:

.. code-block:: shell

  elasticluster stop gridengine

--------------------
Running your own job
--------------------
To run your own job to index a list of BAM files requires the following:

#. Create an ``input list file``
#. Create a ``job config file``
#. Create a gridengine cluster with sufficient disk space attached to each ``compute`` node
#. Upload input list file, config file, and `bigtools` source to the gridengine cluster master
#. Do a "dry run" (*optional*)
#. Launch the job

The following instructions provide guidance on each of these steps.
It is recommended, though not a requirement, that you save your ``input list file`` and ``job config file``
to a directory outside the ``bigtools`` directory. For example, you might create a directory
``${WS_ROOT}/my_jobs``.

1. **Create an** ``input list file``

If all of your input files appear in a single directory, then the easiest way to generate a file list
is with ``gsutil``. For example:

.. code-block:: shell

  gsutil ls gs://MY_BUCKET/PATH/*.vcf.bz2 > ${WS_ROOT}/my_jobs/bam_indexing_list_file.txt
  
2. **Create a** ``job config file``

The easiest way to create a job config file is to base it off the appropriate sample and update

* INPUT_LIST_FILE
* OUTPUT_PATH
* OUTPUT_LOG_PATH

3. **Create a gridengine cluster with sufficient disk space attached to each** ``compute`` **node**

Each ``compute`` node will require sufficient disk space to hold the BAM and the index file
for its current task. Determine the largest file in your input list
and estimate the total space you will need.

*** FIXME: check if using gcsfuse can avoid a full download (and if it is performant).
*** FIXME: possibly doc needs updating for disk sizing based on performance.

Instructions for setting the boot disk size for the compute nodes of your cluster can be found
`here <http://googlegenomics.readthedocs.org/en/staging-2/includes/elasticluster_setup.html#setting-the-boot-disk-size>`_.

You will likely want to set the number of ``compute`` nodes for your cluster to a number higher than the
**3** specified in the cluster setup instructions.

Note that your choice for number of nodes and disk size must take into account your resource quota for
the Compute Engine region of your cluster.

Quota limits and current usage can be viewed with ``gcloud compute``:

  gcloud compute regions describe *region*

or in ``Developers Console``:

  https://console.developers.google.com/project/_/compute/quotas

Important quota limits include CPUs, in-use IP addresses, and disk size.

Once configured, start your cluster.

4. **Upload input list file, config file, and** ``bigtools`` **source to the gridengine cluster master**

.. code-block:: shell

  elasticluster sftp gridengine << EOF
  put ../my_jobs/*
  mkdir src
  put -r src
  EOF

5. **Do a "dry run"** (*optional*)

The ``samtools`` BigTool supports the DRYRUN environment variable.
Setting this value to 1 when launching your job will cause the queued job to
execute *without downloading or uploading* any files.

The local output files, however, will be populated with useful information about
what files *would* be copied. This can be useful for ensuring your file list
is valid and that the output path is correct.

For example:

.. code-block:: shell

   $ DRYRUN=1 ./src/samtools/launch_samtools.sh ./samples/samtools/samtools_config.sh
   Your job-array 5.1-6:1 ("samtools") has been submitted

Then after waiting for the job to complete, inspect:

** FIXME: add real output here:

.. code-block:: shell

   $ head -n 5 samtools.o3.1 
   Task host: compute001
   Task start: 1
   Input list file: ./samples/samtools/samtools_index_file_list.txt
   Output path: gs://cookbook-bucket/bigtools/output_path/samtools_index
   Output log path: gs://cookbook-bucket/bigtools/log_path/samtools_index

   $ grep "^Will download:" samtools.o5.*
   samtools.o5.1:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/pilot2_high_cov_GRCh37_bams/data/NA12878/alignment/NA12878.chrom9.SOLID.bfast.CEU.high_coverage.20100125.bam to /scratch/samtools.5.1/in/
   samtools.o5.2:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/pilot2_high_cov_GRCh37_bams/data/NA12878/alignment/NA12878.chrom1.LS454.ssaha2.CEU.high_coverage.20100311.bam to /scratch/samtools.5.2/in/
   samtools.o5.3:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/pilot_data/data/NA12878/alignment/NA12878.chrom11.SOLID.corona.SRP000032.2009_08.bam to /scratch/samtools.5.3/in/
   samtools.o5.4:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/pilot_data/data/NA12878/alignment/NA12878.chrom12.SOLID.corona.SRP000032.2009_08.bam to /scratch/samtools.5.4/in/
   samtools.o5.5:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/pilot_data/data/NA12878/alignment/NA12878.chrom10.SOLID.corona.SRP000032.2009_08.bam to /scratch/samtools.5.5/in/
   samtools.o5.6:Will download: gs://genomics-public-data/ftp-trace.ncbi.nih.gov/1000genomes/ftp/pilot_data/data/NA12878/alignment/NA12878.chromX.SOLID.corona.SRP000032.2009_08.bam to /scratch/samtools.5.6/in/

6. **Launch the job**

SSH to the master instance
 
.. code-block:: shell

  elasticluster ssh gridengine

Run the launch script, passing in the config file:

.. code-block:: shell

  ./src/samtools/launch_samtools.sh my_job_config.sh
  
where *my_job_config.sh* is replaced by the name of your config file created in step 2.
