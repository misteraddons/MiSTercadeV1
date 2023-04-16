#!/usr/bin/env python

# This script finds missing mappings for all .mra files for a given vid_pid
# It is a python script that masquerades as a bash script so it can be run on MiSTer


import os
import shutil
import xml.etree.ElementTree as ET

# Set the directory to search for files
inputMaps = "/media/fat/config/inputs"

# specify the source and destination directories
src_dir = "/media/fat/_Arcade"
dst_dir = "/media/fat/_Arcade/__MissingMap"
big_dir = "/media/fat/_Arcade/__BIGMRA"
vid_pid = '16d0_10be' # MiSTercade USB Vendor ID Product ID

# create the destination directory if it doesn't exist
if os.path.exists(dst_dir):
    shutil.rmtree(dst_dir)
if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

# create the destination directory if it doesn't exist
if not os.path.exists(big_dir):
    os.makedirs(big_dir)

# Create an empty list to store the truncated file names
truncated_file_names = []

# Iterate through all the files in the directory
for file_name in os.listdir(inputMaps):
    # Check if the file name contains "16d0_10be" or "16DO_10BE"
    if vid_pid in file_name.lower():
        # Get the truncated file name
        truncated_file_name = file_name.split("_")[0]
        # Append the truncated file name to the list
        truncated_file_names.append(truncated_file_name)

# iterate through the files in the source directory
for filename in os.listdir(src_dir):
    if filename.endswith(".mra"):
        
        if "[" in filename or "]" in filename:
            #print("Brackets found")
            escaped_filename = filename
            #escaped_filename = filename.replace("[", r"\[").replace("]", r"\]")
        else:
            escaped_filename = filename

        #full_file_path = os.path.join(src_dir, escaped_filename)
        full_file_path = os.path.join(src_dir, escaped_filename)
        #print(full_file_path)

        # copy mra files larger than 100kB (with embedded rom data) to the big_dir path
        if os.path.getsize(full_file_path) > 875000:
            print("TOO BIG: {}".format(full_file_path))
            dst_path = os.path.join(big_dir, escaped_filename)
            #shutil.copyfile(full_file_path, dst_path)
            continue  # move on to the next file

        # create an ElementTree object
        else:
            tree = ET.parse(full_file_path)

            # get the root element of the xml file
            root = tree.getroot()

            # find the setname element
            setname_element = root.find(".//setname")

            # extract the text of the setname element
            setname = setname_element.text
            #print(setname)

            if setname is None or setname.strip() == "":
                print("MISSING SETNAME: {}".format(full_file_path))
                continue

            # check if the setname is in the truncated filenames
            if setname not in truncated_file_names:
                # if it's not, copy the file to the destination directory
                print("MISSING MAPPING: {}".format(full_file_path))
                src_path = os.path.join(src_dir, escaped_filename)
                dst_path = os.path.join(dst_dir, escaped_filename)
                shutil.copyfile(src_path, dst_path)
                continue

            #else:
            #    print("FOUND MAPPING!")
            #    continue
                