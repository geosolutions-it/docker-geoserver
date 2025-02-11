import re

# Bande necessarie
bands = ["B02", "B03", "B04", "B05", "B08", "SCL"]

# Template URL per le sorgenti
source_url_template = "https://sentinel-cogs.s3.us-west-2.amazonaws.com/sentinel-s2-l2a-cogs/{mgrs1}/{mgrs2}/{mgrs3}/{year}/{month}/S2{sat}_{tile}_{date}_0_L2A/{band}.tif"

# Legge i percorsi da un file
input_file = "/home/aaime/devel/gisData/rurall/docker-geoserver/scripts/index_EVI.txt" 
source_files = []

with open(input_file, "r") as f:
    for line in f:
        s3_file = line.strip()
        match = re.search(r"tile=(\d{2}[A-Z]{3})/S2_(\d{8})_000_\1_([AB])_[A-Z]+\.tif", s3_file)
        if match:
            tile, date, satellite = match.groups()
            year, month = date[:4], str(int(date[4:6]))  # Rimuove lo zero iniziale dal mese

            # Convertire tile in formato /XX/X/XXX/
            mgrs1, mgrs2, mgrs3 = tile[:2], tile[2], tile[3:]

            for band in bands:
                source_files.append(
                    source_url_template.format(
                        mgrs1=mgrs1, mgrs2=mgrs2, mgrs3=mgrs3,
                        year=year, month=month, sat=satellite,
                        tile=tile, date=date, band=band
                    )
                )

# Stampa l'elenco delle sorgenti
for url in source_files:
    print(url)

