# Author-approved observed cumulative stocks. No fitting or statistical tests.
script_arg<-grep("^--file=",commandArgs(trailingOnly=FALSE),value=TRUE)
task<-dirname(normalizePath(sub("^--file=","",script_arg)))
z<-read.csv(file.path(task,"observed_orchard_cumulative_stocks_24.csv"),stringsAsFactors=FALSE)
depths<-c("0-10","10-20","20-50","50-75")
groups<-c("20-year-old orchard","60-year-old orchard")
colors<-c("20-year-old orchard"="#E28065","60-year-old orchard"="#AB3F21")
stopifnot(nrow(z)==24L,length(unique(z$core))==6L,
          setequal(z$depth_interval_cm,depths),all(table(z$core)==4L))
z$y<-5-match(z$depth_interval_cm,depths)
xr<-c(0,34)
ticks<-c(0,10,20,30)
# Local crop starts at original image y=840; panel C border remains y=920-1500.
png(file.path(task,"orchards_observed_stock_panel_REVIEW.png"),
    width=1000,height=810,res=100,pointsize=23.5,type="quartz",bg="white")
par(plt=c(234/1000,960/1000,(810-660)/810,(810-80)/810),
    xaxs="i",yaxs="i",family="Arial",xpd=FALSE)
plot(NA_real_,NA_real_,xlim=xr,ylim=c(.4,4.6),axes=FALSE,ann=FALSE)
box(col="#666666",lwd=1.2)
axis(1,at=ticks,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.018)
axis(2,at=4:1,labels=FALSE,lwd=0,lwd.ticks=1,tck=-.015)
for(management in groups)for(core in sort(unique(z$core[z$management==management]))) {
  zz<-z[z$core==core,,drop=FALSE]
  zz<-zz[match(depths,zz$depth_interval_cm),]
  index<-unique(zz$profile_symbol_index)
  stopifnot(length(index)==1L,index%in%1:3)
  lines(zz$cumulative_c_stock_t_C_ha,zz$y,col=colors[[management]],lwd=1.6,lty=index)
  points(zz$cumulative_c_stock_t_C_ha,zz$y,col=colors[[management]],
         pch=c(16,17,15)[index],cex=.73)
}
par(fig=c(0,1,0,1),mar=c(0,0,0,0),new=TRUE)
plot(NA_real_,NA_real_,xlim=c(0,1000),ylim=c(810,0),
     xaxs="i",yaxs="i",axes=FALSE,ann=FALSE)
text(234+ticks/diff(xr)*726,699,labels=ticks,cex=.97)
text(214,660-((4:1)-.4)/4.2*580,labels=depths,adj=c(1,.5),cex=.97)
text(234,35,"(c)",adj=c(0,.5),cex=1.08)
text(51,370,"Depth (cm)",srt=90,cex=1.08)
text(596,763,expression("Cumulative C stock (t C ha"^{-1}*")"),cex=1.00)
invisible(dev.off())
