FROM centos:7
MAINTAINER Benedikt Riedel "briedel@icecube.wisc.edu"
# Mostly taken from OSG EL7 Docker image
# Modifications to accomodate new CUDA versions
# and pyglidein

RUN yum -y upgrade
RUN yum -y install epel-release yum-plugin-priorities

# osg repo
RUN yum -y install http://repo.opensciencegrid.org/osg/3.4/osg-3.4-el7-release-latest.rpm
   
# pegasus repo 
# RUN echo -e "# Pegasus\n[Pegasus]\nname=Pegasus\nbaseurl=http://download.pegasus.isi.edu/wms/download/rhel/7/\$basearch/\ngpgcheck=0\nenabled=1\npriority=50" >/etc/yum.repos.d/pegasus.repo

# well rounded basic system to support a wide range of user jobs
RUN yum -y groups mark convert \
    && yum -y grouplist \
    && yum -y groupinstall "Compatibility Libraries" \
                           "Development Tools" \
                           "Scientific Support"

RUN yum -y install \
           redhat-lsb \
           astropy-tools \
           bc \
           binutils \
           binutils-devel \
           coreutils \
           curl \
           fontconfig \
           gcc \
           gcc-c++ \
           gcc-gfortran \
           git \
           glew-devel \
           glib2-devel \
           glib-devel \
           graphviz \
           gsl-devel \
           java-1.8.0-openjdk \
           java-1.8.0-openjdk-devel \
           libgfortran \
           libGLU \
           libgomp \
           libicu \
           libquadmath \
           libtool \
           libtool-ltdl \
           libtool-ltdl-devel \
           libX11-devel \
           libXaw-devel \
           libXext-devel \
           libXft-devel \
           libxml2 \
           libxml2-devel \
           libXmu-devel \
           libXpm \
           libXpm-devel \
           libXt \
           mesa-libGL-devel \
           numpy \
           octave \
           octave-devel \
           osg-wn-client \
           openssl098e \
           p7zip \
           p7zip-plugins \
           python-astropy \
           python-devel \
           R-devel \
           redhat-lsb-core \
           rsync \
           scipy \
           subversion \
           tcl-devel \
           tcsh \
           time \
           tk-devel \
           wget \
           which

# Cuda and cudnn - in case we land on GPU nodes. See:
#  https://developer.nvidia.com/cuda-downloads
#  https://gitlab.com/nvidia/cuda/blob/centos7/9.0/devel/cudnn7/Dockerfile
# RUN rpm -Uvh https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-10.0.130-1.x86_64.rpm \
#     && yum -y clean all \
#     && yum -y install cuda-10 \
#     && cd /usr/local \
#     && curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.0.5/cudnn-10.0-linux-x64-v7.tgz -O \
#     && tar --no-same-owner -xzf cudnn-10.0-linux-x64-v7.tgz -C /usr/local \
#     && rm -f cudnn-10.0-linux-x64-v7.tgz \
#     && ldconfig

# osg
# use CA certs from CVMFS
RUN yum -y install osg-ca-certs osg-wn-client \
    && mv /etc/grid-security/certificates /etc/grid-security/certificates.osg-ca-certs \
    && ln -f -s /cvmfs/oasis.opensciencegrid.org/mis/certificates /etc/grid-security/certificates

# htcondor - include so we can chirp
RUN yum -y install condor

# pegasus
# RUN yum -y install pegasus

# Cleaning caches to reduce size of image
RUN yum clean all

# required directories
RUN for MNTPOINT in \
        /cvmfs \
        /hadoop \
        /hdfs \
        /lizard \
        /mnt/hadoop \
        /mnt/hdfs \
        /xenon \
        /spt \
        /stash2 \
        /pyglidein \
        /scratch \
    ; do \
        mkdir -p $MNTPOINT ; \
    done

# make sure we have a way to bind host provided libraries
# see https://github.com/singularityware/singularity/issues/611
RUN mkdir -p /host-libs /etc/OpenCL/vendors

# some extra singularity stuff
COPY .singularity.d /.singularity.d
RUN cd / && \
    ln -s .singularity.d/actions/exec .exec && \
    ln -s .singularity.d/actions/run .run && \
    ln -s .singularity.d/actions/test .shell && \
    ln -s .singularity.d/runscript singularity

# build info
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt

RUN cd /scratch

ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/glidein_start.sh /scratch/glidein_start.sh
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/os_arch.sh /scratch/os_arch.sh
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/log_shipper.sh /scratch/log_shipper.sh
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/startd_cron_scripts/clsim_gpu_test.py /scratch/clsim_gpu_test.py
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/startd_cron_scripts/cvmfs_test.py /scratch/cvmfs_test.py
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/startd_cron_scripts/gridftp_test.py /scratch/gridftp_test.py
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/startd_cron_scripts/post_cvmfs.sh /scratch/post_cvmfs.sh
ADD https://raw.githubusercontent.com/WIPACrepo/pyglidein/master/pyglidein/startd_cron_scripts/pre_cvmfs.sh /scratch/pre_cvmfs.sh

RUN echo $PWD

RUN chmod -R 775 /scratch/*

# RUN exec env -i CPUS=$CPUS GPUS=$GPUS MEMORY=$MEMORY DISK=$DISK WALLTIME=$WALLTIME DISABLE_STARTD_CHECKS=$DISABLE_STARTD_CHECKS SITE=$SITE ResourceName=ResourceName GLIDEIN_DIR=/scratch/ /scratch/glidein_start.sh

# RUN rm -rf .