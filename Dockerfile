FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# Системные зависимости
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libgl1 \
        libglib2.0-0 \
        libglib2.0-dev \
        wget \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Обновляем pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Определяем версию CUDA через torch и ставим onnxruntime-gpu
RUN CUDA_VER=$(python3 -c "import torch; v=torch.version.cuda; print(v[:4] if v else '0')" 2>/dev/null || echo "0") && \
    echo "Detected CUDA: $CUDA_VER" && \
    if echo "$CUDA_VER" | grep -qE "^12\."; then \
        pip install --no-cache-dir onnxruntime-gpu==1.18.0; \
    elif echo "$CUDA_VER" | grep -qE "^11\."; then \
        pip install --no-cache-dir onnxruntime-gpu==1.16.3; \
    else \
        pip install --no-cache-dir onnxruntime-gpu; \
    fi

# Ставим insightface и зависимости
RUN pip install --no-cache-dir \
    insightface==0.7.3 \
    scikit-image \
    scipy

# opencv ставим только если не установлен
RUN python3 -c "import cv2; print('cv2 OK:', cv2.__version__)" 2>/dev/null || \
    pip install --no-cache-dir opencv-python-headless

# Установка ComfyUI-PuLID
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip && \
    unzip -q main.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm main.zip

# __init__.py для ComfyUI — через printf, без heredoc
RUN printf 'from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS\n__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS"]\n' \
    > /comfyui/custom_nodes/ComfyUI-PuLID/__init__.py

# Пути InsightFace
RUN mkdir -p /root/.insightface && \
    ln -sf /runpod-volume/models/insightface /root/.insightface/models

# extra_model_paths.yaml — через printf, без heredoc
RUN printf 'comfyui:\n    base_path: /comfyui/\n    clip_vision: /runpod-volume/models/clip_vision/\n    controlnet: /runpod-volume/models/controlnet/\n    pulid: /runpod-volume/models/pulid/\n    insightface: /runpod-volume/models/insightface/\n\ninsightface:\n    base_path: /runpod-volume/models/insightface\n' \
    > /comfyui/extra_model_paths.yaml

# Проверка импортов
RUN python3 -c "import insightface; import cv2; import onnxruntime; print('All imports OK')"

USER 1000

CMD ["python", "-u", "/comfyui/handler.py"]
