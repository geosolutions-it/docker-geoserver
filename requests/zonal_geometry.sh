#!/bin/bash

# Ensure we have two arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <MGRS Zone> <Index Name>"
    exit 1
fi

WORKSPACE="$1"
INDEX="$2"
DATE="$3"T00:00:00
OUTPUT_FILE="${INDEX}_dynamic.json"
OUTPUT_FILE="${WORKSPACE}_${INDEX}_$3_geometry.json"

# Read the template file into a variable and replace placeholders
TEMPLATE_FILE="zonal_geometry.xml"
REQUEST_XML=$(<"$TEMPLATE_FILE")
REQUEST_XML=${REQUEST_XML//"{{WORKSPACE}}"/$WORKSPACE}
REQUEST_XML=${REQUEST_XML//"{{INDEX}}"/$INDEX}
REQUEST_XML=${REQUEST_XML//"{{DATE}}"/$DATE}


# Perform the WPS request
curl -s -X POST -H "Content-Type: application/xml" --data-binary "$REQUEST_XML" "http://localhost:28081/geoserver/wps" | jq > "$OUTPUT_FILE"

# Check if the request was successful
if [ $? -eq 0 ]; then
    echo "WPS request completed. Output saved to $OUTPUT_FILE"
else
    echo "Error during the WPS request."
fi
