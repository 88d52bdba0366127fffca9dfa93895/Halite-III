#!/usr/bin/env bash

set -e

NUM_BOTS=4

## Create a user to be used by the worker exclusively.
sudo groupadd bots
sudo useradd -m worker -U -G bots -s /bin/bash
for i in $(seq 0 $((NUM_BOTS-1))); do
    sudo groupadd bots_$i
    sudo usermod -aG bots_$i worker
done

## Add necessary repositories for Node.js.
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

## Add Mono repository.
# http://www.mono-project.com/download/#download-lin
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/ubuntu bionic main" | sudo tee /etc/apt/sources.list.d/mono-official.list

## Add dotnet repo.
# https://www.microsoft.com/net/learn/get-started/linuxubuntu
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get install apt-transport-https

## Add Dart repository.
# https://www.dartlang.org/install/linux
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

## Add D/DMD repository.
# http://d-apt.sourceforge.net/
sudo wget http://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
sudo apt-get update --allow-insecure-repositories && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring && sudo apt-get update

## Add sbt repository.
# https://www.scala-sbt.org/1.0/docs/Installing-sbt-on-Linux.html
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823

## Add for Erlang + Elixir Support
# https://www.erlang-solutions.com/resources/download.html
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb

sudo apt-get update
sudo apt-get -y upgrade

## List the packages to install for running bots.
PACKAGES="build-essential gcc g++ python3 python3-pip git ocaml openjdk-8-jdk php ruby scala nodejs mono-complete dotnet-sdk-2.1 libgeos-dev tcl8.5 mit-scheme racket octave luajit lua5.2 ghc esl-erlang coffeescript dart fp-compiler sbcl dmd-compiler mono-vbnc gnat-6 cmake python3-dev python-numpy cython clang libicu-dev elixir sbt libboost-python-dev libboost-all-dev"

## List the packages to install for the worker itself.
WORKER_PACKAGES="virtualenv cgroup-tools unzip iptables-persistent"

## List Python packages to preinstall.
PYTHON_PACKAGES="numpy scipy scikit-learn pillow h5py tensorflow keras theano shapely flask cython pandas torchvision"
## List Ruby gems to preinstall.
RUBY_PACKAGES="bundler"

## Install everything
sudo apt-get -y --allow-unauthenticated install ${PACKAGES} ${WORKER_PACKAGES}

sudo pip3 install http://download.pytorch.org/whl/cu75/torch-0.2.0.post3-cp35-cp35m-manylinux1_x86_64.whl
sudo pip3 install ${PYTHON_PACKAGES}
sudo python3.6 -m pip install http://download.pytorch.org/whl/cu75/torch-0.2.0.post3-cp36-cp36m-manylinux1_x86_64.whl
sudo python3.6 -m pip install ${PYTHON_PACKAGES}

sudo gem install ${RUBY_PACKAGES}

## Install Rustup, making sure the compilation user can access it.
## None of the other users will have access!
sudo -iu bot_compilation sh -c 'curl https://sh.rustup.rs -sSf > rustup.sh; sh rustup.sh -y'
sudo -iu bot_compilation rustup toolchain install nightly beta

## Install Leiningen/Clojure, also for the worker user.
sudo sh -c 'echo "$(curl -fsSL https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein)" > /usr/bin/lein'
sudo chmod a+x /usr/bin/lein
sudo -iu bot_compilation lein

## Install Go, for the bot and compilation users.
curl -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
echo 'export PATH="$PATH:/usr/local/go/bin"' | sudo -iu bot_compilation tee -a /home/bot_compilation/.profile
rm go1.10.3.linux-amd64.tar.gz
# See below for where PATH of the bot users is edited.

# Miniconda
sudo -iu bot_compilation sh -c 'curl https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -sSf > miniconda.sh; bash miniconda.sh -b -p $HOME/miniconda'

# Groovy
curl -s get.sdkman.io | sudo -iu bot_compilation bash
cat <<EOF | sudo -iu bot_compilation tee -a /home/bot_compilation/.profile
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/worker/.sdkman"
[[ -s "/home/worker/.sdkman/bin/sdkman-init.sh" ]] && source "/home/bot_compilation/.sdkman/bin/sdkman-init.sh"
EOF
sudo -iu bot_compilation sdk install groovy

# Julia
wget -O julia.tgz https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.4-linux-x86_64.tar.gz
sudo tar -C /usr/local -xzf julia.tgz
rm julia.tgz
sudo ln -s /usr/local/julia-9d11f62bcb/bin/julia /usr/local/bin/julia

# Swift
wget -O swift.tar.gz https://swift.org/builds/swift-4.0.2-release/ubuntu1610/swift-4.0.2-RELEASE/swift-4.0.2-RELEASE-ubuntu16.10.tar.gz
sudo tar -C /usr/local -xzf swift.tar.gz
echo 'export PATH="$PATH:/usr/local/swift-4.0.2-RELEASE-ubuntu16.10/usr/bin"' | sudo -iu bot_compilation tee -a /home/bot_compilation/.profile
sudo chmod -R o+r /usr/local/swift-4.0.2-RELEASE-ubuntu16.10/usr/lib/swift/CoreFoundation/

## Create four cgroups to isolate bots.
sudo touch /etc/cgconfig.conf
for i in $(seq 0 $((NUM_BOTS-1))); do
    CGROUP="bot_${i}"
    echo "Creating cgroup ${CGROUP}"
    cat <<EOF | sudo tee -a /etc/cgconfig.conf
