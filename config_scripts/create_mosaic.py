import os
import zipfile
import requests
import argparse
from io import BytesIO

def create_indexer_properties( mosaic_name, mosaic_crs):
    return f"""Cog=true
SuggestedSPI=it.geosolutions.imageioimpl.plugins.cog.CogImageReaderSpi
CogRangeReader=it.geosolutions.imageioimpl.plugins.cog.AzureRangeReader
CanBeEmpty=true
SuggestedFormat=org.geotools.gce.geotiff.GeoTiffFormat
Name={mosaic_name}
TypeName={mosaic_name}
Schema=*the_geom:Polygon,location:String,survey:String,ingestion:java.util.Date,name:String,crs:String
PropertyCollectors=TimestampFileNameExtractorSPI[timeregex](ingestion),StringFileNameExtractorSPI[nameregex](name),StringFileNameExtractorSPI[surveyregex](survey)
GranuleAcceptors=org.geotools.gce.imagemosaic.acceptors.HeterogeneousCRSAcceptorFactory
GranuleHandler=org.geotools.gce.imagemosaic.granulehandler.ReprojectingGranuleHandlerFactory
SkipExternalOverviews=true
HeterogeneousCRS=true
MosaicCRS={mosaic_crs}
Heterogeneous=true"""

def create_datastore_properties(workspace):
    return f"""SPI=org.geotools.data.postgis.PostgisNGJNDIDataStoreFactory
jndiReferenceName=java:comp/env/jdbc/pavement
Loose\\ bbox=true
schema={workspace}
preparedStatements=true"""

def create_regex_properties(regex):
    return f"regex={regex}"

def create_footprints():
    return "footprint_source=raster"

def create_zip(workspace, mosaic_name, mosaic_crs):
    buffer = BytesIO()
    with zipfile.ZipFile(buffer, 'w') as zf:
        zf.writestr("indexer.properties", create_indexer_properties(mosaic_name, mosaic_crs))
        zf.writestr("datastore.properties", create_datastore_properties(workspace))
        zf.writestr("timeregex.properties", create_regex_properties("[0-9]{8}"))
        zf.writestr("nameregex.properties", create_regex_properties(".*"))
        zf.writestr("surveyregex.properties", create_regex_properties("(?<=\\\\/)([sS]\\\\d+)(?=\\\\/),fullPath=true"))
        zf.writestr("footprints.properties", create_footprints())
    buffer.seek(0)
    return buffer

def upload_mosaic(geoserver_url, username, password, workspace, mosaic_name, mosaic_crs):
    zip_file = create_zip(workspace, mosaic_name, mosaic_crs)

    headers = {
        "Content-Type": "application/zip",
    }

    url = f"{geoserver_url}/rest/workspaces/{workspace}/coveragestores/{mosaic_name}/file.imagemosaic?configure=none"

    response = requests.put(
        url,
        auth=(username, password),
        headers=headers,
        data=zip_file.getvalue()
    )

    if response.status_code in (200, 201):
        print("Image mosaic created successfully.")
    else:
        print(f"Failed to create image mosaic. Status code: {response.status_code}, Response: {response.text}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a new image mosaic in GeoServer.")
    parser.add_argument("geoserver_url", help="The GeoServer base URL.")
    parser.add_argument("username", help="Admin username.")
    parser.add_argument("password", help="Admin password.")
    parser.add_argument("workspace", help="Target workspace.")
    parser.add_argument("mosaic_name", help="Name of the mosaic.")
    parser.add_argument("mosaic_crs", help="Target CRS for the mosaic.")

    args = parser.parse_args()

    upload_mosaic(
        args.geoserver_url,
        args.username,
        args.password,
        args.workspace,
        args.mosaic_name,
        args.mosaic_crs
    )
