FROM runpod/worker-comfyui:5.8.5-flux1-dev

# Установка системных зависимостей
USER root
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-зависимостей
RUN pip install --no-cache-dir \
    insightface \
    onnxruntime-gpu \
    opencv-python-headless \
    scikit-image \
    scipy \
    Pillow

# Установка PuLID
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

# Создание конфигурационного файла
RUN printf "insightface:\n  base_path: %s\n" "/runpod-volume/models/insightface" > /comfyui/extra_model_paths.yaml

# Корректировка handler.py (если необходимо)
# Базовый образ уже содержит правильный handler.py, поэтому просто проверяем его
RUN echo "Проверка handler.py:" && \
    if [ -f "/comfyui/handler.py" ]; then \
        echo "Файл handler.py существует"; \
        echo "Содержимое:"; \
        cat /comfyui/handler.py; \
    else \
        echo "Создаем handler.py"; \
        echo "from ComfyUI_handler import ComfyUI_Handler" > /comfyui/handler.py; \
        echo "handler = ComfyUI_Handler()" >> /comfyui/handler.py; \
    fi

# Возврат к стандартному пользователю
USER 1000

# Стандартная команда запуска
CMD ["python", "-u", "/comfyui/handler.py"]
