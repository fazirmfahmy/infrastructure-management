#!/bin/bash
#This script will add the service now user along with essential sudo commands
#log=/root/scripts/log/servicenow_user_add_sudo_change-GME-3935-$(date '+%Y-%m-%d-%H:%M:%S').log
log=/root/scripts/log/servicenow_user_add_sudo_change-GME-3935.log
serverlist=/root/scripts/gme_all_servers.list #actual server list.
dc=''
env=''
sc=''			#Server category
os=u			#OS
lob=gmpx		#Line of business
#sleeptime=10

read -rp "Please enter the Datacenter. [dn1] Denver [lo1] London Core [mb1] Mumbai : " dc
read -rp "Please enter the environment. [p]roduction [s]taging [d]evelopment [q]a : " env
read -rp "Please enter the server category. [o]myDashboard [d]logs [m]onza : " sc

#if [ $# -lt 2 ]
#then
#	echo "Re run the script specifying the datacenter as dn1 OR lo1 and enviorenment as [p]roduction [s]taging [d]evelopment [q]a parameters. Example $0 dn1 p"
#	exit 1
#fi

#Check server list file availability
if [ -f $serverlist ]
then
    echo "Server list is available in $serverlist Checking ..." >> $log
    if [ -s $serverlist ]
    then
        echo "Server list is not empty, Checking valid servers" >> $log
    else
        echo "Server list is empty, Please point the correct server list file and re run"
        exit 1
    fi
else
    echo "No servers list found. Please point the server list file correctly and re run"
    exit 1
fi

#echo "Searching for $1u$2* servers in $serverlist" >> $log
echo "Searching for $dc$os$env$lob$sc servers in $serverlist" >> $log

