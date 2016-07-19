\name{Selector plot}
\alias{selectorPlot}

\title{Construct a selector plot via Shiny}
\description{Generate an interactive Shiny plot in which cells can be selected for further analysis.}

\usage{
selectorPlot(x, y, persist=FALSE, plot.width=5, plot.height=500, pch=16, ...)

}

\arguments{
\item{x, y}{Numeric vectors of x-y coordinates, of length equal to the number of cells.}
\item{persist}{A logical scalar indicating whether selections should persist after stopping the app.}
\item{plot.width}{A numeric scalar specifying the plot width, see \code{width} in \code{?\link[shiny]{column}}.}
\item{plot.height}{A numeric scalar specifying the plot height in pixels.}
\item{pch, ...}{Other arguments to pass to \code{plot}.}
}

\details{
This function will return a Shiny app object that can be run with \code{\link{runApp}}.
The aim is to perform dimensionality reduction to obtain coordinates for each cell, e.g., from PCA or t-SNE.
These coordinates can be plotted with \code{selectorPlot}, and subpopulations of interest can be interactively selected.
The selections can then be saved for further manipulation in R.

The app allows users to select groups of cells; mark them as cells of interest; and then save the marked cells into a list.
Currently marked cells will be shown in red, previously saved cells are shown in orange, and all other cells are shown in grey.
The distribution of saved cells is also shown in a separate plot indicating the list element to which they were saved.
This can be repeated multiple times to obtain several groups of interest.

Several buttons are available within the app:
\describe{
\item{\code{Select}:}{Marks the current selection of cells.}
\item{\code{Deselect}:}{Unmarks the current selection of cells.}
\item{\code{Clear selection}:}{Unmarks all currently marked cells.}
\item{\code{Add to list}:}{Saves currently marked cells into a list.}
\item{\code{Reset all}:}{Removes all marking, removes all saved cells from the list.}
\item{\code{Save list to R}:}{Stops the app and returns the list of saved cells to R.}
}
}

\value{
A Shiny app object is returned, which can be run with \code{\link{runApp}}.
This transfers control to a browser window where cells can be selected.
Upon stopping the app with the \code{Save list to R} button, control is transferred back to R and the list of saved cells is returned.
Each element of the list is a logical vector indicating which cells were saved in that group of interest.
}

\seealso{
\code{\link{runApp}}
}

\author{
Aaron Lun
}

\examples{
example(newSCESet)
pca <- plotPCA(example_sceset)

# Slightly tedious to extract x/y from ggplot objects:
x <- ggplot2::ggplot_build(pca)$data[[1]][,1]
y <- ggplot2::ggplot_build(pca)$data[[1]][,2]

app <- selectorPlot(x, y)

\dontrun{
saved <- shiny::runApp(app) 
}

}