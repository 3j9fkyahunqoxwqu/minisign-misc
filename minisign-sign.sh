#!/bin/bash

# minisign-sign v1.4.1 (shell script version)

LANG=en_US.UTF-8
export PATH=/usr/local/bin:$PATH
ACCOUNT=$(who am i | /usr/bin/awk '{print $1}')

# determine correct Mac OS name
MACOS2NO=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{print $2}')
if [[ "$MACOS2NO" -le 7 ]] ; then
	OSNAME="Mac OS X"
elif [[ "$MACOS2NO" -ge 8 ]] && [[ "$MACOS2NO" -le 11 ]] ; then
	OSNAME="OS X"
elif [[ "$MACOS2NO" -ge 12 ]] ; then
	OSNAME="macOS"
fi

# set notification function
notify () {
 	if [[ "$NOTESTATUS" == "osa" ]] ; then
		/usr/bin/osascript -e 'display notification "$2" with title "$ACCOUNT minisign" subtitle "$1"' &>/dev/null
	elif [[ "$NOTESTATUS" == "tn" ]] ; then
		"$TERMNOTE_LOC/Contents/MacOS/terminal-notifier" \
			-title "$ACCOUNT minisign" \
			-subtitle "$1" \
			-message "$2" \
			-appIcon "$ICON" \
			>/dev/null
	fi
}

# look for terminal-notifier
TERMNOTE_LOC=$(/usr/bin/mdfind "kMDItemCFBundleIdentifier = 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | /usr/bin/awk 'NR==1')
if [[ "$TERMNOTE_LOC" == "" ]] ; then
	NOTESTATUS="osa"
else
	NOTESTATUS="tn"
fi

# directories
CACHE_DIR="${HOME}/Library/Caches/local.lcars.minisign"
if [[ ! -e "$CACHE_DIR" ]] ; then
	mkdir -p "$CACHE_DIR"
fi
SIGS_DIR="${HOME}/Documents/minisign"
if [[ ! -e "$SIGS_DIR" ]] ; then
	mkdir -p "$SIGS_DIR"
fi
PRIVATE_DIR="$SIGS_DIR/prvt"
if [[ ! -e "$PRIVATE_DIR" ]] ; then
	mkdir -p "$PRIVATE_DIR"
fi
FLAG=$(cd "$SIGS_DIR" | ls -lO | /usr/bin/awk '/prvt/ {print $5}')
if [[ "$FLAG" != "hidden" ]] ; then
	/usr/bin/chflags hidden "$PRIVATE_DIR"
fi

# icon in base64
ICON64="iVBORw0KGgoAAAANSUhEUgAAAIwAAACMEAYAAAD+UJ19AAACYElEQVR4nOzUsW1T
URxH4fcQSyBGSPWQrDRZIGUq2IAmJWyRMgWRWCCuDAWrGDwAkjsk3F/MBm6OYlnf
19zqSj/9i/N6jKenaRpjunhXV/f30zTPNzePj/N86q9fHx4evi9j/P202/3+WO47
D2++3N4uyzS9/Xp3d319+p3W6+fncfTnqNx3Lpbl3bf/72q1+jHPp99pu91sfr4f
43DY7w+fu33n4tVLDwAul8AAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATIC
A2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEB
MgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZ
gQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzA
ABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERggIzBARmCA
jMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJARGCAjMEBG
YICMwAAZgQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMw
QEZggIzAABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERgg
IzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJAR
GCAjMEBGYICMwAAZgQEy/wIAAP//nmUueblZmDIAAAAASUVORK5CYII="

# decode icon
ICON="$CACHE_DIR/lcars.png"
if [[ ! -e "$ICON" ]] ; then
	echo "$ICON64" > "$CACHE_DIR/lcars.base64"
	/usr/bin/base64 -D -i "$CACHE_DIR/lcars.base64" -o "$ICON" && rm -rf "$CACHE_DIR/lcars.base64"
fi
if [[ -e "$CACHE_DIR/lcars.base64" ]] ; then
	rm -rf "$CACHE_DIR/lcars.base64"
fi

# look for minisign binary
MINISIGN=$(which minisign 2>&1)
if [[ "$MINISIGN" == "minisign not found" ]] || [[ "$MINISIGN" == "which: no minisign in"* ]] ; then
	notify "Error: minisign not found" "Please install minisign first"
	exit
fi

# touch JayBrown public key file
PUBKEY_NAME="jaybrown-github.pub"
PUBKEY_LOC="$SIGS_DIR/$PUBKEY_NAME"
if [[ ! -e "$PUBKEY_LOC" ]] ; then
	touch "$PUBKEY_LOC"
	echo -e "untrusted comment: minisign public key 37D030AC5E03C787\nRWSHxwNerDDQN8RlBeFUuLkB9bPqsR2T6es0jmzguvpvqWiXjxzTfaRY" > "$PUBKEY_LOC"
fi

# check for false input
SIGN_FILE="$1"
TARGET_NAME=$(/usr/bin/basename "$SIGN_FILE")
if [[ "$SIGN_FILE" == *".minisig" ]] || [[ "$SIGN_FILE" == *".pub" ]] || [[ "$SIGN_FILE" == *".key" ]]; then
	notify "Error: wrong file" "$TARGET_NAME"
	exit
fi

# settings
TARGET_DIR=$(/usr/bin/dirname "$SIGN_FILE")
MINISIG_NAME="$TARGET_NAME.minisig"
MINISIG_LOC="$TARGET_DIR/$MINISIG_NAME"

# initial method
MS_METHOD=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set theButton to button returned of (display dialog "Do you want to create a new key pair or sign the file with an existing key?" ¬
		buttons {"Cancel", "New", "Select Key File"} ¬
		default button 3 ¬
		with title "Sign " & "$TARGET_NAME" ¬
		with icon file theLogoPath ¬
		giving up after 180)
	if theButton = "New" then
		set theButton to "new"
	else if theButton = "Select Key File" then
		set theButton to "key"
	end if
end tell
theButton
EOT)
if [[ "$MS_METHOD" == "" ]] || [[ "$MS_METHOD" == "false" ]] ; then
	exit
