# Saved 24-observation stock input; no stock recalculation.
orchard_data <- read.csv(file.path(module_dir, "inputs", "orchard_cumulative_stock.csv"), stringsAsFactors=FALSE)
# factor() tells R that the four endpoints are categories, not a straight-line trend.
orchard_data$core <- factor(orchard_data$core)
orchard_data$site_type <- factor(orchard_data$site_type, levels=c("60-year-old orchard","20-year-old orchard"))
orchard_data$depth_cm <- factor(orchard_data$depth_cm, levels=c("0-10","10-20","20-50","50-75"))
# Actual endpoint coordinates are measured in units of 10 cm for numerical stability.
orchard_data$position <- numFactor(orchard_data$depth_bottom/10)
stopifnot(nrow(orchard_data)==24L, nlevels(orchard_data$core)==6L,
          all(table(orchard_data$site_type,orchard_data$depth_cm)==3L),
          all(is.finite(orchard_data$cumulative_c_stock)),all(orchard_data$cumulative_c_stock>0))
original_snapshot <- c(13.942235754431298,18.600059740824943,22.527758727984292,26.723056437416083,
6.721923919652653,9.1459295304051889,13.367746477309328,16.160976700865291,
16.60005071704035,18.457361817251115,21.43506287355185,24.623608496529361,
10.099708533512864,12.692490364016702,17.716564456543843,23.479335772483857,
9.9120786589043561,14.779032847515424,21.447818134080951,25.147702043032947,
8.7012238197466587,13.957370602132734,22.516452636427633,30.480218426150799)
cat("Maximum difference from original saved-model response:",max(abs(original_snapshot-orchard_data$cumulative_c_stock)),"\n")
stopifnot(max(abs(original_snapshot-orchard_data$cumulative_c_stock))<1e-12)
orchard_inputs_before <- serialize(orchard_data,NULL)
print(orchard_data[,c("core","depth_cm","cumulative_c_stock")],row.names=FALSE,digits=12)
cat("ORCHARD_CORRELATION_INPUTS_VERIFIED_NO_STOCK_RECALCULATION\n")
