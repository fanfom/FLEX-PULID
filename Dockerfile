FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Установка всех зависимостей включая curl (вместо wget)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
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
    Pillow==10.2.0

# 3. Создание целевой директории для PuLID
RUN mkdir -p /comfyui/custom_nodes/ComfyUI-PuLID-Flux

# 4. Загрузка файлов PuLID напрямую через GitHub API
RUN curl -sL https://api.github.com/repos/balmante/ComfyUI-PuLID-Flux/tarball/flux-integration | \
    tar -xz --strip-components=1 -C /comfyui/custom_nodes/ComfyUI-PuLID-Flux

# 5. Настройка InsightFace через переменную окружения
ENV INSIGHTFACE_ROOT=/runpod-volume/models/insightface
RUN mkdir -p /home/runpod/.insightface && \
    ln -s $INSIGHTFACE_ROOT /home/runpod/.insightface/models

# 6. Создание конфига
RUN printf "insightface:\n  base_path: /runpod-volume/models/insightface\npulid:\n  base_path: /runpod-volume/models/pulid\ncontrolnet:\n  base_path: /runpod-volume/models/controlnet\nclip_vision:\n  base_path: /runpod-volume/models/clip_vision" > /comfyui/extra_model_paths.yaml

# 7. Установка владельца
RUN chown -R runpod:runpod /comfyui /home/runpod

USER runpod
