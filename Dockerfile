ARG CUDA_IMAGE=nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
FROM ${CUDA_IMAGE}

LABEL maintainer="JulienZeng"
LABEL description="Docker image for the GSVI inference fork of GPT-SoVITS"

ARG TORCH_VERSION=2.7.0
ARG TORCHAUDIO_VERSION=2.7.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/workspace/GPT-SoVITS

SHELL ["/bin/bash", "-c"]

WORKDIR /workspace/GPT-SoVITS

RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 \
    build-essential \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    libgl1 \
    libopencc-dev \
    libsndfile1 \
    libsndfile1-dev \
    libsox-dev \
    mecab \
    mecab-ipadic-utf8 \
    p7zip-full \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    sox \
    tar \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip

COPY extra-req.txt requirements.txt /workspace/GPT-SoVITS/

RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install \
    "torch==${TORCH_VERSION}" \
    "torchaudio==${TORCHAUDIO_VERSION}" \
    --index-url "${TORCH_INDEX_URL}" && \
    python -m pip install -r extra-req.txt --no-deps && \
    python -m pip install -r requirements.txt

COPY . /app

RUN mkdir -p /workspace && \
    rm -rf /workspace/GPT-SoVITS && \
    mv /app /workspace/GPT-SoVITS && \
    chmod +x /workspace/GPT-SoVITS/Docker/bootstrap_gsvi_assets.sh /workspace/GPT-SoVITS/Docker/entrypoint_gsvi.sh

EXPOSE 8000

ENTRYPOINT ["/workspace/GPT-SoVITS/Docker/entrypoint_gsvi.sh"]
