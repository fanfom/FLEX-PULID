FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Обновляем индексы пакетов и устанавливаем зависимости - ОБЪЕДИНЕНО В ОДНУ КОМАНДУ
RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    python3-dev \
    g++ \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. OpenCV установка через pip вместо apt
RUN pip install --no-cache-dir opencv-python-headless==4.9.0.80

# 3. Установка Python-пакетов с явным указанием версий
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# 4. Клонирование PuLID
RUN cd /home/runpod/comfyui/custom_nodes && \
    git clone --branch flux-integration --depth 1 \
    https://github.com/balmante/ComfyUI-PuLID-Flux.git && \
    rm -rf /home/runpod/comfyui/custom_nodes/ComfyUI-PuLID-Flux/.git

# 5. Настройка InsightFace
RUN mkdir -p /home/runpod/.insightface && \
    ln -s /runpod-volume/models/insightface /home/runpod/.insightface/models

# 6. Копирование конфигурации путей моделей
COPY extra_model_paths.yaml /home/runpod/comfyui/

# 7. Права доступа
RUN chown -R runpod:runpod /home/runpod /home/runpod/.insightface

USER runpod
