#!/bin/bash
LOG="git-repository-configuration.log"
REPOSITORY_DIRECTORY="/opt/scripts/infrastructure-management/"
REPOSITORY_NAME="infrastructure-managment"
ACCOUNT_NAME="fazirmfahmy"

git_repository_directory_status ()
{
    echo "[INFO] Checking for repository path." >> ${LOG}
    if ! ls -l ${REPOSITORY_DIRECTORY} > /dev/null
        then
        echo "[INFO] Repository path is not available. Creating." >> ${LOG}
        mkdir -p ${REPOSITORY_DIRECTORY}
    else
        echo "[INFO] Repository is already available." >> ${LOG}
        exit 1
    fi
}

clone_infrastructure-management_repository ()
{
    echo "[INFO] Cloning ${REPOSITORY_NAME} repository in-progress." >> ${LOG}
    git clone https://github.com/${ACCOUNT_NAME}/${REPOSITORY_NAME}.git
    echo "[INFO] Cloning ${REPOSITORY_NAME} repository is completed." >> ${LOG}
    exit 1
}

os_not_identified ()
{
    echo "[Error] OS not identified." >> ${LOG}
    exit 1
}

identify_os ()
{
    if [[ ( -z "${OS}" ) && ( -z "${DISTRIBUTION}" ) ]]
        then
        if [ "$(command -v lsb_release 2>/dev/null)" ]
            then
            DISTRIBUTION "$(lsb_release -r | cut -f2 | awk -F '.' '{ print $1 }')"
            OS=$(lsb_release -i | cut -f2 | awk '{ print tolower($1) }')
        elif [ -e /etc/oracle-release ]
            then
            DISTRIBUTION "$(cut -f5 --delimiter=' ' /etc/oracle-release | awk -F '.' '{ print $1 }')"
            OS='ol'
        elif [ -e /etc/fedora-release ]
            then
            DISTRIBUTION "$(cut -f3 --delimiter=' ' /etc/fedora-release)"
            OS='fedora'
        elif [ -e /etc/redhat-release ]
            then
            OS_TYPE="$(cat /etc/redhat-release | awk '{ print tolower($1) }')"
            if [ "${OS_TYPE}" = "centos" ]
                then
                DISTRIBUTION="$(cat /etc/redhat-release | awk '{ print $3 }' | awk -F '.' '{ print $1 }')"
                OS='centos'
            elif [ "${OS_TYPE}" = "scientific" ]
                then
                DISTRIBUTION="$(cat /etc/redhat-release | awk '{ print $4 }' | awk -F '.' '{ print $1 }')"
                OS='scientific'
            else
                DISTRIBUTION="$(cat /etc/redhat-release | awk '{ print tolower($7) }' | cut -f1 --delimiter='.')"
                OS='redhatenterpriseserver'
            fi
        else
            if aws "$(grep -q Amazon /etc/issue)"
                then
                DISTRIBUTION='6'
                OS='aws'
            else
                os_not_identified
            fi
        fi
    fi
    if [[ ( -z "${OS}" ) || ( -z "${DISTRIBUTION}" ) ]]
        then
        os_not_identified
    fi
    OS="${OS// /}"
    DISTRBUTION="${DISTRIBUTION// /}"
    echo "[INFO] Detected operating system as ${OS}/${DISTRIBUTION}." >> ${LOG}
}

finalize_yum_repo ()
{
    echo "[INFO] Installing pygpgme to verify GPG signatures." >> ${LOG}
    yum install -y pygpgme --disablerepo='gitlab_gitlab-ee'
    if ! pypgpme_check "$(rpm -qa | grep -qw pygpgme)"
        then
        echo "[INFO] The pygpgme package could not be installed. GPG verification is not possible for any RPM installation." >> ${LOG}
        echo "[INFO] To fix this, Configure EPEL repository for your system will have this." >> ${LOG}
        echo "[INFO] [INFO] Disabling the repository." >> ${LOG}
        sed -i'' 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/gitlab_gitlab-ee.repo
    fi
    echo "[INFO] Installing yum-utils." >> ${LOG}
    echo "[INFO] Instalation of yum-utils is completed." >> ${LOG}
    yum install -y yum-utils --disablerepo='gitlab_gitlab-ee'
    if ! yum_utils_check "$(rpm -qa | grep -qw yum-utils)" >> ${LOG}
        then
        echo "[INFO] yum-utils package could not be installed. You may not be able to install source RPMs or use other yum features." >> ${LOG}
    fi
    echo "[INFO] Generating yum cache for gitlab_gitlab-ee." >> ${LOG}
    yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ee'
    echo "[INFO] Generating yum cache for gitlab_gitlab-ee-source." >> ${LOG}
    yum -q makecache -y --disablerepo='*' --enablerepo='gitlab_gitlab-ee-source'
}

finalize_zypper_repo ()
{
    zypper --gpg-auto-import-keys refresh gitlab_gitlab-ee
    zypper --gpg-auto-import-keys refresh gitlab_gitlab-ee-source
}

main ()
{
    git_command_status
    identify_os
    curl_command_status
    yum_repo_config_url="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/config_file.repo?os=${OS}&dist=${DISTRIBUTION}&source=script"
    if [ "${OS}" = "sles" ] || [ "${OS}" = "opensuse" ]
        then
        yum_repo_path=/etc/zypp/repos.d/gitlab_gitlab-ee.repo
    else
        yum_repo_path=/etc/yum.repos.d/gitlab_gitlab-ee.repo
    fi
    echo "[INFO] Downloading repository file: ${yum_repo_config_url}." >> ${LOG}
    curl -sSf "${yum_repo_config_url}" > $yum_repo_path
    curl_exit_code=$?
    if [ "$curl_exit_code" = "22" ]
        then
        echo -n "[ERROR] Unable to download repo config from:" >> ${LOG}
        echo "${yum_repo_config_url}"
        echo "[ERROR] This usually happens if your operating system is not supported by packagecloud.io, or this script\'s OS detection failed." >> ${LOG}
        echo "[INFO] You can override the OS detection by setting OS= and DISTRIBUTION= prior to running this script. Example, CentOS 6: OS=el DISTRIBUTION=6 ./script.sh ." >> ${LOG}
        echo "[INFO] If you are running a supported OS, please email support@packagecloud.io and report this." >> ${LOG}
        [ -e $yum_repo_path ] && rm $yum_repo_path
        exit 1
    elif [ "$curl_exit_code" = "35" -o "$curl_exit_code" = "60" ]
        then
        echo "[ERROR] curl is unable to connect to packagecloud.io over TLS when running:" >> ${LOG}
        echo "[ERROR] curl ${yum_repo_config_url}"
        echo "[ERROR] Reason could be"
        echo "[ERROR] Missing CA root certificates. Make sure the ca-certificates package is installed." >> ${LOG}
        echo "[ERROR] An old version of libssl. Try upgrading libssl on your system to a more recent version." >> ${LOG}
        echo "[INFO] Contact support@packagecloud.io with information about your system for help." >> ${LOG}
        [ -e $yum_repo_path ] && rm $yum_repo_path
        exit 1
    elif [ "$curl_exit_code" -gt "0" ]
        then
        echo "[INFO] Unable to run:" >> ${LOG}
        echo "[INFO] curl ${yum_repo_config_url}"
        echo "[INFO] Double check your curl installation and try again." >> ${LOG}
        [ -e $yum_repo_path ] && rm $yum_repo_path
        exit 1
    else
        echo "[INFO] done." >> ${LOG}
    fi
    echo
    echo "[INFO] The repository is setup! You can now install packages." >> ${LOG}
}
main