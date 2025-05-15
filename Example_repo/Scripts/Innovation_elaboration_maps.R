##### SPATIAL DISTRIBUTION OF INNOVATION AND ELABORATION

### Investigating the global distribution of innovation and elaboration (I/E) in all the world's birds:
## Innovation and elaboration are evolutionary concepts coined by Endler et al. (2005) - https://academic-oup-com.sheffield.idm.oclc.org/evolut/article/59/8/1795/6756100
## Traits (here, bowerbird colour patterns) either evolve by elaborating on existing traits or innovating new traits.
## Guillerme et al. (2023) model multivariate bird traits to evaluate the magnitude & distribution of I/E - https://www-science-org.sheffield.idm.oclc.org/doi/10.1126/sciadv.adg1641
## Here, I investigate the spatial distribution of I/E in all birds for use in conservation.
## Explanatory variable = biome and anthropogenic factor (i.e. human population density)
## Response variable = changes in spatial distribution of I/E between regions.

## Packages required
# Spatial
library(sf)
library(raster)
library(fasterize)
library(terra)
library(tidyterra)
library(epm) # Trial epm method at end of script
# Analysis
library(dispRity)
library(dplyr)
# Plotting
library(ggplot2)
library(rasterVis) # Unused?
library(viridis)
library(patchwork)
library(ggspatial)
library(ggbeeswarm)

### ----------------------- ###
##### 1: DATA PREPARATION #####
### ----------------------- ###

### Set working directory:
setwd("/home/macrobird/Desktop/Elle/Github/Distribution-of-Innovation-and-Elaboration")

### Raw files required:
## BirdLife spatial distribution polygons for all birds : BirdLife International - https://datazone.birdlife.org/contact-us/request-our-data
all_birds <- st_read("Data/BOTW_2023_1/BOTW.gdb") #11184

## Matrix containing PCs of beak shape (raw trait data): Hughes et al. (2022) - https://onlinelibrary.wiley.com/doi/full/10.1111/ele.13905
load("Data/shapespace.rda")

## Bird species matched to their median innovation/elaboration score: Guillerme et al. (2023) - https://www-science-org.sheffield.idm.oclc.org/doi/10.1126/sciadv.adg1641
# Innovation and elaboration when projected on the variance/covariance (ellipse) of the whole bird phylogeny
# I_E <- read.csv("Data/species_list_final.csv")
# Innovation and elaboration when projected on the variance/covariance (ellipse) of the order or superorder
order_superorder <- read.csv("Data/elaboration_innovation_scale.csv")

## Filter innovation/elaboration data to only species with raw trait data
innovation_elaboration <- order_superorder %>%
  filter(species_Jetz %in% rownames(shapespace)) #8748

## Biome data polygon (TEOW): Olsen (2005) and WWF - https://www.worldwildlife.org/publications/terrestrial-ecoregions-of-the-world
# Make it a "SpatialPolygonsDataFrame" from sp
biomes <- st_read("Data/TEOW")
biomes <- as(biomes, 'Spatial')

## Biodiversity intactness index: PREDICTS - https://data.nhm.ac.uk/dataset/bii-bte?_gl=1*1kdzs44*_ga*MTcwODAwNjk3MC4xNzMzMjQ1NjAx*_ga_PYMKGK73C4*MTc0MTk2ODg3NC40LjAuMTc0MTk2ODg3NC4wLjAuMA
# ! Not currently using
# BII <- readRDS("Data/long_data.rds")

## Human population density data (geotiff): NASA - https://neo.gsfc.nasa.gov/view.php?datasetId=SEDAC_POP
HPD <- raster("Data/population_density_2020_30_min.tif")

## Taxomatch
# Match species from BirdLife by BirdTree taxonomy : Jetz et al. (2012) - https://birdtree.org/
# Using AVONET BirdLife - BirdTree crosswalk: Tobias et al. (2022) -  https://onlinelibrary.wiley.com/doi/10.1111/ele.13898
taxomatch_birds <- all_birds
taxomatch <- read.csv("Data/BirdLife-BirdTree crosswalk.csv")
taxomatch_birds$sci_name <- taxomatch$Species3[match(taxomatch_birds$sci_name, taxomatch$Species1)]
print(length(unique(taxomatch_birds$sci_name))) #9602

# Manually match remaining species
missing <- read.csv("Data/missing_species.csv")
missing$x <- gsub("_", " ", missing$x)
missing$y <- gsub("_", " ", missing$y)

