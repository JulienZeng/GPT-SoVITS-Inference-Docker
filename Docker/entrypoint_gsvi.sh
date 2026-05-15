#!/usr/bin/env bash

set -euo pipefail

APP_DIR="/workspace/GPT-SoVITS"

cd "$APP_DIR"

mkdir -p \
  cache \
  custom_refs \
  outputs \
  models/v2 \
  models/v3 \
  models/v4 \
  models/v2Pro \
  models/v2ProPlus \
  GPT_SoVITS/pretrained_models \
  GPT_SoVITS/text \
  GPT_SoVITS/text/G2PWModel \
  tools/asr/models \
  tools/uvr5/uvr5_weights

if [ "${GSVI_BOOTSTRAP_MODELS:-true}" = "true" ]; then
  "$APP_DIR/Docker/bootstrap_gsvi_assets.sh"
fi

if ! find "$APP_DIR/models" -mindepth 2 -maxdepth 2 -type d | grep -q .; then
  echo "[entrypoint] warning: no speaker packages found under models/<version>/<speaker>."
  echo "[entrypoint] the API can start, but synthesis will need model packages in $APP_DIR/models."
fi

exec python gsvi.py \
  -s "${GSVI_HOST:-0.0.0.0}" \
  -p "${GSVI_PORT:-8000}" \
  -k "${GSVI_KEY:-}" \
  -c "${GSVI_CONFIG:-./GPT_SoVITS/configs/tts_infer.yaml}" \
  -r "${GSVI_REF_AUDIO_DIR:-./custom_refs}"
