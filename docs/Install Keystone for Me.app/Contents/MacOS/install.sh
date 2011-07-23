#!/bin/sh

SIMBL_URL='http://www.culater.net/software/SIMBL/SIMBL.php'

containing_folder=$(dirname "$(dirname "$(dirname "$(dirname "$0")")")")
SIMBL_folder=$HOME/'Library/Application Support/SIMBL/Plugins'

if mkdir -p "$SIMBL_folder"; then
	if [[ -e "$SIMBL_folder/Keystone.bundle" ]]; then
		rm -rf "$SIMBL_folder/Keystone.bundle"
	fi

	if cp -RPf "$containing_folder/Keystone.bundle" "$SIMBL_folder"; then
		should_get_SIMBL=$(osascript <<SCRIPT
			tell app "Finder"
				activate
				set userChoice to display alert "Keystone has been installed." message "If Keystone is not loaded when you next start Safari, you may need to install a recent version of SIMBL." buttons {"Get SIMBL", "OK"}
				if button returned of userChoice is "Get SIMBL"
					true
				end
			end
SCRIPT
		)

		if [[ ! -z "$should_get_SIMBL" ]]; then
			open "$SIMBL_URL"
		fi

		exit 0
	fi
fi

osascript <<SCRIPT
	tell app "Finder"
		activate
		display alert "There was a problem installing Keystone." message "You can install it manually by copying Keystone.bundle to ~/Library/Application Support/SIMBL/Plugins, creating that folder if necessary."
	end
SCRIPT