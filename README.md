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

We are going to rely on the newer `devtooset-10`. Note, this installs gcc version 10 along side the already installed gcc 4.8.

```dockerfile
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-10
```

## setup for RStudio::Connect
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

## setup for Docker
Since we're not actually running RStudio::Connect as part of Docker, we have do implement a slighty 
different approach or local Docker testing. We handle this by COPYing our `devtool-enable.sh` file
into our image and adding an ENTRYPOINT

```dockerfile
COPY devtools-enable.sh /usr/bin/devtools-enable.sh
RUN chmod +x /usr/bin/devtools-enable.sh
ENTRYPOINT [ "/usr/bin/devtools-enable.sh" ]
```

## additional dependencies
The following dependencies are libraries needed for successful compilation of the spatial dependencies
from source in the next section

```dockerfile
RUN yum install -y openssl-devel
RUN yum install -y epel-release
RUN yum install -y udunits2-devel
RUN yum install -y cpp 
RUN yum install -y libtiff-devel 
RUN yum install -y cmake3
RUN yum install -y libcurl-devel
```

## sqlite 3
The version of sqlite availble from the typical CentOS7 repositories is not compatible with our
spatial stack so we need to install the latest version from source.

```dockerfile
RUN curl -L -O https://www.sqlite.org/2021/sqlite-autoconf-3360000.tar.gz \
  && tar -zxvf sqlite-autoconf-3360000.tar.gz \
  && cd sqlite-autoconf-3360000 \
  && ./configure \
  && make \
  && make install
```

## proj
The PROJ library for spatial projection support

```dockerfile
RUN curl -L -O https://download.osgeo.org/proj/proj-7.2.1.tar.gz \
  && tar -zxvf proj-7.2.1.tar.gz \
  && cd proj-7.2.1 \
  && ./configure \
  && make \
  && make install \
  && projsync --all
```

## geos
The GEOS library for spatial functions and computation

```dockerfile
RUN curl -L -O http://download.osgeo.org/geos/geos-3.9.1.tar.bz2 \
  && tar -xvf geos-3.9.1.tar.bz2 \
  && cd geos-3.9.1 \
  && ./configure \
  && make \
  && make install
```

## gdal
The GDAL library for read/write, transformations, of spatial data (this will take relatively longer to build)

```dockerfile
RUN curl -L -O https://github.com/OSGeo/gdal/releases/download/v3.3.2/gdal-3.3.2.tar.gz \
  && tar -zxvf gdal-3.3.2.tar.gz \
  && cd gdal-3.3.2 \
  && ./configure --with-proj=/usr/local --with-sqlite3=/usr/local \
  && make -j 4\
  && make install
```

## R 4.1.1
The final step for our Docker image is to install the latest version of R so we can test package installation

```dockerfile
RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R \
  && ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript \
  && echo "options(repos = c(CRAN = 'http://cran.rstudio.com'))" >> /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site \
  && echo "TZ=Etc/UTC" >> /opt/R/${R_VERSION}/lib/R/etc/Renviron.site
```
