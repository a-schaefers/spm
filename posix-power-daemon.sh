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
# The user_custom_batt_low() is configured for xbacklight/acpilight already-- users of lux, light or whatever will need to customize it.

while true; do
    ############################################################################
    # battery polling frequency
    sleep 15
    # battery % threshholds that trigger events
    LOW_BATT_THRESHHOLDS="20 10 5"
    # arbitrary code block that runs when a battery warning threshhold is hit
    user_custom_batt_low() {
        if [ "$batt" -lt 21 ] && [ "$batt" -gt 10 ]; then
            # 10-20% percent battery
            notify-send "Battery: ${batt}%"
            xbacklight -set 20
        elif [ "$batt" -lt 11 ] && [ "$batt" -gt 5 ]; then
            # 5-10% percent battery
            notify-send "Battery: ${batt}%"
            xbacklight -set 10
        elif [ "$batt" -lt 6 ]; then
            # If 5% battery or less - NOTE: consider running a suspend command
            notify-send "Battery: ${batt}%"
            xbacklight -set 5
        fi
    }
    # arbitrary code block that runs when the battery state changes to Charging or Full
    user_custom_batt_normal() {
        notify-send "Battery: $acpi_status ${batt}%"
        xbacklight -set 100
    }
    ############################################################################
    bail() {
        [ $# -gt 0 ] && printf -- "%s\n" "$*"
        break
    }
    command -v acpi > /dev/null || bail "acpi not found"
    if [ ! -d /tmp/battmon ];then mkdir /tmp/battmon || bail "/tmp is not writeable" ; fi
    acpi="$(acpi)"
    batt="$(echo "$acpi" | awk '{ print $4 }')"
    batt="${batt%\%*}"
    acpi_status="$(echo "$acpi" | awk '{ print $3 }')"
    acpi_status="${acpi_status%,}"
    intcheck () {
        case ${1#[-+]} in
            *[!0-9]* | '') return 1 ;;
            * ) return 0 ;;
        esac
    }
    intcheck "$batt" || bail "$batt is not an integer"
    if [ "$acpi_status" = "Discharging" ];then
        echo "$LOW_BATT_THRESHHOLDS" | tr ' ' '\n' | while read -r thresh; do
            if [ "$batt" -eq "$thresh" ] || [ "$batt" -lt "$thresh" ]; then
                if [ ! -f "/tmp/battmon/$thresh" ]; then
                    if [ -f "/tmp/battmon/100" ]; then rm /tmp/battmon/100; fi
                    touch "/tmp/battmon/$thresh"
                    user_custom_batt_low
                fi
            fi
        done
    fi
    if [ "$acpi_status" = "Charging" ] || [ "$acpi_status" = "Full" ]
    then
        if [ ! -f "/tmp/battmon/100" ];then
            rm /tmp/battmon/*
            user_custom_batt_normal
            touch /tmp/battmon/100
        fi
    fi
done &
