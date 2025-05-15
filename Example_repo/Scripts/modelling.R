### Modelling

## Libraries required
library(tidyverse)
library(ggfortify)
library(effectsize)
library(sjPlot)

## Read in data
global <- read.csv("Data/global_HPD.csv")
superorder <- read.csv("Data/superorder_HPD.csv")
order <- read.csv("Data/order_HPD.csv")
old_order <- read.csv("Data/all_order_HPD.csv")

ggplot(order, aes(x = Species_Richness, y = Innovation_mean)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE, color = "blue") +
  labs(
    x = "Species Richness",
    y = "Mean Innovation per 100km grid cell",
  ) +
  theme_minimal()

## Global
global$grid_ID <- as.character(global$grid_ID)
global$Biome <- paste0("B", global$Biome)

## Superorder
superorder$grid_ID <- as.character(superorder$grid_ID)
superorder$Biome <- paste0("B", superorder$Biome)

## Order
order$grid_ID <- as.character(order$grid_ID)
order$Biome <- paste0("B", order$Biome)

ggplot(order, aes(x=Biome, y=HPD_log10, fill=Biome)) +
  geom_boxplot() +
  scale_fill_viridis_d(name="", na.value = "NA", na.translate = FALSE, direction = 1, option = "D") +
  ylab("Human population density (log10(HPD + 1))") + xlab("Biome-1") + 
  theme_bw()+
  theme(legend.position = "none")

##### ---------------------------- #####
### ALL BIRDS Biome-1 AND HPD - GLOBAL ###
##### ---------------------------- #####

### BIOME

## glm
innov_glm <- glm(Innovation ~ Biome-1, data = allglobal, family = Gamma(link = "log"))
standardize_parameters(innov_glm)
summary(innov_glm)
anova(innov_glm)

elab_glm <- glm(Elaboration ~ Biome-1, data = allglobal, family = Gamma(link = "log"))
summary(elab_glm)
standardize_parameters(elab_glm)
anova(elab_glm)

fd_glm <- glm(Disparity ~ Biome-1, data = allglobal, family = Gamma(link = "log"))
summary(fd_glm)
standardize_parameters(fd_glm)
anova(fd_glm)

sr_glm <- glm(Species_Richness ~ Biome-1, data = allglobal, family = Gamma(link = "log"))
summary(sr_glm)
standardize_parameters(innov_glm)
anova(sr_glm)

### BIOME*HPD

# glm
innov_glm_hpd <- glm(Innovation ~ Biome-1 * HPD_log10, data = global, family = Gamma(link = "log"))
summary(innov_glm_hpd)
anova(innov_glm_hpd)

elab_glm_hpd <- glm(Elaboration ~ Biome-1 * HPD_log10, data = global, family = Gamma(link = "log"))
summary(elab_glm_hpd)
anova(elab_glm_hpd)

fd_glm_hpd <- glm(Disparity ~ Biome-1 * HPD_log10, data = global, family = Gamma(link = "log"))
summary(fd_glm_hpd)
anova(fd_glm_hpd)

sr_glm_hpd <- glm(Species_Richness ~ Biome-1 * HPD_log10, data = global, family = Gamma(link = "log"))
summary(sr_glm_hpd)
anova(sr_glm_hpd)
