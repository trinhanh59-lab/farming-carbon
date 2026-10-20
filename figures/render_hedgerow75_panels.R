#!/usr/bin/env Rscript
# Draw the three 0-75 cm hedgerow model panels from saved means and joint tests.
# No models, contrasts or diagnostics are recomputed by this script.
suppressPackageStartupMessages(library(ragg))
script_arg <- grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)
here <- dirname(normalizePath(sub("^--file=", "", script_arg)))
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=1L) stop("Usage: render_hedgerow75_panels.R NEW_OUTPUT_DIR")
output <- path.expand(args[[1]])
if(file.exists(output)||dir.exists(output)) stop("Output exists; choose a new directory.")
input <- file.path(here,"..","analysis","nonroot_current","saved_results")
means <- read.csv(file.path(input,"nonroot_plot_values.csv"),stringsAsFactors=FALSE)
tests <- read.csv(file.path(input,"nonroot_plot_marker_tests.csv"),stringsAsFactors=FALSE)
means <- means[means$system=="hedgerows",]
tests <- tests[tests$system=="hedgerows",]
depths <- c("0-10","10-20","20-50","50-75")
groups <- c("bare field margin","10-year-old hedgerow","30-year-old hedgerow")
colors <- c("#ECD693","#F7C548","#A98743")
stopifnot(nrow(means)==36L,nrow(tests)==12L,setequal(means$depth_cm,depths))
dir.create(output,recursive=TRUE)
specs <- list(
  c_percent=list(letter="b",width=950,height=840,left=184,top=110,bottom=690,
                 xrange=c(.2,3.2),ticks=1:3,label="C (%)"),
  cumulative_c_stock=list(letter="c",width=1000,height=810,left=234,top=80,bottom=660,
                 xrange=c(5,75),ticks=c(25,50,75),
                 label=expression("Cumulative C stock (t C ha"^{-1}*")")),
  del14c=list(letter="d",width=950,height=810,left=184,top=80,bottom=660,
                 xrange=c(-445,217),ticks=c(-400,-200,0,200),
                 label=expression(Delta^14*C~("\u2030"))))
for(response in names(specs)) {
  s <- specs[[response]]; right <- s$width-40
  z <- means[means$response==response,]; z$y <- 5-match(z$depth_cm,depths)
  t <- tests[tests$response==response,]; t$y <- 5-match(t$depth_cm,depths)
  stopifnot(nrow(z)==12L,nrow(t)==4L,all(z$lower_one_se>s$xrange[1]),
            all(z$upper_one_se<s$xrange[2]))
  ragg::agg_png(file.path(output,paste0("hedgerows_0_75_",s$letter,".png")),
                width=s$width,height=s$height,res=100,pointsize=23.5,background="white")
  par(plt=c(s$left/s$width,right/s$width,(s$height-s$bottom)/s$height,
            (s$height-s$top)/s$height),xaxs="i",yaxs="i",family="Arial",xpd=FALSE)
  plot(NA_real_,NA_real_,xlim=s$xrange,ylim=c(.4,4.6),axes=FALSE,ann=FALSE)
  box(col="#666666",lwd=1.2)
  axis(1,at=s$ticks,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.018)
  axis(2,at=4:1,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.015)
  for(i in seq_along(groups)) {
    zz <- z[z$site_type==groups[i],];zz <- zz[match(depths,zz$depth_cm),]
    segments(zz$lower_one_se,zz$y,zz$upper_one_se,zz$y,col=colors[i],lwd=2.4)
    lines(zz$estimate,zz$y,col=colors[i],lwd=2.4)
    points(zz$estimate,zz$y,col=colors[i],pch=16,cex=1.15)
  }
  # Symbols describe the unchanged unadjusted within-depth joint test.
  for(j in seq_len(nrow(t))) if(nzchar(t$symbol[j])) {
    zz <- z[z$depth_cm==t$depth_cm[j],]
    marker <- max(zz$upper_one_se)+.05*diff(s$xrange)
    text(marker,t$y[j],t$symbol[j],adj=c(0,.5),cex=1.12)
  }
  par(fig=c(0,1,0,1),mar=c(0,0,0,0),new=TRUE)
  plot(NA_real_,NA_real_,xlim=c(0,s$width),ylim=c(s$height,0),
       xaxs="i",yaxs="i",axes=FALSE,ann=FALSE)
  text(s$left+(s$ticks-s$xrange[1])/diff(s$xrange)*(right-s$left),s$bottom+39,
       labels=s$ticks,cex=.97)
  text(s$left-20,s$bottom-((4:1)-.4)/4.2*(s$bottom-s$top),depths,adj=c(1,.5),cex=.97)
  text(s$left,s$top-45,paste0("(",s$letter,")"),adj=c(0,.5),cex=1.08)
  if(response=="cumulative_c_stock") text(51,370,"Depth (cm)",srt=90,cex=1.08)
  text((s$left+right)/2,s$bottom+94,s$label,cex=1.08)
  invisible(dev.off())
}
message("Saved 0-75 cm hedgerow panels: ",output)
