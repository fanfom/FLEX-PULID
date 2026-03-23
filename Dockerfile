# Используем новейший стабильный native образ с FP16 из официальных тегов
FROM runpod/worker-comfyui:6.1.2-fp16

USER root

# 1. Установка минимальных зависимостей с очисткой
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    python3-dev \
    build-essential \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. Установка Python-пакетов (стабильные версии)
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \  # Совместима с CUDA в 6.1.2
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# 3. Клонирование PuLID без .git истории
RUN cd /comfyui/custom_nodes && \
    git clone --branch flux-integration --depth 1 \
    https://github.com/balmante/ComfyUI-PuLID-Flux.git && \
    chown -R runpod:runpod ComfyUI-PuLID-Flux

# 4. Настройка InsightFace через ENV
ENV INSIGHTFACE_ROOT=/runpod-volume/models/insightface

# 5. Копирование конфига в стандартный путь для ComfyUI 6.x
COPY extra_model_paths.yaml /comfyui/config/

# 6. Подтверждаем наличие CLI utils
RUN python --version && pip list

USER runpod
