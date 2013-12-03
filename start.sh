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

# help

usage() {
  printf "Использование:\n\n"
  printf "\t-r  | --run\tСделай мне хорошо!\n"
  printf "\t-rm | --remove\tУдаление\n"
  printf "\t-h  | --help\tЭто сообщение\n"
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

  clear

  printf "➜ Host-файлы: %s\n" "${#HOST_FILES[@]}"

  j=0

  for i in ${HOST_FILES[@]}; do			
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

  [[ $yn = 'y' ]] && ( run_playbook hosts/"${HOST_FILES[$number]}" site.yml )

}

# Apps

ssh_ls_apps(){
		
  for h in `cat hosts/${HOST_FILES[$1]}`; do
    host_name=`echo $h | awk -F: '{print $1}'`
    port=`echo $h | awk -F: '{print $2}'`
    printf "── Host: %s" "$host_name"
    [[ $port ]] && printf ":%s\n" "$port" || printf ":22\n"
    ssh $host_name -p `[[ $port ]] && echo $port || echo 22` 'ls -d /home/deploy/*/*/www' 2>/dev/null || ( echo " ✗ Web-apps not found in /home/deploy!" && return 0 )
    echo
  done

}

list_all_installed_apps() {
  clear

  for f in ${HOST_FILES[@]}; do
    printf "➜ Host file: %s\n\n" "$f"
    ssh_ls_apps $f
  done
}

list_apps() {

  printf "➜ Host-файлы: %s\n" "${#HOST_FILES[@]}"

  j=0

  for i in ${HOST_FILES[@]}; do			
    printf "\t└── $i\t($j)\n"
    let j++
  done

  printf "\n➜ Введите номер интересующего вас host-файла...\nИли просмотреть их все? (a)\n"
  read number

  if [[ $number = 'a' ]]; then
    list_all_installed_apps
  else
    clear
    ssh_ls_apps $number

    [[ $? -eq 0 ]] || exit
			
    echo "➜ Удаляем эти приложения? y/n"
    read yn

    [[ $yn = 'y' ]] && ( run_playbook hosts/"${HOST_FILES[$number]}" remove.yml )
  fi

}

# User

ssh_ls_users() {

  for h in `cat hosts/${HOST_FILES[$1]}`; do
    host_name=`echo $h | awk -F: '{print $1}'`
    port=`echo $h | awk -F: '{print $2}'`
    printf "── Host: %s" "$host_name"
    [[ $port ]] && printf ":%s\n" "$port" || printf ":22\n"
    ssh $host_name -p `[[ $port ]] && echo $port || echo 22` 'ls /home/deploy/' 2>/dev/null
    users=( `ssh $host_name -p \`[[ $port ]] && echo $port || echo 22\` 'ls /home/deploy/' 2>/dev/null` )
  done

}

rm_users() {
  j=0
  printf "\n➜ Users:\n"
  for i in ${users[@]}; do
    printf "└── %s\t(%s)\n" "$i" "$j"
    let j++
  done 

  [[ ! ${users[0]} ]] && echo "Users not found!" && exit

  printf "\n➜ Введите номер юзера...\n"
  read usnum

  printf "Удаляем юзера %s? y/n\n" "${users[$usnum]}"
  read yn

  if [[ $yn = 'y' ]]; then
    printf "\nabsent_user: \"%s\"" "${users[$usnum]}" >> $SETTINGS
    run_playbook hosts/"${HOST_FILES[$1]}" remove_user.yml
  fi 
}

#list_all_users() {
#  clear

#  for f in ${HOST_FILES[@]}; do
#    printf "➜ Host file: %s\n\n" "$f"
#    ssh_ls_users $f
#  done
#  rm_users
#}

list_users() {

  printf "➜ Host-файлы: %s\n" "${#HOST_FILES[@]}"

  j=0

  for i in ${HOST_FILES[@]}; do			
    printf "\t└── $i\t($j)\n"
    let j++
  done

  printf "\n➜ Введите номер интересующего вас host-файла...\n"
#  printf "Или просмотреть их все? (a)\n"
  read number

#  if [[ $number = 'a' ]]; then
#    list_all_users
#  else
    clear
    ssh_ls_users "$number"
    rm_users "$number"
#  fi

}

#===

remove_something_dude() {

  clear

  printf "➜ Что будем удалять?\n"
  printf "\t├── Юзера?\t(1)\n"
  printf "\t└── Приложение?\t(2)\n"
  read num

  [[ $num = 1 ]] && list_users
  [[ $num = 2 ]] && list_apps

}

# Ansible!

run_playbook() {

  echo "➜ Введите пароль от sudo ..."
  ansible-playbook -i $1 $2 -K

}

#===

case $1 in

  -h|--help)
    usage
    ;;

  -r|--run)
    edit_vars
    generate_config
    view_hosts_files
    ;;

  -g|--generate)
    edit_vars
    generate_config
    ;;

  -rm|--remove)
    remove_something_dude
    ;;

  *)
    usage
    ;;

esac

exit 0
