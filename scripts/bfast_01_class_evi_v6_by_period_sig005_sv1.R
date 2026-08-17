#=================================================================================
# Trend Breakpoint Analysis using MODIS data - Classify Trend shift using EVI
# 
#=================================================================================
# 2026-05-27
# Peter R.

#Notes: 
# - Here I prepared this script to classify trends using EVI.
# - I am using h equal to a year of data. SO, h will change depending on the length of the ts. 
#   for 5-year ts h=0.2, for 20-yr t h=0.05, for 25-yr ts h=0.04
# - here I create a loop version to do all periods at once
# - Note that significance level for bfast01 is 0.01 but for bfast_classify is 0.05. This was done so that the results are more conservative and inline with what I did previously.

start.time <- Sys.time()
start.time



#detach("package:rlang", unload=TRUE)
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


# folder
folder1 <- "EVI_250m"

# Output folders
#outf3 <- paste0(dataf, "/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast01/")  # Note: h=0.5 run. Change back when done
outf3 <- paste0(dataf, "/forc_ecu/outputs/output_h1yr/EVI_250m/bfast01/")  # Note: h equals 1 yr of data


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
# Time series
#======================================

timeSleep <- 3

#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/NDVI_250m/bfast/period10/rTs2_v2.rds")
#rTs2 <- readRDS("~/projects/def-mfortin/georod/data/forc_trends_pj/algonquin/output_h5p/EVI_250m/bfast/period10/rTs2.rds")
rTs2 <- readRDS(paste0("~/projects/def-mfortin/georod/data/forc_ecu/outputs/timeseries_copy/output_h5p/", folder1, "/bfast/period7/rTs2.rds"))

  
#------------------------------------------------------
# BFAST_01: Classify breaks into different classes
#------------------------------------------------------
  
#outNames2 <- c("pix", "flag_type", "flag_significance",   "p_segment1", "p_segment2", "pct_segment1", "pct_segment2", "flag_pct_stable")

#bF1_01


#allBrksbF0_01 <- list()
#allBrksbF0_01_Class <- list()


  #foreach (i=1:200, .inorder=TRUE) %dopar% #200 for prototyping
  #foreach (i=1:ncol(rTs2), .inorder=TRUE) %dopar%  #%do% when local environment 

#periodLabs <- c("period1", "period2","period3","period4") #period8, period9, period10/7
#periodLabs <- c("period2","period3","period4") #period8, period9, period10/7
#periodLabs <- c("period5") #period8, period9, period10/7
#periodLabs <- c("period8") #period8

#periodLabs <- c("period1", "period2","period3","period4", "period5", "period6", "period7", "period8") 
periodLabs <- c("period1", "period2","period3","period4", "period5", "period7")

#startp1 <- c(2003, 1, 2008, 1, 2013, 1, 2018, 1) # 
#startp1 <- c(2008, 1, 2013, 1, 2018, 1) # 
#startp1 <- c(2003, 1) # 
startp1 <- c(2001, 1, 2006, 1, 2011, 1, 2016, 1, 2021, 1, 2001, 1)
startM <- matrix(startp1, ncol=2, byrow = TRUE)

#endp1 <- c(2007, 23, 2012, 23, 2017, 23, 2022, 23) # 
#endp1 <- c(2012, 23, 2017, 23, 2022, 23) # 
#endp1 <- c(2012, 23)
endp1 <- c(2005, 23, 2010, 23, 2015, 23, 2020, 23, 2025, 23, 2025, 23)
endM <- matrix(endp1, ncol=2, byrow = TRUE)

#band_val <- c(0.2, 0.2, 0.2, 0.2, 0.1, 0.1, 0.05, 0.067 )
band_val <- c(0.2, 0.2, 0.2, 0.2, 0.2,  0.04 ) # 5-yrs and 25 yrs

#c(startM[i,1], startM[i,2] )
#c(endM[i,1], endM[i,2] )

    
foreach (j=1:nrow(startM)) %do% {
  
  brksbF0_01_Class <- foreach (i=1:ncol(rTs2), .inorder=TRUE) %dopar%  {
      
         print(i) # print cell #
      
        bF0_01  <- try(bfast01( 
                              #window(rTs2[, i], start = c(2003, 1), end=c(2007, 23)),
                              window(rTs2[, i], start = c(startM[j,1], startM[j,2] ), end=c(endM[j,1], endM[j,2] )),
                              formula = NULL,
                              test = "OLS-MOSUM",
                              level = 0.01, # Used 0.05 as sig
                              aggregate = all,
                              trim = NULL,
                              bandwidth = band_val[j], # this bandwidth is h in bfast. For 5 yr ts h=0.2; for 10 yr ts h=0.1; for 15 yr ts h=0.066; for 20 yr ts h=0.05
                              functional = "max",
                              order = 3,
                              lag = NULL,
                              slag = NULL,
                              na.action = na.omit, #na.pass is not a valid option here
                              reg = c("lm"), # c("lm", "rlm"),
                              stl = "none",
                              sbins = 1
          
                        ) )
        
        if(class(bF0_01) == "try-error") {
          
        list( as.data.frame(cbind(i, matrix(rep(NA,2) , nrow=1, ncol=2, byrow=FALSE)) ),
              as.data.frame(cbind(i, matrix(rep(NA,7), nrow=1, ncol=7, byrow=FALSE))),
          
          as.data.frame(cbind(i, matrix(rep(NA,3), nrow=1, ncol=3, byrow=FALSE))),
          
          as.data.frame(cbind(i, matrix(rep(NA,8), nrow=1, ncol=8, byrow=FALSE)))
          
          )
          
        } else {
          
          
      
          bF1_01_Class <- bfast01classify(
          bF0_01,
          alpha = 0.05, # 
          pct_stable = 0.25, # 5 originally, sig005
          typology = c("standard")
            )
          
         list(as.data.frame(cbind(i, bF0_01$breaks, bF0_01$data[bF0_01$breakpoints, 1])),
          as.data.frame(cbind(i, bF1_01_Class)),
          
          # list with model 1 output: trends (no breaks)
          as.data.frame(cbind(i, nrow(bF0_01$data), bF0_01$model[[1]]$coefficients[[1]], bF0_01$model[[1]]$coefficients[[2]])),
          
          # list with model 2 output: breaks & trends 
          as.data.frame(cbind(i, nrow(bF0_01$data), bF0_01$model[[2]]$coefficients[[1]], bF0_01$model[[2]]$coefficients[[2]], bF0_01$model[[2]]$coefficients[[3]],
                              bF0_01$model[[2]]$coefficients[[4]], bF0_01$confint[[1]], bF0_01$confint[[2]], bF0_01$confint[[3]]))
          
          
          )
            
        }
        
       
      
      }
  
  print(paste0("length: ", length(brksbF0_01_Class)))
  
  dir.create(paste0(outf3, periodLabs[j]))

  saveRDS(brksbF0_01_Class, paste0(outf3, periodLabs[j], "/", "brksbF0_01_Class.rds")) 
  
  print(paste0("period ", j, ": done"))
  
  Sys.sleep(timeSleep)
  
  }
  
  


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


print("all loops done")
