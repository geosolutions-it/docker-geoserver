# fail fast
set -e

# get inside working directory
folder_path="$1"
cd $folder_path

# Extract folder name from path
folder_name=$(basename "$folder_path")
# Extract the "32TNQ" part using underscore `_` as a delimiter
zone=$(echo "$folder_name" | cut -d'_' -f2)

# start clean
rm -rf work
rm -rf masked
mkdir work
mkdir masked

# create 10m B05
gdal_translate -q -tr 10 10 B05.tif work/B0510.tif

# create mask
gdal_translate -q -tr 10 10 -co COMPRESS=LZW -co NUM_THREADS=ALL_CPUS SCL.tif work/SCL10.tif
gdal_calc.py -Awork/SCL10.tif -B../WMK/S2_WMK_$zone.tif --outfile=work/cloudMask0.tif --calc="B*(A==2)+B*(A==4)+B*(A==5)+B*(A==6)+B*(A==7)+B*(A==10)" --quiet --NoDataValue=255 --type=Byte --creation-option NUM_THREADS=ALL_CPUS
gdal_sieve.py -st 49 -q work/cloudMask0.tif work/cloudMask1.tif
gdal_translate -a_nodata 1 -q -co NUM_THREADS=ALL_CPUS work/cloudMask1.tif work/cloudMask2.tif
gdal_fillnodata.py -md 2 -q -co NUM_THREADS=ALL_CPUS -si 0 -of GTiff work/cloudMask2.tif work/cloudMask3.tif
gdal_translate -q -a_nodata none -co NUM_THREADS=ALL_CPUS work/cloudMask3.tif work/cloudMask4.tif
gdal_sieve.py -st 47 -q work/cloudMask4.tif work/cloudMask5.tif
gdal_calc.py -Awork/cloudMask5.tif --outfile=masked/MASK.tif --calc="A==1" --quiet --creation-option NUM_THREADS=ALL_CPUS

# mask the various files
gdal_calc.py --quiet -A masked/MASK.tif -B B02.tif --outfile=work/masked_B02.tif --calc="where(A == 0, B, 65535)" --NoDataValue=65535
gdal_translate -q -of COG -co compress=DEFLATE -co NUM_THREADS=ALL_CPUS work/masked_B02.tif masked/B02.tif

gdal_calc.py --quiet -A masked/MASK.tif -B B03.tif --outfile=work/masked_B03.tif --calc="where(A == 0, B, 65535)" --NoDataValue=65535
gdal_translate -q -of COG -co compress=DEFLATE -co NUM_THREADS=ALL_CPUS work/masked_B03.tif masked/B03.tif

gdal_calc.py --quiet -A masked/MASK.tif -B B04.tif --outfile=work/masked_B04.tif --calc="where(A == 0, B, 65535)" --NoDataValue=65535
gdal_translate -q -of COG -co compress=DEFLATE -co NUM_THREADS=ALL_CPUS work/masked_B04.tif masked/B04.tif

gdal_calc.py --quiet -A masked/MASK.tif -B work/B0510.tif --outfile=work/masked_B05.tif --calc="where(A == 0, B, 65535)" --NoDataValue=65535
gdal_translate -q -of COG -co compress=DEFLATE -co NUM_THREADS=ALL_CPUS work/masked_B05.tif masked/B05.tif

gdal_calc.py --quiet -A masked/MASK.tif -B B08.tif --outfile=work/masked_B08.tif --calc="where(A == 0, B, 65535)" --NoDataValue=65535
gdal_translate -q -of COG -co compress=DEFLATE -co NUM_THREADS=ALL_CPUS work/masked_B08.tif masked/B08.tif

# cleanup work directory
rm -rf work

# cleanup original bands to save space
rm B02.tif B03.tif B04.tif B05.tif B08.tif SCL.tif