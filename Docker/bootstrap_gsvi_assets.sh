#!/usr/bin/env bash

set -euo pipefail

APP_DIR="/workspace/GPT-SoVITS"
TMP_DIR="/tmp/gsvi-bootstrap"
MODEL_SOURCE="${MODEL_SOURCE:-HF}"
DOWNLOAD_G2PW="${GSVI_DOWNLOAD_G2PW:-true}"
DOWNLOAD_UVR5="${GSVI_DOWNLOAD_UVR5:-false}"

mkdir -p "$TMP_DIR"

case "$MODEL_SOURCE" in
  HF)
    PRETRAINED_URL="https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/pretrained_models.zip"
    G2PW_URL="https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/G2PWModel.zip"
    UVR5_URL="https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/uvr5_weights.zip"
    NLTK_URL="https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/nltk_data.zip"
    OPEN_JTALK_URL="https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/open_jtalk_dic_utf_8-1.11.tar.gz"
    ;;
  HF-Mirror)
    PRETRAINED_URL="https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/pretrained_models.zip"
    G2PW_URL="https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/G2PWModel.zip"
    UVR5_URL="https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/uvr5_weights.zip"
    NLTK_URL="https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/nltk_data.zip"
    OPEN_JTALK_URL="https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/open_jtalk_dic_utf_8-1.11.tar.gz"
    ;;
  ModelScope)
    PRETRAINED_URL="https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/pretrained_models.zip"
    G2PW_URL="https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/G2PWModel.zip"
    UVR5_URL="https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/uvr5_weights.zip"
    NLTK_URL="https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/nltk_data.zip"
    OPEN_JTALK_URL="https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/open_jtalk_dic_utf_8-1.11.tar.gz"
    ;;
  *)
    echo "Unsupported MODEL_SOURCE: $MODEL_SOURCE"
    exit 1
    ;;
esac

download_with_retry() {
  local url="$1"
  local output="$2"
  if command -v aria2c >/dev/null 2>&1; then
    aria2c -x8 -s8 -c "$url" -d "$(dirname "$output")" -o "$(basename "$output")"
  else
    wget -O "$output" "$url"
  fi
}

ensure_pretrained_models() {
  if [ -f "$APP_DIR/GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s2G2333k.pth" ] \
    && [ -d "$APP_DIR/GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large" ] \
    && [ -d "$APP_DIR/GPT_SoVITS/pretrained_models/chinese-hubert-base" ]; then
    return
  fi

  echo "[bootstrap] downloading pretrained_models.zip from $MODEL_SOURCE"
  download_with_retry "$PRETRAINED_URL" "$TMP_DIR/pretrained_models.zip"
  unzip -q -o "$TMP_DIR/pretrained_models.zip" -d "$APP_DIR/GPT_SoVITS"
}

ensure_g2pw_model() {
  if [ "${DOWNLOAD_G2PW,,}" != "true" ]; then
    return
  fi

  if find "$APP_DIR/GPT_SoVITS/text/G2PWModel" -mindepth 1 | grep -q .; then
    return
  fi

  echo "[bootstrap] downloading G2PWModel.zip from $MODEL_SOURCE"
  download_with_retry "$G2PW_URL" "$TMP_DIR/G2PWModel.zip"
  unzip -q -o "$TMP_DIR/G2PWModel.zip" -d "$APP_DIR/GPT_SoVITS/text"
}

ensure_uvr5_models() {
  if [ "${DOWNLOAD_UVR5,,}" != "true" ]; then
    return
  fi

  if find "$APP_DIR/tools/uvr5/uvr5_weights" -mindepth 1 ! -name '.gitignore' | grep -q .; then
    return
  fi

  echo "[bootstrap] downloading uvr5_weights.zip from $MODEL_SOURCE"
  download_with_retry "$UVR5_URL" "$TMP_DIR/uvr5_weights.zip"
  unzip -q -o "$TMP_DIR/uvr5_weights.zip" -d "$APP_DIR/tools/uvr5"
}

ensure_nltk_data() {
  local py_prefix
  py_prefix="$(python -c 'import sys; print(sys.prefix)')"

  if [ -d "$py_prefix/nltk_data" ]; then
    return
  fi

  echo "[bootstrap] downloading nltk_data.zip from $MODEL_SOURCE"
  download_with_retry "$NLTK_URL" "$TMP_DIR/nltk_data.zip"
  unzip -q -o "$TMP_DIR/nltk_data.zip" -d "$py_prefix"
}

ensure_open_jtalk_dict() {
  local pyopenjtalk_prefix
  pyopenjtalk_prefix="$(python -c 'import os, pyopenjtalk; print(os.path.dirname(pyopenjtalk.__file__))')"

  if [ -d "$pyopenjtalk_prefix/open_jtalk_dic_utf_8-1.11" ]; then
    return
  fi

  echo "[bootstrap] downloading open_jtalk dictionary from $MODEL_SOURCE"
  download_with_retry "$OPEN_JTALK_URL" "$TMP_DIR/open_jtalk_dic_utf_8-1.11.tar.gz"
  tar -xzf "$TMP_DIR/open_jtalk_dic_utf_8-1.11.tar.gz" -C "$pyopenjtalk_prefix"
}

ensure_pretrained_models
ensure_g2pw_model
ensure_nltk_data
ensure_open_jtalk_dict
ensure_uvr5_models

rm -rf "$TMP_DIR"
