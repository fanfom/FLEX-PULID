FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Установка зависимостей (без Git)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Установка Python пакетов
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow>=10.0.0

# 3. Скачивание PuLID с помощью wget вместо Git
RUN mkdir -p /comfyui/custom_nodes/ComfyUI-PuLID-Flux && \
    cd /comfyui/custom_nodes/ComfyUI-PuLID-Flux && \
    wget -q -O - https://github.com/balmante/ComfyUI-PuLID-Flux/archive/refs/heads/flux-integration.tar.gz | tar xz --strip-components=1

# 4. Настройка InsightFace (без использования кириллических символов)
RUN mkdir -p /home/runpod/.insightface && \
    ln -s /runpod-volume/models/insightface /home/runpod/.insightface/models

# 5. Встроенное создание конфигурационного файла
RUN echo "insightface:" > /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/models/insightface" >> /comfyui/extra_model_paths.yaml && \
    echo "pulid:" >> /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/models/pulid" >> /comfyui/extra_model_paths.yaml && \
    echo "controlnet:" >> /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/models/controlnet" >> /comfyui/extra_model_paths.yaml && \
    echo "clip_vision:" >> /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/models/clip_vision" >> /comfyui/extra_model_paths.yaml

# 6. Установка прав
RUN chown -R runpod:runpod /comfyui /home/runpod

USER runpod
