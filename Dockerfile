FROM ubuntu:16.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y cpanminus gcc g++ git make zlib1g-dev unzip wget tabix curl libpng12-dev uuid-dev libssl-dev build-essential libmysqlclient-dev libbz2-dev liblzma-dev locales openssl perl perl-base vim libexpat1-dev  bioperl bioperl-run && apt-get -y purge manpages-dev && apt-get clean

ENV OPT /opt/vep
ENV OPT_SRC $OPT/src
ENV PERL5LIB_TMP $PERL5LIB:$OPT_SRC/ensembl-vep:$OPT_SRC/ensembl-vep/modules
ENV PERL5LIB $PERL5LIB_TMP:$OPT_SRC/bioperl-live
ENV KENT_SRC $OPT/src/ensembl-vep/kent/src
ENV HTSLIB_DIR $OPT_SRC/htslib
ENV MACHTYPE x86_64
ENV DEPS $OPT_SRC
ENV PATH $OPT_SRC/ensembl-vep:$OPT_SRC/var_c_code:$PATH
ENV LANG_VAR en_US.UTF-8

WORKDIR /opt/
RUN mkdir -p $OPT_SRC && cd $OPT_SRC && wget https://github.com/Ensembl/ensembl-vep/archive/release/101.0.tar.gz && tar xzf 101.0.tar.gz && mv ensembl-vep-release-101.0 ensembl-vep && rm 101.0.tar.gz

RUN cd /opt/vep/src/ensembl-vep && wget https://github.com/ucscGenomeBrowser/kent/archive/v335_base.tar.gz && tar xzf v335_base.tar.gz && mv kent-335_base/ kent/ && rm v335_base.tar.gz

RUN cd /opt/vep/src/ensembl-vep/kent/src/lib && echo 'CFLAGS="-fPIC"' > ../inc/localEnvironment.mk && make && cd /opt/vep/src/ensembl-vep/kent/src/jkOwnLib && make

RUN cd $OPT_SRC && wget https://github.com/Ensembl/ensembl-xs/archive/2.3.2.zip -O ensembl-xs.zip && unzip -q ensembl-xs.zip && mv ensembl-xs-2.3.2 ensembl-xs && rm -rf ensembl-xs.zip

RUN cd /opt/vep/src/ensembl-xs && perl Makefile.PL && make && make install && rm -f Makefile* cpanfile

RUN cd /opt/vep/src && wget -q "https://raw.githubusercontent.com/Ensembl/ensembl/release/101/cpanfile" -O "ensembl_cpanfile" && ensembl-vep/travisci/get_dependencies.sh && ensembl-vep/travisci/build_c.sh && cpanm --installdeps --with-recommends --notest --cpanfile ensembl_cpanfile . && cpanm --installdeps --with-recommends --notest --cpanfile ensembl-vep/cpanfile . && cp $HTSLIB_DIR/bgzip $HTSLIB_DIR/tabix $HTSLIB_DIR/htsfile /usr/local/bin/

RUN cd /opt/vep/src/ensembl-vep \
&& echo "n\n" | perl INSTALL.pl \
&& mkdir cache plugin-files \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS CSN \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS ExAC \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS dbNSFP \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS dbscSNV \
&& cd /opt/vep/src/ensembl-vep/plugin-files && wget http://hollywood.mit.edu/burgelab/maxent/download/fordownload.tar.gz && tar xvzf fordownload.tar.gz --strip=1 && rm fordownload.tar.gz \
&& cd /opt/vep/src/ensembl-vep \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS MaxEntScan \
&& echo "n\n" | perl INSTALL.pl -a p --PLUGINS LoFtool \
&& wget -P ~/.vep/Plugins https://raw.githubusercontent.com/Ensembl/VEP_plugins/release/101/LoFtool_scores.txt

RUN apt-get update && apt-get install -y unzip software-properties-common parallel
ENV LC_ALL C.UTF-8
RUN add-apt-repository ppa:ts.sch.gr/ppa
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN apt-get update && apt-get install -y oracle-java8-installer
WORKDIR /opt
RUN  wget http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip && unzip snpEff_latest_core.zip && rm snpEff_latest_core.zip

RUN git clone -b grch38 https://github.com/konradjk/loftee


COPY Dockerfile /opt/Dockerfile
MAINTAINER david.roberson@sevenbridges.com
