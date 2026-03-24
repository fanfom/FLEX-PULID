FROM runpod/worker-comfyui:5.8.5-flux1-dev

USER root

# System deps for building insightface + runtime libs
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential \
      g++ \
      python3-dev \
      libgl1 \
      libglib2.0-0 \
      wget \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# Python deps
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# onnxruntime-gpu + insightface (may compile parts)
RUN pip install --no-cache-dir \
      onnxruntime-gpu==1.18.0 \
      insightface \
      scikit-image \
      scipy

# Install PuLID custom node
RUN cd /comfyui/custom_nodes && \
    wget -q https://github.com/ToTheBeginning/PuLID/archive/refs/heads/main.zip && \
    unzip -q main.zip && \
    mv PuLID-main ComfyUI-PuLID && \
    rm -f main.zip && \
    echo "from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS" > /comfyui/custom_nodes/ComfyUI-PuLID/__init__.py && \
    echo "__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']" >> /comfyui/custom_nodes/ComfyUI-PuLID/__init__.py

# (Optional) shrink a bit: remove build tools after wheels are built
RUN apt-get purge -y build-essential g++ python3-dev && \
    apt-get autoremove -y && \
    apt-get clean -y

USER 1000

# IMPORTANT: do NOT start handler directly; start.sh boots ComfyUI and then handler
CMD ["/start.sh"]
