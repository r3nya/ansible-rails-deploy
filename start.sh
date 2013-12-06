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

# Colors

R="\e[0;31m"  # red
G="\e[0;32m"  # green
Y="\e[0;33m"  # yellow
B="\e[0;34m"  # blue
M="\e[0;35m"  # magenta
C="\e[0;36m"  # cyan
UC="\e[0m"  # user color

# help

usage() {
  printf "$GИспользование:$UC\n\n"
  printf "\t-r  | --run\tДеплой!\n"
  printf "\t-rm | --remove\tУдаление\n"
  printf "\t-a  | --apps\tПросмотр\n"
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

  printf "${G}➜ Host-файлы: %s${UC}\n" "${#HOST_FILES[@]}"

  j=0

  for i in "${HOST_FILES[@]}"; do			
    printf "${C}\n$j) $i\n${UC}"
    cat hosts/"${HOST_FILES[$j]}" | grep -v ^#
    let j++
  done

  printf "${G}➜ Введите номер интересующего вас файла ...${UC}\n"
  read number

  clear
  printf "${G}Deploy hosts:${UC}\n"
  cat hosts/"${HOST_FILES[$number]}"
	
  printf "${R}Перейти к деплою этих хостов? y/n${UC}\n"
  read yn

  [[ $yn = 'y' ]] && ( run_playbook hosts/"${HOST_FILES[$number]}" site.yml )

}

get_host() {
  host_name="`echo $1 | awk -F: '{print $1}'`"
  port="`echo $1 | awk -F: '{print $2}'`"
}

# Apps

ssh_ls_apps() {
		
  for h in "`cat hosts/${HOST_FILES[$1]} | grep -v ^#`"; do
    get_host "$h"
    printf "${G}── Host: %s${UC}" "$host_name"
    [[ $port ]] && (printf "${G}:%s${UC}\n" "$port") || (printf "${G}:22${UC}\n")
    ssh $host_name -p `[[ $port ]] && echo $port || echo 22` 'echo; ls -d /home/deploy/*/*/www' 2>/dev/null || ( printf "${R} ✗ Web-apps not found in /home/deploy!${UC}\n"; FAIL='1')
  done

}

list_all_installed_apps() {
  clear

  j=0

  for f in "${HOST_FILES[@]}"; do
    printf "\n${G} ➜ Host file: %s - %s${UC}\n\n" "$j" "$f"
    ssh_ls_apps "$j"
    let j++
  done
}

list_apps() {

  printf "${G}➜ Host-файлы: %s${UC}\n" "${#HOST_FILES[@]}"

  j=0

  for i in "${HOST_FILES[@]}"; do			
    printf "\t└── ${C}$i${UC}\t($j)\n"
    let j++
  done

  printf "\n${G}➜ Введите номер интересующего вас host-файла...\nИли просмотреть их все? (a)${UC}\n"
  read number

  if [[ $number = 'a' ]]; then
    list_all_installed_apps
  else
    clear
    ssh_ls_apps $number

    set -e

    [[ $FAIL ]] && exit
			
    printf "${R}➜ Удаляем эти приложения? y/n${UC}\n"
    read yn

    [[ $yn = 'y' ]] && ( run_playbook hosts/"${HOST_FILES[$number]}" remove.yml )
  fi

}

# User

ssh_ls_users() {

  for h in "`cat hosts/${HOST_FILES[$1]} | grep -v ^#`"; do
    get_host $h
    users=( `ssh $host_name -p \`[[ $port ]] && echo $port || echo 22\` 'ls /home/deploy/' 2>/dev/null` )
  done

}

rm_users() {
  j=0
  printf "${G}➜ Users:${UC}\n"
  for i in "${users[@]}"; do
    printf "└── %s\t(%s)\n" "$i" "$j"
    let j++
  done 

  [[ ! ${users[0]} ]] && printf "${R} ✗ Users not found!${UC}\n" && exit

  printf "\n${G}➜ Введите номер юзера...${UC}\n"
  read usnum

  printf "${R}Удаляем юзера '%s'? y/n ${UC}\n" "${users[$usnum]}"
  read yn

  if [[ $yn = 'y' ]]; then
    printf "\nabsent_user: \"%s\"" "${users[$usnum]}" >> $SETTINGS
    run_playbook hosts/"${HOST_FILES[$1]}" remove_user.yml
  fi 
}

list_users() {
  printf "${G}➜ Host-файлы: %s${UC}\n" "${#HOST_FILES[@]}"

  j=0

  for i in ${HOST_FILES[@]}; do			
    printf "\t└── ${C}$i\t($j)${UC}\n"
    let j++
  done

  printf "\n${G}➜ Введите номер интересующего вас host-файла...${UC}\n"

  read number

  clear
  ssh_ls_users "$number"
  rm_users "$number"
}

#===

view_apps() { 
  for i in "${HOST_FILES[@]}"; do     
    printf "\n${G}➜ Host file: $i ${UC}\n"
      for h in "`cat hosts/$i | grep -v ^#`"; do
        get_host "$h"

        printf "${C}\n─ Host: %s${UC}" "$host_name"
        [[ $port ]] && printf "${C}:%s${UC}" "$port" || printf "${C}:22${UC}"

        printf "\n└─ Users: "
        ssh $host_name -p `[[ $port ]] && echo $port || echo 22` 'echo; ls /home/deploy/' 2>/dev/null || ( printf "${R}\t✗ Not found!${UC}" )

        printf "\n└─ Apps: "
        ssh $host_name -p `[[ $port ]] && echo $port || echo 22` 'echo; ls -d /home/deploy/*/*/www' 2>/dev/null || ( printf "${R}\t✗ Web-apps not found in /home/deploy!${UC}\n")
      done
  done  
}

#===

remove_something_dude() {

  clear

  printf "${G}➜ Что будем удалять?${UC}\n"
  printf "\t├── ${C}Юзера?\t(1)${UC}\n"
  printf "\t└── ${C}Приложение?\t(2)${UC}\n"
  read num

  [[ $num = 1 ]] && list_users
  [[ $num = 2 ]] && list_apps

}

# Ansible!

run_playbook() {

  printf "${R}➜ Введите пароль от sudo ...${UC}\n"
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

  -a|--apps)
    view_apps
    ;;

  *)
    usage
    ;;

esac

# Hello!

exit 0
