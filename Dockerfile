FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Обновление apt и установка системных зависимостей
# g++ и build-essential НУЖНЫ для компиляции insightface
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    libgl1 \
    libglib2.0-0 \
    wget \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Обновление pip и базовые пакеты
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Установка onnxruntime-gpu (CUDA 12.x из базового образа)
RUN pip install --no-cache-dir onnxruntime-gpu==1.18.0

# Установка insightface и зависимостей
# insightface требует g++ для сборки Cython-расширения
RUN pip install --no-cache-dir \
    insightface\
    scikit-image \
    scipy

# Установка PuLID
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip && \
    unzip -q main.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm main.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# Настройка InsightFace
RUN mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models && \
    printf "insightface:\n  base_path: /runpod-volume/models/insightface\n" > /comfyui/extra_model_paths.yaml

USER 1000

CMD ["python", "-u", "/comfyui/handler.py"]
