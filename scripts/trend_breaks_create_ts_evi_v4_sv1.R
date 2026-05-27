#=================================================================================
# Vegetation Trend Analysis ECU593 - Create time series object 
#=================================================================================
# 2026-05-25
# Peter R.

# Notes:
#   - This version is to be run on DRAC (Compute Canada). It takes too long to create the 20-year+ ts
#   - Study area: all of Algonquin Park
#   - The aim of this script is to produce BFAST outputs using MODIS NDVI & EVI for Peter's proj
#   - I will use MODIS products at 250 m
#   - All quality metrics included. This may be overkill though
#   - original script: C:/Users/Peter R/Documents/st_trends_for_c/algonquin/ver2/scripts/R_git/trend_breaks_create_ts_evi_v4.R
#   - Period 1 to 5 (5-year periods) were run locally.
#   - This could be much simpler. I don't really need to define the ts segments here.
#   - I just need to created the longest ts here and then segment when running bfast01. For bfast I am only running the longest segment.


start.time <- Sys.time()
#start.time


#=================================
# Load libraries
# ================================
# install.packages(c("strucchangeRcpp", "bfast"))
library(terra)
library(sf)
library(bfast)
#install.packages("foreach")
library(foreach)
library(doParallel)
#install.packages("remotes")
#library(remotes)

#install.packages("stlplus")
#library(stlplus)

#remotes::install_github("fdetsch/MODIS")

library(MODIS)

library(raster) # Install raster after terra to avoid package issues
#library(sqldf)


#=================================
# File paths and folders
# ================================

#setwd("~/projects/def-mfortin/georod/scripts/github/forc_ecu") # github folder
#setwd("C:/Users/Peter R/Documents/st_trends_for_c/algonquin")

#dataf <- "~/projects/def-mfortin/georod/data" # data folder
dataf <- "/home/georod/projects/def-mfortin/georod/data/forc_ecu/inputs/modis/southern_ecuador/"
#dataf <- "C:/Users/Peter R/Documents/data/gis"
#dataf2 <- "C:/Users/Peter R/Documents/forc_southern_ecuador"
dataf2 <- "/home/georod/projects/def-mfortin/georod/data/forc_ecu/outputs/"
dataf3 <- "/home/georod/projects/def-mfortin/georod/data/forc_ecu/inputs/"

# MODIS files with original sinusoidal proj for period 2001-2023
fpath <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/EVI") # NDVI
#fpath <- paste0(dataf,"/modis/southern_ecuador/modistsp/VI_16Days_250m_v61/EVI")


# Land cover. For this project I am doing all vegetation as a first run
#fpath2 <- "~/projects/def-mfortin/georod/data/ont_out/ont_CA_forest_VLCE2_2003.tif"

# QA pixels folder
#var1 <- "southern_ecuador"
fpath3_1 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_qual")
fpath3_2 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_usef")
fpath3_3 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_adj_cld")
fpath3_4 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_aer")
fpath3_5 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_mix_cld")
fpath3_6 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_shd")
fpath3_7 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_BRDF")
fpath3_8 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_land_wat")
fpath3_9 <- paste0(dataf,"/modistsp/VI_16Days_250m_v61/QA_snow_ice")


# Skip. I am doing all vegetation
# CSV to reclassify land cover values to keep only forest pixels
#fpath4 <- "./misc/ca_forest_vlce2_lcover_type1_values.csv"

# Path to vector
#shp1 <- "./misc/shp/algonquin_envelope_500m_buff_v1.shp"
#shp1 <- "./misc/shp/algonquin_aoi31.shp"
#shp1 <- "C:/Users/Peter R/Documents/PhD/resnet/data/gis/misc/algonquin_envelope_500m_buff_v1.shp"
#shp1 <- "C:/Users/Peter R/Documents/PhD/resnet/data/gis/misc/algonquin_aoi3.shp"
#shp1 <- "C:/Users/Peter R/Documents/forc_southern_ecuador/data/southern_ecuador_bbox_v1.geojson"
shp1 <- paste0(dataf3, "southern_ecuador_bbox_v1.geojson")

# Output folders
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/EVI_250m/bfast/")  # Note: h=0.5 run. Change back when done
outf3 <- paste0(dataf2, "/timeseries/output_h5p/EVI_250m/bfast/")  
#outf3 <- paste0(dataf, "/outputs/output_h5p/EVI_250m/bfast/")  #....period1, 2, 3,...
#dir.exists(outf3)


#c("NDVI", "EVI")

