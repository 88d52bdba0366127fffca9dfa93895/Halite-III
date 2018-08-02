#!/usr/bin/env bash

# On GPU workers, environment variables needed to set up CUDA properly are
# written to the profile, so make sure those variables actually get loaded.
source ~/.profile

cd ../../environment

cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release
cmake --build build -- -j4

cp build/halite .

cd ../apiserver/worker

cp ../../environment/halite .

# Grab configuration values
python3 grab_config.py

# Fix up cgroups
if [ -f /home/worker/fix_cgroups.sh ]; then
   sudo /home/worker/fix_cgroups.sh
fi

# Start the worker
screen -S worker -d -m /bin/bash -c "python3 worker.py $1"
