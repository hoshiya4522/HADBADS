# Intro
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
NOTE: Use this after you've partitioned and mounted your drive to /mnt .
"
[[ -e /mnt ]] || echo "Please partition your drive, mount it to /mnt and then use this script" && exit
read -p "$(echo -e "\033[1mDo you wish to continue [Y/n]\033[0m") " choice
while ! [[ $choice == "" || $choice == "y" || $choice == "n" || $choice == "Y" ||$choice == "N" ]]; do
	echo "Invalid argument! Please enter y OR n"
	read -p "$(echo -e "\033[1mDo you wish to continue [Y/n]\033[0m") " choice
	[[ $choice == "n" ]] && echo "Exiting..." && exit
done
[[ $choice == "n" ]] && echo "Exiting..." && exit
printf '\033c'


echo "Please Partition a drive to : "
read drive
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist --protocol https --download-timeout 5
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 5/" /etc/pacman.conf
loadkeys us
timedatectl set-ntp true

pacstrap /mnt base base-devel linux linux-firmware vim
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' arch_install.sh > /mnt/hadbads_part2.sh
chmod +x /mnt/hadbads_part2.sh
arch-chroot /mnt ./hadbads_part2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
# sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub efibootmgr os-prober
echo "Enter EFI partition: " 
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi 
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


pacman -S --needed --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick  \
     fzf man-db feh youtube-dl xclip maim \
     zip unzip unrar xdotool papirus-icon-theme brightnessctl  \
     dosfstools git sxhkd zsh pulseaudio \
     vim neovim arc-gtk-theme firefox dash \
     xcompmgr libnotify dunst jq zoxide xdg-user-dirs \
	 dhcpcd networkmanager pamixer alacritty python wget ranger thunar 

pacman -S $(pacman -Ssq noto-fonts-)

systemctl enable NetworkManager.service 
systemctl enable dhcpcd.service

rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username
echo "Pre-Installation Finish Reboot now"
third=/home/$username/hadbads_part3.sh
sed '1,/^#part3$/d' hadbads_part2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 


#part3
printf '\033c'
cd $HOME
mkdir -p ~/Git/dwm
mkdir -p ~/Git/dmenu
git clone --depth=1 https://github.com/hoshiya4522/dwm
sudo make -C ~/Git/dwm install
git clone --depth=1 https://github.com/hoshiya4522/dmenu
sudo make -C ~/Git/dmenu install



xdg-user-dirs-update



echo ".dotfiles" >> .gitignore

git clone --bare https://github.com/hoshiya4522/dotfiles/tree/master $HOME/.dotfiles

alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

dots checkout

mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}

dots checkout

mkdir -p ~/.config/plugins/zsh
mkdir -p ~/.config/plugins/tmux

sudo sh -c "curl https://raw.githubusercontent.com/holman/spark/master/spark -o /usr/local/bin/spark && chmod +x /usr/local/bin/spark"

git clone https://github.com/tmux-plugins/tpm ~/.config/plugins/tmux

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.config/plugins/zsh/zsh-autosuggestions
git clone https://github.com/joshskidmore/zsh-fzf-history-search ~/.config/plugins/zsh/zsh-fzf-history-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.config/plugins/zsh/zsh-syntax-highlighting

mkdir ~/tmp
cd tmp
git clone https://aur.archlinux.org/paru-bin.git 
cd paru-bin
makepkg -si

paru -S picom-jonaburg-git

exit
