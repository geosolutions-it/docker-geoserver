import requests
import xml.etree.ElementTree as ET
import argparse

# Function to get coverages from source store
def get_coverages(geoserver_url, src_workspace, store_name, auth):
    url = f"{geoserver_url}/rest/workspaces/{src_workspace}/coveragestores/{store_name}/coverages.xml"
    response = requests.get(url, auth=auth)
    
    if response.status_code != 200:
        print(f"Error fetching coverages: {response.status_code} - {response.text}")
        return []

    root = ET.fromstring(response.content)
    return [elem.text for elem in root.findall(".//coverage/name")]

# Function to copy a coverage from SRC_WORKSPACE to DST_WORKSPACE
def copy_coverage(geoserver_url, src_workspace, dst_workspace, store_name, coverage_name, auth):
    print(f"Copying coverage: {coverage_name}...")

    # Fetch source coverage details
    url = f"{geoserver_url}/rest/workspaces/{src_workspace}/coveragestores/{store_name}/coverages/{coverage_name}.xml"
    response = requests.get(url, auth=auth)
    
    if response.status_code != 200:
        print(f"Error fetching coverage {coverage_name}: {response.status_code} - {response.text}")
        return
    
    # Modify XML to update workspace reference
    coverage_xml = response.text.replace(f"<name>{src_workspace}</name>", f"<name>{dst_workspace}</name>")
    coverage_xml = coverage_xml.replace(f"<name>{src_workspace}:{store_name}</name>", f"<name>{dst_workspace}:{store_name}</name>")

    # Create coverage in destination workspace
    post_url = f"{geoserver_url}/rest/workspaces/{dst_workspace}/coveragestores/{store_name}/coverages"
    post_response = requests.post(post_url, auth=auth, headers={"Content-Type": "text/xml"}, data=coverage_xml)

    if post_response.status_code not in [200, 201]:
        print(f"Error creating coverage {coverage_name}: {post_response.status_code} - {post_response.text}")
        return
    
    print(f"Successfully copied coverage: {dst_workspace}:{coverage_name}")

# Function to copy a layer from SRC_WORKSPACE to DST_WORKSPACE
def copy_layer(geoserver_url, src_workspace, dst_workspace, coverage_name, auth):
    print(f"Copying layer: {coverage_name}...")

    # Fetch source layer details
    url = f"{geoserver_url}/rest/workspaces/{src_workspace}/layers/{coverage_name}.xml"
    response = requests.get(url, auth=auth)

    if response.status_code != 200:
        print(f"Error fetching layer {coverage_name}: {response.status_code} - {response.text}")
        return

    # Modify XML to update workspace reference
    layer_xml = response.text.replace(f"<name>{src_workspace}:{coverage_name}</name>", f"<name>{dst_workspace}:{coverage_name}</name>")

    # Create layer in destination workspace
    put_url = f"{geoserver_url}/rest/workspaces/{dst_workspace}/layers/{coverage_name}"
    put_response = requests.put(put_url, auth=auth, headers={"Content-Type": "text/xml"}, data=layer_xml)

    if put_response.status_code not in [200, 201]:
        print(f"Error publishing layer {coverage_name}: {put_response.status_code} - {put_response.text}")
    else:
        print(f"Successfully copied and published layer: {dst_workspace}:{coverage_name}")

# Main function
def main():
    parser = argparse.ArgumentParser(description="Copy raster layers between GeoServer workspaces.")
    parser.add_argument("geoserver_url", help="Base URL of GeoServer (e.g., http://localhost:8080/geoserver)")
    parser.add_argument("src_workspace", help="Source workspace")
    parser.add_argument("dst_workspace", help="Destination workspace")
    parser.add_argument("store_name", help="Store name (same in both workspaces)")
    parser.add_argument("-u", "--user", default="admin", help="GeoServer username")
    parser.add_argument("-p", "--password", default="geoserver", help="GeoServer password")

    args = parser.parse_args()
    
    auth = (args.user, args.password)

    # Get list of coverages
    coverages = get_coverages(args.geoserver_url, args.src_workspace, args.store_name, auth)
    
    if not coverages:
        print("No coverages found. Exiting.")
        return

    # Copy each coverage and its corresponding layer
    for coverage in coverages:
        copy_coverage(args.geoserver_url, args.src_workspace, args.dst_workspace, args.store_name, coverage, auth)
        copy_layer(args.geoserver_url, args.src_workspace, args.dst_workspace, coverage, auth)

    print("All coverages and layers copied successfully!")

if __name__ == "__main__":
    main()
