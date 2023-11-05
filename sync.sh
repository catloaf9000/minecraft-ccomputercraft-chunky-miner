#!/bin/bash

# Copies your code to your minecraft world, useful when codding 
# WARNING: will replace disk content!

WORLD_PATH="/mnt/c/Users/dedly/curseforge/minecraft/Instances/Create Above and Beyond/saves/cc-test"

# How to get disk ID
#  1. Place a floppy disk inside disk drive next to computer
#  2. Open computer and write ls - disk will generate an ID
#  3. Hover the mouse on a disk to see its id (press F3 + H for advanced tooltips if you don't see it)
DISK_ID=1

rm -r "${WORLD_PATH}/computercraft/disk/${DISK_ID}" > /dev/null 2>&1
cp -r "disk/0" "${WORLD_PATH}/computercraft/disk/${DISK_ID}"
