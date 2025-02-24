# Setting up Nvidia, Ollama, and Docker on Linux Ubuntu

Created: 2025-02-23

> :warning: Nvidia card was not originaly designed to be shared in virtual environments, so if you reboot your vm you may need to reboot the host as well.

This guide walks through setting up an Ubuntu system with Nvidia GPU support, including installing drivers, Ollama for AI models, and Docker with Nvidia Container Toolkit.

## Prerequisites
- Ubuntu system (running kernel 6.8.0-40-generic)
- Nvidia GPU (GeForce RTX 4060 Ti)

## 1. Installing Nvidia Drivers

First, install the `inxi` tool to check graphics information:

```bash
sudo apt install inxi -y
```

Check initial graphics configuration:
```bash
inxi -G
```
Output:
```
Graphics:
  Device-1: VMware SVGA II Adapter driver: vmwgfx v: 2.20.0.0
  Device-2: NVIDIA driver: N/A
```

Verify system kernel:
```bash
uname -a
```
Output:
```
Linux nvidiaUbuntu 6.8.0-40-generic #40~22.04.3-Ubuntu SMP PREEMPT_DYNAMIC Tue Jul 30 17:30:19 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```

Add the graphics drivers PPA and install Nvidia components:

```bash
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update

sudo apt-get install --no-install-recommends \
    nvidia-cuda-toolkit \
    nvidia-headless-560-open \
    nvidia-utils-560 \
    libnvidia-encode-560
```

After installation, reboot your system:

```bash
sudo reboot now
```

Verify the installation:
```bash
inxi -G
```
Output:
```
Graphics:
  Device-1: VMware SVGA II Adapter driver: vmwgfx v: 2.20.0.0
  Device-2: NVIDIA driver: nvidia v: 560.35.03
```

Check GPU status:
```bash
nvidia-smi
```
Output:
```
Thu Sep  5 12:04:37 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03              Driver Version: 560.35.03      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 Ti     Off |   00000000:0B:00.0 Off |                  N/A |
|  0%   35C    P8              2W /  165W |       7MiB /  16380MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

Check CUDA version:
```bash
nvcc --version
```
Output:
```
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2021 NVIDIA Corporation
Built on Thu_Nov_18_09:45:30_PST_2021
Cuda compilation tools, release 11.5, V11.5.119
Build cuda_11.5.r11.5/compiler.30672275_0
```

## 2. Installing Ollama

Install Ollama and set it up as a system service:

```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
```

Test Ollama by running a model:

```bash
ollama run llama3.1
```

## 3. Setting up Docker

### Install Docker Engine

Add Docker's official GPG key and repository:

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install ca-certificates curl

# Set up Docker's GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Configure Docker

Remove the `-H fd://` option from the Docker service file:

```bash
sudo vim /lib/systemd/system/docker.service
```

Start and enable Docker:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Set up Docker permissions:

```bash
sudo groupadd docker
```
Note: You might see: `groupadd: group 'docker' already exists`

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verify Docker installation:
```bash
docker --version
```
Output:
```
Docker version 27.2.1, build 9e34c9b
```

Test Docker:
```bash
docker run --rm hello-world
```

## 4. Installing Nvidia Container Toolkit

Add Nvidia Container Toolkit repository and install:

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

Configure Docker to use Nvidia runtime:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
```
Output:
```
WARN[0000] Ignoring runtime-config-override flag for docker
INFO[0000] Config file does not exist; using empty config
INFO[0000] Wrote updated config to /etc/docker/daemon.json
INFO[0000] It is recommended that docker daemon be restarted.
```

Restart Docker:
```bash
sudo systemctl restart docker
```

## Testing GPU Support in Docker

Test with Ubuntu base image:

```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```
Output:
```
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
31e907dcc94a: Pull complete
Digest: sha256:8a37d68f4f73ebf3d4efafbcf66379bf3728902a8038616808f04e34a9ab63ee
Status: Downloaded newer image for ubuntu:latest
Fri Sep  6 03:12:04 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03              Driver Version: 560.35.03      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 Ti     Off |   00000000:0B:00.0 Off |                  N/A |
|  0%   33C    P8              5W /  165W |      10MiB /  16380MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

Test with CUDA base image:

```bash
docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
```
Output:
```
Unable to find image 'nvidia/cuda:11.0.3-base-ubuntu20.04' locally
11.0.3-base-ubuntu20.04: Pulling from nvidia/cuda
96d54c3075c9: Pull complete
59f6381879f6: Pull complete
655ed0df26cf: Pull complete
848b95ad96b5: Pull complete
e43c2058e496: Pull complete
Digest: sha256:c8269d6967e10940c368ea24fb8086cb21471cb8fefc66861d72f74f0c67e904
Status: Downloaded newer image for nvidia/cuda:11.0.3-base-ubuntu20.04
Tue Sep 10 16:56:53 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03              Driver Version: 560.35.03      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 Ti     Off |   00000000:0B:00.0 Off |                  N/A |
|  0%   41C    P8              6W /  165W |    5913MiB /  16380MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

## Conclusion

You now have a fully configured Ubuntu system with Nvidia GPU support, Ollama for AI models, and Docker with GPU passthrough capabilities. This setup is ideal for machine learning development, AI model deployment, and GPU-accelerated containerized applications.


## References

- [Graphics drivers PPA](https://fosslinux.community/forum/linux-gaming/how-to-reinstall-nvidia-gpu-drivers-on-ubuntu-desktop/)
- [Install Ollama](https://ollama.com/download/linux)
- [GPU Passthrough on Linux and Docker for AI, ML](https://youtu.be/9OfoFAljPn4)
- [Install Docker Engine official docs by Docker](https://docs.docker.com/engine/install/ubuntu/)
- [Docker daemon fails with "NO SOCKET FOUND"](https://github.com/moby/moby/issues/22847#issuecomment-236318630)
- [Fix Docker permission denied issue](https://stackoverflow.com/questions/48957195/how-to-fix-docker-got-permission-denied-issue)
- [Installing the NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [Running a Sample Workload](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/sample-workload.html)
- [Specialized Configurations with Docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html)