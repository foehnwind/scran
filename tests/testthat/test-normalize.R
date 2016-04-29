# This tests out the normalization methods in scran - specifically, compute*Factors and normalize().

require(scran); require(testthat)

set.seed(20000)
ncells <- 200
ngenes <- 1000
count.sizes <- rnbinom(ncells, mu=100, size=5)
dummy <- matrix(count.sizes, ncol=ncells, nrow=ngenes, byrow=TRUE)

out <- computeSumFactors(dummy)
expect_equal(out, count.sizes/exp(mean(log(count.sizes))))

# Adding some DE genes.

count.sizes <- rnbinom(ncells, mu=100, size=5)
dummy <- matrix(count.sizes, ncol=ncells, nrow=ngenes, byrow=TRUE)
is.de <- sample(ngenes, 100)
dummy[is.de,] <- rnbinom(ncells*length(is.de), mu=100, size=1)
out <- computeSumFactors(dummy)
expect_equal(out, count.sizes/exp(mean(log(count.sizes))))

count.sizes <- rnbinom(ncells, mu=100, size=5)
dummy <- matrix(count.sizes, ncol=ncells, nrow=ngenes, byrow=TRUE)
is.de <- sample(ngenes, 400)
dummy[is.de,] <- rnbinom(ncells*length(is.de), mu=100, size=1)
out <- computeSumFactors(dummy)
expect_equal(out, count.sizes/exp(mean(log(count.sizes))))

# Trying it out with other options.

outx <- computeSumFactors(dummy, positive=TRUE)
expect_true(all(abs(outx -  out) < 1e-3)) # need to be a bit generous here, the solution code is different.
outx <- computeSumFactors(dummy, errors=TRUE)
expect_equal(as.numeric(outx), out)
expect_identical(names(attributes(outx)), "standard.error")

# Trying it out on a SCESet object.

count.sizes <- rnbinom(ncells, mu=100, size=5)
dummy <- matrix(count.sizes, ncol=ncells, nrow=ngenes, byrow=TRUE)
rownames(dummy) <- paste0("X", seq_len(ngenes))
X <- newSCESet(countData=data.frame(dummy))
out <- computeSumFactors(X)
expect_equal(unname(sizeFactors(out)), computeSumFactors(dummy))

# Throwing in some silly inputs.

expect_error(computeSumFactors(dummy[,0,drop=FALSE]), "not enough cells in each cluster")
expect_error(computeSumFactors(dummy[0,,drop=FALSE]), "cells should have non-zero library sizes")
expect_warning(computeSumFactors(dummy[,1:100]), "number of cells in each cluster should be at least twice")
expect_error(computeSumFactors(dummy, sizes=c(10, 10, 20)), "'sizes' is not unique")
expect_error(computeSumFactors(dummy, clusters=integer(0)), "'x' ncols is not equal to 'clusters' length")

# Checking the ring construction.

lib.sizes <- runif(100)
out <- scran:::.generateSphere(lib.sizes)
r <- rank(lib.sizes)
expect_identical(r[out][1:50], 1:50*2-1L) # All odd ranks
expect_identical(r[out][51:100], 50:1*2) # All even ranks
expect_identical(r[out][1:100], r[out][101:200]) # Repeated for easy windowing

lib.sizes <- runif(101)
out <- scran:::.generateSphere(lib.sizes)
r <- rank(lib.sizes)
expect_identical(r[out][1:51], 1:51*2-1L) # All odd ranks
expect_identical(r[out][52:101], 50:1*2) # All even ranks
expect_identical(r[out][1:101], r[out][102:202]) # Repeated for easy windowing

# Checking the matrix construction.

cur.exprs <- matrix(1, nrow=ngenes, ncol=ncells)
subsphere <- sample(ncells)
sphere <- c(subsphere, subsphere)
sizes <- c(20, 51)
use.ave.cell <- rep(1, ngenes)
out <- scran:::.create_linear_system(as.integer(ngenes), as.integer(ncells), cur.exprs, sphere, as.integer(sizes), use.ave.cell)

out$design <- as.matrix(out$design)
size <- sizes[1]
for (i in seq_len(ncells)) { 
    used <- sphere[i:(i+size-1)]
    expect_equal(out[[1]][i, used], rep(1, size))
    expect_equal(out[[1]][i, -used], rep(0, ncells-size))
}
size <- sizes[2]
for (i in seq_len(ncells)) { 
    used <- sphere[i:(i+size-1)]
    expect_equal(out[[1]][i + ncells, used], rep(1, size))
    expect_equal(out[[1]][i + ncells, -used], rep(0, ncells-size))
}
for (i in seq_len(ncells)) { 
    used <- sphere[i]
    expect_equal(out[[1]][i + ncells*2, used], sqrt(0.000001))
    expect_equal(out[[1]][i + ncells*2, -used], rep(0, ncells-1L))
}

expect_identical(nrow(out$design), as.integer(ncells*(length(sizes)+1L)))
expect_identical(ncol(out$design), as.integer(ncells))
expect_equal(out[[2]], rep(c(sizes, sqrt(0.000001)), each=ncells))

####################################################################################################

# Checking out what happens with clustering.

set.seed(20001)
ncells <- 700
ngenes <- 1000
count.sizes <- rnbinom(ncells, mu=100, size=5)
multiplier <- seq_len(ngenes)/100
dummy <- outer(multiplier, count.sizes)

known.clusters <- sample(3, ncells, replace=TRUE)
dummy[1:300,known.clusters==1L] <- 0
dummy[301:600,known.clusters==2L] <- 0  
dummy[601:900,known.clusters==3L] <- 0

