#' Spin goat's hair into wool
#'
#' This function takes a specially formatted R script and converts it to a
#' literate programming document. By default normal text (documentation) should
#' be written after the roxygen comment (\code{#'}) and code chunk options are
#' written after \code{#+} or \code{#-}.
#'
#' Obviously the goat's hair is the original R script, and the wool is the
#' literate programming document (ready to be knitted).
#' @param hair the path to the R script
#' @param knit logical: whether to compile the document after conversion
#' @param report logical: whether to generate report for \file{Rmd}, \file{Rnw}
#'   and \file{Rtex} output (ignored if \code{knit = FALSE})
#' @param format character: the output format (it takes five possible values);
#'   the default is R Markdown
#' @param doc a regular expression to identify the documentation lines; by
#'   default it follows the roxygen convention, but it can be customized, e.g.
#'   if you want to use \code{##} to denote documentation, you can use
#'   \code{'^##\\\\s*'}
#' @inheritParams knit
#' @author Yihui Xie, with the original idea from Richard FitzJohn (who named it
#'   as \code{sowsear()} which meant to make a silk purse out of a sow's ear)
#' @return The path of the literate programming document.
#' @note If the output format is Rnw and no document class is specified in
#'   roxygen comments, this function will automatically add the \code{article}
#'   class to the LaTeX document so that it is complete and can be compiled. You
#'   can always specify the document class and other LaTeX settings in roxygen
#'   comments manually.
#' @export
#' @seealso \code{\link{stitch}} (feed a template with an R script)
#' @references \url{http://yihui.name/knitr/demo/stitch/}
#' @examples #' write normal text like this and chunk options like below
#'
#' #+ label, opt=value
#'
#' (s = system.file('examples', 'knitr-spin.R', package = 'knitr'))
#' spin(s)  # default markdown
#' o = spin(s, knit = FALSE) # convert only; do not make a purse yet
#' knit2html(o) # compile to HTML
#'
#' # other formats
#' spin(s, FALSE, format='Rnw')  # you need to write documentclass after #'
#' spin(s, FALSE, format='Rhtml')
#' spin(s, FALSE, format='Rtex')
#' spin(s, FALSE, format='Rrst')
spin = function(hair, knit = TRUE, report = TRUE, format = c('Rmd', 'Rnw', 'Rhtml', 'Rtex', 'Rrst'),
                doc = "^#+'[ ]?", envir = parent.frame()) {

  format = match.arg(format)
  x = readLines(hair, warn = FALSE); r = rle(str_detect(x, doc))
  n = length(r$lengths); txt = vector('list', n); idx = c(0L, cumsum(r$lengths))
  p = .fmt.pat[[tolower(format)]]
  p1 = str_replace(str_c('^', p[1L], '.*', p[2L], '$'), '\\{', '\\\\{')

  for (i in seq_len(n)) {
    block = x[seq(idx[i] + 1L, idx[i+1])]
    txt[[i]] = if (r$value[i]) {
      # normal text; just strip #'
      str_replace(block, doc, '')
    } else {
      # R code; #+/- indicates chunk options
      block = strip_white(block) # rm white lines in beginning and end
      if (!length(block)) next
      if (any(opt <- str_detect(block, '^#+(\\+|-)'))) {
        block[opt] = str_c(p[1L], str_replace(block[opt], '^#+(\\+|-)\\s*', ''), p[2L])
      }
      if (!str_detect(block[1L], p1)) {
        block = c(str_c(p[1L], p[2L]), block)
      }
      c('', block, p[3L], '')
    }
  }

  outsrc = str_c(file_path_sans_ext(hair), '.', format)
  txt = unlist(txt)
  # make it a complete TeX document if document class not specified
  if (report && format %in% c('Rnw', 'Rtex') && !str_detect(txt, '^\\s*\\\\documentclass')) {
    txt = c('\\documentclass{article}', '\\begin{document}', txt, '\\end{document}')
  }
  cat(txt, file = outsrc, sep = '\n')
  if (knit) {
    if (report) {
      if (format == 'Rmd') knit2html(outsrc, envir = envir) else
        if (format %in% c('Rnw', 'Rtex')) knit2pdf(outsrc, envir = envir)
    } else knit(outsrc, envir = envir)
  }

  invisible(outsrc)
}

.fmt.pat = list(
  rmd = c('```{r ', '}', '```'), rnw = c('<<', '>>=', '@'),
  rhtml = c('<!--begin.rcode ', '', 'end.rcode-->'),
  rtex = c('% begin.rcode ', '', '% end.rcode'), rrst = c('.. {r ', '}', '.. ..')
)
