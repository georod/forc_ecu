#=================================================================================
# Create BFAST01 & BFAST CLASSIFY rasters
#=================================================================================
# 2026-06-03
# Peter R.
# 
# - Study area: Southern Ecuador
# - Script meant to be run locally or on DRAC
# - Not that the script run on DRAC has bfast01 level=0.01 and bfastClassify level=0.05
# - This version was created tocreate raster by periods.
# - The rasters are not masked. They have to be masked to line up with the study area. Clipped was done in previous step.
# - Only bfastclassify objects are converted to rasters (not bfast01)


#=================================
# Load libraries
# ================================
# install.packages(c("strucchangeRcpp", "bfast"))
library(terra)
library(sf)
#library(bfast)
#install.packages("foreach")
library(foreach)


#setwd("/home/georod/projects/def-mfortin/georod/data/forc_ecu/")

outf4 <- "/home/georod/projects/def-mfortin/georod/data/forc_ecu/outputs/output_h1yr/EVI_250m/rasters/" 

#outf4 <- "C:/Users/Peter R/Documents/st_trends_for_c/algonquin/version3/output/EVI_250m/bfast01/"
#outf4 <- "C:/Users/Peter R/Documents/st_trends_for_c/algonquin/output_h1yr/EVI_250m/bfast01/"

frq1 <- "16d"
#prefix1 <- c("EVI_")
#folder1 <- "EVI_250m"
#prefix0 <- c("p")


# object downloaded from DRAC. 
# This object (brksbF0_01_Class.rds) is a list with two lists, one holds the selected output of bfast01 and the other of bfast01classify
# This has a p-value=0.05
#brksbF0_01_Class <- readRDS("C:/Users/Peter R/Documents/st_trends_for_c/algonquin/output_h5p/NDVI_250m/bfast01/period7/brksbF0_01_Class.rds") 

# This object was created with p-value=0.01
#brksbF0_01_Class <- readRDS("C:/Users/Peter R/Documents/st_trends_for_c/algonquin/output_h5p/NDVI_250m/bfast01/period7/brksbF0_01_Class_sv1.rds") 

#brksbF0_01_Class <- readRDS("C:/Users/Peter R/Documents/st_trends_for_c/algonquin/output_h5p/EVI_250m/bfast01/period7/brksbF0_01_Class_sv2.rds") 


#periodLabs <- c("period1", "period2","period3","period4", "period5") 
periodLabs <- c("period7") 

#periodNums <- c(1,2,3,4,5)

# This is a shortcut so that I do not have to create r2 raster again
#r2_template <- rast("C:/Users/Peter R/Documents/st_trends_for_c/algonquin/r2_template.tif")
r2_template <- rast("/home/georod/projects/def-mfortin/georod/data/forc_ecu/inputs/r2_template.tif")

 
foreach (k= 1) %do% {

#brksbF0_01_Class <- readRDS(paste0("C:/Users/Peter R/Documents/st_trends_for_c/algonquin/output_h1yr/EVI_250m/bfast01/period", k, "/brksbF0_01_Class.rds"))

brksbF0_01_Class <- readRDS(paste0("/home/georod/projects/def-mfortin/georod/data/forc_ecu/outputs/output_h1yr/EVI_250m/bfast01/period", k+6, "/brksbF0_01_Class.rds"))

# The first element of the list contains the results of Bfast01. Not needed to create rasters
#l1 <- lapply(brksbF0_01_Class, `[[`, 1)
#outNames1 <- c("pix", "brk", "time")
#l1Df <- do.call(rbind, lapply(l1, setNames, outNames1))

#head(l1Df)
#dim(l1Df)
#dim(l1Df[which(l1Df$brk>0),])
#dim(l1Df[which(l1Df$brk==0),])
#dim(l1Df[is.na(l1Df$brk),])

#The second element contains the trend classification part
l2 <- lapply(brksbF0_01_Class, `[[`, 2)
outNames2 <- c("pix", "flag_type", "flag_significance",   "p_segment1", "p_segment2", "pct_segment1", "pct_segment2", "flag_pct_stable")
l2Df <- do.call(rbind, lapply(l2, setNames, outNames2)) # lapply part standardizes names so they can be rbinded
# head(l2Df)
# table(l2Df$flag_significance)
# table(l2Df$flag_type, l2Df$flag_significance)
# class(l2Df)
#table(l2Df[c(2,3)])

#str(l1Df)
#summary(l1Df)
#sample
#l2Df[sample(nrow(l2Df), 10), ]


# only keep key variables for raster creation
# Note: the extent of the raster is bigger than my study area. Whem doing stats make sure you clip it using the study bbox.

pix1 <- l2Df[c(1,2,3)]
pix1$flag_type_sig <- ifelse(pix1$flag_significance!=3, pix1$flag_type, NA)
#pix1$flag_type_sig2 <- 1

pix1 <- pix1[c(1,4)] # select pix & flag_type_sig only


foreach (i=1:ncol(pix1)) %do% {
    
    rPix <- rast(matrix(pix1[,i], nrow=nrow(r2_template), ncol=ncol(r2_template), byrow=T)) #For Bfast01 classify, no reverse order is needed
    crs(rPix) <- crs(r2_template)
    #crs(rPix) <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs "
    terra::ext(rPix) <- terra::ext(r2_template)
    
    if(names(pix1)[i] %in% c('pix', 'flag_type_sig')) {
      

     # dir.create(outf4, periodLabs[k])
      writeRaster(rPix, paste0(outf4, periodLabs[k], "/",  names(pix1)[i], "_" , frq1, ".tif"), overwrite=FALSE)
     
      
      
    } else {
      
      # This is for numeric/continuous variables. Not really needed for BfastClassify
#      writeRaster(rPix, paste0(outf4, periodLabs[k], "/", prefix1, names(pix1)[i], "_" , frq1, ".tif"), overwrite=FALSE)

 #dir.create(paste0(outf4, periodLabs[k]))
 writeRaster(rPix, paste0(outf4, periodLabs[k], "/", names(pix1)[i], "_" , frq1, ".tif"), overwrite=FALSE)    
      
    }
    
    }
    print(paste0("period: ", k, " done"))
  }