emp.clusters <- quickCluster(dummy)
expect_true(length(unique(paste0(known.clusters, emp.clusters)))==3L)

# Checking out what happens with silly inputs.

expect_error(quickCluster(dummy[0,]), "NA/NaN/Inf in foreign function call") # because the correlations are undefined.
expect_error(quickCluster(dummy[,0]), "fewer cells than the mininimum cluster size")

leftovers <- 100
expect_warning(forced <- quickCluster(dummy[,c(which(known.clusters==1), which(known.clusters==2), which(known.clusters==3)[1:leftovers])]), 
               sprintf("%i cells were not assigned to any cluster", leftovers))
expect_identical(as.character(tail(forced, leftovers)), rep("0", leftovers))

# Seeing how it interacts with the normalization method.

out <- computeSumFactors(dummy, cluster=known.clusters)
expect_equal(out, count.sizes/exp(mean(log(count.sizes)))) # Even though there is a majority of DE, each pair of clusters is still okay.

out1 <- computeSumFactors(dummy, cluster=known.clusters, ref=1)
expect_equal(out, out1)
out2 <- computeSumFactors(dummy, cluster=known.clusters, ref=2)
expect_equal(out, out2)
out3 <- computeSumFactors(dummy, cluster=known.clusters, ref=3)
expect_equal(out, out3)

expect_error(computeSumFactors(dummy, cluster=known.clusters, ref=0), "'ref.clust' value not in 'clusters'")

# Trying it out on a SCESet object.

set.seed(20002)
count.sizes <- rnbinom(ncells, mu=100, size=5)
multiplier <- sample(seq_len(ngenes)/100)
dummy <- outer(multiplier, count.sizes)

known.clusters <- sample(3, ncells, replace=TRUE)
dummy[1:300,known.clusters==1L] <- 0
dummy[301:600,known.clusters==2L] <- 0  
dummy[601:900,known.clusters==3L] <- 0

rownames(dummy) <- paste0("X", seq_len(ngenes))
X <- newSCESet(countData=data.frame(dummy))
emp.clusters <- quickCluster(X)
expect_true(length(unique(paste0(known.clusters, emp.clusters)))==3L)

####################################################################################################

# Checking out the behaviour of the computeSpikeFactors function.

set.seed(20003)
ncells <- 200
ngenes <- 1000
dummy <- matrix(rnbinom(ncells*ngenes, mu=100, size=5), ncol=ncells, nrow=ngenes, byrow=TRUE)
is.spike <- rbinom(ngenes, 1, 0.7)==0L
dummy[is.spike,] <- matrix(rnbinom(sum(is.spike)*ncells, mu=20, size=5), ncol=ncells, nrow=sum(is.spike), byrow=TRUE)

rownames(dummy) <- paste0("X", seq_len(ngenes))
X <- newSCESet(countData=data.frame(dummy))
isSpike(X) <- is.spike
out <- computeSpikeFactors(X)
ref <- log(colSums(dummy[is.spike,]))
expect_equal(unname(sizeFactors(out)), exp(ref-mean(ref)))

# Breaks if you try to feed it silly inputs.

expect_warning(out <- computeSpikeFactors(X[0,]), "zero spike-in counts during spike-in normalization")
expect_identical(unname(sizeFactors(out)), rep(NaN, ncol(out)))
out <- computeSpikeFactors(X[,0])
expect_identical(unname(sizeFactors(out)), numeric(0))

####################################################################################################

# Checking out the behaviour of the normalize() function.

set.seed(20003)
ncells <- 200
ngenes <- 1000
dummy <- matrix(rnbinom(ncells*ngenes, mu=100, size=5), ncol=ncells, nrow=ngenes, byrow=TRUE)
rownames(dummy) <- paste0("X", seq_len(ngenes))
X <- newSCESet(countData=data.frame(dummy))

ref <- log(colSums(dummy))
sf <- exp(ref-mean(ref))
sizeFactors(X) <- sf
out <- normalize(X)
expect_equivalent(exprs(out), edgeR::cpm.default(dummy, lib.size=sf*1e6, prior.count=1, log=TRUE))

out <- normalize(X, log=FALSE)
expect_equivalent(exprs(out), edgeR::cpm.default(dummy, lib.size=sf*1e6, prior.count=1, log=FALSE))
out <- normalize(X, prior.count=3)
expect_equivalent(exprs(out), edgeR::cpm.default(dummy, lib.size=sf*1e6, prior.count=3, log=TRUE))

sf <- log(runif(ncells, 10, 20))
sf <- exp(ref-mean(ref))
sizeFactors(X) <- sf
out <- normalize(X)
expect_equivalent(exprs(out), edgeR::cpm.default(dummy, lib.size=sf*1e6, prior.count=1, log=TRUE))

isSpike(X) <- rbinom(ngenes, 1, 0.7)==0L
X3 <- normalize(X, separate.spikes=FALSE)
expect_equivalent(exprs(out), exprs(X3))

X4 <- normalize(X)
expect_equivalent(exprs(out)[!isSpike(X),], exprs(X4)[!isSpike(X),])
X5 <- computeSpikeFactors(X)
X5 <- normalize(X5)
expect_equal(exprs(X4)[isSpike(X),], exprs(X5)[isSpike(X),])

# Checking out silly inputs.

expect_equal(unname(dim(normalize(X[,0,drop=FALSE]))), c(ngenes, 0L))
expect_equal(unname(dim(normalize(X[0,,drop=FALSE]))), c(0L, ncells)) 

