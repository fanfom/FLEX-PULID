FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# System deps (needed to build insightface extensions)
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

# Avoid git "dubious ownership" warnings in some environments
RUN git config --global --add safe.directory /comfyui || true

# Python deps
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Runtime deps for FaceID (onnxruntime-gpu + insightface)
RUN pip install --no-cache-dir \
      onnxruntime-gpu==1.18.0 \
      insightface \
      scikit-image \
      scipy

# Install PuLID custom node (DO NOT overwrite its __init__.py)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/ToTheBeginning/PuLID.git ComfyUI-PuLID

# If PuLID has requirements.txt, install them (safe even if empty/missing)
RUN if [ -f /comfyui/custom_nodes/ComfyUI-PuLID/requirements.txt ]; then \
      pip install --no-cache-dir -r /comfyui/custom_nodes/ComfyUI-PuLID/requirements.txt; \
    fi

# Ensure ComfyUI can write to user/temp dirs when running as UID 1000
RUN mkdir -p /comfyui/temp /comfyui/user /comfyui/user/__manager /comfyui/user/default && \
    chown -R 1000:1000 /comfyui/temp /comfyui/user

# (Optional) shrink image a bit after building insightface
RUN apt-get purge -y build-essential g++ python3-dev && \
    apt-get autoremove -y && \
    apt-get clean -y

USER 1000

# IMPORTANT: start.sh boots ComfyUI + handler correctly
CMD ["/start.sh"]
