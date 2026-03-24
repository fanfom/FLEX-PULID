FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Очистка кеша пакетов и обновление
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update -y

# Установка системных зависимостей
RUN apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    wget \
    unzip

# Обновление pip и установка зависимостей с совместимыми версиями
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    insightface==0.7.3 \
    opencv-python-headless==4.9.0.80 \
    Pillow==10.2.0 \
    scikit-image==0.22.0 \
    scipy==1.13.0
# Динамическая установка onnxruntime-gpu
RUN if [ -f /usr/local/cuda/version.txt ]; then \
        cuda_ver=$(cat /usr/local/cuda/version.txt | awk '{print $3}' | cut -d. -f1-2); \
        if [ "$cuda_ver" = "12.1" ]; then \
            pip install --no-cache-dir onnxruntime-gpu==1.17.1; \
        else \
            pip install --no-cache-dir onnxruntime-gpu==1.15.1; \
        fi; \
    else \
        pip install --no-cache-dir onnxruntime; \
    fi

# Установка и конфигурация PuLID
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