fi

# generate new key pair
if [[ "$MS_METHOD" == "new" ]] ; then
	KEYPAIR_NAME=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set theReply to text returned of (display dialog "Enter the name of the new minisign key pair." ¬
		default answer "" ¬
		buttons {"Cancel", "Enter"} ¬
		default button 2 ¬
		with title "Enter Key Pair Name" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
theReply
EOT)
	if [[ "$KEYPAIR_NAME" == "" ]] || [[ "$KEYPAIR_NAME" == "false" ]] ; then
		exit
	fi
	KEYPAIR_PW=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set thePassword to text returned of (display dialog "Enter the password for the new secret key. It will be stored in your " & "$OSNAME" & " keychain." ¬
		default answer "" ¬
		with hidden answer ¬
		buttons {"Cancel", "Enter"} ¬
		default button 2 ¬
		with title "Enter Password" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
thePassword
EOT)
	if [[ "$KEYPAIR_PW" == "" ]] || [[ "$KEYPAIR_PW" == "false" ]] ; then
		exit
	fi
	/usr/bin/security add-generic-password -s "minisign-$KEYPAIR_NAME" -a "$ACCOUNT" -w "$KEYPAIR_PW"
	(echo "$KEYPAIR_PW";echo "$KEYPAIR_PW") | "$MINISIGN" -G -p "$SIGS_DIR/$KEYPAIR_NAME.pub" -s "$PRIVATE_DIR/$KEYPAIR_NAME.key"
	SIGNING_KEY="$PRIVATE_DIR/$KEYPAIR_NAME.key"
	PUBKEY_LOC="$SIGS_DIR/$KEYPAIR_NAME.pub"
fi

