#!/bin/bash

set -e
set -o pipefail

# Assert existence of xdotool to begin with
if ! xdotool --help &>/dev/null; then
    printf "ERROR: 'xdotool' is not present (or not in the PATH). Please visit http://www.semicomplete.com/projects/xdotool/ to download it for your platform.\n" >&2
    exit 1
fi

load_wait_time=4
save_wait_time=8
scriptname="$(basename "$0")"
destination=""
browser="google-chrome"
url=""

function print_usage() {
    printf "\n%s: Open the given url in a browser tab/window, perform 'Save As' operation and close the tab/window.\n\n" "${scriptname}" >&2
    printf "USAGE:\n   %s URL [OPTIONS]\n\n" "${scriptname}" >&2
    printf "URL                             The url of the web page to be saved.\n\n" >&2
    printf "options:\n" >&2
    printf "  -d, --destination             Destination path. If a directory, then file is saved with default name inside the directory, else assumed to be full path of target file.\n" >&2
    printf "  -b, --browser                 Browser executable to be used (must be one of 'google-chrome' or 'firefox'). Default = '%s'.\n" "${browser}" >&2
    printf "  -l, --load-wait-time          Number of seconds to wait for the page to be loaded (i.e., seconds to sleep before Ctrl+S is 'pressed'). Default = %s\n" "${load_wait_time}" >&2
    printf "  -s, --save-wait-time          Number of seconds to wait for the page to be saved (i.e., seconds to sleep before Ctrl+F4 is 'pressed'). Default = %s\n" "${save_wait_time}" >&2
    printf "  -h, --help                    Display this help message and exit.\n" >&2
}

while [ "$#" -gt 0 ]
do
    case "$1" in
        -d | --destination)
            shift;
            destination="$1"
            shift
            ;;
        -b | --browser)
            shift;
            browser="$1"
            shift
            ;;
       
        -l | --load-wait-time)
            shift;
            load_wait_time="$1"
            shift
            ;;
        -s | --save-wait-time)
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

function validate_input() {
    if [[ -z "${url}" ]]; then
        printf "ERROR: URL must be specified." >&2
        print_usage
        exit 1
    fi

    if [[ -d "${destination}" ]]; then
        printf "INFO: '%s' is a directory, will save file inside it with the default name.\n" "${destination}">&2
    else
        local basedir="$(dirname "${destination}")"
        if [[ ! -d "${basedir}" ]]; then
            printf "ERROR: Directory '%s' does not exist - Will NOT continue.\n" "${basedir}" >&2
            exit 1
        fi
    fi
    
    if [[ "${browser}" != "google-chrome" && "${browser}" != "firefox" ]]; then
        printf "ERROR: Browser (${browser}) is not supported, must be one of 'google-chrome' or 'firefox'.\n" >&2
        exit 1
    fi

    local num_regexp='^.[0-9]+$|^[0-9]+$|^[0-9]+.[0-9]+$'  # Matches a valid number (in decimal notation)
    if [[ ! "${load_wait_time}" =~ $num_regexp || ! "${save_wait_time}" =~ $num_regexp ]]; then
        printf "ERROR: --load-wait-time (='%s'), and --save_wait_time(='%s') must be valid numbers.\n" "${load_wait_time}" "${load_wait_time}" >&2
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

# Activate the 'Save File' dialog and type in the appropriate filename (depending on ${destination} value: 1) directory, 2) full path, 3) empty)
if [[ ! -z "${destination}" ]]; then 
    if [[ -d "${destination}" ]]; then
        # Case 1: --destination was a directory.
        xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers Left
        xdotool type --delay 10 --clearmodifiers "${destination}/"
    else
        # Case 2: --destination was full path.
        xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers "ctrl+a" "BackSpace"
        xdotool type --delay 10 --clearmodifiers "${destination}"
    fi
fi
xdotool windowactivate "${savefile_wid}" key --delay 20 --clearmodifiers Return

printf "\nINFO: Saving web page ...\n" >&2

# Wait for the file to be completely saved
sleep ${save_wait_time}

# Close the browser tab/window (Ctrl+F4)
xdotool windowactivate "${browser_wid}" key --clearmodifiers "ctrl+F4"

printf "Done!\n"
