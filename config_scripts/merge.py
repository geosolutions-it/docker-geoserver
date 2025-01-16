import os
import re
import sys
import argparse
import subprocess
import tempfile
import shutil


def extract_epsg(file_path):
    """
    Extract the EPSG code from a GeoTIFF file using gdalinfo.
    Returns the EPSG code as a string, or None if not found.
    """
    try:
        result = subprocess.run(
            ["gdalinfo", file_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        match = re.findall(r'ID\["EPSG",(\d+)\]', result.stdout)
        return f"EPSG:{match[-1]}" if match else None
    except subprocess.CalledProcessError as e:
        print(f"Error reading file {file_path} with gdalinfo: {e.stderr}")
        return None


def reproject_to_vrt(input_file, target_crs, output_file):
    """
    Reproject a GeoTIFF to a specified CRS and save it as a VRT.
    """
    try:
        subprocess.run(
            ["gdalwarp", "-t_srs", target_crs, "-of", "VRT", "-dstalpha", input_file, output_file],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error reprojecting file {input_file} to {target_crs}: {e.stderr}")
        sys.exit(1)


def build_vrt(input_files, output_vrt):
    """
    Build a VRT from multiple input files.
    """
    try:
        subprocess.run(
            ["gdalbuildvrt", output_vrt, *input_files],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error building VRT: {e.stderr}")
        sys.exit(1)


def convert_to_cog(input_file, output_file):
    """
    Convert a VRT to a Cloud Optimized GeoTIFF using gdal_translate with multithreading.
    """
    try:
        subprocess.run(
            [
                "gdal_translate",
                input_file,
                output_file,
                "-of",
                "COG",
                "-co",
                "COMPRESS=JPEG",
                "-co",
                "SPARSE_OK=YES",
                "-co",
                "NUM_THREADS=ALL_CPUS",  # Use all available CPUs
                "--config",
                "GDAL_CACHEMAX",
                "4096",  # Set cache to 4 GB
            ],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error converting file to COG: {e.stderr}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Process GeoTIFF files into a COG.")
    parser.add_argument(
        "-t", "--target-crs", required=True, help="Target CRS (e.g., EPSG:4326)."
    )
    parser.add_argument(
        "-o", "--output-file", required=True, help="Path to the output COG file."
    )
    parser.add_argument(
        "input_files", nargs="+", help="List of input GeoTIFF files."
    )
    args = parser.parse_args()

    target_crs = args.target_crs
    output_cog_file = args.output_file
    input_files = args.input_files

    # Create a temporary directory for intermediate files
    temp_dir = tempfile.mkdtemp()
    print(f"Using temporary directory: {temp_dir}")

    try:
        vrt_files = []
        for file in input_files:
            print(f"Processing {file}...")
            current_crs = extract_epsg(file)
            if not current_crs:
                print(f"Could not determine CRS for {file}. Skipping...")
                continue

            print(f"Detected CRS: {current_crs}")
            if current_crs != target_crs:
                # Reproject to target CRS
                vrt_file = os.path.join(temp_dir, os.path.basename(file) + ".vrt")
                reproject_to_vrt(file, target_crs, vrt_file)
                vrt_files.append(vrt_file)
            else:
                # Use the original file directly
                vrt_files.append(file)

        # Build a single VRT from all reprojected and original files
        combined_vrt = os.path.join(temp_dir, "combined.vrt")
        print(f"Building combined VRT: {combined_vrt}...")
        build_vrt(vrt_files, combined_vrt)

        # Convert the combined VRT into a COG
        print(f"Converting {combined_vrt} to COG: {output_cog_file}...")
        convert_to_cog(combined_vrt, output_cog_file)

        print(f"Processing complete. Output COG file: {output_cog_file}")

    finally:
        # Clean up temporary directory
        print(f"Cleaning up temporary files...")
        shutil.rmtree(temp_dir)


if __name__ == "__main__":
    main()

