#!/bin/bash

SETTINGS="group_vars/all"
HOST_FILES=( `ls hosts/` )

# Default variables

APP_NAME='awesome-site'
GIT_URL='https://github.com/railstutorial/sample_app_rails_4.git'
GIT_BRANCH='master'

USER_NAME='deploy'
USER_PASSWORD='12345'
USER_SHELL='/bin/bash'
USER_HOME='/home/$user'

NGINX_LISTEN_ADDRESS='0.0.0.0'
NGINX_LISTEN_PORT='80'
UNICORN_WORKERS='2'

###

usage() {

	printf "Использование:\n\n"
	printf "\t-r | --run\tСделай мне хорошо!\n"
	printf "\t-v | --view\tПросмотреть текущие параметры\n"
	printf "\t-h | --help\tЭто сообщение\n"
}

edit_vars() {

	read -e -p "Application name: " -i "$APP_NAME" APP_NAME
	read -e -p "Git url: " -i "$GIT_URL" GIT_URL
	read -e -p "Branch name for git checkout: " -i "$GIT_BRANCH" GIT_BRANCH

<<<<<<< HEAD
	read -e -p "User name: " -i "$USER_NAME" USER
=======
	read -e -p "User name: " -i "$USER_NAME" USER_NAME
>>>>>>> b586bd16ea24a623000a32a476c073d636351fce
	read -e -p "User password: " -i "$USER_PASSWORD" USER_PASSWORD
	read -e -p "User shell: " -i "$USER_SHELL" USER_SHELL
	read -e -p "User home: " -i "$USER_HOME" USER_HOME

	read -e -p "Nginx listen address: " -i "$NGINX_LISTEN_ADDRESS" NGINX_LISTEN_ADDRESS
	read -e -p "Nginx listen port: " -i "$NGINX_LISTEN_PORT" NGINX_LISTEN_PORT
	read -e -p "Unicorn workers: " -i "$UNICORN_WORKERS" UNICORN_WORKERS

 }

generate_config() {

	echo "---" > $SETTINGS

	printf "### Application\n" >> $SETTINGS

	printf "app_name: \"%s\"\n" "$APP_NAME"	>> $SETTINGS
	printf "git_url: \"%s\"\n" "$GIT_URL"	>> $SETTINGS
	printf "git_branch: \"%s\"\n" "$GIT_BRANCH" >> $SETTINGS
	
	printf "\n### System\n" >> $SETTINGS

	printf "user: \"%s\"\n" "$USER_NAME"	>> $SETTINGS
	printf "user_password: \"%s\"\n" "$USER_PASSWORD" >> $SETTINGS
	printf "user_shell: \"%s\"\n" "$USER_SHELL" >> $SETTINGS
	printf "home: \"%s\"\n" "$USER_HOME" >> $SETTINGS

	printf "\n### Config files\n" >> $SETTINGS

	printf "nginx_listen_address: \"%s\"\n" "$NGINX_LISTEN_ADDRESS"	>> $SETTINGS
	printf "nginx_listen_port: \"%s\"\n\n" "$NGINX_LISTEN_PORT"		>> $SETTINGS
	printf "unicorn_workers: \"%s\"" "$UNICORN_WORKERS" >> $SETTINGS

}

view_hosts_files() {

	printf "Host-файлы: %s\n\n" "${#HOST_FILES[@]}"

	j=0

	for i in ${HOST_FILES[@]}
		do			
			printf "$j: $i\n"
			let j++
		done
}

cat_hosts_files() {

	printf "Введите номер файла для просмотра его хостов\n"
	read number
	cat hosts/"${HOST_FILES[$number]}"

	echo "Перейти к деплою этих хостов? y/n"
	read yn

	if [ $yn = 'y' ]
		then
			run_playbook hosts/"${HOST_FILES[$number]}"
	fi

}


run_playbook() {

	echo "Введите пароль от sudo ..."
	ansible-playbook -i $1 site.yml -K

}

case $1 in

	-h|--help)
		usage
		;;

	-v|--view)
		view_hosts_files
		cat_hosts_files
		;;

	-r|--run)

		edit_vars
		generate_config
		;;

	*)
		usage
		;;

esac

exit 0
