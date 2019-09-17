#!/bin/bash
LOG="/var/log/bootstrap.log"

echo "[INFO] Root password setting : In progress" > ${LOG}
echo "1qaz2wsx@" | passwd --stdin root
echo "[INFO] Root password setting : Completed succusfully" >> ${LOG}

echo "[INFO] Configure permit root login access : In progress" >> ${LOG}
sed -i '/^PermitRootLogin/s/no/yes/g' /etc/ssh/sshd_config
echo "[INFO] Configure permit root login access : Completed succusfully" >> ${LOG}

echo "[INFO] Configure password base authtication : In progress" >> ${LOG}
sed -i '/^PasswordAuthentication/s/no/yes/g' /etc/ssh/sshd_config
echo "[INFO] Configure password base authentication : Completed succusfully" >> ${LOG}

echo "[INFO] Making the change effect by restart the service : In progress" >> ${LOG}
systemctl restart sshd.service
echo "[INFO] Making the change effect by restart the service : Completed succusfully" >> ${LOG}

echo "[INFO] Git client installation : In progress" >> ${LOG}
yum install git -y
echo "[INFO] Git client installation : Completed succusfully"  >> ${LOG}

echo "[INFO] Git client installation validation : In progress" >> ${LOG}
git --version >> ${LOG}

if [ $? -eq 0 ]
then
    echo "[INFO] Git client installation validation : client installed" >> ${LOG}
else
    echo "[ERROR] Git client installation validation : Client doesnt installed" >> ${LOG}
fi

echo "[INFO] JAVA  installation : In progress" >> ${LOG}
yum install java-1.8* -y
echo "[INFO] JAVA installation : Completed succusfully"  >> ${LOG}

java -version
if [ $? -eq 0 ]
then
    echo "[INFO] JAVA path configuration : Successful" >> ${LOG}
else
    echo "[ERROR] JAVA path configuration : Failed" >> ${LOG}
fi

echo "[INFO] Jenkins repo configuration validation : In progress" >> ${LOG}
ls -l /etc/yum.repos.d/jenkins.repo
if [ $? -eq 0 ]
then
    echo "[INFO] Jenkins repo configuration : Already done, Nothing to do" >> ${LOG}
else
    echo "[INFO] Jenkins repo configuration : False" >> ${LOG}
    echo "[INFO] Jenkins repo configuration file download : In progress" >> ${LOG}
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    echo "[INFO] Jenkins repo configuration file download : Completed succusfully" >> ${LOG}
fi
echo "[INFO] Jenkins repo configuration validation : Completed" >> ${LOG}