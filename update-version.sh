#!/bin/bash
# A command-line script for incrementing build numbers for all known targets in an Xcode project.
#
# This script has two main goals: firstly, to ensure that all the targets in a project have the
# same CFBundleVersion and CFBundleShortVersionString values. This is because mismatched values
# can cause a warning when submitting to the App Store. Secondly, to ensure that the build number
# is incremented appropriately .
#
# If not using git, you are a braver soul than I.

##
# The xcodeproj. This is usually found by the script, but you may need to specify its location
# if it's not in the same folder as the script is called from (the project root if called as a
# build phase run script).
#
# This value can also be provided (or overridden) using "--xcodeproj=<path>"
#
#xcodeproj="Project.xcodeproj"

##
# We have to define an Info.plist as the source of truth. This is typically the one for the main
# target. If not set, the script will try to guess the correct file from the list it gathers from
# the xcodeproj file, but this can be overriden by setting the path here.
#
# This value can also be provided (or overridden) using "--plist=<path>"
#
#plist="Project/Info.plist"

##
# By default, the script ensures that the build number is incremented when changes are declared
# based on git's records. Alternatively the number of commits on the current branch can be used
# by toggling the "reflect_commits" variable to true. If not on "master", the current branch name
# will be used to ensure no version collisions across branches, i.e. "497-develop".
#
# This setting can also be enabled using "--reflect-commits"
#
#reflect_commits=true

##
# If you would like to iterate the build number only when a specific branch is checked out
# (i.e. "master"), you can specify the branch name. The current version will still be replicated
# across all Info.plist files (to ensure consistency) if they don't match the source of truth.
#
# This setting can be enabled for multiple branches can be enabled by using comma separated names
# (i.e. "master,develop"). No spacing is permitted.
#
# This setting can also be enabled using "--branch"
#
#enable_for_branch="master"

# We use PlistBuddy to handle the Info.plist values. Here we define where it lives.
plistBuddy="/usr/libexec/PlistBuddy"

# Parse input variables and update settings.
for i in "$@"; do
case $i in
	-h|--help)
	echo "usage: sh version-update.sh [options...]\n"
	echo "Options: (when provided via the CLI, these will override options set within the script itself)"
	echo "    --reflect-commits         Reflect the number of commits in the current branch when preparing build numbers."
	echo "-b, --branch=<name[,name...]> Only allow the script to run on the branch with the given name(s)."
	echo "-p, --plist=<path>            Use the specified plist file as the source of truth for version details."
	echo "-x, --xcodeproj=<path>        Use the specified Xcode project file to gather plist names."
	echo "\nFor more detailed information on the use of these variables, see the script source."
	exit 1 
	;;
	--reflect-commits)
	reflect_commits=true
	shift
	;;
	-x=*|--xcodeproj=*)
	xcodeproj="${i#*=}"
	shift
	;;
	-p=*|--plist=*)
	plist="${i#*=}"
	shift
	;;
	-b=*|--branch=*)
	enable_for_branch="${i#*=}"
	shift
	;;
	*)
	;;
esac
done

# Locate the xcodeproj.
# If we've specified a xcodeproj above, we'll simply use that instead.
if [[ -z ${xcodeproj} ]]; then
	xcodeproj=$(find . -depth 1 -name "*.xcodeproj" | sed -e 's/^\.\///g')
fi

# Check that the xcodeproj file we've located is valid, and warn if it isn't.
# This could also indicate an issue with the code used to automatically locate the xcodeproj file.
# If you're encountering this and the file exists, ensure that ${xcodeproj} contains the correct
# path, or use the "--xcodeproj" variable to provide an accurate location.
if [[ ! -f "${xcodeproj}/project.pbxproj" ]]; then
	echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the xcodeproj file \"${xcodeproj}\"."
	exit 1
else 
	echo "Xcode Project: \"${xcodeproj}\""
fi

# Find unique references to Info.plist files in the project
projectFile="${xcodeproj}/project.pbxproj"
plists=$(grep "^\s*INFOPLIST_FILE.*$" "${projectFile}" | sed -Ee 's/^[[:space:]]+INFOPLIST_FILE[[:space:]*=[[:space:]]*["]?([^"]+)["]?;$/\1/g' | sort | uniq)

# Attempt to guess the plist based on the list we have.
# If we've specified a plist above, we'll simply use that instead.
if [[ -z ${plist} ]]; then
	read -r plist <<< "${plists}"
fi

# Check that the plist file we've located is valid, and warn if it isn't.
# This could also indicate an issue with the code used to match plist files in the xcodeproj file.
# If you're encountering this and the file exists, ensure that ${plists} contains _ONLY_ filenames.
if [[ ! -f ${plist} ]]; then
	echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the plist file \"${plist}\"."
	exit 1		
else
	echo "Source Info.plist: \"${plist}\""
fi

# Find the current build number in the main Info.plist
mainBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${plist}")
mainBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${plist}")
echo "Current project version is ${mainBundleShortVersionString} (${mainBundleVersion})."

# Increment the build number if git says things have changed. Note that we also check the main
# Info.plist file, and if it has already been modified, we don't increment the build number.
# Alternatively, if the script has been called using "--reflect-commits", we just update to the
# current number of commits
git=$(sh /etc/profile; which git)
branchName=$("${git}" rev-parse --abbrev-ref HEAD)
if [[ -z ${enable_for_branch} ]] || [[ ",${enable_for_branch}," == *",${branchName},"* ]]; then
	if [[ -z ${reflect_commits} ]] && [[ ${reflect_commits} ]]; then
		currentBundleVersion=${mainBundleVersion}
		mainBundleVersion=$("${git}" rev-list --count HEAD)
		if [[ ${branchName} != "master" ]]; then
			mainBundleVersion="${mainBundleVersion}-${branchName}"
		fi
		if [[ ${currentBundleVersion} != ${mainBundleVersion} ]]; then
			echo "Branch \"${branchName}\" has ${mainBundleVersion} commit(s). Updating build number..."
		fi
	else
		status=$("${git}" status --porcelain)
		if [[ ${#status} != 0 ]] && [[ ${status} != *"M ${plist}"* ]] && [[ ${status} != *"M \"${plist}\""* ]]; then
			echo "Repository is dirty. Iterating build number..."
			mainBundleVersion=$((${mainBundleVersion} + 1))
		fi
	fi
else
	echo "${BASH_SOURCE}:${LINENO}: warning: Version number updates are disabled for the current git branch (${branchName})."
fi

# Update all of the Info.plist files we discovered
while read -r thisPlist; do
	# Find out the current version
	thisBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${thisPlist}")
	thisBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${thisPlist}")
	# Update the CFBundleVersion if needed
	if [[ ${thisBundleVersion} != ${mainBundleVersion} ]]; then
		echo "Updating \"${thisPlist}\" with build ${mainBundleVersion}..."
		"${plistBuddy}" -c "Set :CFBundleVersion ${mainBundleVersion}" "${thisPlist}"
	fi
	# Update the CFBundleShortVersionString if needed
	if [[ ${thisBundleShortVersionString} != ${mainBundleShortVersionString} ]]; then
		echo "Updating \"${thisPlist}\" with marketing version ${mainBundleShortVersionString}..."
		"${plistBuddy}" -c "Set :CFBundleShortVersionString ${mainBundleShortVersionString}" "${thisPlist}"
	fi
done <<< "${plists}"