missing_to_add <- missing[!missing$y %in% taxomatch_birds$sci_name, ]
rows_to_add <- all_birds[match(missing_to_add$x, all_birds$sci_name), ]
rows_to_add$sci_name <- missing_to_add$y

all_birds_matched <- rbind(taxomatch_birds, rows_to_add)
print(length(unique(all_birds_matched$sci_name))) #9871

## Filter spatial data to only species with I/E data
species_Jetz <- innovation_elaboration$species_Jetz
all_birds_matched$sci_name <- gsub(" ", "_", all_birds_matched$sci_name)

my_birds <- all_birds_matched %>%
  filter(sci_name %in% species_Jetz) #8466

## Filter again for only extant/probably extant, native/reintroduced and breeding/resident species
birds_filter <- my_birds %>%
  filter(presence %in% c(1, 2) & origin %in% c(1, 2) & seasonal %in% c(1, 2))

birds_filter$sci_name <- factor(birds_filter$sci_name) #8432

## Change multisurface geometries to multipolygons
birds_filter <- st_cast(birds_filter, "MULTIPOLYGON")

### ---------------------------------- ###
##### 2: GLOBAL DISTRIBUTION FIGURES #####
### ---------------------------------- ###

### Disparity calculations: 
## This code takes the morphospace from Guillerme at al and Hughes et al.
## It is the first 8 PCs of all variation in beak shape and was used to calculate I/E values.

## Filter for species with spatial data only
shapespace <- shapespace[rownames(shapespace) %in% birds_filter$sci_name, , drop = FALSE]

## Calculate disparity metric (Mean distance to centroid) for raw beak traits
# PC 1 - 8
traits <- shapespace[,1:8]
distances <- as.data.frame(dispRity(traits, metric= centroids)$disparity[[1]][[1]])
distances$species_Jetz <- rownames(traits) #8432

### Make a template raster:

## Set coordinates reference system (CRS) to the Berhmann equal area projection
EAproj <- "+proj=cea +lat_ts=30 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
birds_filter <- st_transform(birds_filter, crs = EAproj)

## Define resolution in meters (100000 = 100km)
resolution <- 100000

## Combine spatial data with metric data
# I/E data and dispRity calculations
mapping_data <- left_join(birds_filter, innovation_elaboration, by = c("sci_name" = "species_Jetz"))
mapping_data <- left_join(mapping_data, distances, by = c("sci_name" = "species_Jetz"))
st_write(mapping_data, "Data/mapping_data.gpkg", append=TRUE)

## Create empty raster template using terra
ext <- st_bbox(mapping_data)

template <- rast(
  xmin = ext["xmin"], xmax = ext["xmax"],
  ymin = ext["ymin"], ymax = ext["ymax"],
  resolution = resolution,
  crs = EAproj)

## Convert back to raster from terra
birds_raster <- raster(template)
writeRaster(birds_raster, "Data/birds_raster.grd")

### Read in data:
## Use "/mapping_data_global" or "/mapping_data" for order/superorder
mapping_data <- st_read("Data/mapping_data.gpkg")
birds_raster <- raster("Data/birds_raster.grd")

## Set biomes to correct CRS
biomes <- spTransform(biomes, EAproj)

### a) Figure 1.1. Global innovation distribution

## Assuming you have already created an empty raster of grid cells as a template

## Populate the empty raster with innovation values
# Sum of innovation per grid cell
innovation_raster_sum <- fasterize(mapping_data, birds_raster, field = "median_distance_centre_order", fun = "sum")

# Number of innovation values per grid cell (species richness)
innovation_raster_count <- fasterize(mapping_data, birds_raster, field = "median_distance_centre_order", fun = "count")

# Mean innovation per grid cell
# Calculate by duplicating the sum object and replacing it's values by the sum/counts
innovation_raster_mean <- innovation_raster_sum
values(innovation_raster_mean) <- values(innovation_raster_sum) / values(innovation_raster_count)

# Max value
innovation_raster_max <- fasterize(mapping_data, birds_raster, field = "median_innovation_order", fun = "max")

# Min value
innovation_raster_min <- fasterize(mapping_data, birds_raster, field = "median_innovation_order", fun = "min")

