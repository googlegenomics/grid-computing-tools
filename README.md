bigtools
==========================

BigTools provides a collection of scripts and recipes for solving some very common issues,
which typically fall under the category of "simple for a few files, hard for many files."
Examples include:

* I have many VCFs that I need to (de)compress
* I have many VCFs that have something wrong with the header
* I have many BAMs form which I need to compute index files
 
BigTools Components
-------------------

The primary components of the canonical BigTools examples are:

* Google Cloud Storage - location of source input files and destination for output files
* Google Compute Engine - virtual machines in the cloud
* Grid Engine - job scheduling software to distribute commands across a cluster of virtual machines

The BigTools approach is intended to provide a familiar environment to computational scientists who
are accustomed to working with fixed-size clusters available at their research institution.
A more "cloud-native" approach would not involve creating a fixed cluster and installing a scheduler
but would instead create virtual machine instances as needed.

Getting Started
---------------

* Find a tool you need
* Create a cluster
* Run your job
* Destroy your cluster

Performance notes
-----------------
Many of the BigTools tasks provide best price/performance by using clusters of n1-standard-1
instances with the default boot disk type of pd-standard and boot disk size of 10 GB.
Factors that would change these choices...

* Anything more i/o intensive (even just needing to download/upload bigger files)

TODOs
-----
Create a playbook for updating gcloud and installing crcmod
Give instructions for creating an image and using it
Give instructions for monitoring and restarting tasks

qdel $JOB_ID
qalter -r y $JOB_ID
qmod   -rj  $JOB_ID
