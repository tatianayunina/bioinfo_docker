# Базовый образ — Ubuntu 22.04
FROM ubuntu:22.04

# Устанавливаем общие системные пакеты
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    ca-certificates \
    git \
    autoconf \
    automake \
    libtool \
    pkg-config \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем переменную окружения SOFT
ENV SOFT=/soft
RUN mkdir -p $SOFT

# Устанавливаем Python-библиотеки
RUN pip3 install --no-cache-dir pysam

# Копируем скрипт
COPY convert_alleles.py /app/convert_alleles.py

WORKDIR /app

# -------------------------------
# libdeflate v1.24 (релиз 2025-05-11)
# -------------------------------
RUN git clone --branch v1.24 https://github.com/ebiggers/libdeflate.git $SOFT/libdeflate_br250511 && \
    cd $SOFT/libdeflate_br250511 && \
    cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate_br250511 && \
    cmake --build build --parallel && \
    cmake --install build && \
    cd / && rm -rf $SOFT/libdeflate_br250511/build

ENV LIBDEFLATE=$SOFT/libdeflate_br250511
ENV PATH=$LIBDEFLATE/bin:$PATH

# -------------------------------
# htslib 1.22 (релиз 2025-05-30)
# -------------------------------
RUN git clone --branch 1.22 https://github.com/samtools/htslib.git $SOFT/htslib_br250530 && \
    cd $SOFT/htslib_br250530 && \
    git submodule update --init --recursive && \
    autoreconf -i && \
    ./configure --prefix=$SOFT/htslib_br250530 && \
    make -j$(nproc) && make install && \
    cd / && rm -rf $SOFT/htslib_br250530/build

ENV HTSLIB=$SOFT/htslib_br250530
ENV PATH=$HTSLIB/bin:$PATH

# -------------------------------
# samtools 1.22 (релиз 2025-05-30)
# -------------------------------
RUN git clone --branch 1.22 https://github.com/samtools/samtools.git $SOFT/samtools_br250530 && \
    cd $SOFT/samtools_br250530 && \
    autoheader && autoconf && ./configure --prefix=$SOFT/samtools_br250530 --with-htslib=$HTSLIB && \
    make -j$(nproc) && make install && \
    cd / && rm -rf $SOFT/samtools_br250530/build

ENV SAMTOOLS=$SOFT/samtools_br250530
ENV PATH=$SAMTOOLS/bin:$PATH

# -------------------------------
# bcftools 1.22 (релиз 2025-05-30)
# -------------------------------
RUN git clone --branch 1.22 https://github.com/samtools/bcftools.git $SOFT/bcftools_br250530 && \
    cd $SOFT/bcftools_br250530 && \
    autoheader && autoconf && ./configure --prefix=$SOFT/bcftools_br250530 --with-htslib=$HTSLIB && \
    make -j$(nproc) && make install && \
    cd / && rm -rf $SOFT/bcftools_br250530/build

ENV BCFTOOLS=$SOFT/bcftools_br250530
ENV PATH=$BCFTOOLS/bin:$PATH

# -------------------------------
# vcftools v0.1.17 (релиз 2025-05-15)
# -------------------------------
RUN git clone --branch v0.1.17 https://github.com/vcftools/vcftools.git $SOFT/vcftools_br250515 && \
    cd $SOFT/vcftools_br250515 && \
    ./autogen.sh && ./configure --prefix=$SOFT/vcftools_br250515 && \
    make -j$(nproc) && make install && \
    cd / && rm -rf $SOFT/vcftools_br250515/build

ENV VCFTOOLS=$SOFT/vcftools_br250515
ENV PATH=$VCFTOOLS/bin:$PATH

# Экспортим переменные окружения для каждой программы
ENV LIBDEFLATE=$SOFT/libdeflate_br250511

# Показываем версии установленных программ
CMD ["bash", "-c", "samtools --version && bcftools --version && vcftools --version"]