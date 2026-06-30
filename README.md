<img src="logo.png" width="550px" alt="HADBADS Logo">

**H**oshiya's **A**wful **D**otfiles **B**ootstrap **A**nd **D**eployment **S**cript - HADBADS

> [!WARNING]
> I made this script for myself. This may or may not work for you.

> [!NOTE]
> Havent tested the dev version...

**Default Config:**
- **Hostname:** Pluto `(I like space related names)`
- **Username:** hoshiya4522  `(Hey, thats me :D)`
- **Storage Drive:** `/dev/vda` - **Make sure to change this to your actual drive.**
- **Password:** 123 `(Most secure password in the world)`
- **Dotfiles Repo (Managed with Chezmoi):**  [hoshiya4522/dotfiles](https://github.com/hoshiya4522/dotfiles).
- ⚠️ NOTE: This script only works for UEFI systems, for now

## How to Install

1. Boot into the Arch Linux Live USB.
2. Connect to the internet. [Guide](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet), [Using iwctl](https://wiki.archlinux.org/title/Iwd#iwctl)
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

5. Wait for the installation to finish and then reboot your computer.



## References (Places I've stolen from)

- [Archer - Archlinux install script by mietinen](https://github.com/mietinen/archer) - Heavily "inspired" from
- [Modern Arch linux installation guide by mjkstra](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae)
- [Official Arch Linux Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [Bangla fonts fix linux by tazihad](https://github.com/tazihad/bangla-font-fix-linux)
