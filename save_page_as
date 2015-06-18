#!/bin/bash

set -e
set -u
set -o pipefail

# Assert existence of xdotool to begin with
if ! xdotool --help &>/dev/null; then
    printf "ERROR: 'xdotool' is not present (or not in the PATH). Please visit http://www.semicomplete.com/projects/xdotool/ to download it for your platform.\n" >&2
    exit 1
fi

load_wait_time=4
save_wait_time=8
scriptname="$(basename "$0")"
destination="."
browser="google-chrome"
suffix=""
url=""

function print_usage() {
    printf "\n%s: Open the given url in a browser tab/window, perform 'Save As' operation and close the tab/window.\n\n" "${scriptname}" >&2
    printf "USAGE:\n   %s URL [OPTIONS]\n\n" "${scriptname}" >&2
    printf "URL                      The url of the web page to be saved.\n\n" >&2
    printf "options:\n" >&2
    printf "  -d, --destination      Destination path. If a directory, then file is saved with default name inside the directory, else assumed to be full path of target file. Default = '%s'\n" "${destination}" >&2
    printf "  -s, --suffix           An optional suffix string for the target file name (ignored if --destination arg is a full path)\n" >&2
    printf "  -b, --browser          Browser executable to be used (must be one of 'google-chrome', 'chromium-browser' or 'firefox'). Default = '%s'.\n" "${browser}" >&2
    printf "  --load-wait-time       Number of seconds to wait for the page to be loaded (i.e., seconds to sleep before Ctrl+S is 'pressed'). Default = %s\n" "${load_wait_time}" >&2
    printf "  --save-wait-time       Number of seconds to wait for the page to be saved (i.e., seconds to sleep before Ctrl+F4 is 'pressed'). Default = %s\n" "${save_wait_time}" >&2
    printf "  -h, --help             Display this help message and exit.\n" >&2
}

while [ "$#" -gt 0 ]
do
    case "$1" in
        -d | --destination)
            shift;
            destination="$1"
            shift
            ;;
        -s | --suffix)
            shift;
            suffix="$1"
            shift;
            ;;
        -b | --browser)
            shift;
            browser="$1"
            shift
            ;;

        --load-wait-time)
            shift;
            load_wait_time="$1"
            shift
            ;;
        --save-wait-time)
            shift;
            save_wait_time="$1"
            shift
            ;;
        -h | --help)
            print_usage
            exit 0
            ;;
        -*)
            printf "ERROR: Unknown option: %s\n" "${1}">&2
            print_usage
            exit 1
            ;;
        *)  if [ ! -z "$url" ]; then
                printf "ERROR: Expected exactly one positional argument (URL) to be present, but encountered a second one ('%s').\n\n" "${1}" >&2
                print_usage
                exit 1
            fi
            url="$1"
            shift;
            ;;
    esac
done

# Returns 1 if input param contains any non-printable or non-ascii character, else returns 0
# (Inspiration: http://stackoverflow.com/a/13596664/1857518)
function has_non_printable_or_non_ascii() {
    LANG=C
    if printf "%s" "${1}" | grep '[^ -~]\+' &>/dev/null; then
        printf 1
    else
        printf 0
    fi
}

function validate_input() {
    if [[ -z "${url}" ]]; then
        printf "ERROR: URL must be specified." >&2
        print_usage
        exit 1
    fi

    if [[ -d "${destination}" ]]; then
        printf "INFO: The specified destination ('%s') is a directory path, will save file inside it with the default name.\n" "${destination}">&2
    else
        local basedir="$(dirname "${destination}")"
        if [[ ! -d "${basedir}" ]]; then
            printf "ERROR: Directory '%s' does not exist - Will NOT continue.\n" "${basedir}" >&2
            exit 1
        fi
    fi
    destination="$(readlink -f "$destination")"  # Ensure absolute path

    if [[ "${browser}" != "google-chrome" && "${browser}" != "chromium-browser" && "${browser}" != "firefox" ]]; then
        printf "ERROR: Browser (%s) is not supported, must be one of 'google-chrome', 'chromium-browser' or 'firefox'.\n" "${browser}" >&2
        exit 1
    fi

    if ! command -v "${browser}" &>/dev/null; then
        printf "ERROR: Command '${browser}' not found. Make sure it is installed, and in path.\n" >&2
        exit 1
    fi

    local num_regexp='^.[0-9]+$|^[0-9]+$|^[0-9]+.[0-9]+$'  # Matches a valid number (in decimal notation)
    if [[ ! "${load_wait_time}" =~ $num_regexp || ! "${save_wait_time}" =~ $num_regexp ]]; then
        printf "ERROR: --load-wait-time (='%s'), and --save_wait_time(='%s') must be valid numbers.\n" "${load_wait_time}" "${load_wait_time}" >&2
        exit 1
    fi

    if [[ $(has_non_printable_or_non_ascii "${destination}") -eq 1 || $(has_non_printable_or_non_ascii "${suffix}") -eq 1 ]]; then
        printf "ERROR: Either --destination ('%s') or --suffix ('%s') contains a non ascii or non-printable ascii character(s). " "${destination}" "${suffix}" >&2
        printf "'xdotool' does not mingle well with non-ascii characters (https://code.google.com/p/semicomplete/issues/detail?id=14).\n\n" >&2
        printf '!!!! Will NOT proceed !!!!\n' >&2
        exit 1
    fi
}
validate_input
##############

