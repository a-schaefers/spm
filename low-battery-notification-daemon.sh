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

# TODO add optional customization section to run advanced actions per threshhold

# low battery notifier
while true; do
    # battery percentages that send notifications
    THRESHHOLDS="20 10 5 4 3 2 1"
    # battery polling frequency
    sleep 20
    [ -n "$(command -v acpi)" ] || break
    [ ! -d /tmp/battmon ] && mkdir /tmp/battmon
    batt="$(acpi | awk '{ print $4 }')"
    batt="${batt%\%*}"
    intcheck () {
        case ${1#[-+]} in
            *[!0-9]* | '') return 1 ;;
            * ) return 0 ;;
        esac
    }
    intcheck "$batt"
    [ $? -eq 1 ] && break
    echo "$THRESHHOLDS" | tr ' ' '\n' | while read -r thresh; do
        if [ "$batt" -eq "$thresh" ]; then
            if [ ! -f "/tmp/battmon/$thresh" ]; then
                touch "/tmp/battmon/$thresh"
                notify-send "Battery: ${batt}%"
            fi
        fi
    done
    for file in /tmp/battmon/*; do
        [ -f "$file" ] || break
        intcheck "${file##*/}"
        [ $? -eq 1 ] && break
        if [ "$batt" -gt "${file##*/}" ]; then rm "$file"; fi
    done
done &
