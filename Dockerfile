FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GRADIO_SERVER_NAME=0.0.0.0

# Install necessary packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    openssh-client \
    build-essential \
    git && \
    rm -rf /var/lib/apt/lists/*

COPY . /lang-segment-anything

# Install dependencies
WORKDIR /lang-segment-anything

EXPOSE 8000

# Create user and set permissions
RUN useradd -ms /bin/bash fbarraganc && \
    usermod -aG sudo fbarraganc && \
    mkdir -p /home/fbarraganc/.cache/huggingface/hub && \
    mkdir -p /home/fbarraganc/.cache/torch/hub/checkpoints && \
    chown -R fbarraganc:fbarraganc /home/fbarraganc/.cache && \
    chown -R fbarraganc:fbarraganc /lang-segment-anything

# Copy model files as root to ensure proper permissions
COPY --chown=fbarraganc:fbarraganc /lang_sam/checkpoints/sam2.1_hiera_small.pt /home/fbarraganc/.cache/torch/hub/checkpoints/
COPY --chown=fbarraganc:fbarraganc /lang_sam/checkpoints/models--IDEA-Research--grounding-dino-base/ /home/fbarraganc/.cache/huggingface/hub/models/IDEA-Research/grounding-dino-base/

# Ensure permissions for models (execute as root)
RUN chown -R fbarraganc:fbarraganc /home/fbarraganc/.cache/huggingface && \
    chown -R fbarraganc:fbarraganc /home/fbarraganc/.cache/torch && \
    chmod -R u+rw /home/fbarraganc/.cache/huggingface && \
    chmod -R u+rw /home/fbarraganc/.cache/torch

# Switch to non-root user
USER fbarraganc

# Set cache environment variables
ENV HF_HOME /home/fbarraganc/.cache/huggingface
ENV TORCH_HOME /home/fbarraganc/.cache/torch
ENV TRANSFORMERS_CACHE /home/fbarraganc/.cache/huggingface
ENV TRANSFORMERS_OFFLINE 1

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Entry point
CMD ["python3", "app.py"]
