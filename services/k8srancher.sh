#!/bin/bash
#
#   Kubernetes Rancher Installation
#

git clone https://github.com/rancher/quickstart.git
cd quickstart/vagrant
sudo bash -x scripts/configure_rancher_server.sh admin 1.5.1 ""