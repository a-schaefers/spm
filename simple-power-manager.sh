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
# The user_custom functions are configured for xbacklight/acpilight already-- users of lux, light or whatever will need to customize

while true; do
    ############################################################################
    # battery polling frequency
    sleep 5

    # if trigger has not already been fired, and if battery % is less than or equal
    # to a threshhold and if battery state is Discharging, then run user_custom_low_battery_hook
    user_custom_low_battery_hook() {
        if [ "$batt" -lt 100 ] && [ "$batt" -gt 80 ]; then
            # 80-99% battery
            echo # do nothing

        elif [ "$batt" -lt 81 ] && [ "$batt" -gt 40 ]; then
            # 40-80% battery
            echo # do nothing

        elif [ "$batt" -lt 41 ] && [ "$batt" -gt 20 ]; then
            # 20-40% battery
            echo # do nothing

        elif [ "$batt" -lt 21 ] && [ "$batt" -gt 10 ]; then
            # 10-20% battery
            notify-send "Battery: ${batt}%"
            xbacklight -set 20

        elif [ "$batt" -lt 11 ] && [ "$batt" -gt 5 ]; then
            # 5-10% battery
            notify-send "Battery: ${batt}%"
            xbacklight -set 10

        elif [ "$batt" -lt 6 ]; then
            # 5% battery or less
            notify-send "Battery: ${batt}%"
            xbacklight -set 5
        fi
    }

    # if trigger has not already been fired, and if battery state is Charging or
    # Full, then run user_custom_battery_normal_hook
    user_custom_battery_normal_hook() {
        # battery Charging / Full
        notify-send "Battery: $acpi_status ${batt}%"
        xbacklight -set 80
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
        batt_threshholds="99 80 40 20 10 5"
        echo "$batt_threshholds" | tr ' ' '\n' | while read -r thresh; do
            if [ "$batt" -eq "$thresh" ] || [ "$batt" -lt "$thresh" ]; then
                if [ ! -f "/tmp/battmon/$thresh" ]; then
                    if [ -f "/tmp/battmon/100" ]; then rm /tmp/battmon/100; fi
                    touch "/tmp/battmon/$thresh"
                    user_custom_low_battery_hook
                fi
            fi
        done
    fi
    if [ "$acpi_status" = "Charging" ] || [ "$acpi_status" = "Full" ]
    then
        if [ ! -f "/tmp/battmon/100" ];then
            rm /tmp/battmon/*
            user_custom_battery_normal_hook
            touch /tmp/battmon/100
        fi
    fi
done &
