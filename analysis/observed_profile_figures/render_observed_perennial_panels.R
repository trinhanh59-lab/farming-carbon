# Author-approved measured core profiles. No mass addition, fitting or tests.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
task <- dirname(normalizePath(sub("^--file=", "", script_arg)))
observed <- read.csv(file.path(task,"observed_perennial_root_profiles_60.csv"),
                     stringsAsFactors=FALSE)
stopifnot(nrow(observed)==60L,all(observed$addition_g==0),
          max(abs(observed$observed_density_mg_cm3-
              1000*observed$working_root_mass_g/observed$volume_cm3))<1e-12)
depths <- c("0-10","10-20","20-50","50-75")
groups <- list(orchards=c("20-year-old orchard","60-year-old orchard"),
               hedgerows=c("bare field margin","10-year-old hedgerow","30-year-old hedgerow"))
colors <- c("20-year-old orchard"="#E28065","60-year-old orchard"="#AB3F21",
            "bare field margin"="#ECD693","10-year-old hedgerow"="#F7C548",
            "30-year-old hedgerow"="#A98743")

for(system in names(groups)) {
  z<-observed[observed$system==system,,drop=FALSE]
  stopifnot(nrow(z)==length(groups[[system]])*12,
            setequal(z$management,groups[[system]]),setequal(z$depth_interval_cm,depths),
            all(table(z$core)==4L))
  z$y<-5-match(z$depth_interval_cm,depths)
  largest<-max(z$observed_density_mg_cm3)
  xr<-c(-.035*largest,1.10*largest)
  ticks<-pretty(c(0,largest),n=4)
  ticks<-ticks[ticks>=0&ticks<xr[2]]
  png(file.path(task,paste0(system,"_observed_root_panel_REVIEW.png")),
      width=1000,height=840,res=100,pointsize=23.5,type="quartz",bg="white")
  par(plt=c(234/1000,960/1000,(840-690)/840,(840-110)/840),
      xaxs="i",yaxs="i",family="Arial",xpd=FALSE)
  plot(NA_real_,NA_real_,xlim=xr,ylim=c(.4,4.6),axes=FALSE,ann=FALSE)
  box(col="#666666",lwd=1.2)
  axis(1,at=ticks,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.018)
  axis(2,at=4:1,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.015)
  # Color identifies the field; shape and line type distinguish its three cores.
  # Connected points are repeated increments from one actual core, not fitted lines.
  for(management in groups[[system]]) for(core in sort(unique(z$core[z$management==management]))) {
    zz<-z[z$core==core,,drop=FALSE]
    zz<-zz[match(depths,zz$depth_interval_cm),]
    index<-unique(zz$profile_symbol_index)
    stopifnot(length(index)==1L,index%in%1:3)
    lines(zz$observed_density_mg_cm3,zz$y,col=colors[[management]],lwd=1.6,lty=index)
    points(zz$observed_density_mg_cm3,zz$y,col=colors[[management]],
           pch=c(16,17,15)[index],cex=.73)
  }
  par(fig=c(0,1,0,1),mar=c(0,0,0,0),new=TRUE)
  plot(NA_real_,NA_real_,xlim=c(0,1000),ylim=c(840,0),
       xaxs="i",yaxs="i",axes=FALSE,ann=FALSE)
  text(234+(ticks-xr[1])/diff(xr)*726,729,
       labels=format(ticks,trim=TRUE,nsmall=if(system=="orchards")1 else 0),cex=.97)
  text(214,690-((4:1)-.4)/4.2*580,labels=depths,adj=c(1,.5),cex=.97)
  text(234,65,"(a)",adj=c(0,.5),cex=1.08)
  text(51,400,"Depth (cm)",srt=90,cex=1.08)
  text(596,774,"Recovered root mass density",cex=.96)
  text(596,817,expression("(mg cm"^{-3}*")"),cex=.96)
  invisible(dev.off())
}
