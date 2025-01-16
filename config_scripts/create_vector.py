import argparse
import requests
from requests.auth import HTTPBasicAuth

def create_feature_type(geoserver_url, username, password, workspace, datastore, table_name):
    layer_name = f"{table_name}_footprints"
    
    # Endpoint to create the feature type
    feature_type_url = f"{geoserver_url}/rest/workspaces/{workspace}/datastores/{datastore}/featuretypes"

    # Payload for the feature type creation
    payload = f"""
    <featureType>
        <name>{layer_name}</name>
        <nativeName>{table_name}</nativeName>
        <enabled>true</enabled>
    </featureType>
    """
    headers = {"Content-Type": "application/xml"}

    # Create the feature type
    response = requests.post(feature_type_url, auth=HTTPBasicAuth(username, password), data=payload, headers=headers)
    if response.status_code not in [200, 201]:
        print(f"Error creating feature type: {response.status_code} - {response.text}")
        return False

    print(f"Feature type {layer_name} created successfully.")
    return layer_name

def assign_style(geoserver_url, username, password, workspace, layer_name):
    # Endpoint to associate a style with the layer
    style_url = f"{geoserver_url}/rest/layers/{workspace}:{layer_name}"

    # Payload to set the style
    payload = f"""
    <layer>
        <enabled>true</enabled>
        <defaultStyle>
            <name>line</name>
        </defaultStyle>
    </layer>
    """
    headers = {"Content-Type": "application/xml"}

    # Update the layer with the style
    response = requests.put(style_url, auth=HTTPBasicAuth(username, password), data=payload, headers=headers)
    if response.status_code not in [200, 201]:
        print(f"Error assigning style to layer: {response.status_code} - {response.text}")
        return False

    print(f"Style 'line' assigned to layer {layer_name} successfully.")
    return True

def main():
    parser = argparse.ArgumentParser(description="Create a new feature type and layer in GeoServer.")
    parser.add_argument("geoserver_url", help="The base URL of the GeoServer instance (e.g., http://localhost:8080/geoserver).")
    parser.add_argument("username", help="GeoServer admin username.")
    parser.add_argument("password", help="GeoServer admin password.")
    parser.add_argument("workspace", help="GeoServer workspace name.")
    parser.add_argument("datastore", help="GeoServer data store name.")
    parser.add_argument("table_name", help="Name of the table in the data store.")

    args = parser.parse_args()

    # Create the feature type
    layer_name = create_feature_type(args.geoserver_url, args.username, args.password, args.workspace, args.datastore, args.table_name)
    if not layer_name:
        return

    # Assign the style to the layer
    assign_style(args.geoserver_url, args.username, args.password, args.workspace, layer_name)

if __name__ == "__main__":
    main()
