printf '\033c'
echo -e "\e[34m
██╗               ██╗██╗               ██╗
██║               ██║██║               ██║
██████╗  ████╗██████║██████╗  ████╗██████║  ████╗
██╔═██║██╔═██║██╔═██║██╔═██║██╔═██║██╔═██║  ██╔═╝
██║ ██║██████║██████║██████║██████║██████║████║
╚═╝ ╚═╝╚═════╝╚═════╝╚═════╝╚═════╝╚═════╝╚═══╝\e[0m
╔═══════════════════════════════════════════════════════════════════╗
║ \e[34mHoshiya's Auto Dotfiles Bootstrap And Deployment Script (HADBADS)\e[0m ║
║ (C) 2021 hoshiya4522 - MIT                                        ║
║\e[33m WARNING: This script is experimental.\e[0m                             ║
║         \e[33m Use at your own risk!\e[0m                                    ║
╚═══════════════════════════════════════════════════════════════════╝
"
read -p "$(echo -e "\033[1mDo you wish to continue [Y/n]\033[0m") " choice
while ! [[ $choice == "" || $choice == "y" || $choice == "n" || $choice == "Y" ||$choice == "N" ]]; do
	echo "Invalid argument! Please enter y OR n"
	read -p "$(echo -e "\033[1mDo you wish to continue [Y/n]\033[0m") " choice
	[[ $choice == "n" ]] && echo "Exiting..." && exit
done
[[ $choice == "n" ]] && echo "Exiting..." && exit
printf '\033c'
