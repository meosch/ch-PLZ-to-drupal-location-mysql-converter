# ch-PLZ-to-drupal-location-mysql-converter
Script to convert geo-location data for Swiss PLZ (Short for the German Postleitzahl, which is German for zip code) into a MySQL format for import into a database as the **zipcodes** table. This is for use with the [Drupal location module](http://drupal.org/project/location) for distance / proximity searches.

opendata.swiss - Official index of cities and towns including postal codes and perimeter
https://opendata.swiss/en/dataset/amtliches-ortschaftenverzeichnis-mit-postleitzahl-und-perimeter1

Amtliches Ortschaftenverzeichnis
http://www.cadastre.ch/internet/kataster/de/home/services/service/plz.html

- Download the CSV (Excel) WGS84 format file from the last link above.
- Unzip the downloaded file.
- Place the file that matches the wildcard **PLZO_CSV_WGS*.csv** into the same folder as the script.
- Run the script with `./ch-plz-mysql-conv.sh`
- Import the file that matches the wildcard **zipcodes.ch.*.sql**

## Quality of Geo-location Data

The quality of the geo-location data included with the [Drupal location module](http://drupal.org/project/location) is questionable. Notably St. Gallen, PLZ 9000 is kilometers away from the town center.

The quality of the data from the Swiss government is better but there are some omissions that make searching not work as expected. Notably Biel, 2500 PLZ is not included meaning that searching for this PLZ returns no results.

The solution is to first import the data included with the  [Drupal location module](http://drupal.org/project/location) then update records if they exist otherwise create them. The script has been modified to create an sql statement that does this.