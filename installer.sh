#!/bin/bash

# Config start
hostname="Pluto"
username="hoshiya4522"
password="123"

device="/dev/vda"	# you may want to change it to "/dev/nvme0n1"
efidevice=""		# if left empty, devicep2 will be chosen automatically
			# example: nvme0n1p1
rootdevice=""		# if left empty, devicep1 will be chosen automatically
			# example: nvme0n1p2

preserve_home=true
home_subvolume="@home"

swapsize="$(free -b|awk '/^Mem:/{print $2}')"

dotfiles_repo="https://github.com/hoshiya4522/dotfiles"

timezone="Asia/Dhaka"

# Config End



# Turn on extended globbing
shopt -s extglob


# define root and efi devices, depending on, vda, sda, nvme

# identify naming scheme
if [[ "${device}" == /dev/nvme* ]]; then
	part_suffix="p"
else
	part_suffix=""
fi

# check if efi
if [[ -d "/sys/firmware/efi" ]]; then
	if [[ -n "${efidevice}" ]]; then
		efidev="${efidevice}"			# Use user config if provided
	else
		efidev="${device}${part_suffix}1"	# else use the first partition
	fi
else
	echo "This script only supports UEFI systems for now."
	exit 1
fi

if [[ -n "${rootdevice}" ]]; then
	rootdev="${rootdevice}"				# Use user config if provided
else
	if [[ -d "/sys/firmware/efi" ]]; then
		rootdev="${device}${part_suffix}2"	# else use second partition
	else
		echo "This script only supports UEFI systems for now."
		exit 1
		# rootdev="${device}${part_suffix}1"
	fi
fi



hadbads_check_liveiso() {
	if [ ! -d "/sys/firmware/efi" ]; then
		echo "This system is ment to be run on UEFI systems."
		exit 1
	fi
	if [ ! "$(uname -n)" = "archiso" ]; then
		echo "This script is ment to be run from the Archlinux live medium."
		exit
	fi
	if [ "$(id -u)" -ne 0 ]; then
		echo "This script must be run as root."
		exit
	fi
}


hadbads_setclock() {
	# Setting system clock
	timedatectl set-ntp true
}

hadbads_disk_partition() {
	if [[ "${preserve_home}" = false ]]; then
		# esp partition from start to 1G
		# primary partition from 1G to finish
		# parted -s "$device" mklabel gpt \
		# 	mkpart esp 0% 1GiB \ 
		# 	mkpart primary 1GiB 100% \ 
		# 	set 1 esp on
		parted -s "$device" mklabel gpt mkpart esp 0% 1GiB mkpart primary 1GiB 100% set 1 esp on

		# specify device type
		mkfs.fat -F 32 "${efidev}"
		mkfs.btrfs -f "${rootdev}"

		mount "${rootdev}" /mnt

		# https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout
		# | tags       | final mountpoint | mountpoint for pacstrap |
		# |------------|------------------|-------------------------|
		# | @          | /                | /mnt/@                  |
		# | @home      | /home            | /mnt/@home              |
		# | @snapshots | /.snapshots      | /mnt/@snapshots         |
		# | @var_log   | /var/log         | /mnt/@var_log           |
		# | @swap      | /.swap           | /mnt/@swap              |

		# subvolumes creation
		btrfs subvolume create "/mnt/${home_subvolume}"
	else
		mkfs.fat -F 32 "${efidev}"

		# mount existing btrfs device
		mount "${rootdev}" /mnt

		# delete all subvolumes except home_subvolume
		btrfs subvolume list /mnt | sed 's/.*path //' | while read -r subvol; do
		if [ "$subvol" != "$home_subvolume" ]; then
			btrfs subvolume delete "/mnt/$subvol" 2>/dev/null || true
		fi
		done
	fi

	btrfs subvolume create /mnt/@
	btrfs subvolume create /mnt/@snapshots
	btrfs subvolume create /mnt/@var_log
	btrfs subvolume create /mnt/@swap

	# unmount
	umount /mnt

	# mount with proper options
	mount -o compress=zstd,subvol=@ "${rootdev}" /mnt
	mkdir -p /mnt/home /mnt/.snapshots /mnt/var/log /mnt/.swap /mnt/boot/efi

	mount -o compress=zstd,subvol="${home_subvolume}" "${rootdev}" /mnt/home
	mount -o compress=zstd,subvol=@var_log "${rootdev}" /mnt/var/log
	mount -o compress=zstd,subvol=@snapshots "${rootdev}" /mnt/.snapshots

	# Mount swap file
	mount -o compress=zstd,subvol=@swap "${rootdev}" /mnt/.swap
	btrfs filesystem mkswapfile --size "${swapsize}" --uuid clear /mnt/.swap/swapfile
	swapon /mnt/.swap/swapfile

	# Mount boot partition
	mount "${efidev}" /mnt/boot/efi
}

hadbads_pac_mirror() {
	pacman -Sy reflector --noconfirm --needed
	reflector --country Bangladesh,India --sort rate --save /etc/pacman.d/mirrorlist
}

hadbads_pacstrap() {
	if grep -q "Intel" /proc/cpuinfo; then
		UCODE="intel-ucode"
	elif grep -q "AMD" /proc/cpuinfo; then
		UCODE="amd-ucode"
	else
		UCODE=""
		echo "Warning: Unknown CPU. No microcode selected."
	fi

	pacstrap /mnt $(awk -F'#' '{print $1}' pkglists/base.txt) $UCODE

	genfstab -U /mnt >> /mnt/etc/fstab
}


