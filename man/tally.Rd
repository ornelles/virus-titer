% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tally.R
\name{tally}
\alias{tally}
\title{Tally Positive Fluorescent Values}
\usage{
tally(df, pd = NULL, moi = NULL, by = NULL, param = "mfi")
}
\arguments{
\item{df}{Annotated \code{data.frame} with fluorescent values to evaluate.}

\item{pd}{Optional phenotype \code{data.frame} to add to results.}

\item{moi}{Character string identifying the independent value. If \code{NULL},
variables named \code{"moi"} and \code{"x"} will be sought. Note
that in the returned value, this variable will be named \code{"x"}.}

\item{by}{Character string identifying the grouping variable. If \code{NULL},
either \code{"well"} or \code{"file"} must be present and will be used as
the grouping variable.}

\item{param}{Character string identifying the variable in \code{df} to evaluate, 
typically \code{"mfi"}.}
}
\value{
A \code{data.frame} of tallied values for each level of the grouping
variable (typically \code{well} or \code{file}) with additional information
provided by the optional phenotype data. Variables generated by \code{\link{tally}} are
expected by downstream functions. Notably, the dependent variable will
be renamed \code{x} in the output. These variables include:
\itemize{
	\item The independent variable representing the multiplicity of infection
    in \code{x}
  \item The dependent variable as the fraction of positive cells in \code{y}
  \item The number of positive cells in \code{pos}
  \item The number of negative in \code{neg}
  \item Details about the grouping variable, typically \code{well} or \code{file}
}
}
\description{
Tally positive and negative values from from the data.frame generated
by \code{\link{parseImages}} by a grouping variable such as \code{"well"}
or \code{"file"} that corresponds to a single multiplicity.
}
\details{
The variable named \code{positive} will be tallied for each value of
\code{moi} (if present) represented by each level of the grouping
variable \code{by}.
}
\examples{
# Sample data by folder
  f <- system.file("extdata", "by_folder", package = "virustiter")
  pd <- read.csv(system.file("extdata", "by_folder/phenoData.csv", package = "virustiter"))
  i <- getImages(f)
  v <- parseImages(i)
  v <- mergePdata(pd, v)
  v <- score(v)
  tally(v)

}