# Launch ${browser}, and wait for the page to load
"${browser}" "${url}" &>/dev/null &
sleep ${load_wait_time}

# Find the id for the ${browser} window
browser_wid="$(xdotool search --sync --onlyvisible --class "${browser}" | head -n 1)"
wid_re='^[0-9]+$'  # window-id must be a valid integer
if [[ ! "${browser_wid}" =~ ${wid_re} ]]; then
    printf "ERROR: Unable to find X-server window id for browser.\n" >&2
    exit 1
fi

# Activate the ${browser} window, and "press" ctrl+s
xdotool windowactivate "${browser_wid}" key --clearmodifiers "ctrl+s"

sleep 1 # Give 'Save as' dialog box time to show up

# Resolve the expected title name for save file dialog box (chrome & firefox differ in this regard)
if [[ "${browser}" == "firefox" ]]; then
    savefile_dialog_title="Save as"
else
    savefile_dialog_title="Save file"
fi
# Find window id for the "Save file" dialog box
savefile_wid="$(xdotool search --name "$savefile_dialog_title" | head -n 1)"
if [[ ! "${savefile_wid}" =~ ${wid_re}  ]]; then
    printf "ERROR: Unable to find window id for 'Save File' Dialog.\n" >&2
    exit 1
fi

# Fix for Issue #1: Explicitly focus on the "name" field (works on both: gnome, and kde)
xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifier "Alt+n"

# Check if we are using kde
is_kde=0
# Don't feel bad if DESKTOP_SESSION env variable is not present
set +u
if [[ "${DESKTOP_SESSION}" =~ ^kde-? ]]; then
    is_kde=1
fi
set -u

if [[ ! -z "${suffix}" ]]; then
    ###########################
    # Make sure that we are at correct position before typing the "suffix"
    #
    # If the user is using 'kde-plasma', then the full name of the file including the extension is highlighted
    # in the name field, so simply pressing a Right key and adding suffix leads to incorrect result.
    # Hence as a special case for 'kde-*' we move back 5 characters Left from the end before adding the suffix.
    # Now this strategy is certainly not full proof and assumes that file extension is always 4 characters long ('html'),
    # but this is the only fix I can think for this special case right now. Of course it's easy to tweak the number of
    # Left key moves you need if you know your file types in advance.
    if [[ "${is_kde}" -eq 1 ]]; then
        printf "INFO: Desktop session is found to be '${DESKTOP_SESSION}', hence the full file name will be highlighted. " >&2
        printf "Assuming extension .html to move back 5 character left before adding suffix (change accordingly if you need to).\n" >&2
        xdotool windowactivate "${savefile_wid}" key --delay 40 --clearmodifier End Left Left Left Left Left
    else
        xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers Right
    fi
    set -u
    ###########################

    extraarg=""
    if [[ "${suffix::1}}" == "-" ]]; then
        extraarg="-"
    fi
    xdotool type --delay 10 --clearmodifiers "${extraarg}" "${suffix}"
fi

# Activate the 'Save File' dialog and type in the appropriate filename (depending on ${destination} value: 1) directory, 2) full path, 3) empty)
if [[ ! -z "${destination}" ]]; then
    if [[ -d "${destination}" ]]; then
        # Case 1: --destination was a directory.
        xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers Home
        xdotool type --delay 10 --clearmodifiers "${destination}/"
    else
        # Case 2: --destination was full path.
        xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers "ctrl+a" "BackSpace"
        xdotool type --delay 10 --clearmodifiers "${destination}"
    fi
fi
xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers Return

printf "INFO: Saving web page ...\n" >&2

# Wait for the file to be completely saved
sleep ${save_wait_time}

# Close the browser tab/window (Ctrl+w for KDE, Ctrl+F4 otherwise)
if [[ "${is_kde}" -eq 1 ]]; then
    xdotool windowactivate "${browser_wid}" key --clearmodifiers "ctrl+w"
else
    xdotool windowactivate "${browser_wid}" key --clearmodifiers "ctrl+F4"
fi
printf "INFO: Done!\n">&2
