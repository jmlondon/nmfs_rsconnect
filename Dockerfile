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
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

RUN yum -y groupinstall "Development Tools"

RUN yum install -y openssl-devel
RUN yum install -y epel-release
RUN yum install -y udunits2-devel
RUN yum install -y gdal-devel
RUN yum install -y gdal
RUN yum install -y geos-devel
RUN yum install -y proj-devel
RUN yum install -y proj-epsg

RUN yum install -y cpp 
RUN yum install -y sqlite-devel 
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
  && make \
  && make install

RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R \
  && ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript \
  && echo "options(repos = c(CRAN = 'http://cran.rstudio.com'))" >> /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site \
  && echo "TZ=Etc/UTC" >> /opt/R/${R_VERSION}/lib/R/etc/Renviron.site