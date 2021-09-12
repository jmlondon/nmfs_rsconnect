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

RUN yum -y install epel-release
RUN yum update -y
RUN yum upgrade -y
RUN yum clean all -y

RUN yum -y groupinstall "Development Tools"

RUN yum -y install \
  git \
  xml2 \
  pandoc \
  libxml2-devel \
  libtiff-devel \
  curl \
  curl-devel \
  libcurl-devel \
  udunits2-devel \
  openssl-devel \
  libjpeg-turbo-devel \
  freetype-devel \
  v8-devel \
  openssl098e \
  supervisor \
  passwd 

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
  && ./configure \
  && make \
  && make install

RUN yum -y install \
  lbzip2 \
  bzip2-devel \
  libXmu \
  libXt \
  libicu \
  libicu-devel \
  fftw-devel \
  gsl-devel \
  mesa-libGL \
  mesa-libGL-devel \
  mesa-libGLU \
  mesa-libGLU-devel \
  hdf-devel \
  hdf5-devel \
  jq-devel \
  libpq-devel \
  postgis \
  protobuf-devel \
  netcdf-devel \
  netcdf \
  protobuf-compiler \
  tk-devel \
  unixODBC-devel \
  openblas \
  openblas-devel \
  pcre2 \
  pcre2-devel \
  which

RUN curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R \
  && ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript \
  && echo "options(repos = c(CRAN = 'http://cran.rstudio.com'))" >> /opt/R/${R_VERSION}/lib/R/etc/Rprofile.site \
  && echo "TZ=Etc/UTC" >> /opt/R/${R_VERSION}/lib/R/etc/Renviron.site

  
RUN Rscript -e "install.packages(c('littler', 'docopt'), repo = '$CRAN')" \
  && ln -s /opt/R/${R_VERSION}/lib/R/library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /opt/R/${R_VERSION}/lib/R/library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /opt/R/${R_VERSION}/lib/R/library/littler/bin/r /usr/local/bin/r

RUN install2.r -l /opt/R/${R_VERSION}/lib/R/library --error \
    RColorBrewer \
    RandomFields \
    RNetCDF \
    classInt \
    deldir \
    devtools \
    gstat \
    lubridate \
    mapdata \
    maptools \
    mapview \
    ncdf4 \
    plotly \
    proj4 \
    raster \
    rgdal \
    rgeos \
    rmarkdown \
    sf \
    shiny \
    sp \
    spacetime \
    spatstat \
    spdep \
    tidyverse \
    geoR \
    geosphere \