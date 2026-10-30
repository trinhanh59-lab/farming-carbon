#!/usr/bin/env Rscript
# Redraw the approved profiles from frozen means, SEs and bracket geometry.
# No statistical model or test is fitted here.
suppressPackageStartupMessages({library(grid);library(ragg);library(systemfonts)})
argv<-commandArgs(trailingOnly=FALSE)
here<-dirname(normalizePath(gsub('~+~',' ',sub('^--file=','',argv[grepl('^--file=',argv)][1]),fixed=TRUE)))
repo<-dirname(dirname(here));args<-commandArgs(trailingOnly=TRUE)
output_dir<-if(length(args))args[1]else file.path(repo,'figures','rendered')
dir.create(file.path(output_dir,'grayscale'),recursive=TRUE,showWarnings=FALSE)
dd<-file.path(repo,'figures','profile_data')
fit<-read.csv(file.path(dd,'hedgerow_means1se.csv'),stringsAsFactors=FALSE)
annotations<-read.csv(file.path(dd,'hedgerow_brackets.csv'),stringsAsFactors=FALSE)
axes<-read.csv(file.path(dd,'hedgerow_axes.csv'),stringsAsFactors=FALSE)
responses<-c('root','c_percent','cumulative_c_stock','del14c')
groups<-c('bare field margin','10-year-old hedgerow','30-year-old hedgerow')
labels<-c('bare margin','10-year','30-year');ds<-c('0-10','10-20','20-50','50-75')
offset<-c(.18,0,-.18);shapes<-c(21,22,24);patterns<-c(1,2,3)
fills<-c('#ECD693','#F7C548','#A98743');strokes<-c('#A88C3A','#C4930E','#80642F')
font<-if('Arial'%in%systemfonts::system_fonts()$family)'Arial' else 'sans'
sha<-function(path)strsplit(system2('/usr/bin/shasum',c('-a','256',shQuote(path)),stdout=TRUE),' ')[[1]][1]
# Original normalized publication frames, scaled from 6.5x6.1 to9x8.45 inches.
frames<-list(c(234/1950,1-690/1830,726/1950,580/1830),c(1184/1950,1-690/1830,726/1950,580/1830),
             c(234/1950,1-1500/1830,726/1950,580/1830),c(1184/1950,1-1500/1830,726/1950,580/1830))
