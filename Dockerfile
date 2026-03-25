FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# System deps
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential \
      g++ \
      python3-dev \
      libgl1 \
      libglib2.0-0 \
      wget \
      unzip \
      git \
    && rm -rf /var/lib/apt/lists/*

# Git safe.directory
RUN git config --global --add safe.directory /comfyui || true

# Python deps
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# ═══════════════════════════════════════════════════════
# ИСПРАВЛЕНИЕ #1: NumPy < 2 (ДОЛЖЕН БЫТЬ ПЕРЕД ВСЕМИ ОСТАЛЬНЫМИ pip)
# Без этого onnxruntime и kornia падают с AttributeError: _ARRAY_API
# ═══════════════════════════════════════════════════════
RUN pip install --no-cache-dir "numpy<2.0.0" --force-reinstall

# Runtime deps for FaceID
RUN pip install --no-cache-dir \
      onnxruntime-gpu==1.18.0 \
      insightface \
      scikit-image \
      scipy \
      opencv-python-headless \
      timm \
      einops \
      ftfy \
      facexlib \
      safetensors \
      torchsde

# ═══════════════════════════════════════════════════════
# ИСПРАВЛЕНИЕ #2: PuLID из правильного репозитория
# ToTheBeginning/PuLID может не иметь __init__.py
# Используем рабочий форк
# ═══════════════════════════════════════════════════════
RUN cd /comfyui/custom_nodes && \
    rm -rf ComfyUI-PuLID && \
    git clone --depth 1 https://github.com/balazik/ComfyUI-PuLID-Flux.git ComfyUI-PuLID

# Проверяем что __init__.py существует
RUN ls -la /comfyui/custom_nodes/ComfyUI-PuLID/__init__.py || \
    (echo "ERROR: __init__.py not found!" && exit 1)

# ═══════════════════════════════════════════════════════
# ИСПРАВЛЕНИЕ #3: Создание extra_model_paths.yaml
# ═══════════════════════════════════════════════════════
RUN echo 'ComfyUI:' > /comfyui/extra_model_paths.yaml && \
    echo '  models_path: /runpod-volume/models' >> /comfyui/extra_model_paths.yaml

# ═══════════════════════════════════════════════════════
# ИСПРАВЛЕНИЕ #4: Создание ВСЕХ служебных директорий
# Permission denied: '/comfyui/input/3d' исправляется здесь
# ═══════════════════════════════════════════════════════
RUN mkdir -p \
    /comfyui/temp \
    /comfyui/user \
    /comfyui/user/__manager \
    /comfyui/user/default \
    /comfyui/input \
    /comfyui/input/3d \
    /comfyui/output \
    /runpod-volume/models/pulid \
    /runpod-volume/models/insightface/models/antelopev2 \
    && chown -R 1000:1000 /comfyui/temp /comfyui/user /comfyui/input /comfyui/output \
    && chmod -R 777 /runpod-volume

# Cleanup
RUN apt-get purge -y build-essential g++ python3-dev && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    pip cache purge

USER 1000

CMD ["/start.sh"]
