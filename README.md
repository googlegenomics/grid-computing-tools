grid-computing-tools
====================

The grid-computing-tools repo is intended to be a place for scripts and
recipes for solving some very common issues, which typically fall under
the category of "simple for a few files, hard for many files."
Examples include:

* I have many VCFs in Cloud Storage that I need to (de)compress
* I have many VCFs in Cloud Storage that have something wrong with the header
* I have many BAMs in Cloud Storage for which I need to compute index files
 
grid-computing-tools components
-------------------------------

The primary components of the grid-computing-tools examples are:

* [Google Cloud Storage](https://cloud.google.com/storage/) - location of source input files and destination for output files
* [Google Compute Engine](https://cloud.google.com/compute/) - virtual machines in the cloud
* [Grid Engine](http://gridengine.info/) - job scheduling software to distribute commands across a cluster of virtual machines

The approach here is intended to provide a familiar environment to
computational scientists who are accustomed to using Grid Engine to
submit jobs to fixed-size clusters available at their research institution.

Available Tools
---------------
Documentation for the tools in this repo can be found at
http://googlegenomics.readthedocs.org/

The following tools are available:

* [Compress/Decompress files in Google Cloud Storage](http://googlegenomics.readthedocs.org/en/latest/use_cases/compress_or_decompress_many_files/index.html)
* [With SAMtools index BAM files in Google Cloud Storage](http://googlegenomics.readthedocs.org/en/latest/use_cases/run_samtools_over_many_files/index.html)