text_at<-function(label,x,y,size=11,just='centre',rot=0){grid.text(label,x=x,y=y,just=just,rot=rot,gp=gpar(fontfamily=font,fontsize=size,col='black'))}
panels<-lapply(responses,function(response){
 z<-fit[fit$response==response,];a<-annotations[annotations$response==response,]
 bounds<-range(c(z$lower_one_SE,z$upper_one_SE));if(response!='del14c')bounds[1]<-min(0,bounds[1])
 span<-diff(bounds);if(span==0)span<-1
 ax<-axes[axes$response==response,];stopifnot(nrow(ax)==1L)
 xr<-c(ax$xlower,ax$xupper);xt<-pretty(bounds,n=4);xt<-xt[xt>=xr[1]&xt<=xr[2]]
 list(response=response,fit=z,ann=a,bounds=bounds,span=span,xr=xr,xt=xt)
})
render<-function(grey=FALSE){
 pal<-if(grey)c('#D7D7D7','#999999','#454545')else fills
 stroke<-if(grey)c('#777777','#444444','#111111')else strokes
 suffix<-if(grey)'greyscale' else 'colour'
 ragg::agg_png(file.path(if(grey)file.path(output_dir,'grayscale')else output_dir,'Figure_4.png'),width=9,height=8.45,units='in',res=260,background='white')
 grid.newpage()
 for(pi in 1:4){
  p<-panels[[pi]];f<-frames[[pi]];left<-f[1];bottom<-f[2];pw<-f[3];ph<-f[4]
  grid.rect(x=left,y=bottom,width=pw,height=ph,just=c('left','bottom'),gp=gpar(col='#666666',fill=NA,lwd=.9))
  pushViewport(viewport(x=left,y=bottom,width=pw,height=ph,just=c('left','bottom'),xscale=p$xr,yscale=c(.5,4.5),clip='on'))
  for(j in 1:3){
   z<-p$fit[p$fit$management==groups[j],];z<-z[match(ds,z$depth),]
   grid.segments(x0=unit(z$lower_one_SE,'native'),x1=unit(z$upper_one_SE,'native'),y0=unit(z$y_plot,'native'),y1=unit(z$y_plot,'native'),gp=gpar(col=stroke[j],lwd=1.25))
   for(k in 1:4)grid.segments(x0=unit(c(z$lower_one_SE[k],z$upper_one_SE[k]),'native'),x1=unit(c(z$lower_one_SE[k],z$upper_one_SE[k]),'native'),y0=unit(z$y_plot[k]-.025,'native'),y1=unit(z$y_plot[k]+.025,'native'),gp=gpar(col=stroke[j],lwd=.9))
   grid.lines(x=unit(z$estimate,'native'),y=unit(z$y_plot,'native'),gp=gpar(col=stroke[j],lwd=1.25,lty=patterns[j]))
   grid.points(x=unit(z$estimate,'native'),y=unit(z$y_plot,'native'),pch=shapes[j],size=unit(2.4,'mm'),gp=gpar(col='black',fill=pal[j],lwd=.65))
  }
  a<-p$ann
  if(nrow(a))for(i in seq_len(nrow(a))){
   cap<-.02*p$span
   grid.lines(x=unit(c(a$x[i]-cap,a$x[i],a$x[i],a$x[i]-cap),'native'),y=unit(c(a$y0[i],a$y0[i],a$y1[i],a$y1[i]),'native'),gp=gpar(col='#222222',lwd=.8))
   grid.text(a$stars[i],x=unit(a$star_x[i],'native'),y=unit(a$star_y[i],'native'),just='left',gp=gpar(fontfamily=font,fontsize=if(pi==3)10 else 11,col='black'))
  }
  popViewport()
  for(x in p$xt){
   xx<-left+pw*(x-p$xr[1])/diff(p$xr)
   grid.lines(x=c(xx,xx),y=c(bottom,bottom-.006),gp=gpar(col='#444444',lwd=.7))
   text_at(format(x,trim=TRUE,scientific=FALSE),xx,bottom-.023,11)
  }
  dl<-if(pi==3)paste0('0–',sub('.*-','',ds))else gsub('-','–',ds)
  for(k in 1:4){yy<-bottom+ph*((5-k)-.5)/4;text_at(dl[k],left-.017,yy,11,'right')}
  text_at(paste0('(',letters[pi],')'),left,bottom+ph+.026,13,'left')
  if(pi%in%c(1,3))text_at('Depth (cm)',.026,bottom+ph/2,12,rot=90)
  cx<-left+pw/2;ay<-bottom-.060
  if(pi==1){text_at('Recovered root mass density',cx,ay+.007,11.5);grid.text(expression(paste('(mg ',cm^{-3},')')),x=cx,y=ay-.024,gp=gpar(fontfamily=font,fontsize=11.5))}
  if(pi==2)text_at('C (%)',cx,ay,12)
  if(pi==3)grid.text(expression(paste('Cumulative C stock (t C ',ha^{-1},')')),x=cx,y=ay,gp=gpar(fontfamily=font,fontsize=11.5))
  if(pi==4)grid.text(expression(paste(Delta^{14},'C (‰)')),x=cx,y=ay,gp=gpar(fontfamily=font,fontsize=12))
 }
 text_at('Error bars: ±1 SE',.5,.083,10.5)
 # Shared bottom legend, matching the original figure's location and labels.
 for(j in 1:3){lx<-c(.25,.455,.66)[j]
  grid.lines(x=c(lx,lx+.04),y=c(.043,.043),gp=gpar(col=stroke[j],lty=patterns[j],lwd=1.3))
  grid.points(x=unit(lx+.02,'npc'),y=unit(.043,'npc'),pch=shapes[j],size=unit(2.4,'mm'),gp=gpar(col='black',fill=pal[j],lwd=.65))
  text_at(labels[j],lx+.054,.043,11,'left')
 }
 dev.off()
}
render(FALSE);render(TRUE)