group ${CGROUP} {
        # Grant control over the cgroup to the worker user
        perm {
                admin {
                        uid = root;
                        gid = root;
                }
                task {
                        uid = worker;
                        gid = worker;
                }
        }
        cpu {
                cpu.shares="1024";
        }
        memory {
                memory.limit_in_bytes="1G";
        }
        devices {
                devices.allow="a *:* rwm";
        }
        cpuset {
               cpuset.cpu_exclusive=1;
               cpuset.cpus=${i};
               cpuset.mems=0;
        }
}
EOF
done

## cgconfig doesn't let us set multiple denied devices, so we need a
## sudo-executable script that fixes this for us
cat <<EOF | sudo tee -a /home/worker/fix_cgroups.sh
#!/bin/sh
echo "c 195:1 rwm" > /sys/fs/cgroup/devices/bot_0/devices.deny
echo "c 195:2 rwm" > /sys/fs/cgroup/devices/bot_0/devices.deny
echo "c 195:3 rwm" > /sys/fs/cgroup/devices/bot_0/devices.deny

echo "c 195:0 rwm" > /sys/fs/cgroup/devices/bot_1/devices.deny
echo "c 195:2 rwm" > /sys/fs/cgroup/devices/bot_1/devices.deny
echo "c 195:3 rwm" > /sys/fs/cgroup/devices/bot_1/devices.deny

echo "c 195:0 rwm" > /sys/fs/cgroup/devices/bot_2/devices.deny
echo "c 195:1 rwm" > /sys/fs/cgroup/devices/bot_2/devices.deny
echo "c 195:3 rwm" > /sys/fs/cgroup/devices/bot_2/devices.deny

echo "c 195:0 rwm" > /sys/fs/cgroup/devices/bot_3/devices.deny
echo "c 195:1 rwm" > /sys/fs/cgroup/devices/bot_3/devices.deny
echo "c 195:2 rwm" > /sys/fs/cgroup/devices/bot_3/devices.deny
EOF
sudo chmod 544 /home/worker/fix_cgroups.sh

## Create a user to be used by compilation. This user will have limited Internet access.
sudo useradd -m bot_compilation -G bots
## No access to 10. addresses (which are our own servers)
## We are giving them general network access (to download dependencies)
sudo iptables -A OUTPUT -d 10.0.0.0/8 -m owner --uid-owner bot_compilation -j DROP
sudo iptables -A OUTPUT -d 127.0.0.0/8 -m owner --uid-owner bot_compilation -j DROP
## Grant sudo access to the worker as this user.
sudo sh -c "echo \"worker ALL=(bot_compilation) NOPASSWD: ALL\" > /etc/sudoers.d/worker_bot_compilation"
## Grant sudo access to the cgroup fixer script as root.
sudo sh -c "echo \"worker ALL=(root) NOPASSWD: /home/worker/fix_cgroups.sh\" >> /etc/sudoers.d/worker_bot_compilation"
sudo chmod 0400 /etc/sudoers.d/worker_bot_compilation

## Create four users to isolate bots.
for i in $(seq 0 $((NUM_BOTS-1))); do
    USERNAME="bot_${i}"
    sudo useradd -m -g bots_${i} ${USERNAME}
    ## Deny all network access to this user.
    sudo iptables -A OUTPUT -m owner --uid-owner ${USERNAME} -j DROP
    ## Grant sudo access to the worker.
    sudo sh -c "echo \"worker ALL=(${USERNAME}) NOPASSWD: ALL\" > /etc/sudoers.d/worker_${USERNAME}"
    sudo chmod 0400 /etc/sudoers.d/worker_${USERNAME}
    echo 'export PATH="$PATH:/usr/local/go/bin"' | sudo -iu ${USERNAME} tee -a /home/${USERNAME}/.profile
done

## Make sure iptables rules persist
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

## Make sure cgroups persist
cat <<EOF | sudo tee /etc/systemd/system/cgroups.service
[Unit]
Description=Recreate cgroups on startup

[Service]
Type=oneshot
ExecStart=/usr/sbin/cgconfigparser -l /etc/cgconfig.conf

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cgroups.service

## Disable fqdn in sudo. This prevents most DNS lookups, and hopefully
## will avoid the `sudo: failed to resolve` error that comes up.
echo 'Defaults !fqdn' | sudo tee /etc/sudoers.d/no-fqdn

## Print out packages installed.
echo "Packages"
for package in ${PACKAGES}; do
    dpkg-query -W ${package}
done

echo "Worker Packages"
for package in ${WORKER_PACKAGES}; do
    dpkg-query -W ${package}
done

echo "Python 3.5 Packages"
for package in ${PYTHON_PACKAGES}; do
    echo ${package} $(pip3 show ${package} | grep Version | awk '{print $2}')
done

echo "Python 3.6 Packages"
for package in ${PYTHON_PACKAGES}; do
    echo ${package} $(python3.6 -m pip show ${package} | grep Version | awk '{print $2}')
done

echo "Ruby Gems"
for package in ${RUBY_PACKAGES}; do
    gem list | grep ${package}
done

echo "Rust Packages"
sudo -iu bot_compilation bash << EOF
rustc -V
cargo -V
rustup -V
EOF

echo "Clojure Packages"
sudo -iu bot_compilation bash << EOF
lein version
EOF

echo "Groovy Packages"
sudo -iu bot_compilation sdk current | grep groovy

echo "Miniconda"
sudo -iu bot_compilation bash -c 'source ~/miniconda/bin/activate; conda -V'

# Don't just grant random people sudo access.
sudo rm /etc/sudoers.d/google_sudoers
