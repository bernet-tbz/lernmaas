#!/bin/bash
#
#   Zentraler Script wird von cloud-init aufgerufen.
#   
#   Installiert anhand lernmaas/config.yaml die VMs.
#
#   Zuerst werden die Services durchlaufen und dann die zusaetzlichen Scripts
#

# einfacher YAML Parser von https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
function parse_yaml 
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

################### YAML datei auswerten ###################

# config.yaml parsen und als config_xxxx Umgebungsvariablen setzen
export HOST=$(hostname | cut -d- -f 1)
for e in $(eval parse_yaml config.yaml | grep "^${HOST}" | sed "s/^${HOST}/config/")
do
    export $e
done

################### Services ###################

# NFS Abhandlung
[ "${config_services_nfs}" -eq "true" ] && { bash -x services/nfs.sh; }

# Wireguard
[ "${config_services_wireguard}" -eq "true" ] && { bash -x services/wireguard.sh ${HOST} ${config_wireguard}; }

# Docker
[ "${config_services_docker}" -eq "true" ] && { bash -x services/docker.sh; }

# Kubernetes
if [ "${config_services_k8s" -eq "master" ] 
then
    bash -x services/k8sbase.sh
    bash -x services/k8smaster.sh
    bash -x services/k8saddons.sh
    bash -x services/k8swebui.sh
fi

if [ "${config_services_k8s" -eq "worker" ] 
then
    bash -x services/k8sbase.sh
    bash -x services/k8sjoin.sh
fi

# Samba
[ "${config_services_samba}" -eq "true" ] && { bash -x services/samba.sh; }

################### Repositories ###################

[ "${config_repositories}" != "" ] && { bash -x services/repositories.sh ${config_repositories}; }

################### Scripts ###################

for script in ${config_scripts}
do
    bash -x scripts/${script}
done

################### Firewall ###################

[ "${config_services_firewall}" -eq "true" ] && { bash -x services/ufw.sh; }
