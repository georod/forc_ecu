#=================================================================================
# Trend Breakpoint Analysis using MODIS data - Short version Bfast Only
#=================================================================================
# 2026-05-27
# Peter R.

# Notes:
#   This version is to be run on DRAC (Compute Canada) using parallel computing
#   Study area: Southern Ecuador
#   The aim of this script is to produce BFAST outputs using MODIS NDVI & EVI
#   I use MODIS products at 250 m


start.time <- Sys.time()
start.time


#=================================
# Load libraries
# ================================
# install.packages(c("strucchangeRcpp", "bfast"))
#library(terra)
#library(sf)
library(bfast)
#install.packages("foreach")
library(foreach)
library(doParallel)
#install.packages("remotes")
#library(remotes)

#install.packages("stlplus")
library(stlplus)

#remotes::install_github("fdetsch/MODIS")

#library(MODIS)

#library(raster) # Install raster after terra to avoid package issues
#library(sqldf)


#=================================
# File paths and folders
# ================================

#setwd("~/projects/def-mfortin/georod/scripts/forc_trends") # github folder
#setwd("C:/Users/Peter R/Documents/st_trends_for_c/algonquin")

dataf <- "~/projects/def-mfortin/georod/data" # data folder

# MODIS files with original sinusoidal proj for period 2001-2023
#fpath <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/NDVI")
#fpath <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/EVI")


# Land cover
#fpath2 <- "~/projects/def-mfortin/georod/data/ont_out/ont_CA_forest_VLCE2_2003.tif"

# QA pixels folder
# fpath3_1 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_qual")
# fpath3_2 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_usef")
# fpath3_3 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_adj_cld")
# fpath3_4 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_aer")
# fpath3_5 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_mix_cld")
# fpath3_6 <- paste0(dataf,"/modis/algonquin_v2/modistsp/VI_16Days_250m_v61/QA_shd")


# CSV to reclassify land cover values to keep only forest pixels
#fpath4 <- "./misc/ca_forest_vlce2_lcover_type1_values.csv"

# Path to vector
#shp1 <- "./misc/shp/algonquin_envelope_500m_buff_v1.shp"
#shp1 <- "./misc/shp/algonquin_aoi3.shp"

# Output folders
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/")  # Note: h=0.5 run. Change back when done
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/LAI_500m/bfast/")  
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/FPAR_500m/bfast/")  
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/GPP_500m/bfast/")  
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/PSN_500m/bfast/")
outf3 <- paste0(dataf, "/forc_ecu/outputs/output_h5p/EVI_250m/bfast/period7/") # Note: Given the 25-years of data h=0.04

folder1 <- "EVI_250m"

#c("NDVI", "EVI")




#========================================
# Parallel processing settings
#========================================

# Code shared by Flavio A.
# Use the environment variable SLURM_CPUS_PER_TASK to set the number of cores.
# This is for SLURM. Replace SLURM_CPUS_PER_TASK by the proper variable for your system.
# Avoid manually setting a number of cores.
ncores = Sys.getenv("SLURM_CPUS_PER_TASK") 

registerDoParallel(cores=ncores)# Shows the number of Parallel Workers to be used
print(ncores) # this how many cores are available, and how many you have requested.
#getDoParWorkers()# you can compare with the number of actual workers



#======================================
# Time series loop
#======================================

timeSleep <- 3

#r1Br <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/period7/r1Br.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/period7/rTs2.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/period10/rTs2.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/period10/rTs2_v2.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/LAI_500m/bfast/output10/rTs2.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/FPAR_500m/bfast/output10/rTs2.rds")
rTs2 <- readRDS(paste0("~/projects/def-mfortin/georod/data/forc_ecu/outputs/timeseries/output_h5p/", folder1, "/bfast/period7/rTs2.rds"))

#rTs2 <- rTs2[, sample(1:125)]

  

  #-----------------------------------
  # Run BFast
  #-----------------------------------
  
  #dir.create(paste0(outf3, periods1Labs[z])) #Sensibility test for determining the effect of different period lenght (modifiable time unit problem)
  #dir.create(paste0(outf3, periods1Labs[z],"/errors")) #Sensibility test for determining the effect of different period lenght (modifiable time unit problem)
  
# For use in local, standard R session use %do%. When parellel environment use %dopar%

  # Biggest and all breaks and default Bfast output
  #allBrksbF0 <- list()

  #foreach (i=1:ncol(rTs2), .inorder=TRUE) %dopar% # %do% IN normal R you can use %dopar% as it won't work
    
allBrksbF0 <-  foreach (i=1:ncol(rTs2), .inorder=TRUE) %dopar% 
      
      {
        
        print(i) # print cell #
        
        bF0 <- try( bfast(
          rTs2[, i], 
          h = 0.04, #0.04 is 1 year when using a 25-yr time series
          season= c("harmonic"), #c("dummy") # harmonic worked nice for the monthly time series
          max.iter = 10,
          breaks = NULL,
          hpc = "foreach",
          level=0.01, # significance level
          decomp = c("stlplus"),
          type = "OLS-MOSUM"
          
        ))
        
        if(class(bF0) == "try-error") { 
          # This is to jump pixels with all NA values. The number of NAs needs to match the vars found below in 'else'
          
        as.data.frame(cbind(i, matrix(rep(NA, 9), nrow=1, ncol=9, byrow=FALSE)))
          
          
        } else {
          
          # forest cells with data
          
          # if trend break then
          if (bF0$nobp[[1]]==FALSE) {
            # all trend breaks 
            # var names: pixel, break, # of observations, # of interactions, time lower bound, time estimate, time upper bound, metric value right before break, metric values right after break, magnitude of break & direction
            as.data.frame(cbind(i, bF0$nobp[[1]], bF0$output[[length(bF0$output)]]$bp.Vt$nobs, length(bF0$output), 
                                matrix(cbind(time(rTs2[, i])[as.numeric(names(bF0$output[[length(bF0$output)]]$bp.Vt$y)[ifelse(as.vector(bF0$output[[length(bF0$output)]]$ci.Vt$confint) < 1, 1, ifelse(as.vector(bF0$output[[length(bF0$output)]]$ci.Vt$confint) > 460, 460, as.vector(bF0$output[[length(bF0$output)]]$ci.Vt$confint) ))])], as.vector(bF0$Mags) ), 
                                       nrow = length(bF0$output[[length(bF0$output)]]$bp.Vt$breakpoints), ncol = 6, byrow = FALSE, dimnames = NULL)))
            
            
          } else {
            # if no trend break then
            
            as.data.frame(cbind(i, 1, NA, NA, matrix(rep(NA, 6), nrow=1, ncol=6, byrow=FALSE)))
            
            
          }
          
          
        }
        
  
} 
  


Sys.sleep(timeSleep)

print(paste0("object length: ", length(allBrksbF0)))

saveRDS(allBrksbF0, paste0(outf3, "allBrksbF0.rds")) #period7 which means full ts length. In this case 25-yrs
  

end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

print("done")

