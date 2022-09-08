#!/bin/bash
#######################################################################
#                            Home of the Vars!                       ##
#                                                                    ##
# Enables extented globbing for more advanced pattern matching.      ##
shopt -s extglob                                                     ##
# Ensures "." files included in advanced pattern matching.           ##
shopt -s dotglob                                                     ##
stamp=$(date +%b-%d-%Y)                                              ##
logfile=logs/wpfunk.log                                              ##
webuser=www-data                                                     ##
green=$'\e[1;32m'                                                    ##
red=$'\e[1;31m'                                                      ##
white=$'\e[0m'                                                       ##
#######################################################################
# Helps create a log of all actions performed.
logger () {
  echo -e "$(date +%a-%b-%d@%T): ${1}" >> "${logfile}"
}
# Confirms the use of a dangerous or irreversible command.
confirmcommand () {
	clear
	while :
	do
	read -r -p "Are you sure you wish to $1?" ccmnd
	case $ccmnd in
	[Yy]* ) break ;;
	[Nn]* ) exit 1;;
	* ) echo "Please enter only yes or no. (y/n)"
	esac
	done
}
# Disables all plugins within the WordPress Directory by moving them to new folder.
dplugins () {
confirmcommand "disable plugins for this WordPress instance"
if [ ! -d "${wpdir}"/disabled/plugins ]; then
	mkdir -p "${wpdir}"/disabled/plugins
fi
mv -f "${wpdir}"/wp-content/plugins/* "${wpdir}"/disabled/plugins/
echo "Plugins have been moved to the disabled directory."
sleep 3
}
# Disables all but default themes.
dthemes () {
	confirmcommand "disable Themes for this wordpress instance"
	if [ ! -d "${wpdir}"/disabled/themes ]; then
		mkdir -p "${wpdir}"/disabled/themes
	fi
	mv -f "${wpdir}"/wp-content/themes/!(twenty*teen) "${wpdir}"/disabled/themes/
	sleep 3
}
# Enumerates WordPress DB Credentials and verifies them. Does not Display Creds.
ccreds () {
	DB_USER=$(grep DB_USER < "$wpconf" | awk '{print $2}')
	DB_USER=${DB_USER:1:$((${#DB_USER} - 5))}
	DB_PASS=$(grep DB_PASS < "$wpconf" | awk '{print $2}')
	DB_PASS=${DB_PASS:1:$((${#DB_PASS} - 5))}
	mysql -u"${DB_USER}" -p"${DB_PASS}" -e 'SELECT "Credentials are Correct."'
	sleep 3
}
# Checks which IP a Domain is Pointing to.
cip () {
	dig A "$1" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n 1
	sleep 3
}
# Attempts to find and fix any permissions that may not be quite right.
fixperms () {
	confirmcommand "Give files and folders correct permissions within ${wpdir}"
	find "${wpdir}"/ -type d -exec chmod a+rx {} +
	find "${wpdir}"/ -type f -exec chmod a+r {} +
	echo -e ""
	sleep 3
}
# Assigns the ownership of the files to specified user.
fixowner() {
	confirmcommand "set the owner of the WordPress Directory to $1"
	chown -R "$1":"$1" "${wpdir}"/
	echo -e "Changed the ownership of ${wpdir} to $1."
	sleep 3
}
# Updates to the latest version of WordPress
updatewp () {
	confirmcommand "update this Instance to the latest version of WordPress"
	wget https://wordpress.org/latest.tar.gz
	tar -xvf latest.tar.gz
	chown -R "${webuser}":"${webuser}" wordpress/ && echo -e "Fixed Ownership.\\n"
	rm latest.tar.gz
	rsync -auP wordpress/ .
	rm -rfv wordpress/
	echo "Downloaded and installed latest version of wordpress."
	sleep 3
}
# Creates a full backup of the WordPress instance.
backup () {
	if [ ! -d "${wpdir}/../backup" ]; then
		mkdir -p "${wpdir}/../backup"
	fi
	  DB_NAME=$(grep DB_NAME < "$wpconf" | awk '{print $2}')
	  DB_NAME=${DB_NAME:1:$((${#DB_NAME} - 5))}
	  DB_USER=$(grep DB_USER < "$wpconf" | awk '{print $2}')
	  DB_USER=${DB_USER:1:$((${#DB_USER} - 5))}
	  DB_PASS=$(grep DB_PASS < "$wpconf" | awk '{print $2}')
	  DB_PASS=${DB_PASS:1:$((${#DB_PASS} - 5))}
	  mysqldump -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" > "database_${DB_NAME}_${stamp}.sql"
	tar --exclude "$(basename "$0")" -czvf "../backup/backup_${stamp}.tar.gz" ./
	rm database_"${DB_NAME}"_"${stamp}".sql
	echo -e "\n Backed up WordPress instance to ${wpdir}/backup/backup_${stamp}.tar.gz"
	sleep 3
}
getwpdir() {
if [ -f wp-config.php ]; then
	wpdir=$(pwd)
	wpconf=$wpdir/wp-config.php
	elif [ -f ../wp-config.php ]; then
		wpdir=$(pwd)
		wpconf=$wpdir/../wp-config.php
	else
	clear && echo -e "\nScript is not in the WordPress root Directory."
	sleep 3
	exit
fi
}
getwpuser() {
	wpuser=$(stat -c %U "$wpconf")
}
getwpcli() {
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
}
getwpdir
getwpuser
getwpcli
initbackup() {
	clear
	while :
	do
	read -r -p "Do you want to create a backup of this WordPress site before you begin?" ccmnd
	case $ccmnd in
	[Yy]* ) backup;;
	[Nn]* ) break;;
	*) echo "Please enter only yes or no. (y/n)";;
	esac
	done
}
initbackup
clear
menu () {
	DB_NAME="Φ"
	DB_USER="Φ"
	DB_PASS="Φ"
	clear
	echo
	echo -e "$green""      __      ____________  ___________            __           "
	echo -e "     /  \    /  \______   \ \_   _____/_ __  ____ |  | __       "
	echo -e "     \   \/\/   /|     ___/  |    __)|  |  \/    \|  |/ /       "
	echo -e "      \        / |    |      |     \ |  |  /   |  \    <        "
	echo -e "       \__/\  /  |____|      \___  / |____/|___|  /__|_ \       "
	echo -e "            \/                   \/             \/     \/     \n"
	echo -e "${red}""                    And I'm all out of Gum..                  \n"
	echo "${white}""################################################################"
	echo -e "##                                                            ##"
	echo -e "## backup - Backs up the WordPress Directory.                 ##"
	echo -e "## dplugins - Disable Wordpress Plugins                       ##"
	echo -e "## dthemes - Disable Wordpress Themes                         ##"
	echo -e "## ccreds - Check WordPress SQL Database Credentials          ##"
	echo -e "## fixperms Fix WordPress File Permissions Issues             ##"
	echo -e "## fixowner <user> - Fix WordPress File Ownership Issues      ##"
	echo -e "## updatewp - Manually update to latest WordPress Version     ##"
	echo -e "## cip <domain> - Check for proper DNS A Record.              ##"
	echo -e "## shelldrop - Drops into an interactive bash shell           ##"
	echo -e "##                                                            ##"
	echo -e "################################################################\n"
}
while :
	do
	menu
	read -r cmnd arg1
	case $cmnd in
	backup) backup;;
	dplugins) dplugins;;
	dthemes) dthemes;;
	ccreds) ccreds;;
	fixperms) fixperms;;
	fixowner) fixowner "${arg1}";;
	updatewp) updatewp;;
	cip) cip "${arg1}";;
	shelldrop) shelldrop;;
	*) echo -e "Unknown Command." && sleep 1;;
	esac
done