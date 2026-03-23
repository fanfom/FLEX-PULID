FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Системные зависимости
RUN apt-get update && apt-get install -y \
    python3-dev \
    g++ \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Python-пакеты с фиксированными версиями
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \
    opencv-python-headless==4.9.0.80

# Клонирование PuLID с нужной веткой
RUN cd /home/runpod/comfyui/custom_nodes && \
    git clone --branch flux-integration --depth 1 \
    https://github.com/balmante/ComfyUI-PuLID-Flux.git

# Установка зависимостей PuLID
RUN cd /home/runpod/comfyui/custom_nodes/ComfyUI-PuLID-Flux && \
    pip install --no-cache-dir -r requirements.txt

# Настройка InsightFace
RUN mkdir -p /home/runpod/.insightface && \
    ln -s /runpod-volume/models/insightface /home/runpod/.insightface/models

# Копирование конфигурации путей моделей
COPY extra_model_paths.yaml /home/runpod/comfyui/

# Права доступа
RUN chown -R runpod:runpod /home/runpod/comfyui/ /home/runpod/.insightface
