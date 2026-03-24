FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Определение архитектуры GPU (x86/ARM)
ARG ARCH="x86_64"

# Установка системных зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-зависимостей с совместимыми версиями
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# Динамический выбор onnxruntime-gpu по версии CUDA
RUN if [ -e /usr/local/cuda/version.txt ]; then \
        CUDA_MAJOR=$(cut -d' ' -f3 /usr/local/cuda/version.txt | cut -d'.' -f1); \
        if [ "$CUDA_MAJOR" -ge 12 ]; then \
            pip install --no-cache-dir onnxruntime-gpu==1.17.1; \
        else \
            pip install --no-cache-dir onnxruntime-gpu==1.15.1; \
        fi; \
    else \
        echo "CUDA not detected, installing CPU version"; \
        pip install --no-cache-dir onnxruntime; \
    fi

# Установка и конфигурация PuLID
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip && \
    unzip -q main.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm main.zip && \
    printf "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS\n__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" > ComfyUI-PuLID/__init__.py

# Настройка путей для InsightFace
RUN mkdir -p /root/.insightface && \
    ln -s /runpod-volume/models/insightface /root/.insightface/models && \
    printf "insightface:\n  base_path: %s\n" "/runpod-volume/models/insightface" > /comfyui/extra_model_paths.yaml

# Поддержка старых карт
RUN if [ -f /usr/local/bin/install_old_cuda_drivers.sh ]; then \
        /usr/local/bin/install_old_cuda_drivers.sh; \
    else \
        echo "Deprecated driver support script not found"; \
    fi

# Возраст к стандартному пользователю
USER 1000

CMD ["python", "-u", "/comfyui/handler.py"]
