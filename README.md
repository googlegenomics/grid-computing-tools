BigTools
==========================

BigTools is intended to be a place for scripts and recipes for solving some very common issues,
which typically fall under the category of "simple for a few files, hard for many files."
Examples include:

* I have many VCFs in Cloud Storage that I need to (de)compress
* I have many VCFs in Cloud Storage that have something wrong with the header
* I have many BAMs in Cloud Storage for which I need to compute index files
 
BigTools Components
-------------------

The primary components of the BigTools examples are:

* Google Cloud Storage - location of source input files and destination for output files
* Google Compute Engine - virtual machines in the cloud
* Grid Engine - job scheduling software to distribute commands across a cluster of virtual machines

The BigTools approach is intended to provide a familiar environment to computational scientists who
are accustomed to using Grid Engine to submit jobs to fixed-size clusters available at their research institution.

Available Tools
---------------
The following tools are available:

* [Compress/Decompress files in Google Cloud Storage] (https://github.com/googlegenomics/bigtools/blob/master/docs/compress.rst)