# select existing secret key
if [[ "$MS_METHOD" == "key" ]] ; then
	SIGNING_KEY=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theKeyDirectory to (((path to documents folder from user domain) as text) & "minisign:prvt") as alias
	set aKey to choose file with prompt "Select your minisign secret key (.key) file…" default location theKeyDirectory with invisibles
	set theKeyPath to (POSIX path of aKey)
end tell
theKeyPath
EOT)
	if [[ "$SIGNING_KEY" == "" ]] || [[ "$SIGNING_KEY" == "false" ]] ; then
		exit
	fi
	if [[ "$SIGNING_KEY" != *".key" ]] ; then
		notify "Error: not a .key file" "$SIGNING_KEY"
		exit
	fi
	SEC_KEY_NAME=$(/usr/bin/basename "$SIGNING_KEY")
	SEC_KEY_DIR=$(/usr/bin/dirname "$SIGNING_KEY")
	if [[ "$SEC_KEY_DIR" != "$PRIVATE_DIR" ]] ; then
		cp "$SIGNING_KEY" "$PRIVATE_DIR/$SEC_KEY_NAME"
		SIGNING_KEY="$PRIVATE_DIR/$SEC_KEY_NAME"
	fi
	KEYPAIR_NAME="${SEC_KEY_NAME%.*}"
	PUBKEY_NAME="$KEYPAIR_NAME.pub"
	PUBKEY_LOC="$SIGS_DIR/$PUBKEY_NAME"
	if [[ ! -e "$PUBKEY_LOC" ]] ; then
		if [[ -e "$SEC_KEY_DIR/$KEYPAIR_NAME.pub" ]] ; then
			cp "$SEC_KEY_DIR/$KEYPAIR_NAME.pub" "$PUBKEY_LOC"
		else
			LOCATE_PUBKEY=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theKeyDirectory to (((path to documents folder from user domain) as text) & "minisign") as alias
	set aKey to choose file with prompt "Locate the corresponding public key (.pub) file…" default location theKeyDirectory without invisibles
	set theKeyPath to (POSIX path of aKey)
end tell
theKeyPath
EOT)
			if [[ "$LOCATE_PUBKEY" == "" ]] || [[ "$LOCATE_PUBKEY" == "false" ]] ; then
				exit
			fi
			if [[ "$LOCATE_PUBKEY" == *".pub" ]] ; then
				cp "$LOCATE_PUBKEY" "$PUBKEY_LOC"
			else
				notify "Error: not a .pub file" "$LOCATE_PUBKEY"
				exit
			fi
		fi
	fi
	KEYPAIR_PW=$(/usr/bin/security 2>&1 >/dev/null find-generic-password -s "minisign-$KEYPAIR_NAME" -ga "$ACCOUNT" | /usr/bin/ruby -e 'print $1 if STDIN.gets =~ /^password: "(.*)"$/' | xargs)
	if [[ "$KEYPAIR_PW" == "" ]] ; then
		KEYPAIR_PW=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set thePassword to text returned of (display dialog "There is no password stored in your " & "$OSNAME" & " keychain for this secret key. Enter the password you chose when you created this key." ¬
		default answer "" ¬
		with hidden answer ¬
		buttons {"Cancel", "Enter"} ¬
		default button 2 ¬
		with title "Enter Password" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
thePassword
EOT)
		if [[ "$KEYPAIR_PW" == "" ]] || [[ "$KEYPAIR_PW" == "false" ]] ; then
			exit
		fi
		/usr/bin/security add-generic-password -s "minisign-$KEYPAIR_NAME" -a "$ACCOUNT" -w "$KEYPAIR_PW"
	fi
fi

# enter trusted comment
TRUSTED=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set theComment to text returned of (display dialog "Enter a one-line trusted comment for your signature file. Leave blank to skip." ¬
		default answer "" ¬
		buttons {"Cancel", "Enter"} ¬
		default button 2 ¬
		with title "Enter Trusted Comment" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
theComment
EOT)
if [[ "$TRUSTED" == "false" ]] ; then
	exit
fi

