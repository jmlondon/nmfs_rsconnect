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

# PKG_CONFIG_PATH is needed for successful sqlite build
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

# Dev Tools installs many of the toolkits needed for building from source
RUN yum -y groupinstall "Development Tools"

# Development Tools for Centos7 installs gcc 4.8; we need newer
# The easy option is to install devtoolset-10 which gets us access
# to gcc 10.
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-10

# Enable devtoolset-10 from our devtools-enable.sh
# and set it as our entrypoint
COPY devtools-enable.sh /usr/bin/devtools-enable.sh
RUN chmod +x /usr/bin/devtools-enable.sh
ENTRYPOINT [ "/usr/bin/devtools-enable.sh" ]

# For RStudio::Connect, we can set up a Program Supervisor script to 
# enable devtools-10 for package compilation server wide.
# see https://support.rstudio.com/hc/en-us/articles/360006142673-RStudio-Connect-with-devtoolset-enabled

# If enabling devtools-10 is not an option, then will need to install gcc 10 from source
# RUN curl -L -O http://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-10.3.0/gcc-10.3.0.tar.gz \
#   && tar -xvf gcc-10.3.0.tar.gz \
#   && cd gcc-10.3.0 \
#   && ./contrib/download_prerequisites \
#   && ./configure --disable-multilib --enable-languages=c,c++,fortran \
#   && make -j 4\
#   && make install

# will also need to set
# export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64

RUN yum install -y openssl-devel
RUN yum install -y epel-release
RUN yum install -y udunits2-devel
RUN yum install -y cpp 
RUN yum install -y libtiff-devel 
RUN yum install -y cmake3
RUN yum install -y libcurl-devel

RUN curl -L -O https://www.sqlite.org/2021/sqlite-autoconf-3360000.tar.gz \
  && tar -zxvf sqlite-autoconf-3360000.tar.gz \
  && cd sqlite-autoconf-3360000 \
  && ./configure \
  && make \
  && make install

RUN curl -L -O https://download.osgeo.org/proj/proj-7.2.1.tar.gz \
  && tar -zxvf proj-7.2.1.tar.gz \
  && cd proj-7.2.1 \
  && ./configure \
  && make \
  && make install \
  && projsync --all

RUN curl -L -O http://download.osgeo.org/geos/geos-3.9.1.tar.bz2 \
  && tar -xvf geos-3.9.1.tar.bz2 \
  && cd geos-3.9.1 \
  && ./configure \
  && make \
  && make install

RUN curl -L -O https://github.com/OSGeo/gdal/releases/download/v3.3.2/gdal-3.3.2.tar.gz \
  && tar -zxvf gdal-3.3.2.tar.gz \
  && cd gdal-3.3.2 \
  && ./configure --with-proj=/usr/local --with-sqlite3=/usr/local \
  && make -j 4\
  && make install

RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R \
  && ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript \
  && echo "options(repos = c(CRAN = 'http://cran.rstudio.com'))" >> /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site \
  && echo "TZ=Etc/UTC" >> /opt/R/${R_VERSION}/lib/R/etc/Renviron.site