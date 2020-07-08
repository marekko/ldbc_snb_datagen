#!/bin/bash

set -e

if [ ! -f params.ini ]; then
    echo "The params.ini file is not present"
    exit 1
fi

# Running the generator
hadoop jar target/ldbc_snb_datagen-0.4.0-SNAPSHOT-jar-with-dependencies.jar params.ini

# Cleanup
rm -f m*personFactors*
rm -f .m*personFactors*
rm -f m*activityFactors*
rm -f .m*activityFactors*
rm -f m0friendList*
rm -f .m0friendList*

#Preparing Converter: from cypher/impl

echo "Starting preprocessing CSV files"

NEO4J_CSV_DIR="/opt/ldbc_snb_datagen/social_network"
NEO4J_CSV_POSTFIX="_0_0.csv"

echo Loading the following parameters
echo -------------------------------------------------------------------------------
echo NEO4J_CSV_DIR: $NEO4J_CSV_DIR
echo NEO4J_CSV_POSTFIX: $NEO4J_CSV_POSTFIX
echo -------------------------------------------------------------------------------



echo "Replace headers"
while read line; do
  IFS=' ' read -r -a array <<< $line
  FILENAME=${array[0]}
  HEADER=${array[1]}

  echo ${FILENAME}: ${HEADER}
  # replace header (no point using sed to save space as it creates a temporary file as well)
  echo ${HEADER} | cat - <(tail -n +2 ${NEO4J_CSV_DIR}/${FILENAME}${NEO4J_CSV_POSTFIX}) > tmpfile.csv && mv tmpfile.csv ${NEO4J_CSV_DIR}/${FILENAME}${NEO4J_CSV_POSTFIX}
done < headers.txt

echo "Replace labels with one starting with an uppercase letter"
sed -i.bkp "s/|city$/|City/" "${NEO4J_CSV_DIR}/static/place${NEO4J_CSV_POSTFIX}"
sed -i.bkp "s/|country$/|Country/" "${NEO4J_CSV_DIR}/static/place${NEO4J_CSV_POSTFIX}"
sed -i.bkp "s/|continent$/|Continent/" "${NEO4J_CSV_DIR}/static/place${NEO4J_CSV_POSTFIX}"
sed -i.bkp "s/|company|/|Company|/" "${NEO4J_CSV_DIR}/static/organisation${NEO4J_CSV_POSTFIX}"
sed -i.bkp "s/|university|/|University|/" "${NEO4J_CSV_DIR}/static/organisation${NEO4J_CSV_POSTFIX}"

# remove .bkp files
rm ${NEO4J_CSV_DIR}/*/*.bkp

echo "Finished preprocessing CSV files"

echo "Move stuff to directory mounted to the host machine"

mv social_network/ out/
