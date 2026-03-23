# 1. Установка Python и системных зависимостей
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3.10-venv \
    git \
    wget \
    unzip \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 2. Создание и активация виртуального окружения
RUN python3.10 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 3. Установка Torch с совместимостью для CUDA 12.x
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 4. Установка ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui
WORKDIR /comfyui
RUN pip install --no-cache-dir -r requirements.txt

# 5. Установка зависимостей
RUN pip install --no-cache-dir "numpy<2" && \
    pip install --no-cache-dir \
    insightface==0.7.3 \
    onnxruntime-gpu==1.17.1 \
    opencv-python-headless==4.9.0.80 \
    scikit-image==0.22.0 \
    scipy==1.13.0 \
    Pillow==10.2.0

# 6. Установка PuLID
RUN cd custom_nodes && \
    git clone https://github.com/ToTheBeginning/PuLID.git ComfyUI-PuLID && \
    cd ComfyUI-PuLID && \
    pip install --no-cache-dir -r requirements.txt

# 7. Настройка InsightFace
ENV INSIGHTFACE_ROOT=/models/insightface
RUN mkdir -p $INSIGHTFACE_ROOT && \
    mkdir -p /root/.insightface && \
    ln -s $INSIGHTFACE_ROOT /root/.insightface/models

# 8. Создание конфига
RUN printf "insightface:\n  base_path: %s\npulid:\n  base_path: %s/models/pulid\ncontrolnet:\n  base_path: %s/models/controlnet\nclip_vision:\n  base_path: %s/models/clip_vision" \
    "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" "$INSIGHTFACE_ROOT" > extra_model_paths.yaml

# 9. Создание файла запуска
RUN printf "#!/bin/bash\npython main.py --listen 0.0.0.0 --port 3000" > /run.sh
RUN chmod +x /run.sh

# 10. Открытие порта
EXPOSE 3000

# 11. Запуск обработчика
CMD ["/run.sh"]
