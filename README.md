# HADBADS
Hoshiya's Awful Dotfiles Bootstrap And Deployment Script

> [!WARNING]
> I made this script for myself. This may or may not work for you.
> Works on my VM™.

**Note:**
- hostname is "Pluto" (I like intersteller names)
- username "hoshiya4522"  (me :D)
- device is `/dev/vda` - **Make sure to change this to your actual drive.**
- and the password is `123` (Most secure password in the world)
- (Also this only works for UEFI systems, for now)

## How to Install

1. Boot into the Arch Linux Live USB.
2. Connect to the internet. [Guide](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet), [Using iwctl](https://wiki.archlinux.org/title/Iwd)
3. Install git:
```bash
pacman -Sy git
```

4. Download or clone this repository:
```bash
git clone https://github.com/hoshiya4522/hadbads.git
cd hadbads
```

5. Run the script as root:
```bash
chmod +x installer.sh && ./installer.sh
```

5. Wait for the installation to finish and reboot your computer.



## References (Codes ive stolen from)
- [Archer - Archlinux install script by mietinen](https://github.com/mietinen/archer) - Heavily "inspired" from
- [Modern Arch linux installation guide by mjkstra](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae)
- [Official Arch Linux Installation guide](https://wiki.archlinux.org/title/Installation_guide)
