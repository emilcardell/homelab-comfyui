# ==========================================
# ComfyUI + Qwen-Image + Hunyuan3D (ROCm 7.1)
# ==========================================
FROM ubuntu:22.04

# -----------------------------
# System setup
# -----------------------------
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y wget git python3 python3-pip python3-venv libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------
# Install ROCm 7.1 and PyTorch (ROCm-enabled)
# -----------------------------
# Add ROCm repository
RUN wget https://repo.radeon.com/rocm/rocm.gpg.key -O /etc/apt/trusted.gpg.d/rocm.gpg && \
    echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/7.1 jammy main" > /etc/apt/sources.list.d/rocm.list && \
    apt-get update && \
    apt-get install -y rocm-dev rocm-libs miopen-hip hipblas hipfft rocblas rocfft hipcub && \
    echo 'export PATH=/opt/rocm/bin:$PATH' >> /etc/bash.bashrc && \
    echo 'export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH' >> /etc/bash.bashrc

# -----------------------------
# Create workspace and install ComfyUI
# -----------------------------
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && pip install --upgrade pip

# -----------------------------
# Install PyTorch with ROCm
# -----------------------------
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm7.1

# -----------------------------
# Install additional dependencies
# -----------------------------
RUN pip install accelerate transformers safetensors opencv-python Pillow tqdm einops scipy

# -----------------------------
# Install Hunyuan3D and Qwen-Image ComfyUI nodes
# -----------------------------
WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/Tencent/Hunyuan3D-2.1-ComfyUI.git && \
    git clone https://github.com/Comfy-Org/Qwen-Image_ComfyUI.git

# -----------------------------
# Copy model weights into image
# -----------------------------
WORKDIR /workspace/ComfyUI/models
# Assumes you have these files in the same directory as the Dockerfile
COPY qwen_image_fp8_e4m3fn.safetensors ./checkpoints/
COPY qwen2.5_vl_7b_fp8_scaled.safetensors ./text_encoders/
COPY qwen_image_vae.safetensors ./vae/

# -----------------------------
# Expose port and launch ComfyUI
# -----------------------------
EXPOSE 8188
WORKDIR /workspace/ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
