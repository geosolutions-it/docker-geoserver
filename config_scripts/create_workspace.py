import requests
import sys
import os
import subprocess
from requests.auth import HTTPBasicAuth

# Define the base URL of the GeoServer REST API (adjust as needed)
geoserver_url = "http://localhost:8080/geoserver/rest"

# Read command line arguments
if len(sys.argv) != 4:
    print("Usage: python create_workspace.py <admin_username> <admin_password> <workspace_name>")
    sys.exit(1)

admin_username = sys.argv[1]
admin_password = sys.argv[2]
workspace_name = sys.argv[3]

# Create the database schema
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
    f"CREATE SCHEMA \"{workspace_name}\";"
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
    print(f"Schema '{workspace_name}' created successfully.")
else:
    print(f"Error creating schema:\n{result.stderr}")

# Authentication setup
auth = HTTPBasicAuth(admin_username, admin_password)

# Create the workspace XML payload
workspace_xml = f"""
<workspace>
    <name>{workspace_name}</name>
    <namespace>
        <uri>http://terracon.com/pavement/{workspace_name}</uri>
        <prefix>{workspace_name}</prefix>
    </namespace>
</workspace>
"""

# Create the workspace in GeoServer
workspace_url = f"{geoserver_url}/workspaces"
response = requests.post(workspace_url, data=workspace_xml, headers={"Content-Type": "application/xml"}, auth=auth)

if response.status_code == 201:
    print(f"Workspace '{workspace_name}' created successfully.")
else:
    print(f"Error creating workspace: {response.text}")
    sys.exit(1)

# Create the user with the same name and password as the workspace
user_url = f"{geoserver_url}/security/usergroup/users"
user_xml = f"""
<user>
    <userName>{workspace_name}</userName>
    <password>{workspace_name}</password>
    <enabled>true</enabled>
</user>
"""

response = requests.post(user_url, data=user_xml, headers={"Content-Type": "application/xml"}, auth=auth)

if response.status_code == 201:
    print(f"User '{workspace_name}' created successfully.")
else:
    print(f"Error creating user: {response.text}")
    sys.exit(1)

# Create the role for the workspace (e.g., ROLE_$workspaceName)
role_url = f"""{geoserver_url}/security/roles/role/ROLE_{workspace_name}"""

response = requests.post(role_url, headers={"Content-Type": "application/xml"}, auth=auth)

if response.status_code == 201:
    print(f"Role 'ROLE_{workspace_name}' created successfully.")
else:
    print(f"Error creating role: {response.text}")
    sys.exit(1)

# Link the user with the created role
role_assignment_url = f"{geoserver_url}/security/roles/role/ROLE_{workspace_name}/user/{workspace_name}"

response = requests.post(role_assignment_url, headers={"Content-Type": "application/xml"}, auth=auth)

if response.status_code == 200:
    print(f"User '{workspace_name}' assigned to role 'ROLE_{workspace_name}'.")
else:
    print(f"Error assigning role to user: {response.text}")
    sys.exit(1)

# Grant the role read permissions to the workspace
permission_url = f"{geoserver_url}/security/acl/layers"
acl_xml = f"""
<rules>
  <rule resource="{workspace_name}.*.r">ROLE_{workspace_name}</rule>
</rules>
"""

response = requests.post(permission_url, data=acl_xml, headers={"Content-Type": "application/xml"}, auth=auth)

if response.status_code == 200:
    print(f"Read permission granted to role 'ROLE_{workspace_name}' for workspace '{workspace_name}'.")
else:
    print(f"Error granting permissions: {response.text}")
    sys.exit(1)

# Create the PostGIS datastore to publish mosaic indexes
datastore_url = f"{geoserver_url}/workspaces/{workspace_name}/datastores"
datastore_xml = f"""
<dataStore>
    <name>{workspace_name}</name>
    <connectionParameters>
        <entry key="dbtype">postgis</entry>
        <entry key="schema">{workspace_name}</entry>
        <entry key="jndiReferenceName">java:comp/env/jdbc/pavement</entry>
        <entry key="preparedStatements">true</entry>
    </connectionParameters>
</dataStore>
"""
response = requests.post(datastore_url, data=datastore_xml, headers={"Content-Type": "application/xml"}, auth=auth)
if response.status_code == 201:
    print(f"Created datastore '{workspace_name}' for workspace '{workspace_name}'")
else:
    print(f"Failed creating datastore for workspace: {response.text}")
    sys.exit(1)
