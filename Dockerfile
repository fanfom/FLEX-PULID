FROM runpod/worker-comfyui:5.8.5-flux1-dev

# Исправляем проблему прав для совместимости с RunPod
USER root
RUN chown 1000:1000 /comfyui /runpod-volume

# Устанавливаем системные зависимости
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем необходимые Python-пакеты (без строгой версионности)
RUN pip install --no-cache-dir \
    insightface \
    onnxruntime-gpu \
    opencv-python-headless \
    scikit-image \
    scipy \
    Pillow

# Устанавливаем и конфигурируем PuLID
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip -O pulid.zip && \
    unzip -q pulid.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm pulid.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# Настройка InsightFace
RUN mkdir -p /runpod-volume/models/insightface && \
    mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models

# Конфигурация модели
RUN printf "insightface:\n  base_path: %s" "/runpod-volume/models/insightface" > /comfyui/extra_model_paths.yaml

# Убеждаемся, что handler.py корректен
RUN echo "from ComfyUI_handler import ComfyUI_Handler" > /comfyui/handler.py && \
    echo "handler = ComfyUI_Handler()" >> /comfyui/handler.py

# Проверка установки - минимум для отладки
RUN echo "Check handler:" && cat /comfyui/handler.py && \
    echo "Check PuLID:" && ls /comfyui/custom_nodes/ComfyUI-PuLID

# Возвращаемся к рекомендуемым правам
USER 1000

# Оставляем стандартный CMD как есть