## Plot innovation scores
# Mask to extent of terrestrial biomes
innovation_masked <- mask(innovation_raster_mean, biomes)
F1.1 <- ggplot() +
  layer_spatial(innovation_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

raw_innovation_masked <- mask(innovation_raster_sum, biomes)
F1.1.2 <- ggplot() +
  layer_spatial(raw_innovation_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

max_innovation_masked <- mask(innovation_raster_max, biomes)
F1.1.3 <- ggplot() +
  layer_spatial(max_innovation_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

min_innovation_masked <- mask(innovation_raster_min, biomes)
F1.1.4 <- ggplot() +
  layer_spatial(min_innovation_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

### b) Figure 1.2. Global elaboration distribution

## The following code is the same as above for the remaining diversity metrics, but with less annotation

## Populate the empty raster with elaboration values
elaboration_raster_sum <- fasterize(mapping_data, birds_raster, field = "median_elaboration_order", fun = "sum")
elaboration_raster_count <- fasterize(mapping_data, birds_raster, field = "median_elaboration_order", fun = "count")

elaboration_raster_mean <- elaboration_raster_sum
values(elaboration_raster_mean) <- values(elaboration_raster_sum) / values(elaboration_raster_count)

elaboration_raster_max <- fasterize(mapping_data, birds_raster, field = "median_elaboration_order", fun = "max")
elaboration_raster_min <- fasterize(mapping_data, birds_raster, field = "median_elaboration_order", fun = "min")

## Plot elaboration scores
elaboration_masked <- mask(elaboration_raster_mean, biomes)
F1.2 <- ggplot() +
  layer_spatial(elaboration_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

raw_elaboration_masked <- mask(elaboration_raster_sum, biomes)
F1.2.2 <- ggplot() +
  layer_spatial(raw_elaboration_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

max_elaboration_masked <- mask(elaboration_raster_max, biomes)
F1.2.3 <- ggplot() +
  layer_spatial(max_elaboration_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

min_elaboration_masked <- mask(elaboration_raster_min, biomes)
F1.2.4 <- ggplot() +
  layer_spatial(min_elaboration_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

### c) Figure 1.3. Global functional diversity distribution

## Populate the empty raster with elaboration values
disparity_raster_sum <- fasterize(mapping_data, birds_raster, field = "V1", fun = "sum")
disparity_raster_count <- fasterize(mapping_data, birds_raster, field = "V1", fun = "count")

disparity_raster_mean <- disparity_raster_sum
values(disparity_raster_mean) <- values(disparity_raster_sum) / values(disparity_raster_count)

disparity_raster_max <- fasterize(mapping_data, birds_raster, field = "V1", fun = "max")
disparity_raster_min <- fasterize(mapping_data, birds_raster, field = "V1", fun = "min")

## Plot disparity scores
disparity_masked <- mask(disparity_raster_mean, biomes)
F1.3 <- ggplot() +
  layer_spatial(disparity_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

raw_disparity_masked <- mask(disparity_raster_sum, biomes)
F1.3.2 <- ggplot() +
  layer_spatial(raw_disparity_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

max_disparity_masked <- mask(disparity_raster_max, biomes)
F1.3.3 <- ggplot() +
  layer_spatial(max_disparity_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

min_disparity_masked <- mask(disparity_raster_min, biomes)
F1.3.4 <- ggplot() +
  layer_spatial(min_disparity_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

### d) Figure 1.4. Global species richness distribution

## Populate the empty raster with number of species per grid cell
mapping_data$sci_name <- factor(mapping_data$sci_name)
richness_raster <- fasterize(mapping_data, birds_raster, field="sci_name", fun="count")

## Plot richness scores
richness_masked <- mask(richness_raster, biomes)
F1.4 <- ggplot() +
  layer_spatial(richness_masked) +
  scale_fill_viridis(name="", na.value = "NA", direction = 1, option = "D") +
  theme(legend.position = "bottom", 
        legend.text = element_text(size = 18)) +
  guides(fill = guide_colourbar(barwidth = 25))

## Patchwork figure 1 - mean/sum/max/min
mean_order <- (F1.1 + F1.2) / (F1.3 + F1.4)
raw_order <- (F1.1.2 + F1.2.2) / (F1.3.2 + F1.4)
max_order <- (F1.1.3 + F1.2.3) / (F1.3.3 + F1.4)
min_order <- (F1.1.4 + F1.2.4) / (F1.3.4 + F1.4)

### !!!!!!!!!! DO NOT USE !!!!!!!!!

## Crop and mask
#for (biome in 1:14) {
  
  ## Get the correct biome object
 # biome_n <- get(paste0("biome", biome))
  
  ## Crop raster to match the extent of the biome
  ## Then, mask to pull out chosen biome
  #HPD_crop <- crop(HPD_raster, extent(biome_n))
  #HPD_masked <- mask(HPD_crop, biome_n)
  
  ## Make copy of raster for each biome
  #assign(paste0("biome", biome, "HPD_masked"), HPD_masked)
#}
