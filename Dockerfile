FROM runpod/worker-comfyui:6.1.2-flux1

# 1. Смена пользователя обязательна для установки пакетов
USER root

# 2. Установка ТОЛЬКО критических зависимостей
RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    python3-dev \
    build-essential \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/*

# 3. Установка Python-пакетов в системное окружение
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.18.0 \
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# 4. Клонирование PuLID
RUN cd /comfyui/custom_nodes && \
    git clone --branch flux-integration --depth 1 \
    https://github.com/balmante/ComfyUI-PuLID-Flux.git && \
    chown -R runpod:runpod ComfyUI-PuLID-Flux

# 5. Настройка InsightFace через ENV
ENV INSIGHTFACE_ROOT=/runpod-volume/models/insightface

# 6. Копирование конфига в надлежащий путь
COPY extra_model_paths.yaml /comfyui/config/  # Критически важный путь

# 7. Возврат к стандартному пользователю
USER runpod
