% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getMAF.R
\name{getMAF}
\alias{getMAF}
\title{Calculate MAF}
\usage{
getMAF(z = NULL, noCall = 9, flip = TRUE, dosageMax = 2)
}
\arguments{
\item{z}{matrix object, rows are samples, columns are SNPs, values range 0-2.}

\item{noCall}{missing value for genotype, defaults to 9.}

\item{flip}{default TRUE. If maf is more than 0.5, then flip 1-maf.}

\item{dosageMax}{default is 2 , for chr23 use 1.}
}
\value{
a \code{matrix} object. First column is MAF (range 0-0.5), second column is 1 if the MAF is flipped, else 0.
}
\description{
This function calculates MAF for imputed SNP data in dosage format.
}
\examples{
# dummy SNP data, 25 samples, 4 SNPs
set.seed(123)
geno <- matrix(sample(c(0, 1, 2), 100, replace = TRUE), ncol = 4)
# calculate MAF, returns 2 column matrix
getMAF(geno)
}
\author{
Tokhir Dadaev
}
\keyword{dosage}
\keyword{maf}
\keyword{snp}
