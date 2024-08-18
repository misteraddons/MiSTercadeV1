#!/usr/bin/env python

# This script finds missing mappings for all .mra files for a given vid_pid
# It is a python script that masquerades as a bash script so it can be run on MiSTer


import os
import shutil
import xml.etree.ElementTree as ET

# import xml.etree.ElementTree as ET
# parser = ET.XMLParser(encoding="utf-8")
# tree = ET.fromstring(xmlstring, parser=parser)

#from bs4 import BeautifulSoup

# Set file paths
inputMaps =     "/media/fat/config/inputs"
mra_dir =       "/media/fat/_Arcade"
missing_dir =   "/media/fat/_Arcade/__MissingMapV1"
big_dir =       "/media/fat/_Arcade/__BIGMRA"
vid_pid = '16d0_10be' # MiSTercade USB Vendor ID Product ID

excluded_dirs = set(['__MissingMap', '__BigMRA'])

copy_big_mra = "true"

# remove missing and big directories if they exist
if os.path.exists(missing_dir):
    shutil.rmtree(missing_dir)

if os.path.exists(big_dir):
    shutil.rmtree(big_dir)

# Create an empty list to store the truncated file names
truncated_map_names = []

large_mras = [
                "Asteroids Deluxe.mra",
                "Zaxxon.mra",
                "Wizard of Wor (Speech).mra",
                "Zaxxon (Set 1, Rev D).mra",
                "Sea Wolf II.mra",
                "Space Invaders (Samples).mra",
                "Space Panic.mra",
                "Street Fighter 2 Mix (Ver 1.0 210623) [hbmame].mra",
                "Street Fighter II' Champion Edition (Golden Edition 180924) [hbmame].mra",
                "Street Fighter II' Champion Edition (Golden Edition Deluxe 190331) [hbmame].mra",
                "Street Fighter II' Champion Edition (Koryu V2 181101) [hbmame].mra",
                "Street Fighter II' Champion Edition (Omega Edition 181112) [hbmame].mra",
                "Street Fighter Zero 3 Mix (Brazil 220325 V0.07).mra",
                "Super Street Fighter II The New Legacy (World 201113) [Beta v0.4].mra",
                "Super Street Fighter II The New Legacy (World 210611) [Beta v0.5].mra",
                "Super Street Fighter II The New Legacy (World 220208) [Beta v0.6].mra",
                "Super Street Fighter II The New Legacy (World 230723) [Beta v0.8].mra",
                "No Mans Land.mra",
                "Progear Red Label Halfway to Hell (Japan 160117).mra",
                "Pulsar.mra",
                "Magical Spot.mra",
                "Future Spy.mra ",
                "Gorf (Program 1).mra",
                "Gorf (Speech).mra",
                "Kozmik Krooz'r.mra",
                "Carnival.mra",
                "Cosmic Alien.mra",
                "Cosmic Guerilla.mra",
                "Devil Zone.mra ",
                "Future Spy (315-5061).mra",
                "Super Zaxxon.mra",
                "Super Zaxxon (315-5013).mra",
                "Future Spy.mra",
                "Devil Zone.mra"
            ]

incompatible_mras = [
                        "High Impact Football (rev LA5 02-15-91).mra", 
                        "Mortal Kombat (rev 4.0 09-28-92).mra",
                        "Smash T.V. (rev 8.00).mra",
                        "Super High Impact (rev LA1 09-30-91).mra",
                        "Terminator 2 - Judgment Day (rev LA4 08-03-92).mra",
                        "Total Carnage (rev LA1 03-10-92).mra",
                        "NeoGeo Pocket.mra",
                        "NeoGeo Pocket Color.mra"
                    ]

duplicate_setname_mras = [
                        #"Road Blasters (upright, German, rev X).mra",
                        #"R&T (Rod-Land Prototype).mra",
                        #"Polaris.mra",
                        #"Indiana Jones (german).mra"
                        ]

# Create list of existing mappings
for map_name in os.listdir(inputMaps):
    # Check if the file name contains "16d0_10be" or "16DO_10BE"
    if vid_pid in map_name.lower():
        truncated_map_name = map_name.split("_input")[0] # Get the truncated file name
        truncated_map_names.append(truncated_map_name) # Append the truncated file name to the list
        #print(map_name)

# iterate through the files in the source directory
#for subdirs, dirs, files in os.walk(mra_dir):
for subdir, dirs, files in os.walk(mra_dir, topdown=True):
    dirs[:] = [d for d in dirs if d not in excluded_dirs]
#for root, dirs, files in os.walk(mra_dir, topdown=True):
    for file in files:
        #print(file)
        if file.endswith(".mra") and file not in large_mras and file not in incompatible_mras and file not in duplicate_setname_mras:
            if ("[" or "&") in file:
                if "[" in file:
                    file.replace("[", r"\[").replace("]", r"\]")
                if "&" in file:
                    file.replace("&", r"\&")
                    print("FOUND & IN: {}".format(file))
                #print(file)
            full_file_path = os.path.join(subdir, file)
            src_path = os.path.join(subdir, file)

            # copy mra files larger than 100kB (with embedded rom data) to the big_dir path
            if os.path.getsize(full_file_path) > 875000:
                #print("TOO BIG: {}".format(full_file_path))
                dst_path = os.path.join(big_dir, file)
                if copy_big_mra == "true":
                    if not os.path.exists(big_dir):
                        os.makedirs(big_dir)
                    shutil.copyfile(src_path, dst_path)
                continue  # move on to the next file

            # create an ElementTree object
            else:
                #print(full_file_path)
                #tree = ET.parse(full_file_path) # IF ERROR HERE, DUPLICATE MRA WITH SAME SETNAME
                #tree = ET.parse(full_file_path, parser = ET.XMLParser(encoding = 'iso-8859-5'))
                #tree = ET.parse(full_file_path, parser = ET.XMLParser(encoding = "utf-8"))
                with open (full_file_path, 'r') as xml_file:
                    tree = ET.parse(xml_file, parser = ET.XMLParser(encoding = "utf-8-sig"))
                #print(ET.tostring(tree.getroot()))
                #tree = BeautifulSoup(full_file_path, 'xml')

                # get the root element of the xml file
                root = tree.getroot()

                # find the setname element
                setname_element = root.find(".//setname")

                # extract the text of the setname element
                setname = setname_element.text
                if setname == "gorodki":
                    continue
                #print(setname)

                if setname is None or setname.strip() == "":
                    #print("MISSING SETNAME: {}".format(full_file_path))
                    continue

                # check if the setname is in the truncated filenames
                if setname not in truncated_map_names:
                    # if it's not, copy the file to the destination directory
                    print("MISSING MAPPING: {}".format(full_file_path))
                    #print(setname)
                    #src_path = os.path.join(mra_dir, file)
                    dst_path = os.path.join(missing_dir, file)
                    if not os.path.exists(missing_dir):
                        os.makedirs(missing_dir)
                    shutil.copyfile(src_path, dst_path)
                    continue

                #else:
                #    print("FOUND MAPPING!")
                #    continue
print("COMPLETE")
