![MSmisc-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![MSmisc-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![MSmisc-depend-minsign](https://img.shields.io/badge/dependency-minisign%200.6-green.svg)](https://github.com/jedisct1/minisign)
[![MSmisc-depend-tnote](https://img.shields.io/badge/dependency-terminal--notifier%201.6.3-green.svg)](https://github.com/alloy/terminal-notifier)
[![MSmisc-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/minisign-misc/blob/master/license.md)

# Minisign Miscellanea <img src="https://github.com/JayBrown/minisign-misc/blob/master/img/jb-img.png" height="20px"/>
**macOS workflows and shell scripts to verify and sign files with minisign**

![ms-sign-screengrab](https://github.com/JayBrown/minisign-misc/blob/master/img/minisign-sign-grab.png)

![ms-verify-screengrab](https://github.com/JayBrown/minisign-misc/blob/master/img/minisign-verify-grab.png)

## Prerequisites
Install using [Homebrew](http://brew.sh) with `brew install <software-name>` (or with a similar manager)

* [minisign](https://github.com/jedisct1/minisign)
* [terminal-notifier](https://github.com/alloy/terminal-notifier)

You need to have Spotlight enabled for `mdfind` to locate the terminal-notifier.app on your volume; if you don't install terminal-notifier, or if you have deactivated Spotlight, the minisign scripts will call notifications via AppleScript instead

## Installation & Usage
* [Download the latest DMG](https://github.com/JayBrown/minisign-misc/releases) and open

### Workflows
* Double-click on the workflow files to install
* If you encounter problems, open them with Automator and save/install from there
* Standard Finder integration in the Services menu

### Shell scripts [optional]
* Move the scripts to `/usr/local/bin`
* In your shell enter `chmod +x /usr/local/bin/minisign-verify.sh` and `chmod +x /usr/local/bin/minisign-sign.sh`
* Run the scripts with `minisign-verify.sh /path/to/your/file` and `minisign-sign.sh /path/to/your/file`

Only necessary if for some reason you want to run this from the shell or another shell script.

## General Notes
* My own minisign public key for releases on Github will be created in `${HOME}/Documents/minisign`

## To-do
* Switch private keys directory to `${HOME}/.minisign` (depending on minisign update)
