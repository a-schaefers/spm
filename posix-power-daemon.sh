#!/bin/sh

# MIT License

# Copyright (c) 2018 Adam Schaefers sch@efers.org

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
#    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#    copies of the Software, and to permit persons to whom the Software is
#    furnished to do so, subject to the following conditions:

#    The above copyright notice and this permission notice shall be included in all
#    copies or substantial portions of the Software.

#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#    SOFTWARE.

# Dependencies:
# The "acpi" command is used to determine the current battery level
# The "notify-send" command (libnotify) is used to send desktop notifications

while true; do
    ############################################################################
    # battery polling frequency
    sleep 20

    # battery percentages that send notifications
    THRESHHOLDS="20 10 5"

    # arbitrary code block  that runs when battery warning threshhold is hit
    user_custom_batt_low() {
        if [ "$batt" -eq 20 ]; then echo "20 backlight set"; xbacklight -set 20; fi
        if [ "$batt" -eq 10 ]; then echo "10 backlight set"; xbacklight -set 10; fi
        if [ "$batt" -eq 5 ]; then echo "5 backlight set"; xbacklight -set 5; fi
    }

    # an arbitrary code block that runs once when out of the warning threshholds
    user_custom_batt_normal() {
        xbacklight -set 100 && echo "backlight set to 100"
    }
    ############################################################################
    bail() {
        [ $# -gt 0 ] && printf -- "%s\n" "$*"
        break
    }
    command -v acpi > /dev/null || bail "acpi not found"
    if [ ! -d /tmp/battmon ];then mkdir /tmp/battmon || bail "/tmp is not writeable" ; fi
    batt="$(acpi | awk '{ print $4 }')"
    batt="${batt%\%*}"

    intcheck () {
        case ${1#[-+]} in
            *[!0-9]* | '') return 1 ;;
            * ) return 0 ;;
        esac
    }
    intcheck "$batt" || bail "$batt is not an integer"
    echo "$THRESHHOLDS" | tr ' ' '\n' | while read -r thresh; do
        if [ "$batt" -eq "$thresh" ]; then
            if [ ! -f "/tmp/battmon/$thresh" ]; then
                if [ -f "/tmp/battmon/100" ]; then rm /tmp/battmon/100; fi
                touch "/tmp/battmon/$thresh"
                notify-send "Battery: ${batt}%"
                user_custom_batt_low
            fi
        fi
    done
    for file in /tmp/battmon/*; do
        if [ ! -f "$file" ]; then
            if [ ! -f "/tmp/battmon/100" ];then
                user_custom_batt_normal
                touch /tmp/battmon/100
            fi
            break
        fi
        if [ "$batt" -gt "${file##*/}" ]; then rm "$file"; fi
    done
done &
