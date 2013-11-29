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
USER_HOME='/home/deploy/{{ user }}'

RUBY_VERSION='2.0.0-p353'

NGINX_LISTEN_ADDRESS='0.0.0.0'
NGINX_LISTEN_PORT='80'
UNICORN_WORKERS='2'

###

usage() {

	printf "Использование:\n\n"
	printf "\t-r | --run\tСделай мне хорошо!\n"
	printf "\t-a | --apps\tПросмотр установленных приложений\n"
	printf "\t-h | --help\tЭто сообщение\n"
}

edit_vars() {

	read -e -p "Application name: " -i "$APP_NAME" APP_NAME
	read -e -p "Git url: " -i "$GIT_URL" GIT_URL
	read -e -p "Branch name for git checkout: " -i "$GIT_BRANCH" GIT_BRANCH

	read -e -p "User name: " -i "$USER_NAME" USER_NAME
	read -e -p "User password: " -i "$USER_PASSWORD" USER_PASSWORD
	read -e -p "User shell: " -i "$USER_SHELL" USER_SHELL

	read -e -p "Ruby version: " -i "$RUBY_VERSION" RUBY_VERSION

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

	printf "ruby_version: \"%s\"\n" "$RUBY_VERSION" >> $SETTINGS

	printf "\n### Config files\n" >> $SETTINGS

	printf "nginx_listen_address: \"%s\"\n" "$NGINX_LISTEN_ADDRESS"	>> $SETTINGS
	printf "nginx_listen_port: \"%s\"\n\n" "$NGINX_LISTEN_PORT"		>> $SETTINGS
	printf "unicorn_workers: \"%s\"" "$UNICORN_WORKERS" >> $SETTINGS

}

view_hosts_files() {

	printf "Host-файлы: %s\n" "${#HOST_FILES[@]}"

	j=0

	for i in ${HOST_FILES[@]}
		do			
			printf "\n$j) $i\n"
			cat hosts/"${HOST_FILES[$j]}"
			let j++
		done

	printf "Введите номер интересующего вас файла ...\n"
	read number

	clear
	echo "Deploy hosts:"
	cat hosts/"${HOST_FILES[$number]}"
	
	echo "Перейти к деплою этих хостов? y/n"
	read yn

	[ $yn = 'y' ] && ( run_playbook hosts/"${HOST_FILES[$number]}" )

}

ssh_ls_apps(){
		
		for h in `cat hosts/${HOST_FILES[$1]}`; do
			host_name=`echo $h | awk -F: '{print $1}'`
			port=`echo $h | awk -F: '{print $2}'`
			printf "Host: %s\n" "$host_name"
			ssh $host_name -p `[ $port ] && echo $port || echo 22` 'ls -d /home/deploy/*/*/www' 2>/dev/null
			echo
		done

}

list_all_installed_apps() {

	clear

	for f in ${HOST_FILES[@]}; do
		printf "Host file: %s\n\n" "$f"
		ssh_ls_apps $f
	done
}

list_apps() {

	printf "Host-файлы: %s\n" "${#HOST_FILES[@]}"

	j=0

	for i in ${HOST_FILES[@]}
		do			
			printf "\n$j) $i\n"
			let j++
		done

	printf "\nВведите номер интересующего вас host-файла...\nИли просмотреть их все? (a)\n"
	read number

	if [ $number = 'a' ]
		then
			list_all_installed_apps
		else
			clear
			ssh_ls_apps $number
			
			echo "Удаляем эти приложения? y/n"
			read yn

			[ $yn = 'y' ] && ( delete_apps hosts/"${HOST_FILES[$number]}" )
	fi

}

delete_apps() {

	echo "Введите пароль от sudo ..."
	ansible-playbook -i $1 remove.yml -K

}


run_playbook() {

	echo "Введите пароль от sudo ..."
	ansible-playbook -i $1 site.yml -K

}

case $1 in

	-h|--help)
		usage
		;;

	-r|--run)
		view_hosts_files
		;;

	-g|--generate)
		edit_vars
		generate_config
		;;

	-a|--apps)
		list_apps
		;;

	*)
		usage
		;;

esac

exit 0
