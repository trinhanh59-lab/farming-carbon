#!/usr/bin/env Rscript
# Redraw Figures 2-4 from saved publication values with consistent typography.
# This script does not fit models, compute contrasts or run statistical tests.
suppressPackageStartupMessages({library(grid); library(ragg); library(systemfonts)})
script_arg <- grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)
here <- dirname(normalizePath(sub("^--file=", "", script_arg)))
root <- normalizePath(file.path(here, ".."))
args <- commandArgs(trailingOnly=TRUE)
orchard_stock_only <- "--orchard-stock-only" %in% args
args <- args[args != "--orchard-stock-only"]
out <- if(length(args)) path.expand(args[[1]]) else file.path(here,"regenerated","profile_figures")
readback <- if(length(args)>1L) path.expand(args[[2]]) else file.path(out,"plotting_data")
if(file.exists(out)) stop("Output exists; choose a new output directory.")
dir.create(out,recursive=TRUE)
dir.create(readback,recursive=TRUE,showWarnings=FALSE)
font_names <- unique(systemfonts::system_fonts()$family)
font <- if("Arial" %in% font_names) "Arial" else if("DejaVu Sans" %in% font_names) "DejaVu Sans" else stop("Arial or DejaVu Sans is required.")
width_in <- 6.5; height_in <- 6.1; dpi <- 300
axis_pt <- 9; tick_pt <- 8.5; legend_pt <- 8.5; tag_pt <- 11
options(digits=17)
read_saved <- function(rel) read.csv(file.path(root,rel),stringsAsFactors=FALSE,check.names=FALSE)
annual_path <- "analysis/figure2_review/figure2a_display_values.csv"
annual_test_path <- "analysis/figure2_review/figure2a_significance_values.csv"
root_path <- "analysis/observed_profile_figures/observed_perennial_root_profiles_60.csv"
nonroot_path <- "analysis/nonroot_current/saved_results/nonroot_plot_values.csv"
test_path <- "analysis/nonroot_current/saved_results/nonroot_plot_marker_tests.csv"
annual <- read_saved(annual_path); annual_tests <- read_saved(annual_test_path)
observed_roots <- read_saved(root_path)
nonroot <- read_saved(nonroot_path); tests <- read_saved(test_path)
stopifnot(nrow(annual)==12L,nrow(annual_tests)==6L,nrow(observed_roots)==60L,
          nrow(nonroot)==96L,nrow(tests)==42L,
          all(annual$added_mass_g==0.00017),all(observed_roots$addition_g==0))
systems <- c("annual vegetables","orchards","hedgerows")
depths <- list(c("0-10","10-20","20-30","30-40","40-50","50-100"),
               c("0-10","10-20","20-50","50-75"),c("0-10","10-20","20-50","50-75"))
groups <- list(c("monoculture","polyculture"),c("20-year-old orchard","60-year-old orchard"),
               c("bare field margin","10-year-old hedgerow","30-year-old hedgerow"))
colors <- c(monoculture="#8C9C6D",polyculture="#4C6B5F",
            "20-year-old orchard"="#E28065","60-year-old orchard"="#AB3F21",
            "bare field margin"="#ECD693","10-year-old hedgerow"="#F7C548","30-year-old hedgerow"="#A98743")
labels <- c(monoculture="monoculture",polyculture="polyculture",
            "20-year-old orchard"="20-year","60-year-old orchard"="60-year",
            "bare field margin"="bare margin","10-year-old hedgerow"="10-year","30-year-old hedgerow"="30-year")

# Absolute positions preserve the current 2x2 publication panel frames.
frames <- list(a=c(234,960,110,690),b=c(1184,1910,110,690),
               c=c(234,960,920,1500),d=c(1184,1910,920,1500))
px_x <- function(x) x/1950
px_y <- function(y) 1-y/1830
text_at <- function(label,x,y,size=tick_pt,just="centre",rot=0) {
  grid.text(label,x=px_x(x),y=px_y(y),just=just,rot=rot,
            gp=gpar(fontfamily=font,fontsize=size,col="black"))
}

