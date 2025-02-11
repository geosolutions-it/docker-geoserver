import sys
import requests
from requests.auth import HTTPBasicAuth

def harvest_cogs(geoserver_url, username, password, workspace, store_name, file_path):
    try:
        # Read the file containing URLs
        with open(file_path, 'r') as file:
            cog_urls = file.read().splitlines()

        if not cog_urls:
            print("The file does not contain any URLs.")
            return

        # Perform the REST call for each COG URL
        for url in cog_urls:
            rest_url = f"{geoserver_url}/rest/workspaces/{workspace}/coveragestores/{store_name}/remote.imagemosaic"
            headers = {"Content-type": "text/plain"}
            print(f"Harvesting COG: {url}")

            response = requests.post(
                rest_url,
                auth=HTTPBasicAuth(username, password),
                headers=headers,
                data=url
            )

            # Check response status
            if response.status_code == 202:
                print(f"Successfully harvested: {url}")
            else:
                print(f"Failed to harvest: {url} (HTTP {response.status_code})")
                print(f"Response: {response.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 7:
        print("Usage: python script.py <geoserver_url> <username> <password> <workspace> <store_name> <file_path>")
        print(sys.argv)
        sys.exit(1)

    geoserver_url, username, password, workspace, store_name, file_path = sys.argv[1:]
    harvest_cogs(geoserver_url, username, password, workspace, store_name, file_path)
