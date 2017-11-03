library(tidyverse)
library(fastICA)

pca_reduce <- function(pca_data, ncomp) {
  result <- pca_data$x[,1:ncomp] %*% t(pca_data$rotation[,1:ncomp])
  
  #and add the center (and re-scale) back to data
  if(pca_data$scale != FALSE){
    result <- scale(result, center = FALSE , scale=1/pca_data$scale)
  }
  if(pca_data$center != FALSE){
    result <- scale(result, center = -1 * pca_data$center, scale=FALSE)
  }
  result
}

map_plot <- function(data) {
  ggplot(data, aes(x, y, fill = value)) + 
    geom_raster() +
    viridis::scale_fill_viridis() +
    scale_y_reverse() +
    coord_equal() +
    theme_minimal() +
    theme(
      axis.text = element_blank(), 
      axis.ticks = element_blank(), 
      axis.title = element_blank(), 
      legend.position = "none"
    )
}  

map3spread <- raman171027 %>% 
  filter(files == "GrNH2 map 3 high region.txt") %>% 
  select(x, y, wavenumber, intensity) %>% 
  spread(key = wavenumber, value = intensity)

coordinates <- map3spread %>% select(x, y)

map3mat <- map3spread %>% select(-x, -y) %>% as.matrix()


map3mat_pca <- prcomp(map3mat, center = TRUE, scale. = TRUE)


tibble(eigs = (map3mat_pca$sdev^2)) %>% 
  mutate(exp_var = round(eigs / sum(eigs)*100,3), n = 1:n()) %>% 
  mutate(cum_exp_var = cumsum(exp_var)) %>% 
  View()


plot(as.numeric(colnames(map3mat)), map3mat_pca$rotation[,"PC1"], type = 'l')




data_trunc <- pca_reduce(map3mat_pca, ncomp = 20)
dim(data_trunc); dim(map3mat)

as_tibble(data_trunc) %>% 
  summarise_all(funs(mean(.))) %>% 
  gather(key = wavenumber, value = intensity, convert = TRUE) %>% 
  ggplot(aes(wavenumber, intensity)) + 
  geom_line()



#---- Perform ICA on truncated data object
set.seed(1)
data.ica <- fastICA(X = as.matrix(data_trunc), n.comp = 2)
#data.ica$A # Estimated mixing matrix
#data.ica$S # Estimated source matrix
# 
# data.ica.res <- bind_cols(coordinates, as_tibble(data.ica$S))
# 
# ica_res <- data.ica.res %>% 
#   gather(key = "IC", value = "value", -x, -y) %>% 
#   group_by(IC) %>% 
#   nest() %>% 
#   mutate(plot = map(data, map_plot))
# 
# gridExtra::grid.arrange(grobs = ica_res$plot, ncol = 1)
# 

bind_cols(tibble(w = as.numeric(colnames(map3mat))), as_tibble(data.ica$A %>% t())) %>% 
  gather(key = IC, value = int, -w) %>% 
  ggplot(aes(w, int, color = IC)) + 
  geom_line() +
  facet_wrap(~IC, ncol = 1, scales = "free_y")
