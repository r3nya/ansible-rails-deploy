#!/bin/bash

SETTINGS="group_vars/all2"

###

# Привет, параметры для Nginx & unicorn можно править руками.
VARS=`awk -F: '/\w/ {print $1}' $SETTINGS | grep -vP '(^#|home|nginx)'`

###

usage() {

	echo 'Использование:'
	echo
	echo '-h | --help		Это сообщение'
	echo '-r | --run 		Сделай мне хорошо!'
	echo '-v | --view		Просмотреть текущие параметры'
	echo '-s | --setup		Настройка параметров'
}

view_setting() {

	cat $SETTINGS | grep -v ^\-
	echo
}

edit_config_dude() {

	echo 'Введите параметры...'

	for i in $VARS
		do
			echo $i ' == '
			read input_variable
			echo "Выбрано: $input_variable"
			sed "s/$i\:.*/$i\:\ \"$input_variable\"/" -i $SETTINGS
		done
}

setup_me() {

	echo 'Есть еще шанс прервать, продолжаем? y/n'

	read yn
		case $yn in
			y )
				edit_config_dude
				;;
			n )
				exit
				;;
		esac	
}

run_playbook() {
	echo "Введите пароль от sudo :)"
	ansible-playbook -i host site.yml -K
}

case $1 in

	-v|--view)
		view_setting
		;;

	-s|--setup)
		setup_me
		;;

	-h|--help)
		usage
		;;

	-r|--run)
		run_playbook
		;;

	*)
		usage
		;;

esac

exit 0