#!/usr/bin/env Rscript
# Render Figures 2-4 from the approved saved means, one SE and bracket geometry.
# Pass an output directory as the first argument; default is figures/regenerated/profiles.
script <- grep('^--file=', commandArgs(trailingOnly=FALSE), value=TRUE)
stopifnot(length(script)==1L)
here <- dirname(normalizePath(gsub('~+~',' ',sub('^--file=', '', script),fixed=TRUE)))
args <- commandArgs(trailingOnly=TRUE)
output <- if(length(args)) args[1] else file.path(here, 'regenerated', 'profiles')
for(system in c('annual', 'orchard', 'hedgerow')) {
  status <- system2(file.path(R.home('bin'), 'Rscript'), c('--vanilla',
    shQuote(file.path(here, 'profile_renderers', paste0('render_', system, '_1se.R'))),
    shQuote(output)))
  if(status != 0L) stop('Figure render failed: ', system)
}