# Superscripts use raised Arial glyphs rather than a fallback font.
rich_label <- function(parts,x,y) {
  grobs <- lapply(parts,function(p) textGrob(p[[1]],gp=gpar(fontfamily=font,fontsize=p[[2]],col="black")))
  widths <- vapply(grobs,function(g) convertWidth(grobWidth(g),"inches",valueOnly=TRUE),numeric(1))
  left <- px_x(x)-sum(widths)/width_in/2
  for(i in seq_along(parts)) {
    grid.text(parts[[i]][[1]],x=left+sum(widths[seq_len(i-1L)])/width_in,
              y=px_y(y)+parts[[i]][[3]]/72/height_in,just=c("left","centre"),
              gp=gpar(fontfamily=font,fontsize=parts[[i]][[2]],col="black"))
  }
}
axis_label <- function(response,x,y) {
  if(response=="root") {
    text_at("Recovered root mass density",x,y-18,axis_pt)
    rich_label(list(list("(mg cm",axis_pt,0),list("-3",axis_pt*.7,3),list(")",axis_pt,0)),x,y+25)
  } else if(response=="c_percent") text_at("C (%)",x,y,axis_pt)
  else if(response=="cumulative_c_stock") rich_label(list(list("Cumulative C stock (t C ha",axis_pt,0),list("-1",axis_pt*.7,3),list(")",axis_pt,0)),x,y)
  else rich_label(list(list("\u0394",axis_pt,0),list("14",axis_pt*.7,3),list("C (\u2030)",axis_pt,0)),x,y)
}

prepare_panel <- function(si,letter) {
  system <- systems[si]; response <- c(a="root",b="c_percent",c="cumulative_c_stock",d="del14c")[[letter]]
  if(letter=="a" && si==1L) {
    z <- data.frame(management=annual$management,core="",depth=annual$depth,
       value=annual$display_mean,se=annual$SE,lower_one_se=annual$display_lower_one_SE,
       upper_one_se=annual$display_upper_one_SE,profile_symbol_index=1L,
       role="fitted annual root mean, added density subtracted for display",source=annual_path)
    m <- data.frame(depth=annual_tests$comparison,symbol=annual_tests$symbol,source=annual_test_path)
  } else if(letter=="a") {
    q <- observed_roots[observed_roots$system==system,,drop=FALSE]
    z <- data.frame(management=q$management,core=q$core,depth=q$depth_interval_cm,value=q$observed_density_mg_cm3,
         se=NA_real_,lower_one_se=NA_real_,upper_one_se=NA_real_,profile_symbol_index=q$profile_symbol_index,
         role="observed root core increment",source=root_path)
    m <- data.frame(depth=character(),symbol=character(),source=character())
  } else {
    q <- nonroot[nonroot$system==system & nonroot$response==response,,drop=FALSE]
    z <- data.frame(management=q$site_type,core="",depth=q$depth_cm,value=q$estimate,se=q$se,
         lower_one_se=q$lower_one_se,upper_one_se=q$upper_one_se,profile_symbol_index=1L,
         role="fitted mean with one model-based SE",source=nonroot_path)
    t <- tests[tests$system==system & tests$response==response,,drop=FALSE]
    m <- data.frame(depth=t$depth_cm,symbol=t$symbol,source=test_path)
  }
  z$figure <- si+1L;z$panel <- letter;z$system <- system;z$response <- response
  z$y <- length(depths[[si]])+1L-match(z$depth,depths[[si]])
  m$figure <- rep(si+1L,nrow(m));m$panel <- rep(letter,nrow(m))
  m$system <- rep(system,nrow(m));m$response <- rep(response,nrow(m))
  m$y <- length(depths[[si]])+1L-match(m$depth,depths[[si]])
  if(nrow(m)) {
    m$marker_x <- vapply(m$depth,function(d) {
      a<-z[z$depth==d,,drop=FALSE];hi<-max(a$upper_one_se);lo<-min(a$lower_one_se)
      hi+.24*max(hi-lo,abs(hi)*.08,1e-8)
    },numeric(1))
  } else m$marker_x <- numeric()
  if(si==1L && letter=="a") {xr<-c(-.01,.36);xt<-c(0,.1,.2,.3);m$marker_x<-.334}
  else if(letter=="a") {largest<-max(z$value);xr<-c(-.035*largest,1.10*largest);xt<-pretty(c(0,largest),n=4);xt<-xt[xt>=0 & xt<xr[2]]}
  else if(si==2L && letter=="c") {xr<-c(0,34);xt<-c(0,10,20,30)}
  else if(si==3L) {
    xr<-switch(letter,b=c(.2,3.2),c=c(5,75),d=c(-445,217))
    xt<-switch(letter,b=1:3,c=c(25,50,75),d=c(-400,-200,0,200))
    m$marker_x<-vapply(m$depth,function(d) max(z$upper_one_se[z$depth==d])+.05*diff(xr),numeric(1))
  } else {
    rr<-range(z$lower_one_se,z$upper_one_se,m$marker_x)
    xr<-rr+c(-.05,.30)*diff(rr)
    xt<-if(si==1L) switch(letter,b=c(.25,.5,.75),c=c(10,20,30,40),d=c(-200,-100,0)) else switch(letter,b=c(.5,1,1.5),d=c(-100,0,100))
  }
  list(data=z,markers=m,response=response,xrange=xr,ticks=xt)
}

