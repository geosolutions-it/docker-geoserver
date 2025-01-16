import argparse
import requests
from requests.auth import HTTPBasicAuth

def create_coverage_and_layer(geoserver_url, username, password, workspace, coverage_store, coverage_name):
    # Define the URL for the REST API
    rest_url = f"{geoserver_url}/rest/workspaces/{workspace}/coveragestores/{coverage_store}/coverages"
    
    # Prepare the XML payload for the coverage creation
    payload = f"""
    <coverage>
        <name>{coverage_name}</name>
        <nativeName>{coverage_name}</nativeName>
        <title>{coverage_name}</title>
        <parameters>
            <entry>
                <string>AllowMultithreading</string>
                <boolean>true</boolean>
            </entry>
            <entry>
                <string>USE_JAI_IMAGEREAD</string>
                <boolean>false</boolean>
            </entry>
            <entry>
                <string>FootprintBehavior</string>
                <string>Transparent</string>
            </entry>
        </parameters>
    </coverage>
    """
    
    # Send a POST request to create the coverage and layer
    headers = {"Content-Type": "application/xml"}
    response = requests.post(
        rest_url,
        data=payload,
        headers=headers,
        auth=HTTPBasicAuth(username, password)
    )
    
    # Handle the response
    if response.status_code == 201:
        print(f"Successfully created coverage and layer '{coverage_name}' in workspace '{workspace}'.")
    else:
        print(f"Failed to create coverage and layer. HTTP {response.status_code}: {response.text}")

    # Now update its parameters (cannot be passed during creation)
    payload = f"""
    <coverage>
        <name>{coverage_name}</name>
        <nativeName>{coverage_name}</nativeName>
        <title>{coverage_name}</title>
        <parameters>
            <entry>
                <string>AllowMultithreading</string>
                <boolean>true</boolean>
            </entry>
            <entry>
                <string>USE_JAI_IMAGEREAD</string>
                <boolean>false</boolean>
            </entry>
            <entry>
                <string>FootprintBehavior</string>
                <string>Transparent</string>
            </entry>
            <entry>
                <string>OVERVIEW_POLICY</string>
                <string>QUALITY</string>
            </entry>
        </parameters>
    </coverage>
    """

    rest_url = f"{geoserver_url}/rest/workspaces/{workspace}/coveragestores/{coverage_store}/coverages/{coverage_name}"
    response = requests.put(
        rest_url,
        data=payload,
        headers=headers,
        auth=HTTPBasicAuth(username, password)
    )

     # Handle the response
    if response.status_code == 200:
        print(f"Successfully updated coverage parameters for '{coverage_name}' in workspace '{workspace}'.")
    else:
        print(f"Failed to update coverage. HTTP {response.status_code}: {response.text}")


if __name__ == "__main__":
    # Define command-line arguments
    parser = argparse.ArgumentParser(description="Create a new coverage and layer in GeoServer.")
    parser.add_argument("geoserver_url", help="GeoServer URL (e.g., http://localhost:8080/geoserver)")
    parser.add_argument("username", help="Admin username for GeoServer")
    parser.add_argument("password", help="Admin password for GeoServer")
    parser.add_argument("workspace", help="Workspace name")
    parser.add_argument("coverage_store", help="Coverage store name")
    parser.add_argument("coverage_name", help="Coverage name")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Run the function with the provided arguments
    create_coverage_and_layer(
        args.geoserver_url,
        args.username,
        args.password,
        args.workspace,
        args.coverage_store,
        args.coverage_name
    )
