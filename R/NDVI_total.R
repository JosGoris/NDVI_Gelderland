#Import libraries
library(raster)
library(sp)
library(rgdal)


ifolder <- "./data/"
ofolder <- "./output/"
dir.create(ifolder, showWarnings = FALSE)
dir.create(ofolder, showWarnings = FALSE)

# Download Province boundaries
nlProvincie <- raster::getData('GADM',country='NLD', level=1,path=ifolder)

# Change projection of the province data
nlProvincie_sinu <- spTransform(nlProvincie, CRS("+init=epsg:28992")) 

# Select Gelderland
Gelderland <- nlProvincie_sinu[4,] 

#-------------------------------------
# Next make an empty raster
# make a random matrix
xy <- matrix(nrow = 881, ncol = 1263)

# Turn the matrix into a raster
rast <- raster(xy)

# Give it the extent of gelderland (this extent is coming from the province boundaries)
extent(rast) <- c(128017.2, 254361.2, 416123.1, 504188.1)

# ... and assign a projection(RD New)
projection(rast) <- CRS("+init=epsg:28992")

# resample the cell size to 100 by 100
res(rast)<-100

#give the rastercells the value 0
GelderlandRas <- setValues(rast, 0)

#mask it to gelderland (maybe not useful now)
GelderlandRas <- mask(GelderlandRas, Gelderland)

#------------------------------------
#Next download the NDVI data
NDVIURL <- "https://github.com/GeoScripting-WUR/VectorRaster/raw/gh-pages/data/MODIS.zip"
inputZip <- list.files(path=ifolder, pattern= '^.*\\.zip$')
if (length(inputZip) == 0){ ##only download when not alrady downloaded
  download.file(url = NDVIURL, destfile = 'data/NDVI_data.zip', method = 'wget')
  
}

# Data pre-processing
unzip('data/NDVI_data.zip', exdir=ifolder)  # unzip NDVI data
NDVIlist <- list.files(path=ifolder,pattern = '+.grd$', full.names=TRUE) # list NDVI raster
NDVI_12 <- stack(NDVIlist) # NDVI rasters
NDVI_RD <- projectRaster(NDVI_12, crs = "+init=epsg:28992")

# Select and calculate NDVI mean of the year
NDVI_mean <- calc(NDVI_RD,mean)

# Resample to the gelderland raster with cells of 100 by 100
NDVI_meanRes <- resample(NDVI_mean, GelderlandRas)

#crop and mask the result
NDVIGelderland <- crop(NDVI_meanRes, Gelderland)
NDVIGelderland <- mask(NDVIGelderland, Gelderland)

# Visualization
plot(NDVIGelderland)
plot(Gelderland, add = TRUE)