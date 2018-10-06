#' Check Paired Microscopic Images
#'
#' Check validity and optionally show paired DNA and a fluorescent images
#' using the same selection criteria provided to \code{parseImages()}.
#'
#' @param path A character vector of directory with either multilayer tiff
#'   image files \emph{or} subdirectories identified by well with separate,
#'   paired images per well.
#' @param type A character string identifying the type of image files to parse
#'   ("tif", "tiff", "jpeg", "jpg" or "png".)
#' @param which.images An integer of length 2 or 3. The first two numbers indicate
#'   the relative position of the DNA image and the target in each field. The optional
#'   third number specifies the total number of images for each field. A value of
#'   \code{c(1, 2)} indicates DNA first and target second. A value of \code{c(2, 1)}
#'   indicates that the order is target first and DNA image second. A value of
#'   \code{c(1, 2, 3)} indicates a DNA image, a target image, and a third (ignored)
#'   image such as a phase contrast image or second fluorescent color in each set.
#' @param pattern Optional grep pattern as character string used by \code{list.files()}
#'   to select image files.
#' @param method Character string specifying the method of displaying images.
#'   Default of \code{"none"} simply summarizes the images. A value of \code{"raster"}
#'   uses R raster graphics and \code{"browser"} attempts to use a browser,
#'   which currently fails with EBImage...
#'
#' @details
#'
#' Images specified in \code{path} will be read, normalized and (optionally) displayed
#' with the same logic in \code{parseImages()}. This functions determines if
#' the proper number of files are present. If desired, images are displayed in
#' pairs by either the browser or by the raster method. This has been implemented
#' with \code{\link{EBImage}} and is part of a suite of tools to determine
#' viral titers from fluorescent micrograph pairs. Typically, the first of each
#' pair is a DNA image and the second a fluorescent image of the viral target.
#' target signal. Although the nuclear (typically DAPI) image file is expected
#' to precede the corresponding viral antigen image file, this order can be
#' changed with the \code{which.images} argument.
#'
#' Pairs of images associated with each moi can be individual files in a
#' single directory where each directory is named for the well such as
#' \code{A1}, \code{A2}, etc. and the files within are identified as
#' \code{A1/file001.tif}, \code{A1/file002.tif}, etc. The well identifier
#' can be in upper or lower case and can contain leading zeros such as
#' \code{c0003/file12.tif}.
#'
#' Alternatively, each group of images associated with a given moi can be
#' a multi-layered tiff file where the sequence of images in the file is
#' specified by the argument \code{which.images}.
#'
#' @return
#'
#' This function is called to examine the sequence of image files and 
#' optionally display the normalized images. Diagnostic messages are
#' printed on the console via \code{message()}. Use the \code{grep} string
#' in \code{pattern} to limit the selected images. The last group of images
#' displayed is invisibly returned. 
#'
#' @examples
#' # Example with data organized by folder or well
#'   path.by.folder <- system.file("extdata", "by_folder", package = "virustiter")
#'   checkImages(path.by.folder)
#'
#' @import EBImage
#'
#' @export
#'
checkImages <- function(path, type = "tiff", which.images = c(1, 2, 2),
	pattern = NULL, method = c("none", "raster", "browser"))
{
# requires EBImage, ensure appropriate values for parameters
	if (!require(EBImage))
		stop("The 'EBImage' package must be installed with biocLite")
	if (length(path) > 1)
		warning("only the first value in 'path' will be used")
	path <- path[1]
	if (file.info(path)$isdir == FALSE)
		stop("The value in 'path' is not a directory.")
	if (length(which.images) == 2)
			which.images <- c(which.images, max(which.images))
	if (length(which.images) != 3)
		stop("'which.images' must be an integer vector of length 2 or 3")
	if (which.images[3] != max(which.images))
		stop("the third value in 'which.images' must be the largest")

# method
	method <- match.arg(method)
	if (method == "browser") {
		message("Currently the display with browser seems to fail in EBImage")
		message("The value has been changed to 'raster'.")
		message("Use 'par(ask = TRUE)' to view images one-by-one")
		method <- "raster"
	}

# extract paths to image files
	ff <- list.images(path = path, type = type, pattern = pattern)
	message("Found ", length(ff), " image files")

# extract fields to determine if images are organized by well or stack
	spl <- strsplit(ff, "/")
	field1 <- sapply(spl, tail, 1)
	field2 <- sapply(spl, function(x) head(tail(x, 2), 1))
	sel <- grepl("^[[:alpha:]][[:digit:]]+$", field2) # test for well pattern

# assign variables to direct processing
	if (all(sel)) {
		imageType <- "byWell"
		well <- field2
		filename <- NULL
	}
	else if (!any(sel)) {
		imageType <- "byStack"
		well <- NULL
		filename <- field1
	}
	else
		stop("unable to use mixture of image files in ", path, '"')

# split image paths into related groups (by well or by file)
	if (imageType == "byWell")
		ffsplit <- split(ff, well)
	else if (imageType == "byStack")
		ffsplit <- split(ff, filename)
	else
		stop("unexpected value for 'imageType'")

# read all images as a list and coerce to grayscale with a warning
	message("Reading images grouped by ", ifelse(imageType == "byWell", "well", "file"))
	img <- lapply(ffsplit, function(f) suppressWarnings(readImage(f)))
	if (any(sapply(img, colorMode) != 0)) {
		warning("images have been converted to grayscale by uniform RGB averaging")
		img <- lapply(img, channel, "gray")
	}

# check for expected numbers of images
	n_dna <- which.images[1]
	n_mfi <- which.images[2]
	n_field <- which.images[3]

# are total images in each group sensible?
	n <- sapply(img, function(x) dim(x)[3])
	bad <- which(n %% n_field != 0)
	if (length(bad))
		stop("The number of images in ", paste(names(img)[bad], collapse = ", "),
			" are not multiples of ", n_field)

# extract dna images and adjust to 3 dimensions
	dnaImages <- lapply(img, function(x, first = n_dna, by = n_field) {
		dm <- dim(x)
		if (length(dm) == 2)
			dim(x) <- c(dm, 1)
		N <- dim(x)[3]
		x[,,seq(first, N, by)]})

# extract mfi images and adjust to 3 dimensions
	mfiImages <- lapply(img, function(x, first = n_mfi, by = n_field) {
		dm <- dim(x)
		if (length(dm) == 2)
			dim(x) <- c(dm, 1)
		N <- dim(x)[3]
		x[,,seq(first, N, by)]})

# count and report on the number of groups to display
	nff <- length(ffsplit)
	message("Found ", nff, " groups of images")

# process each group of files in turn
	for (IDX in seq_along(ffsplit)) {
		message(sprintf("%4d: ", IDX), "  ", names(ffsplit)[IDX])
		myDna <- normalize(dnaImages[[IDX]])
		myMfi <- normalize(mfiImages[[IDX]])
		n <- dim(myDna)[3]
		if (is.null(n) || is.na(n))
			n <- 1
		i <- c(rbind(seq_len(n), n + seq_len(n)))
		img <- combine(myDna, myMfi)[,,i]
		if (method != "none")
			display(tile(img, nx = 2), all = TRUE, method = method,
				title = names(ffsplit)[IDX])
	}
	message("Done")
	invisible(img)
}