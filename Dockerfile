FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Переменные для склейки ссылок
ENV GH_URL="https://github.com"
ENV PULID_REPO="balmante/ComfyUI-PuLID-Flux.git"

# Системные либы для сборки insightface и работы с графикой
RUN apt-get update && apt-get install -y \
    python3-dev \
    g++ \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-пакетов
RUN pip install --no-cache-dir insightface onnxruntime-gpu

# Клонируем ноду PuLID через склейку переменных
RUN cd /home/runpod/comfyui/custom_nodes && \
    git clone ${GH_URL}${PULID_REPO}

# Создаем симлинк, чтобы библиотека insightface видела модели на твоем Network Volume
# Мы связываем стандартный путь поиска (~/.insightface) с твоим диском
RUN mkdir -p /home/runpod/.insightface && \
    ln -s /runpod-volume/models/insightface/models /home/runpod/.insightface/models

# Копируем твой конфиг путей (должен лежать рядом с Dockerfile)
COPY extra_model_paths.yaml /home/runpod/comfyui/extra_model_paths.yaml

# Права доступа
RUN chown -R runpod:runpod /home/runpod/comfyui/ /home/runpod/.insightface

USER runpod
