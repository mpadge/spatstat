#'
#'	metricPdt.R
#'
#'     Metric distance transform of pixel mask
#'
#'	$Revision: 1.6 $	$Date: 2020/11/29 07:42:07 $


rectdistmap <- function(X, asp=1.0, npasses=1, verbose=FALSE) {
  w <- as.mask(X)
  check.1.real(asp)
  check.1.integer(npasses)
  stopifnot(asp > 0)
  #' ensure grid has suitable aspect ratio
  dx <- w$xstep
  dy <- w$ystep
  a <- dy/(asp*dx)
  if(verbose) 
    splat("grid aspect", signif(a, 3))
  refined <- (a > 1.2 || a < 0.8)
  if(refined) {
    flipped <- (a < 1)
    if(flipped) a <- 1/a
    n <- if(a > 10) 1 else if(a > 6) 2 else if(a > 4) 4 else 12
    an <- if(n > 1) round(a * n) else ceiling(a)
    k <- c(an, n)/greatest.common.divisor(an, n)
    if(flipped)
      k <- rev(k)
    woriginal <- w
    w <- as.owin(w, dimyx=k * dim(w))
    if(verbose) {
      splat("Grid expansion", k[1], "x", k[2])
      splat("Adjusted grid aspect", (a * k[2])/k[1])
    }
  }
  #'
  nr <- w$dim[1L]
  nc <- w$dim[2L]
  #' input image will be padded out with a margin of width 2 on all sides
  mr <- mc <- 2L
  #' full dimensions of padded image
  Nnr <- nr + 2 * mr
  Nnc <- nc + 2 * mc
  N <- Nnr * Nnc
  #' output image (subset): rows & columns (R indexing)
  rmin <- mr + 1L
  rmax <- Nnr - mr
  cmin <- mc + 1L
  cmax <- Nnc - mc
  #' do padding
  x <- matrix(FALSE, nrow=Nnr, ncol=Nnc)
  x[rmin:rmax, cmin:cmax] <- w$m
  #' compute distmap
  res <- .C("mdtPOrect",
            as.double(w$xrange[1L]),
            as.double(w$yrange[1L]),
            as.double(w$xrange[2L]),
            as.double(w$yrange[2L]),
            nr = as.integer(nr),
            nc = as.integer(nc),
            mr = as.integer(mr),
            mc = as.integer(mc),
            inp = as.integer(t(x)),
            asp = as.double(asp),
            npasses = as.integer(npasses),
            distances = as.double (double(N)),
            rows      = as.integer(integer(N)),
            cols      = as.integer(integer(N)),
            PACKAGE = "spatstat")
  dist <- matrix(res$distances,
                 ncol=Nnc, nrow=Nnr, byrow = TRUE)[rmin:rmax, cmin:cmax]
  result <- as.im(dist, w)
  if(refined) result <- as.im(result, W=woriginal) 
#  rows <- matrix(res$rows,
#                 ncol=Nnc, nrow=Nnr, byrow = TRUE)[rmin:rmax, cmin:cmax]
#  cols <- matrix(res$cols,
#                 ncol=Nnc, nrow=Nnr, byrow = TRUE)[rmin:rmax, cmin:cmax]
  # convert from C to R indexing
#  rows <- rows + 1L - as.integer(mr)
#  cols <- cols + 1L - as.integer(mc)
#  return(list(d=dist,row=rows,col=cols,b=bdist, w=w))
  edge <- TRUE
  if(edge) {
    #' calculate distance transform to boundary
    y <- x
    y[] <- TRUE
    y[rmin:rmax, cmin:cmax] <- FALSE
    y[rmin, ] <- TRUE
    y[rmax, ] <- TRUE
    y[, cmin] <- TRUE
    y[, cmax] <- TRUE
    #' compute distmap
    bres <- .C("mdtPOrect",
               as.double(w$xrange[1L]),
               as.double(w$yrange[1L]),
               as.double(w$xrange[2L]),
               as.double(w$yrange[2L]),
               nr = as.integer(nr),
               nc = as.integer(nc),
               mr = as.integer(mr),
               mc = as.integer(mc),
               inp = as.integer(t(y)),
               asp = as.double(asp),
               npasses = as.integer(npasses),
               distances = as.double (double(N)),
               rows      = as.integer(integer(N)),
               cols      = as.integer(integer(N)),
               PACKAGE = "spatstat")
    bdist <- matrix(bres$distances,
                    ncol=Nnc, nrow=Nnr, byrow = TRUE)[rmin:rmax, cmin:cmax]
    bdist <- as.im(bdist, w)
    if(refined) bdist <- as.im(bdist, W=woriginal) 
    attr(result, "bdist") <- bdist
  }
  return(result)
}

