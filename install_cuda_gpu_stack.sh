#!/bin/bash

set -e

# ----------------------------------------
# CONFIGURATION - Change version here
# ----------------------------------------
CUDA_VERSION="12.8.0"
CUDA_MAJOR="12-8"
UBUNTU_VERSION="wsl-ubuntu"
CUDA_DEB="cuda-repo-${UBUNTU_VERSION}-${CUDA_MAJOR}-local_${CUDA_VERSION}-1_amd64.deb"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_DEB}"

# ----------------------------------------
# 1. Install CUDA Toolkit (nvcc, etc.)
# ----------------------------------------
echo "[1/4] Downloading CUDA Toolkit ${CUDA_VERSION}..."
wget -q ${CUDA_URL} -O ${CUDA_DEB}
sudo dpkg -i ${CUDA_DEB}
sudo cp /var/cuda-repo-${UBUNTU_VERSION}-${CUDA_MAJOR}-local/*.pub /usr/share/keyrings/
sudo apt-get update
sudo apt-get install -y cuda-toolkit-${CUDA_MAJOR}

# ----------------------------------------
# 2. Add CUDA to PATH
# ----------------------------------------
echo "[2/4] Adding CUDA to PATH..."
CUDA_PATH="/usr/local/cuda-${CUDA_MAJOR}"
if ! grep -q "${CUDA_PATH}/bin" ~/.bashrc; then
  echo "export PATH=${CUDA_PATH}/bin:\$PATH" >> ~/.bashrc
  echo "export LD_LIBRARY_PATH=${CUDA_PATH}/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
fi
source ~/.bashrc

# ----------------------------------------
# 3. Install NVIDIA Container Toolkit
# ----------------------------------------
echo "[3/4] Installing NVIDIA Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# ----------------------------------------
# 4. Configure Docker for GPU
# ----------------------------------------
echo "[4/4] Configuring Docker GPU runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

echo "✅ All done! Restart Docker Desktop from Windows to apply changes."
echo "To test: docker run --rm --gpus all nvidia/cuda:${CUDA_VERSION}-base-ubuntu22.04 nvidia-smi"
