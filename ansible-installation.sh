#!/bin/bash
log="ansible_installation.log"
if ! command -v ansible >/dev/null;
    then
    echo "[INFO] Ansible is not installed. Installation is in-progress." >> ${log}
    echo "[INFO] Operating system identification prior installation is in-progress." >> ${log}
    if [[ -f /etc/os-release ]] #Amazon Linux platform
        then
        echo "[INFO] Operating system identified as Amazon Linux." >> ${log}
        if yum search ansible
            then
            echo "[INFO] Ansible packages found in enabled repositories." >> ${log}
            echo "[INFO] "[INFO] Installation in progress." >> ${log}
            yum install -y ansible
        else
            echo "[INFO] Configuration of EPEL repository is required." >> ${log}
            echo "[INFO] Verifying if EPEL repository is configured." >> ${log}
            if ! rpm -q epel-release-7-11.noarch || yum repolist | grep -i epel
                then
                echo "[INFO] EPEL repository is not configured. Configuration in-progress." >> ${log}
                echo "[INFO] Verifying connectivity to EPEL repo installation RPM." >> ${log}
                if curl --output /dev/null --silent --head --fail https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    then
                    echo "[INFO] Connectivity to EPEL repo installation RPM is pass. Installing EPEL repo configuration." >> ${log}
                    if yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                        then
                        { echo "[INFO] EPEL repository is already configured. Ansible installation is in-progress."; yum install -y ansible; } &>> ${log}
                        echo "[INFO] Ansible installation is completed." >> ${log}
                        exit 0
                    else
                        echo "\[ERROR\] EPEL repo configuration is failed. Exiting." >> ${log}
                        exit 1
                    fi
                else
                    echo "\[ERROR\] Connectivity to EPEL repo installation RPM is failed. Exiting." >> ${log}
                    exit 1
                fi
            else
                { echo "[INFO] EPEL repository is already configured. Ansible installation is in-progress."; yum install -y ansible; } &>> ${log}
                echo "[INFO] Ansible installation is completed." >> ${log}
                exit 0
            fi
        fi
    elif [[ -f /etc/redhat-release ]] #RedHat, CentOS platform or Oracle Linux
        then
        echo "[INFO] Operating system identified as Red Hat like OS." >> ${log}
        if yum search ansible
            then
            echo "[INFO] Ansible packages found in enabled repositories." >> ${log}
            echo "[INFO] "[INFO] Installation in progress." >> ${log}
            yum install -y ansible
        else
            echo "[INFO] Configuration of EPEL repository is required." >> ${log}
            echo "[INFO] Verifying if EPEL repository is configured." >> ${log}
            if ! rpm -q epel-release-7-11.noarch || yum repolist | grep -i epel
                then
                echo "[INFO] EPEL repository is not configured. Configuration in-progress." >> ${log}
                echo "[INFO] Verifying connectivity to EPEL repo installation RPM." >> ${log}
                if curl --output /dev/null --silent --head --fail https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    then
                    echo "[INFO] Connectivity to EPEL repo installation RPM is pass. Installing EPEL repo configuration." >> ${log}
                    if yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                        then
                        { echo "[INFO] EPEL repository is already configured. Ansible installation is in-progress."; yum install -y ansible; } >> ${log}
                        echo "[INFO] Ansible installation is completed." >> ${log}
                        exit 0
                    else
                        echo "[ERROR] EPEL repo configuration is failed. Exiting." >> ${log}
                        exit 1
                    fi
                else
                    echo "[ERROR] Connectivity to EPEL repo installation RPM is failed. Exiting." >> ${log}
                    exit 1
                fi
            else
                { echo "[INFO] EPEL repository is already configured. Ansible installation is in-progress."; yum install -y ansible; } >> ${log}
                echo "[INFO] Ansible installation is completed." >> ${log}
                exit 0
            fi
        fi
    elif [[ -f /etc/lsb-release ]] #Debian platform
        then
        echo "[INFO] Operating system identified as Debian based OS." >> ${log}
    else
        echo "[ERROR] Cannot identify the Operating system. Exiting." >> ${log}
        exit 1
    fi
else
    echo "[INFO] Ansible is already installed. Exiting." &>> ${log}
    exit 0
fi
