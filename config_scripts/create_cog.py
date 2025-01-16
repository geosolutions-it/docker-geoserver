import requests
import sys

if len(sys.argv) != 7:
    print("Usage: python publish_cog.py <geoserver_url> <username> <password> <workspace> <store_name> <cog_url>")
    sys.exit(1)

# Command line arguments
geoserver_url = sys.argv[1]
username = sys.argv[2]
password = sys.argv[3]
workspace = sys.argv[4]
store_name = sys.argv[5]
cog_url = f"cog://{sys.argv[6]}"

# XML representation of the CoverageStore 
xml_data = f"""
<coverageStore>
    <name>{store_name}</name>
    <type>GeoTIFF</type>
    <url>{cog_url}</url>
    <enabled>true</enabled>
    <workspace>${workspace}</workspace>
</coverageStore>
"""

# Construct endpoint URL
endpoint = f"{geoserver_url}/rest/workspaces/{workspace}/coveragestores"

headers = {
    "Content-Type": "application/xml"
}

try:
    response = requests.post(endpoint, headers=headers, data=xml_data, auth=(username, password))
    if response.status_code == 201:
        print(f"Successfully published '{store_name}' as a GeoTIFF store in workspace '{workspace}'.")
    elif response.status_code == 401:
        print("Authentication failed. Check your username and password.")
    elif response.status_code == 404:
        print(f"Workspace '{workspace}' not found. Ensure the workspace exists.")
    else:
        print(f"Failed to publish COG store. HTTP Status: {response.status_code}. Response: {response.text}")
except requests.RequestException as e:
    print(f"Error: {e}")