draw_panel <- function(p,si,letter) {
  f<-frames[[letter]];n<-length(depths[[si]]);yr<-c(.4,n+.6)
  vx<-px_x(f[1]);vy<-px_y(f[4]);vw<-px_x(f[2]-f[1]);vh<-(f[4]-f[3])/1830
  grid.rect(x=vx,y=vy,width=vw,height=vh,just=c("left","bottom"),gp=gpar(fill=NA,col="#666666",lwd=.9))
  pushViewport(viewport(x=vx,y=vy,width=vw,height=vh,just=c("left","bottom"),xscale=p$xrange,yscale=yr,clip="on"))
  if(si==1L && letter=="a") grid.lines(x=unit(c(0,0),"native"),y=unit(yr,"native"),gp=gpar(col="#D7D7D7",lty=2,lwd=.7))
  z<-p$data;observed<-any(nzchar(z$core))
  for(management in groups[[si]]) {
    keys<-if(observed) sort(unique(z$core[z$management==management])) else ""
    for(core in keys) {
      q<-z[z$management==management & z$core==core,,drop=FALSE]
      q<-q[match(depths[[si]],q$depth),,drop=FALSE]
      index<-unique(q$profile_symbol_index);stopifnot(length(index)==1L)
      if(!observed) grid.segments(x0=unit(q$lower_one_se,"native"),x1=unit(q$upper_one_se,"native"),
              y0=unit(q$y,"native"),y1=unit(q$y,"native"),gp=gpar(col=colors[[management]],lwd=if(letter=="a") .65 else 1.05))
      grid.lines(x=unit(q$value,"native"),y=unit(q$y,"native"),
          gp=gpar(col=colors[[management]],lwd=if(observed || letter=="a") .65 else 1.05,lty=if(observed) index else 1))
      grid.points(x=unit(q$value,"native"),y=unit(q$y,"native"),pch=if(observed) c(16,17,15)[index] else 16,
          size=unit(if(observed || letter=="a") 1.05 else 1.55,"mm"),gp=gpar(col=colors[[management]],fill=colors[[management]]))
    }
  }
  if(nrow(p$markers)) for(i in seq_len(nrow(p$markers))) if(nzchar(p$markers$symbol[i]))
    grid.text(p$markers$symbol[i],x=unit(p$markers$marker_x[i],"native"),y=unit(p$markers$y[i],"native"),
              just=if(si==3L) c("left","centre") else "centre",gp=gpar(fontfamily=font,fontsize=axis_pt,col="black"))
  popViewport()
  xtx<-f[1]+(p$ticks-p$xrange[1])/diff(p$xrange)*(f[2]-f[1])
  for(i in seq_along(p$ticks)) {
    grid.lines(x=unit(rep(px_x(xtx[i]),2),"npc"),y=unit(px_y(c(f[4],f[4]+10)),"npc"),gp=gpar(col="#333333",lwd=.7))
    lab<-if(si==1L && letter=="a") sprintf("%.2f",p$ticks[i]) else if(si==2L && letter=="a") sprintf("%.1f",p$ticks[i]) else format(p$ticks[i],trim=TRUE,scientific=FALSE)
    text_at(lab,xtx[i],f[4]+39,tick_pt)
  }
  ypx<-f[4]-((n:1)-yr[1])/diff(yr)*(f[4]-f[3])
  for(i in seq_along(ypx)) {
    grid.lines(x=unit(px_x(c(f[1]-10,f[1])),"npc"),y=unit(rep(px_y(ypx[i]),2),"npc"),gp=gpar(col="#333333",lwd=.7))
    text_at(depths[[si]][i],f[1]-20,ypx[i],tick_pt,just="right")
  }
  text_at(paste0("(",letter,")"),f[1],f[3]-45,tag_pt,just="left")
  if(letter %in% c("a","c")) text_at("Depth (cm)",51,mean(f[3:4]),axis_pt,rot=90)
  axis_label(p$response,mean(f[1:2]),if(letter %in% c("a","b")) 792 else 1602)
}
space_markers <- function(p,si) {
  # Keep the existing marker rule, adding only the clearance needed by its font.
  if(nrow(p$markers)) for(i in seq_len(nrow(p$markers))) if(nzchar(p$markers$symbol[i])) {
    m<-p$markers[i,];hi<-max(p$data$upper_one_se[p$data$depth==m$depth])
    w<-convertWidth(grobWidth(textGrob(m$symbol,gp=gpar(fontfamily=font,fontsize=axis_pt))),"inches",valueOnly=TRUE)
    clearance<-(if(si==3L) 0 else w/2)+2.5/72
    p$markers$marker_x[i]<-max(m$marker_x,hi+clearance/(726/300)*diff(p$xrange))
  }
  p
}
write_readback <- function(z,path) {
  # Seventeen significant digits retain the plotted double-precision values.
  for(name in names(z)) if(is.numeric(z[[name]])) z[[name]]<-ifelse(is.na(z[[name]]),"",format(z[[name]],digits=17,trim=TRUE))
  write.csv(z,path,row.names=FALSE,na="")
}
draw_legend <- function(si) {
  g<-groups[[si]];widths<-vapply(labels[g],function(t) convertWidth(grobWidth(textGrob(t,gp=gpar(fontfamily=font,fontsize=legend_pt))),"inches",valueOnly=TRUE),numeric(1))
  entry<-widths+.30;gap<-.17;left<-(width_in-sum(entry)-gap*(length(g)-1))/2
  for(i in seq_along(g)) {
    xx<-left+sum(entry[seq_len(i-1L)])+gap*(i-1L)
    grid.lines(x=unit(c(xx,xx+.22),"inches"),y=unit(rep(px_y(1750),2),"npc"),gp=gpar(col=colors[[g[i]]],lwd=1.05))
    grid.points(x=unit(xx+.11,"inches"),y=unit(px_y(1750),"npc"),pch=16,size=unit(1.55,"mm"),gp=gpar(col=colors[[g[i]]]))
    grid.text(labels[[g[i]]],x=unit(xx+.30,"inches"),y=unit(px_y(1750),"npc"),just=c("left","centre"),gp=gpar(fontfamily=font,fontsize=legend_pt,col="black"))
  }
}
for(si in if(orchard_stock_only) 2L else seq_along(systems)) {
  letters <- if(orchard_stock_only) "c" else c("a","b","c","d")
  panels<-setNames(lapply(letters,function(l) prepare_panel(si,l)),letters)
  ragg::agg_png(file.path(out,if(orchard_stock_only) "Figure_3c_canvas.png" else paste0("Figure_",si+1L,".png")),width=width_in,height=height_in,units="in",res=dpi,pointsize=axis_pt,background="white")
  grid.newpage()
  panels<-lapply(panels,space_markers,si=si)
  for(letter in names(panels)) draw_panel(panels[[letter]],si,letter)
  if(!orchard_stock_only) draw_legend(si)
  invisible(dev.off())
  write_readback(do.call(rbind,lapply(panels,`[[`,"data")),file.path(readback,paste0("Figure_",si+1L,"_plotting_data.csv")))
  write_readback(do.call(rbind,lapply(panels,`[[`,"markers")),file.path(readback,paste0("Figure_",si+1L,"_marker_data.csv")))
}
writeLines(c(paste0("Font family: ",font),paste0("Regular font file: ",systemfonts::match_fonts(font)$path[1]),
  "Canvas: 6.5 x 6.1 in; 1950 x 1830 px; 300 dpi",paste0("Axis labels: ",axis_pt," pt"),
  paste0("Ticks and legend: ",tick_pt," pt"),paste0("Panel letters: ",tag_pt," pt"),
  "Only saved publication values and saved marker strings were read; no models or tests were run."),file.path(readback,"render_settings.txt"))
message("Saved-value profile figures: ",out)
