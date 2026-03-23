# Используем современный стабильный образ
FROM runpod/worker-comfyui:6.1.2-fp16

USER root

# Установка системных зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    python3-dev \
    build-essential \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Установка Python-пакетов (без комментариев внутри!)
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.18.0 \
    opencv-python-headless \
    scikit-image \
    scipy \
    Pillow

# Клонирование PuLID
RUN cd /comfyui/custom_nodes && \
    git clone --branch main --depth 1 \
    https://github.com/balmante/ComfyUI-PuLID-Flux.git && \
    chown -R runpod:runpod ComfyUI-PuLID-Flux

# Настройка InsightFace
ENV INSIGHTFACE_ROOT=/runpod-volume/models/insightface

# Копирование конфига
COPY extra_model_paths.yaml /comfyui/config/

USER runpod