# enter untrusted comment
UNTRUSTED=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set theComment to text returned of (display dialog "Enter a one-line untrusted comment for your signature file. Leave blank to skip." ¬
		default answer "" ¬
		buttons {"Cancel", "Enter"} ¬
		default button 2 ¬
		with title "Enter Untrusted Comment" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
theComment
EOT)
if [[ "$UNTRUSTED" == "false" ]] ; then
	exit
fi

# read public key
PUBKEY=$(/usr/bin/sed -n '2p' "$PUBKEY_LOC" | xargs)

# target file size
BYTES=$(/usr/bin/stat -f%z "$SIGN_FILE")
MEGABYTES=$(/usr/bin/bc -l <<< "scale=6; $BYTES/1000000")
if [[ ($MEGABYTES<1) ]] ; then
	SIZE="0$MEGABYTES"
else
	SIZE="$MEGABYTES"
fi
LIMIT=$(echo $SIZE">"500 | /usr/bin/bc -l)
if [[ "$LIMIT" == "0" ]] ; then
	PREHASH="false"
elif [[ "$LIMIT" == "1" ]] ; then
	PREHASH="true"
fi

# sign target file
if [[ "$PREHASH" == "true" ]] ; then
	MS_OUT=$(echo "$KEYPAIR_PW" | "$MINISIGN" -S -H -x "$MINISIG_LOC" -s "$SIGNING_KEY" -c "$UNTRUSTED" -t "$TRUSTED" -m "$SIGN_FILE")
elif [[ "$PREHASH" == "false" ]] ; then
	MS_OUT=$(echo "$KEYPAIR_PW" | "$MINISIGN" -S -x "$MINISIG_LOC" -s "$SIGNING_KEY" -c "$UNTRUSTED" -t "$TRUSTED" -m "$SIGN_FILE")
fi
if [[ $(echo "$MS_OUT" | /usr/bin/grep "Wrong password for that key") != "" ]] ; then
	notify "Signing error" "Wrong password"
	exit
fi

# checksums
CHECKSUM21=$(/usr/bin/shasum -a 256 "$SIGN_FILE" | /usr/bin/awk '{print $1}')

# additional checksums (optional); uncomment if needed, then expand $INFO_TXT and $CLIPBOARD_TXT
# CHECKSUM5=$(/sbin/md5 -q "$SIGN_FILE")
# CHECKSUM1=$(/usr/bin/shasum -a 1 "$SIGN_FILE" | /usr/bin/awk '{print $1}')
# CHECKSUM22=$(/usr/bin/shasum -a 512 "$SIGN_FILE" | /usr/bin/awk '{print $1}')

# notify
notify "Signing successful" "$TARGET_NAME"

# set info text
if [[ "$PREHASH" == "false" ]] ; then
	PREHASH_INFO="compatible with OpenBSD signify"
elif [[ "$PREHASH" == "true" ]] ; then
	PREHASH_INFO="not compatible with OpenBSD signify"
fi
INFO_TXT="■︎■■ File ■■■
$TARGET_NAME

■■■ Size ■■■
$SIZE MB

■︎■■ Hash (SHA-2, 256 bit) ■■■
$CHECKSUM21

■︎■■ Minisign public key ■■■
$PUBKEY

■︎■■ Prehashing ■︎■■
$PREHASH
[$PREHASH_INFO]

This information has also been copied to your clipboard"

# send info to clipboard
CLIPBOARD_TXT="File: $TARGET_NAME
Size: $SIZE MB
Hash (SHA-2, 256 bit): $CHECKSUM21
Minisign public key: $PUBKEY
Prehashing: $PREHASH [$PREHASH_INFO]"
echo "$CLIPBOARD_TXT" | /usr/bin/pbcopy

# info window
INFO=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.minisign:lcars.png"
	set userChoice to button returned of (display dialog "$INFO_TXT" ¬
		buttons {"OK"} ¬
		default button 1 ¬
		with title "Results" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
EOT)

# bye
exit
