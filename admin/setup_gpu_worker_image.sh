#!/usr/bin/env bash

echo "This script should be run after the base worker image setup script."

echo "Installing CUDA and cudnn."

curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
wget -O libcudnn.deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6_6.0.21-1+cuda8.0_amd64.deb
wget -O libcudnn-dev.deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn6-dev_6.0.21-1+cuda8.0_amd64.deb

sudo dpkg -i ./cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
sudo apt-get update
sudo apt-get remove libglx-mesa0
sudo apt-get install nvidia-396 cuda -y
sudo dpkg -i libcudnn.deb
sudo dpkg -i libcudnn-dev.deb

echo 'export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}' >> ~/.profile
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.profile
source ~/.profile

sudo apt-get install -y libcupti-dev libcupti9.1

sudo pip3 install tensorflow-gpu

sudo pip3 install http://download.pytorch.org/whl/cu80/torch-0.2.0.post3-cp36-cp36m-manylinux1_x86_64.whl

# Print out installed versions of packages
PACKAGES="cuda libcupti-dev"
PYTHON_PACKAGES="tensorflow-gpu"

echo "Packages"
for package in ${PACKAGES}; do
    dpkg-query -W ${package}
done

echo "Python 3.6 Packages"
for package in ${PYTHON_PACKAGES}; do
    echo ${package} $(python3.6 -m pip show ${package} | grep Version | awk '{print $2}')
done
