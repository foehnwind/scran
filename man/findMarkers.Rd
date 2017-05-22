\name{findMarkers}
\alias{findMarkers}
\alias{findMarkers,matrix-method}
\alias{findMarkers,SCESet-method}

\title{Find marker genes}
\description{Find candidate marker genes for clusters of cells, by testing for differential expression between clusters.}

\usage{
\S4method{findMarkers}{matrix}(x, clusters, design=NULL, pval.type=c("any", "all"), subset.row=NULL)

\S4method{findMarkers}{SCESet}(x, ..., subset.row=NULL, assay="exprs", get.spikes=FALSE) 
}

\arguments{
\item{x}{
    A numeric matrix of normalized log-expression values, where each column corresponds to a cell and each row corresponds to an endogenous gene.
    Alternatively, a SCESet object containing such a matrix.
}
\item{clusters}{
A vector of cluster identities for all cells.
}
\item{design}{A numeric matrix containing blocking terms, i.e., uninteresting factors driving expression across cells.}
\item{pval.type}{A string specifying the type of combined p-value to be computed, i.e., Simes' or IUT.}
\item{subset.row}{A logical, integer or character scalar indicating the rows of \code{x} to use.}
\item{...}{Additional arguments to pass to the matrix method.}
\item{assay}{A string specifying which assay values to use, e.g., \code{counts} or \code{exprs}.}
\item{get.spikes}{A logical scalar specifying whether decomposition should be performed for spike-ins.}
}

\details{
This function uses \pkg{limma} to test for differentially expressed genes (DEGs) between pairs of clusters.
For each cluster, the log-fold changes and other statistics from all relevant pairwise comparisons are combined into a single table.
A list of such tables is returned for all clusters to define a set of potential marker genes.

Each table is sorted by the \code{Top} value, which specifies the size of the candidate marker set.
Taking all rows with \code{Top} values no greater than some integer X will yield a set containing the top X genes (ranked by significance) from each pairwise comparison.
For example, if X is 5, the set will consist of the \emph{union} of the top 5 genes from each pairwise comparison.
The marker set for each cluster allows it to be distinguished from the other clusters based on the expression of at least one gene.

The \code{FDR} value is calculated by consolidating p-values across contrasts for each gene, and then applying the BH method across genes.
By default, the null hypothesis is that the gene is not DE in any of the contrasts, and Simes' method is used to combine p-values for each gene.
In both cases, the reported value is intended only as a rough measure of significance.
Properly correcting for multiple testing is not generally possible when \code{clusters} is determined from the same \code{x} used for DE testing.

Genes that are uniquely expressed in a cluster are not explicitly favoured by default.
Such a strategy is often too stringent, especially in cases involving overclustering or cell types defined by combinatorial gene expression.
However, if \code{pval.type="all"}, the null hypothesis is that the gene is not DE in all contrasts, and the IUT p-value is computed for each gene.
This can be used to re-rank the genes based on the resulting FDR values.

The application of \pkg{limma} uses the \dQuote{trend} approach on the normalized log-expression values, as described by Law et al. (2015).
This is fast and avoids putting too much weight on outliers or cells with large library sizes.
Uninteresting factors of variation (e.g., preparation time, sequencing batch) will be blocked if they are stored in \code{design}.
Note that the presence of factors that are confounded with \code{clusters} will raise a warning about unestimable coefficients.

By default, spike-in transcripts are ignored in \code{findMarkers,SCESet-method} with \code{get.spikes=FALSE}.
This is overridden by any non-\code{NULL} value of \code{subset.row}.
}

\value{
A named list of data frames, where each data frame corresponds to a cluster and contains a ranked set of potential marker genes.
In each data frame, the log-fold change of the cluster against every other cluster Y is also reported, under the column named \code{logFC.Y}.
} 

\author{
Aaron Lun
}

\seealso{
\code{\link{normalize}}
}

\references{
Law CW, Chen Y, Shi W and Smyth, GK (2014). 
voom: precision weights unlock linear model analysis tools for RNA-seq read counts. 
\emph{Genome Biol.} 15:R29 

Simes RJ (1986). 
An improved Bonferroni procedure for multiple tests of significance. 
\emph{Biometrika} 73:751-754.

Berger RL and Hsu JC (1996). 
Bioequivalence trials, intersection-union tests and equivalence confidence sets.
\emph{Statist. Sci.} 11, 283-319.
}

\examples{
example(computeSpikeFactors) # Using the mocked-up data 'y' from this example.

kout <- kmeans(t(exprs(y)), centers=2)

out <- findMarkers(y, clusters=kout$cluster)
}