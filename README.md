![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/television-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/television-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/television-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/television-debian)

<h1>
   <p align="center">
     <a href="https://alexpasmantier.github.io/television/"><img src="https://github.com/dariogriffo/television-debian/blob/main/television.png" alt="television Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/television-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>television for Debian
   </p>
</h1>
<p align="center">
 television is a very fast, portable and hackable fuzzy finder for the terminal.
</p>

# television for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [television](https://github.com/alexpasmantier/television/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Jammy (22.04)
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions
- i386 (x86 32-bit) - Debian only

Upstream publishes no armel, armhf or riscv64 binaries, so those architectures
are not available.

The packages include the television binary, the man page and shell completions
for bash, fish and zsh.

> ⚠️ **The command is `tv`, not `television`.** The package installs
> `/usr/bin/tv`, matching upstream's own naming.
>
> Because of that, this package **conflicts with `treeviewx`**, the only package
> in Debian/Ubuntu that also ships `/usr/bin/tv` (and `tv.1`). apt will refuse to
> install both at once rather than corrupt either package's files.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the television source code, see
[television](https://github.com/alexpasmantier/television/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-television-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-television-in-ubuntu.html)

### The Debian way

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/television-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y television
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/television-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

### Build for single architecture
```sh
./build.sh <television_version> <build_version> <architecture>
# Example: ./build.sh 0.15.9 1 arm64
```

### Build for all architectures
```sh
./build.sh <television_version> <build_version> all
# Example: ./build.sh 0.15.9 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64, i386)

## Disclaimer

- This repo is not open for issues related to television. This repo is only for _unofficial_ Debian packaging.