# This is the key step. Get the indices right. NOte: you only need to create the longest ts object. 
# Breaks are only estimated for the long ts and segments can be created while running bfast01
# Keep 2000-2025 EVI, leave 2026 raster out as there are not complete. Note 2000 rasters are incomplete. Start at 2001
# steps of 115 as there are 115 16-day time points in a 5-year period
#start5yr <- seq(1,575, 115) # for a total 595 raster files
#end5yr <- seq(115,575, 115) 
#start10yr <- seq(1,575, 230) 
#end10yr <- seq(230,575, 230) 

start20yr <- c(1)
end20yr <- c(575)

#end2 <- c(115,230,345,length(rastfiles))
#periods1 <- cbind(c(start5yr,start10yr, start20yr), c(end5yr, end10yr, end20yr))
#periods1 <- cbind(c(start5yr,start10yr, start20yr), c(end5yr, end10yr, end20yr))
#periods1 <- cbind(c(start5yr, start20yr), c(end5yr, end20yr))
periods1 <- cbind(c(start20yr), c(end20yr))
#periods1Labs <- c("period1", "period2", "period3", "period4", "period5", "period6", "period7")
#periods1Labs <- c("period1", "period2", "period3", "period4", "period5","period7") # 25 year ts, period5 is another 5-year period
periods1Labs <- c("period7") # Period 7 is the longest ts

periods1 <- matrix(periods1, ncol=2)
#periods1 <- matrix(periods1[6,], nrow=1)
#periods1Labs <- periods1Labs[6]

#========================================
# Parallel processing settings
#========================================

# Code shared by Flavio A.
# Use the environment variable SLURM_CPUS_PER_TASK to set the number of cores.
# This is for SLURM. Replace SLURM_CPUS_PER_TASK by the proper variable for your system.
# Avoid manually setting a number of cores.
#ncores = Sys.getenv("SLURM_CPUS_PER_TASK") 

#registerDoParallel(cores=ncores)# Shows the number of Parallel Workers to be used
#print(ncores) # this how many cores are available, and how many you have requested.
#getDoParWorkers()# you can compare with the number of actual workers



#======================================
# Time series loop
#======================================


#dir.create(paste0(outf3, periods1Labs[1])) #Sensibility test for determining the effect of different period lenght (modifiable time unit problem)
#dir.create(paste0(outf3, periods1Labs[1],"/errors")) #Sensibility test for determining the effect of different period lenght (modifiable time unit problem)
#dir.create(paste0(outf3, periods1Labs))

# This is the key step. Get the indices right.
startI <- 21
endI <- 595 # This is the length from Gtiff 1
timeSleep <- 3

