FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Установка Git и зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    git \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Установка Python пакетов
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu \
    opencv-python-headless \
    scikit-image \
    scipy \
    Pillow

# 3. Клонирование PuLID с прямой указанием пути
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/balmante/ComfyUI-PuLID-Flux.git && \
    cd ComfyUI-PuLID-Flux && \
    git checkout flux-integration

# 4. Настройка InsightFace
RUN mkdir -p /home/runpod/.insightface && \
    ln -s /runpod-volume/models/insightface /home/runpod/.insightface/models

# 5. Копирование конфига
COPY extra_model_paths.yaml /comfyui/  # Не в config!

# 6. Права доступа
RUN chown -R runpod:runpod /comfyui /home/runpod

USER runpod
