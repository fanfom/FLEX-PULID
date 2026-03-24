FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Установка зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Фикс совместимости NumPy
RUN pip install --no-cache-dir "numpy<2" && \
    pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# 3. Установка PuLID с исправлением структуры
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip -O pulid.zip && \
    unzip -q pulid.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm pulid.zip && \
    # Создаем недостающий __init__.py
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# 4. Настройка InsightFace
ENV INSIGHTFACE_ROOT=/runpod-volume/models/insightface
RUN mkdir -p $INSIGHTFACE_ROOT && \
    mkdir -p /root/.insightface && \
    ln -s $INSIGHTFACE_ROOT /root/.insightface/models

# 5. Создание конфига
RUN printf "insightface:\n  base_path: %s\npulid:\n  base_path: %s/models/pulid\ncontrolnet:\n  base_path: %s/models/controlnet\nclip_vision:\n  base_path: %s/models/clip_vision" \
    "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" > /comfyui/extra_model_paths.yaml

# 6. Гарантированная установка ComfyUI_handler
RUN wget -q https://raw.githubusercontent.com/runpod/runpod-worker-comfy/main/ComfyUI_handler.py -O /comfyui/ComfyUI_handler.py

# 7. Гарантированное создание handler.py
RUN echo "from ComfyUI_handler import ComfyUI_Handler" > /comfyui/handler.py && \
    echo "handler = ComfyUI_Handler()" >> /comfyui/handler.py

# 8. Проверка установки
RUN echo "=== Проверка критических файлов ===" && \
    ls -la /comfyui/ComfyUI_handler.py && \
    ls -la /comfyui/handler.py && \
    echo "=== Содержимое handler.py ===" && \
    cat /comfyui/handler.py && \
    echo "=== Проверка PuLID ===" && \
    ls -la /comfyui/custom_nodes/ComfyUI-PuLID && \
    echo "=== Содержимое __init__.py ===" && \
    cat /comfyui/custom_nodes/ComfyUI-PuLID/__init__.py

# 9. Запуск обработчика
CMD ["python", "-u", "/comfyui/handler.py"]
