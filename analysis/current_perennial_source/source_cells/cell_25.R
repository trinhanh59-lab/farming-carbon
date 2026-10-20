# Machine-readable detail for the online audit record; no data are altered.
# Original observations and all valid within-layer contrasts remain inspectable.
cat("SAME_SAMPLE_INPUT_JSON_BEGIN\n")
cat(toJSON(ss_input_readback,dataframe="rows",auto_unbox=TRUE,digits=16,na="null"))
cat("\nSAME_SAMPLE_INPUT_JSON_END\n")
for(s in names(ss_results)) {
  cat("SAME_SAMPLE_LAYER_JSON_BEGIN:",s,"\n",sep="")
  cat(toJSON(ss_results[[s]]$layers,dataframe="rows",auto_unbox=TRUE,digits=16,na="null"))
  cat("\nSAME_SAMPLE_LAYER_JSON_END\n")
}
cat("SAME_SAMPLE_DETAIL_RECORDED\n")