# (z in 1:2)
# z in 3:nrow(periods1)
for (z in 1:nrow(periods1) ) {
#for (z in 1 ) {
  
  
  # Path to raster files
  # The year 2003 starts at position i=23 for EVI. This may be different for other indices
  rastfiles <- list.files(path=fpath, pattern = "*EVI*", full.names = TRUE)
  rastfiles <- rastfiles[startI:endI] # For 1 km & 500 mstart at 43
  #rastfiles <- rastfiles[43:length(rastfiles)] # For 500m start at 43
  
  #length(rastfiles)
  #rastfiles[[1]]
  
  rastfilesNames <- list.files(path=fpath, pattern = "*EVI*", full.names = FALSE)
  rastfilesNames <- rastfilesNames[startI:endI ] # For 1 km start at 43
  #length(rastfilesNames)
  #rastfilesNames[[1]]
  
  
  rastfilesQA1 <- list.files(path=fpath3_1, pattern = "*_QA_qual*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA1 <- rastfilesQA1[startI:endI ] # I used 23 by mistake
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA2 <- list.files(path=fpath3_2, pattern = "*_QA_usef*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA2 <- rastfilesQA2[startI:endI ] # For 1 km start at 43
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA3 <- list.files(path=fpath3_3, pattern = "*_QA_adj*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA3 <- rastfilesQA3[startI:endI ] # For 1 km start at 43
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA4 <- list.files(path=fpath3_4, pattern = "*_QA_aer*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA4 <- rastfilesQA4[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA5 <- list.files(path=fpath3_5, pattern = "*_QA_mix_cld*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA5 <- rastfilesQA5[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA6 <- list.files(path=fpath3_6, pattern = "*_QA_shd*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA6 <- rastfilesQA6[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA7 <- list.files(path=fpath3_7, pattern = "*_QA_BRDF*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA7 <- rastfilesQA7[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA8 <- list.files(path=fpath3_8, pattern = "*_QA_land_wat*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA8 <- rastfilesQA8[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  rastfilesQA9 <- list.files(path=fpath3_9, pattern = "*_QA_snow_ice*", full.names = TRUE)
  #length(rastfilesQA)
  rastfilesQA9 <- rastfilesQA9[startI:endI ] # 
  #length(rastfilesQA)
  #rastfilesQA[[1]]  
  
  
  
  
  #--------------------------------------
  # Produce raster files objects
  #--------------------------------------
  
  rastfiles <- rastfiles[periods1[z,1]:periods1[z, 2]]
  rastfilesNames <- rastfilesNames[periods1[z,1]:periods1[z, 2]]
  
  
  rastfilesQA1 <- rastfilesQA1[periods1[z,1]:periods1[z, 2]]
  rastfilesQA2 <- rastfilesQA2[periods1[z,1]:periods1[z, 2]]
  rastfilesQA3 <- rastfilesQA3[periods1[z,1]:periods1[z, 2]]
  rastfilesQA4 <- rastfilesQA4[periods1[z,1]:periods1[z, 2]]
  rastfilesQA5 <- rastfilesQA5[periods1[z,1]:periods1[z, 2]]
  rastfilesQA6 <- rastfilesQA6[periods1[z,1]:periods1[z, 2]]
  
  rastfilesQA7 <- rastfilesQA7[periods1[z,1]:periods1[z, 2]]
  rastfilesQA8 <- rastfilesQA8[periods1[z,1]:periods1[z, 2]]
  rastfilesQA9 <- rastfilesQA9[periods1[z,1]:periods1[z, 2]]
  
  print("done selecting QAs")
  #--------------------------------------
  # Read data
  #--------------------------------------
  
  # Read in raster stack
  r1 <- terra::rast(rastfiles)
  
  Sys.sleep(timeSleep)
  
  #--------------------
  # Read in vector
  # transform shp1 to raster projection
  vpolyList1 <- list()
  
  for (y in 1:length(shp1)) {
    
    temp1 <- vect(st_read(shp1[y]))
    vpolyList1[[y]] <- project(temp1,r1)
    
  }
  
  #--------------------
  # Crop time series
  r2 <- crop(r1, vpolyList1[[1]])
  
  Sys.sleep(timeSleep)
  
  print("time series cropped")
  
  #--------------------
  # Read in QA pixels
  
  # Note: QA vaues range from 1 to 15.
  # See https://lpdaac.usgs.gov/documents/621/MOD13_User_Guide_V61.pdf for more info
  #r1QA <- terra::rast(rastfilesQA)
  
  #r1QAL <- list(terra::rast(rastfilesQA1),terra::rast(rastfilesQA2),terra::rast(rastfilesQA3), terra::rast(rastfilesQA4), terra::rast(rastfilesQA5), terra::rast(rastfilesQA6))
  #r1QAL <- raster(list(rastfilesQA1, rastfilesQA2)) # this won't work
  r1QAL <- list(terra::rast(rastfilesQA1),terra::rast(rastfilesQA2),terra::rast(rastfilesQA3), terra::rast(rastfilesQA4), terra::rast(rastfilesQA5), terra::rast(rastfilesQA6),
                terra::rast(rastfilesQA7), terra::rast(rastfilesQA8), terra::rast(rastfilesQA9) )
  
  Sys.sleep(timeSleep)
  
#stop("message stop")
  # Crop time series
  #r2QA <- crop(r1QA, vpolyList1[[1]])
  #nlyr(r2QA)
  
  r2QACL <- list()
  
  r2QACL <- foreach (j = 1:length(r1QAL)) %do%
    crop(r1QAL[[j]],vpolyList1[[1]])
  
  #saveRDS(r2QACL, paste0(outf3, periods1Labs[1], "/", "r2QACL.rds")) # I can't save rast object as RDS
  
print("QAs cropped")

  Sys.sleep(timeSleep)
  
  # Reclassify QA pixel, keep only good ones. See Samantha2010
  ## from-to-becomes
  m1 <- c(2, 3, NA) # MODLAND_QA. Include only QA scores from 0 & 1, rest NA.
  m2 <- c(7, 15, NA) # VI usefulness . Include only QA scores from 1 to 9, rest NA. This is 2 levels more conservative than Samantha2010
  m3 <- c(1, NA) # Include only QA scores 0, rest NA. Adjacent cloud detected, flag values must be equal to 0.
  m4 <- c(0, NA, 3, NA) # Aerosol Quantity . Include only QA scores 1, 2, rest NA. Exclude Climatology, High Aerosols TO FIX
  m5 <- c(1,NA) # Include only QA scores 0, rest NA. Mixed clouds flag values must be equal to 0.
  m6 <- c(1, NA) # Include only QA scores 0, rest NA. Possible shadow  flag values must be equal to 0.
  
  m7 <- c(1, NA) # Include only QA scores 0, rest NA. Atmosphere BRDF correction flag values must be equal to 0.
  m8 <- c(0, 0, NA, 2, 7, NA) # Include only QA scores 0, rest NA. Land/Water masks flag values must be equal to 1, rest NA.
  m9 <- c(1, NA) # Include only QA scores 0, rest NA.  Possible snow/ice  flag values must be equal to 0.
  
  
  
  rclMList <- list(matrix(m1, ncol=3, byrow=TRUE), matrix(m2, ncol=3, byrow=TRUE), matrix(m3, ncol=2, byrow=TRUE),
                   matrix(m4, ncol=2, byrow=TRUE),  matrix(m5, ncol=2, byrow=TRUE), matrix(m6, ncol=2, byrow=TRUE),
                   matrix(m7, ncol=2, byrow=TRUE), 
                   matrix(m8, ncol=3, byrow=TRUE),
                   matrix(m9, ncol=2, byrow=TRUE)
  )
  
  r2QACLC <- list()
  r2QACLC <- foreach (j = 1:length(r2QACL)) %do%
    classify(r2QACL[[j]], rclMList[[j]], include.lowest=TRUE, right=TRUE)
  
  
  # create SpatRasterDataset
  r2QAsds <- sds(r2QACLC)
  
  r2QAall <- app(r2QAsds, 'sum', na.rm=TRUE) # This may not work.
  
  # replace integer values with a new single value
  r2QAallMask <- ifel(r2QAall >=0, 1, r2QAall) #terra's ifel
  #plot(r2QAallMask[[1]], type="class")
  
  
  
  #-----------------------------------
  # Clean pixels, remove noisy pixels
  #-----------------------------------
  
  # this creates a list of rasters. The foreach function creates a list
  r1CL <- foreach (j= 1:nlyr(r2)) %do%
    mask(r2[[j]], r2QAallMask[[j]])
  
  Sys.sleep(timeSleep)

print("raster masked")
  
  # Read list of cleaned rasters
  r1C <- rast(r1CL)
  
  rm(r1CL)
  
  print("list of rasters removed")
  
  Sys.sleep(timeSleep)
  
  # # ---------------------
  # # Read in Land cover
  # # ---------------------
  # # Read land cover 2003
  # rLc <- terra::rast(fpath2)
  # 
  # rLc <- crop(rLc, project(vpolyList1[[1]],crs(rLc) )) # project vector rather than raster
  # 
  # # Reclassify Land cover to keep only forest
  # LcType1 <- read.csv(fpath4)
  # 
  # rclM2 <- as.matrix(LcType1[,c(1,3)]) # Note: I am also including wetland-treed
  # rLc2 <- classify(rLc,rclM2)
  # #rm(rLc)
  
  
  #-------------------------------
  # Mask out non-forest pixels
  #-------------------------------
  
  # # I can skip this for now
  # rLc3 <- project(rLc2, crs(r1C),  method='near', threads=TRUE)
  # 
  # rLc3 <- resample(rLc3 , r1C, method='near', threads=TRUE) # Is there a better method? I only have 1 and 0's here. method='q3' produces the same results
  # 
  # terra::ext(rLc3) <- terra::ext(r1C)
  # r3 <- mask(r1C, rLc3, maskvalue=0)
  # r4 <- mask(r3, rLc3, maskvalue=NA)
  
  # Count NAs
  # Note that some time series raster layers can have more or less NA values. The monthly time series should be more consistent.
  #global(r4, fun="isNA")
  
  #r4 <- r1C  
  
  r1Br <- raster::brick(r1C ) # I need to convert SpatRast object to raster object as Bfast needs the latter
  
  #saveRDS(r1Br, paste0(outf3, periods1Labs[1], "/", "r1Br.rds"))
  # writeRaster(r1Br, paste0(outf3, periods1Labs[1]))
  
  
  
  #-----------------------------------
  # Dates & Time series
  #-----------------------------------
  #Dates for period 2001-01-01 to 2025-12-31
  #this shows the human readable dates. E.g. 2003_001 as "2003-01-01"
  rDates <- MODIS::extractDate(paste0((sapply(strsplit(rastfilesNames, '_'), "[", 3)), (sapply(strsplit(rastfilesNames, '_'), "[", 4))),1, 7, asDate = TRUE)$inputLayerDates
  #rDates
  
  # Create data frane and transpose
  t1 <- t(as.data.frame(r1Br))
  
  # time-series
  rTs2 <- bfastts(t1, dates= rDates, type = c("16-day"))

print("ts created")
  
  dir.create(paste0(outf3, periods1Labs[z]))
  
  saveRDS(rTs2, paste0(outf3, periods1Labs[z], "/", "rTs2.rds")) # equivalent to rTs2_v2.rds in NDVI
  
  #rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/EVI_250m/bfast/period1/rTs2.rds")
  
  print("done") 
  
} # end of very long loop


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

#print(paste0("rows: ", nrow(rTs2), "cols: ", ncol(rTs2)))
#print("done")