hadbads_chroot(){
	# Copy this script into root
	# -D : Create directories if required
	# m755 : Owner can read and write, and others can execute.
	install -Dm755 "$0" /mnt/root/archer.sh
	cp -r pkglists /mnt/root/

	# Use cache if it exists
	# make sure to mount it if it is on a separate partition
	# mount /dev/vdb /var/cache/pacman/pkg
	mkdir -p /mnt/var/cache/pacman/pkg
	mount --bind /var/cache/pacman/pkg /mnt/var/cache/pacman/pkg

	arch-chroot /mnt /root/archer.sh --chroot
}

hadbads_locale(){
	sed -i '/^#'en_US.UTF'/s/^#//g' /etc/locale.gen
	printf "LANG=en_US.UTF-8" > /etc/locale.conf
	locale-gen
	ln -sf /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
	hwclock --systohc
}

hadbads_hostname() {
	printf "%s\n" "$hostname" > /etc/hostname
	printf "%-16s %s %s\n" "127.0.1.1" "$hostname" >> /etc/hosts
}

hadbads_initramfs() {
	sed -i '/^MODULES=/s/=()/=(btrfs)/' /etc/mkinitcpio.conf
	mkinitcpio -P
	chmod 600 /boot/initramfs-linux*
}

hadbads_configure_pacman() {
	sed -i "s/^#\(Color\)/\1/" /etc/pacman.conf
	sed -i "s/^#\(ILoveCandy\)/\1/" /etc/pacman.conf
	sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
}

hadbads_configure_bootloader() {
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
}

hadbads_setup_chaotic_aur() {
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB

	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

	cat >> /etc/pacman.conf <<EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

	pacman -Syu --noconfirm
}

hadbads_setup_xlibre_repo() {
	pacman-key --recv-keys 73580DE2EDDFA6D6
	pacman-key --finger 73580DE2EDDFA6D6
	pacman-key --lsign-key 73580DE2EDDFA6D6

	cat >> /etc/pacman.conf <<EOF
[xlibre]
Server = https://x11libre.net/repo/arch_based/x86_64
EOF
	pacman -Syu --noconfirm
}

hadbads_packages_install() {
	pacman -Syu --noconfirm --needed $(awk -F'#' '{print $1}' /root/pkglists/pacman_packages.txt) yay

	# select stable rust. as yay may have some rust programs
	sudo -u "$username" rustup default stable

	sudo -u "$username" yay -Syu --noconfirm --needed $(awk -F'#' '{print $1}' /root/pkglists/aur_packages.txt)

	usermod -aG libvirt "$username"

	# Download handy
	URL=$(curl -s "https://api.github.com/repos/cjpais/Handy/releases/latest" | sed -n 's/.*"browser_download_url": "\(.*amd64\.AppImage\)".*/\1/p')
	curl -L "$URL" -o handy.AppImage && chmod +x handy.AppImage
	mkdir -p /home/$username/.local/bin
	mv handy.AppImage /home/$username/.local/bin/

	# Download hexecute
	URL=$(curl -s "https://api.github.com/repos/m31-galaxy/Hexecute/releases" | sed -n 's/.*"browser_download_url": "\(.*hexecute\)".*/\1/p' | head -n 1)
	curl -LO "$URL" && chmod +x hexecute
	mv hexecute /home/$username/.local/bin/
}

hadbads_configure_user() {
	echo "root:${password}" | chpasswd

	useradd -mG wheel -s /bin/bash "$username"

	echo "${username}:${password}" | chpasswd

	sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

	sudo -H -u "$username" xdg-user-dirs-update
}

hadbads_install_tpm() {
	# tmux package manager
	sudo -u "$username" mkdir -p "/home/$username/.tmux/plugins"
	sudo -u "$username" git clone https://github.com/tmux-plugins/tpm "/home/$username/.tmux/plugins/tpm"
}

hadbads_apply_dotfiles() {
	pacman -S --noconfirm --needed git chezmoi # confirming one more time
	sudo -u "$username" chezmoi init --apply "${dotfiles_repo}"
}

hadbads_bengali_font_fix() {
	# https://github.com/tazihad/bangla-font-fix-linux
	sudo -u "$username" sh -c "curl -sSL https://raw.githubusercontent.com/tazihad/bangla-font-fix-linux/main/fonts-bangla-download.sh | sh"
	sudo -u "$username" sh -c "curl -sSL https://raw.githubusercontent.com/tazihad/bangla-font-fix-linux/main/bangla-nirmalaui-default.sh | sh"
	sudo -u "$username" sh -c "curl -sSL https://raw.githubusercontent.com/tazihad/bangla-font-fix-linux/main/msfonts-download.sh | sh"

}

hadbads_enable_services() {
	systemctl enable NetworkManager
	systemctl enable auto-cpufreq
	systemctl enable cups
	systemctl enable avahi-daemon
	systemctl enable libvirtd
	systemctl enable cronie
	systemctl enable plasmalogin
	systemctl enable fstrim.timer
}



if [ "$1" != "--chroot" ]; then
	hadbads_check_liveiso
	hadbads_setclock
	hadbads_disk_partition
	hadbads_pac_mirror
	hadbads_pacstrap
	hadbads_chroot
else
	hadbads_locale
	hadbads_hostname
	hadbads_initramfs
	# Temporarily disable sudo password requirement
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_wheel_nopasswd
	hadbads_configure_pacman
	hadbads_configure_bootloader
	hadbads_setup_xlibre_repo
	hadbads_setup_chaotic_aur
	hadbads_configure_user
	hadbads_packages_install
	hadbads_install_tpm
	hadbads_apply_dotfiles
	hadbads_bengali_font_fix
	hadbads_enable_services
	# Enable sudo password requirements
	rm /etc/sudoers.d/99_wheel_nopasswd
	echo "Installation Complete. Reboot now."
fi
