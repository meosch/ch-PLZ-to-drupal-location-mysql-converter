#!/bin/bash
### Script to convert the "csv" (actually semicolon separated) from the 
### Swiss government into an SQL statement file that can be run to import
### it as the zipcodes table. 
### More info at:
### opendata.swiss - Official index of cities and towns including postal codes and perimeter
### https://opendata.swiss/en/dataset/amtliches-ortschaftenverzeichnis-mit-postleitzahl-und-perimeter1
###
### Amtliches Ortschaftenverzeichnis
### http://www.cadastre.ch/internet/kataster/de/home/services/service/plz.html
###
### Download the CSV (Excel) WGS84 format file (PLZO_CSV_WGS84.csv) from the last link above.
### Frederick Henderson - 2016.10.21

PS4=':${LINENO} + '
# Next line for testing
#set -x

# Set the locale for formating. de locales use commas (,) for the
# decimal point. We need a period so we use the US English locale.
export LANG="en_US.UTF-8"

setvariables1(){
#Set some variables we will need.
  filenamefromdate=$(date +%Y%m%d)
# Folder where Filemaker by default places the exported files.
  wd="."
#  "/Volumes/MEOS\ Server/MEOS\ Medien/\ \ \ Shop\ Import/"
# The default name suggested by Filemaker for the exported file. We will delete this at the end of this script anyways.
 infile="${wd}/PLZO_CSV_WGS*.csv"
}

setvariables2(){
#Set some more variables we will need.
filenamefromdatewithtime=$(date +%Y%m%d_%H%M%S)
outfile="${wd}/zipcodes.ch.${filenamefromdatewithtime}${filenamesuffix}.sql"
tmpfile="/tmp/${filenamefromdate}-zipcodes.ch.converter.tmp"
timestamp=$(date "+%Y-%m-%d %T")
}

# Is there only one matching file?
existsExactlyOne() {
  [[ $# -eq 1 && -f $1 ]];
}
# Does a file exist?
exists() {
  [[ -f $1 ]];
}
checkforinputfile(){
file=$(ls PLZO_CSV_WGS*.csv 2>/dev/null)
if existsExactlyOne PLZO_CSV_WGS*.csv; then
  infile=$file # only one file found, set infile name
else # If not only one match then check if we have more than one.
  if exists PLZO_CSV_WGS*.csv; then
    echo -e "${col_red}We have more than one file that matches the ${col_yellow}PLZO_CSV_WGS*.csv${col_red} wildcard.${col_reset}"
    echo -e "${col_red}Please delete or remove the file you do not want us to process.${col_reset}"
    exit
  fi
fi
  # If we have gotten this far we have no input file.
  if [ ! -f "$infile" ]; then
    echo -e "${col_red}Input file ${col_yellow}${infile}${col_red} not found!${col_reset}"
    echo -e "${col_red}Please download the PLZ data file in the ${col_yellow}CSV (Excel) LV03${col_red} format before running this script.${col_reset}"
    echo -e "${col_red}The wildcard for the filename to import is ${col_yellow}PLZO_CSV_WGS${col_green}*${col_yellow}.csv${col_red} for conversion from the ${col_yellow}PLZO_CSV_WGS${col_green}*${col_yellow}.zip${col_red} file.${col_reset}"
    echo -e "${col_red}Download at: ${col_yellow}http://www.cadastre.ch/internet/kataster/de/home/services/service/plz.html${col_reset}"
    exitscript
    exit
fi
}

loadcolor(){
# Colors  http://wiki.bash-hackers.org/snipplets/add_color_to_your_scripts
# More info about colors in bash http://misc.flogisoft.com/bash/tip_colors_and_formatting
esc_seq="\x1b["  #In Bash, the <Esc> character can be obtained with the following syntaxes:  \e  \033  \x1B
col_reset=$esc_seq"39;49;00m"
col_red=$esc_seq"31;01m"
col_green=$esc_seq"32;00m"
col_yellow=$esc_seq"33;01m"
col_blue=$esc_seq"34;01m"
col_magenta=$esc_seq"35;01m"
col_cyan=$esc_seq"36;01m"
}

convertdata(){
# Deletes all blank lines in the list file 
#sed  '/^$/d' "$infile" | 
# # Delete the first line of the file, as it is the heading with the description of the fields.
sed '1,1d' "$infile" |
# Convert DOS/Windows newlines (CRLF) to Unix newlines (LF). Otherwise we get a dos/windows new line with the longitude and the line wraps in the middle. 
sed 's/.$//' |
awk -F ';' '{print"( \""$2"\", \""$1"\", \""$5"\", \""$7"\", \""$6"\", \"1\", \"1\", \"ch\" ),"}' |
# Replace comma at the end of the last line with nothing
sed '$s/,$//' >"$tmpfile"

# zip, city, state, latitude, longitude, timezone, dst, country - field order in original zipcodes.ch.mysql file included with Drupal location module https://www.drupal.org/project/location
# PLZ,﻿Ortschaftsname, Kantonskürzel, N, E, 1, 1, ch - fields and static data in the order that this script will output them.
# ﻿Ortschaftsname;PLZ;Zusatzziffer;Gemeindename;Kantonskürzel;E;N - field order in file from http://www.cadastre.ch/internet/kataster/de/home/services/service/plz.html
}

add_field_headings_line(){
sed -i '1 i\
INSERT INTO zipcodes (zip, city, state, latitude, longitude, timezone, dst, country) VALUES' "$tmpfile"
}

add_update_on_duplicate_lines(){
sed -e '$a\
ON DUPLICATE KEY UPDATE city=VALUES(city), state=VALUES(state), latitude=VALUES(latitude), longitude=VALUES(longitude), timezone=VALUES(timezone), dst=VALUES(dst), country=VALUES(country);' "$tmpfile" >"$outfile"
}

cleanup(){
  rm "$tmpfile"
  rm "$infile" # Deletes input file
echo
}

informuser(){
echo ""
echo -e "We will now convert the ${col_red}${infile}${col_reset} Swiss PLZ data file into a MySQL script."
echo " "
}

notwhatyouwanted(){
echo -e "If this is not what you want hit ${col_red}Ctrl + C${col_reset} to abort this script or press any key to continue."
read -p " " -n 1 -r
}

finished(){
  echo -e "${col_red}==============================================================================================================================   ${col_reset}"
  echo -e "All done converting! Exported file ${col_yellow}${outfile}${col_reset} is ready to import."
}

exitscript(){
  read -p "Press any key to exit." -n 1 -r
  echo
}

#### Main Program follows ####
loadcolor
setvariables1
checkforinputfile
informuser
notwhatyouwanted
setvariables2
convertdata
add_field_headings_line
add_update_on_duplicate_lines
cleanup
finished
exitscript
