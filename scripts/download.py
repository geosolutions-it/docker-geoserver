import os
import requests
import concurrent.futures
from urllib.parse import urlparse

def download_file(url, output_dir):
    parsed_url = urlparse(url)
    filename = os.path.basename(parsed_url.path)
    product_name = os.path.basename(os.path.dirname(parsed_url.path))
    product_dir = os.path.join(output_dir, product_name)
    os.makedirs(product_dir, exist_ok=True)
    
    file_path = os.path.join(product_dir, filename)
    
    if os.path.exists(file_path):
        print(f"Skipping {filename}, already exists.")
        return
    
    print(f"Downloading {filename} to {product_dir}...")
    
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(file_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        print(f"Finished downloading {filename}.")
    except requests.RequestException as e:
        print(f"Failed to download {filename}: {e}")

def download_from_file(file_path, output_dir, max_workers=4):
    with open(file_path, 'r') as file:
        urls = [line.strip() for line in file if line.strip()]
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(lambda url: download_file(url, output_dir), urls)

if __name__ == "__main__":
    input_file = "/home/ubuntu/docker-geoserver/scripts/sources.txt"
    output_directory = "downloaded_rasters"
    max_parallel_downloads = 4  # Adjust for your network and system capacity
    
    download_from_file(input_file, output_directory, max_parallel_downloads)
