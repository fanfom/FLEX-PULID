FROM runpod/worker-comfyui:5.8.5-flux1-dev

# Установка минимальных системных зависимостей
USER root
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-зависимостей без строгих версий
RUN pip install --no-cache-dir \
    insightface \
    onnxruntime-gpu \
    opencv-python-headless \
    scikit-image \
    scipy \
    Pillow

# Установка PuLID с автоматической конфигурацией
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip -O pulid.zip && \
    unzip -q pulid.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm pulid.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# Настройка путей для InsightFace
RUN mkdir -p /runpod-volume/models/insightface && \
    mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models

# Создание конфигурационного файла
RUN echo "insightface:" > /comfyui/extra_model_paths.yaml && \
    echo "  base_path: /runpod-volume/models/insightface" >> /comfyui/extra_model_paths.yaml

# Гарантированная настройка обработчика
RUN wget -q https://raw.githubusercontent.com/runpod/runpod-worker-comfy/main/ComfyUI_handler.py -O /comfyui/ComfyUI_handler.py && \
    echo "from ComfyUI_handler import ComfyUI_Handler" > /comfyui/handler.py && \
    echo "handler = ComfyUI_Handler()" >> /comfyui/handler.py

# Проверка критических компонентов
RUN echo "=== Проверка PuLID ===" && \
    ls -la /comfyui/custom_nodes/ComfyUI-PuLID && \
    echo "=== Проверка обработчика ===" && \
    ls -la /comfyui/ComfyUI_handler.py /comfyui/handler.py

# Возврат к стандартному пользователю образа
USER 1000

# Стандартная команда запуска
CMD ["python", "-u", "/comfyui/handler.py"]
