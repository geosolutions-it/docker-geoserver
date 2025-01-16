import requests
import sys
import os
import subprocess
from requests.auth import HTTPBasicAuth

# Define the base URL of the GeoServer REST API (adjust as needed)
geoserver_url = "http://localhost:8080/geoserver/rest"

# Read command line arguments
if len(sys.argv) != 4:
    print("Usage: python cleanup_workspace.py <admin_username> <admin_password> <workspace_name>")
    sys.exit(1)

admin_username = sys.argv[1]
admin_password = sys.argv[2]
workspace_name = sys.argv[3]

# delete the database schema
# Set the PGPASSWORD environment variable
env = os.environ.copy()
env['PGPASSWORD'] = 'cite'

# Construct the psql command
command = [
    "docker",
    "exec",
    "postgres",
    "psql",
    f"--dbname=geoserver",
    f"--username=geoserver",
    "-c",
    f"DROP SCHEMA IF EXISTS \"{workspace_name}\" CASCADE;"
]

# Execute the command and capture the output
result = subprocess.run(
    command,
    text=True,  # Ensure output is in string format
    input="",  # Pass input if psql prompts for anything
    capture_output=True,
    env=env  # Pass the modified environment
)

# Check the result
if result.returncode == 0:
    print(f"Schema '{workspace_name}' deleted successfully.")
else:
    print(f"Error deleting schema:\n{result.stderr}")

# Authentication setup
auth = HTTPBasicAuth(admin_username, admin_password)

# Remove the workspace (including all its contents, will also remove the security rules for it)
workspace_url = f"{geoserver_url}/workspaces/{workspace_name}?recurse=true"
response = requests.delete(workspace_url, auth=auth)

if response.status_code == 200:
    print(f"Workspace '{workspace_name}' removed successfully.")
else:
    print(f"Error removing workspace: {response.text}")
    sys.exit(1)

# Remove the mosaic configurations in the workspace (if any)
configs_url = f"{geoserver_url}/resource/data/{workspace_name}"
response = requests.delete(configs_url, auth=auth)

if response.status_code == 200:
    print(f"Resources under '{workspace_name}' removed successfully.")
if response.status_code == 404:
    print(f"No resources found.")
else:
    print(f"Error removing resources (might not have been there): {response.text}")

# Remove the user
user_url = f"{geoserver_url}/security/usergroup/user/{workspace_name}"
response = requests.delete(user_url, auth=auth)

if response.status_code == 200:
    print(f"User '{workspace_name}' removed successfully.")
else:
    print(f"Error removing user: {response.text}")
    sys.exit(1)

# Remove the role
role_url = f"{geoserver_url}/security/roles/role/ROLE_{workspace_name}"
response = requests.delete(role_url, auth=auth)

if response.status_code == 200:
    print(f"Role 'ROLE_{workspace_name}' removed successfully.")
else:
    print(f"Error removing role: {response.text}")
    sys.exit(1)
