FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# 1. Устанавливаем только необходимые системные пакеты
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Минимальный набор Python-зависимостей (+ force reinstall для конфликтующих)
RUN pip install --no-cache-dir --force-reinstall \
    insightface==0.7.3 \
    onnxruntime \  # Используем CPU-версию как страховку
    opencv-python-headless==4.9.0.80

# 3. Установка PuLID без скачивания - локальное копирование
ADD https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip /tmp/pulid.zip
RUN cd /comfyui/custom_nodes && \
    unzip -q /tmp/pulid.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm /tmp/pulid.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> ComfyUI-PuLID/__init__.py

# 4. Настройка пути InsightFace (важная оптимизация)
RUN printf "insightface:\n  base_path: %s\n" "/runpod-volume/models/insightface" > /comfyui/extra_model_paths.yaml && \
    mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models
    
USER 1000

# 5. Переопределение команды запуска для диагностики
CMD echo "Загрузка зависимостей завершена" && \
    nvidia-smi && \
    python -c "import insightface; print(f'InsightFace version: {insightface.__version__}')" && \
    python -u /comfyui/handler.py