while read host ip
do
#host=`echo $host | grep $dc.$env`
    host=`echo $host | grep $dc$os$env$lob$sc`

    if [ -z $host ]
        then
	        echo "Searching for $dc$os$env$lob$sc* servers in $serverlist file" >> $log
        else
	        echo "Checking reachability to $host" >> $log
		    #ping -c2 $ip &> /dev/null
	        #if [ $? -eq 0 ]
	        if ping -c2 $ip &> /dev/null
	    	    then
			        echo "$host is reachable" >> $log

			        echo "Starting $host configuration =============================================================================================" >> $log

			        # RedHat or Cent OS
			        if ssh -n root@$ip "[ -f /etc/redhat-release ]"
			            then
				            echo "Operating system is a Red Hat like system" >> $log
                            echo "Checking the servicenowsvc user availability. . ." >> $log
                            #id servicenowsvc 2> /dev/null
                            #if [ $? -eq 0 ]
                            if ssh -n root@$ip "id servicenowsvc" 2> /dev/null
                                then
                                    echo "User is available, Make sure correct password is set" >> $log
                                    ssh -n root@$ip "echo "Rx2tzTJI" | passwd --stdin servicenowsvc" >>  $log
                                    echo "Make sure user will not expire" >> $log
                                    ssh -n root@$ip "chage -l servicenowsvc" >>  $log
                                else
                                    ssh -n root@$ip "useradd -c "ServiceNow CMDB User GME-3935" servicenowsvc; echo "Rx2tzTJI" | passwd --stdin servicenowsvc"
                                    echo "User is created" >> $log
                                    echo "Make sure user will not expire" >> $log
                                    ssh -n root@$ip "chage -l servicenowsvc" >>  $log
                                    echo "Checking the SUDO entry. . ." >> $log
                                    #sudo -l -U servicenowsvc | grep "(root) NOPASSWD: /usr/sbin/dmidecode, (root) /usr/sbin/lsof, (root) /bin/ls, (root) /bin/netstat, (root) /usr/bin/gcore, (root) /sbin/ifconfig, (root) /sbin/fdisk"
                                if ssh -n root@$ip sudo -l -U servicenowsvc | grep '(root) NOPASSWD: /usr/sbin/dmidecode, (root) /usr/sbin/lsof, (root) /bin/ls, (root) /bin/netstat, (root) /usr/bin/gcore, (root) /sbin/ifconfig, (root) /sbin/fdisk'
                                #if [ $? -eq 0 ]
                                    then
                                        echo "SUDO is done, Make sure commands are working find" >> $log
                                        for i in dmidecode lsof ls netstat gcore ifconfig fdisk
                                            do
                                                ssh -n root@$ip "sudo $i" >> $log
                                                if [ $? -eq 0 ]
                                                    then
                                                        echo "Command $i is working fine" >> $log
                                                    else
                                                        echo "ERROR: Command $i is NOT available" >> $log
                                                fi
                                        done
                                    else
                                        echo "Need to configure SUDO. Configuring . . ." >> $log
                                        ssh -n root@$ip "cp /etc/sudoers /etc/sudoers.GME-3935.vfahmmo.`date '+%Y-%m-%d-%H:%M'`"
                                        ssh -n root@$ip "echo '# GME-3935 Allows servicenowsvc user to run ServiceNow essential commands without password.' >> /etc/sudoers"
                                        ssh -n root@$ip "echo 'servicenowsvc ALL=(root) NOPASSWD: /usr/sbin/dmidecode, /usr/sbin/lsof, /bin/ls, /bin/netstat, /usr/bin/gcore, /sbin/ifconfig, /sbin/fdisk' >> /etc/sudoers"
                                        ssh -n root@$ip "visudo -c" >> $log
                                fi
                            fi

                        echo "Checking the availability of SUDO commands" >> $log
                        for i in /usr/sbin/dmidecode /usr/sbin/lsof /bin/ls /bin/netstat /usr/bin/gcore /sbin/ifconfig /sbin/fdisk
                        do
                            ssh -n root@$ip "ls -lrt $i" >> $log
                            if [ $? -eq 0 ]
                                then
                                    echo "Command $i is available" >> $log
                                else
                                    echo "ERROR: Command $i is NOT available" >> $log
                            fi
                        done
			        # Ubuntu
			        elif ssh -n root@$ip "[ -f /etc/lsb-release ]"
			            then
                            echo "Operating system is a Debian like system" >> $log
                            echo "Checking the servicenowsvc user availability. . ." >> $log
                            #id servicenowsvc 2> /dev/null
                            #if [ $? -eq 0 ]
                            if ssh -n root@$ip "id servicenowsvc" 2> /dev/null
                                then
                                    echo "User is available, Make sure correct password is set" >> $log
                                    ssh -n root@$ip "echo 'servicenowsvc:Rx2tzTJI' | chpasswd" >>  $log
                                    echo "Make sure user will not expire" >> $log
                                    ssh -n root@$ip "chage -l servicenowsvc" >>  $log
                            else
                                ssh -n root@$ip "useradd servicenowsvc; echo 'servicenowsvc:Rx2tzTJI' | chpasswd"
                                echo "User is created" >> $log
                                echo "Make sure user will not expire" >> $log
                                ssh -n root@$ip "chage -l servicenowsvc" >>  $log
                                echo "Checking the SUDO entry" >> $log
                                #sudo -l -U servicenowsvc | grep "(root) NOPASSWD: /usr/sbin/dmidecode, (root) /usr/bin/lsof, (root) /bin/ls, (root) /bin/netstat, (root) /usr/bin/gcore, (root) /sbin/ifconfig, (root) /sbin/fdisk"
                                if ssh -n root@$i sudo -l -U servicenowsvc | grep '(root) NOPASSWD: /usr/sbin/dmidecode, (root) /usr/sbin/lsof, (root) /bin/ls, (root) /bin/netstat, (root) /usr/bin/gcore, (root) /sbin/ifconfig, (root) /sbin/fdisk'
                                #if [ $? -eq 0 ]
                                    then
                                        echo "SUDO is done, nothing to do" >> $log
                                    else
                                      echo "Need to configure SUDO. Configuring . . ." >> $log
                                        ssh -n root@$ip "cp /etc/sudoers /etc/sudoers.GME-3935.vfahmmo.`date '+%Y-%m-%d-%H:%M'`"
                                        ssh -n root@$ip "echo '# GME-3935 Allows servicenowsvc user to run ServiceNow essential commands without password.' >> /etc/sudoers"
                                        ssh -n root@$ip "echo 'servicenowsvc ALL=(root) NOPASSWD: /usr/sbin/dmidecode, /usr/bin/lsof, /bin/ls, /bin/netstat, /usr/bin/gcore, /sbin/ifconfig, /sbin/fdisk' >> /etc/sudoers"
                                        ssh -n root@$ip "visudo -c" >> $log
                                fi
                        fi

                        echo "Checking the availabilty of SUDO commands" >> $log
                        for i in /usr/sbin/dmidecode /usr/bin/lsof /bin/ls /bin/netstat /usr/bin/gcore /sbin/ifconfig /sbin/fdisk
                        do
                            ssh -n root@$ip "ls -lrt $i" >> $log
                            if [ $? -eq 0 ]
                                then
                                    echo "Command $i is available" >> $log
                                else
                                    echo "ERROR: Command $i is NOT available" >> $log
                            fi
                        done
            # Other OS types
			else
				echo "Operating system was not identified. Please check"
			fi
			echo "Completed $host configuration =============================================================================================" >> $log
		else
			echo "Cannot reach $host please check the connectivity." >> $log
		fi
fi
done < $serverlist
echo "Task completed for $dc$os$env$lob$sc servers" >> $log
exit 0