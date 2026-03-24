FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Установка системных зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-зависимостей (исправленный синтаксис)
RUN pip install --no-cache-dir --force-reinstall \
    insightface==0.7.3 \
    onnxruntime \
    opencv-python-headless==4.9.0.80

# Установка и конфигурация PuLID
ADD https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip /tmp/pulid.zip
RUN cd /comfyui/custom_nodes && \
    unzip -q /tmp/pulid.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm /tmp/pulid.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# Настройка InsightFace
RUN mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models && \
    printf "insightface:\n  base_path: %s\n" "/runpod-volume/models/insightface" > /comfyui/extra_model_paths.yaml

USER 1000

# Команда запуска с диагностикой
CMD nvidia-smi && \
    echo "InsightFace версия: $(python -c 'import insightface; print(insightface.__version__)')" && \
    echo "PuLID установлен: $(ls /comfyui/custom_nodes/ComfyUI-PuLID)" && \
    python -u /comfyui/handler.py
