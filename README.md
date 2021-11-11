# nmfs_rsconnect
Dockerfile to test NMFS RStudio::Connect server for dependecies

## summary
The NMFS RStudio::Connect server is running on AWS with CentOS 7 as the operating system. CentOS 7 does not provide access to
more current versions of system libraries that are required for some R packages. This is especially true for the spatial
stack of system dependencies (e.g. PROJ, GEOS, GDAL) and R packages (e.g. sf, stars, terra, sp, raster). In addition to the
spatial stack, the gcc version provided by CentOS 7 is 4.8 and some R packages require newer versions of gcc to compile. Here
we use a Dockerfile to document the necessary setup. This Dockerfile can also be used to create a local Docker image for testing
installation of R packages prior to deployment on the NMFS RStudio::Connect server.

## setup
Here we start by pulling the base CentOS 7 image and setting up a few details for the build of R.

```dockerfile
FROM centos:7

LABEL maintainer="Josh M London <josh.london@noaa.gov>"

ARG R_VERSION
ARG BUILD_DATE
ARG CRAN
ENV BUILD_DATE ${BUILD_DATE:-2020-09-11}
ENV R_VERSION=${R_VERSION:-4.1.1} \
    CRAN=${CRAN:-https://cran.rstudio.com} \ 
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 
```

Several of the dependencies and many R packages rely on a current version of sqlite. We will need to build sqlite
from source. The following environment variable must be set for successful sqlite build

```dockerfile
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
```

## development tools
The base OS does not come with many of the needed compiling and development tools we will rely on for compiling
various libraries and packages from source. We start by installing the "Development Tools" group.

```dockerfile
RUN yum -y groupinstall "Development Tools"
```

This installation, however, installs an outdated version of gcc. We could install a new version of gcc from
source, but there is an easier and less intrusive method. The approach described here is adapted from an
[article on the RStudio Connect Support site](https://support.rstudio.com/hc/en-us/articles/360006142673-RStudio-Connect-with-devtoolset-enabled).

We are going to rely on the newer `devtooset-10`

```dockerfile
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-10
```

In many use cases, one could call `source scl_source enable devtoolset-10` from a command line to enable `devtoolset-10` and
have access to updated gcc version. However, in the case of RStudio::Connect, we need to ensure all compilation processes
during deployment/install of an application use `devtoolset-10`. RStudio::Connect enables this through the use of a 
Program Supervisor.

First, we'll want to create a directory to hold the scripts on the server

```bash
mkdir -p /opt/scripts
```

And, then, create a script file `devtools-enable.sh` with the following code:

```bash
#!/bin/bash

echo arguments: "$@" >&2
echo >&2

source scl_source enable devtoolset-10

exec "$@"
```

We meed to allow access to the file with

```bash
chmod 755 /opt/scripts/devtool-enable.sh
```

Finally, we need to edit the configuration file `/etc/rstudio-connect/rstudio-connect.gcfg` by 
adding the following entry

```bash
[Applications]
Supervisor = /opt/scripts/devtool-enable.sh
```

Since we're not actually running RStudio::Connect, we have do implement a slight different approach
