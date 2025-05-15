# Open Research & FAIR Data: A Day for Reproducibility and Transparent Workflows

## Workshop pitch:

We are going to try to sort out a repository to make it reusable and reproducible to adhere to FAIR data principles.
The idea here is to learn tips and tools to facilitate this workflow so that you can apply it to your current project or to your future projects.
This is not about criticising or ranking who does or doesn't do reproducible workflows!

We will be looking at three main aspects:

 1. Writing instructions for people to reproduce your work (for other workers and for future you!): the README file.
 <!-- TODO: include here the lego workshop? -->

 2. Sharing your data so that everyone can re-use it and understand it (mainly future you!)
 <!-- TODO: find an activity idea: maybe the README file workshop ZZ did? -->
 
 3. Sharing your code so that everyone can re-use it in the future.
 <!-- TODO: maybe some kind of discussion/workshop on making shell scripts for package installations? Also discussion on how much is needed for making things reproducible: e.g. README + correct path + library versions = necessary, Docker = overkill -->

### Use your own project!

For this workshop we will be using the work of Elle Quinn that's wrapping up her masters project on the global distribution of new diversity metrics. In very brief: Elle is looking how different diversity metrics (species richness, functional diversity and traits innovation and elaboration) are distributed across the globe for all birds species and whether some spatial distribution patterns correlate with human activities.

For the purpose of this workshop though, we won't need to know much of the details and the methods used in her excellent work. Here we will use a version of her work repository that we slightly modified for illustrating the points we want to teach. **We really encourage you to apply what we are going to learn today directly to your own project or, to a project you are thinking of starting so you get the good habits early**. If you don't have a project you want/can currently work on, you can use a simplified copy of Elle's work [here](https://github.com/TGuillerme/ReproducibleWork/tree/main/Example_repo/). If you don't have a laptop or just want to listen, you can pair up with a colleague in the room!

The exercise here will not be about correcting anyone's work (especially Elle's) but rather in rearrange files and adding description so that the work will be easier to share and reproduce in the future.


<!-- TODO: Thomas: share a "simplified" version of Elle's repository:

Need the following data:

## Modeling script:

global <- read.csv("Data/global_HPD.csv")
superorder <- read.csv("Data/superorder_HPD.csv")
order <- read.csv("Data/order_HPD.csv")
old_order <- read.csv("Data/all_order_HPD.csv")

## Map script:
all_birds <- st_read("Data/BOTW_2023_1/BOTW.gdb") #11184
load("Data/shapespace.rda")
order_superorder <- read.csv("Data/elaboration_innovation_scale.csv")
biomes <- st_read("Data/TEOW")
HPD <- raster("Data/population_density_2020_30_min.tif")
taxomatch <- read.csv("Data/BirdLife-BirdTree crosswalk.csv")
missing <- read.csv("Data/missing_species.csv")
 -->