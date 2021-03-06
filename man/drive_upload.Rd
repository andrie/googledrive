% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/drive_upload.R
\name{drive_upload}
\alias{drive_upload}
\title{Upload into a new Drive file}
\usage{
drive_upload(media, path = NULL, name = NULL, type = NULL, ...,
  overwrite = NA, verbose = TRUE)
}
\arguments{
\item{media}{Character, path to the local file to upload.}

\item{path}{Specifies target destination for the new file on Google
Drive. Can be an actual path (character), a file id marked with \code{\link[=as_id]{as_id()}},
or a \code{\link{dribble}}. If specified as an actual path, it is best to explicitly
indicate if it's a folder by including a trailing slash, since it cannot
always be worked out from the context of the call. Will default to its local name.}

\item{name}{Character, new file name if not specified as part of
\code{path}. This will force \code{path} to be treated as a folder, even if it is
character and lacks a trailing slash. Will default to its local name.}

\item{type}{Character. If \code{type = NULL}, a MIME type is automatically
determined from the file extension, if possible. If the source file is of a
suitable type, you can request conversion to Google Doc, Sheet or Slides by
setting \code{type} to \code{document}, \code{spreadsheet}, or \code{presentation},
respectively. All non-\code{NULL} values for \code{type} are pre-processed with
\code{\link[=drive_mime_type]{drive_mime_type()}}.}

\item{...}{Named parameters to pass along to the Drive API. Has the tidy dots
semantics that come from using \code{\link[rlang:list2]{rlang::list2()}}. You can affect the
metadata of the target file by specifying properties of the Files resource
via \code{...}. Read the "Request body" section of the Drive API docs for the
associated endpoint to learn about relevant parameters.}

\item{overwrite}{Logical, indicating whether to check for a pre-existing file
at the targetted "filepath". The quotes around "filepath" refer to the fact
that Drive does not impose a 1-to-1 relationship between filepaths and files,
like a typical file system; read more about that in \code{\link[=drive_get]{drive_get()}}.
\itemize{
\item \code{NA} (default): Just do the operation, even if it results in multiple
files with the same filepath.
\item \code{TRUE}: Check for a pre-existing file at the filepath. If there is
zero or one, move a pre-existing file to the trash, then carry on. Note
that the new file does not inherit any properties from the old one, such
as sharing or publishing settings. It will have a new file ID. An error is
thrown if two or more pre-existing files are found.
\item \code{FALSE}: Error if there is any pre-existing file at the filepath.
}

Note that existence checks, based on filepath, are expensive operations, i.e.
they require additional API calls.}

\item{verbose}{Logical, indicating whether to print informative messages
(default \code{TRUE}).}
}
\value{
An object of class \code{\link{dribble}}, a tibble with one row per item.
}
\description{
Uploads a local file into a new Drive file. To update the content or metadata
of an existing Drive file, use \code{\link[=drive_update]{drive_update()}}. To upload or update,
depending on whether the Drive file already exists, see \code{\link[=drive_put]{drive_put()}}.
}
\examples{
\dontrun{
## upload a csv file
chicken_csv <- drive_upload(
  drive_example("chicken.csv"),
  "chicken-upload.csv"
)

## or convert it to a Google Sheet
chicken_sheet <- drive_upload(
  drive_example("chicken.csv"),
  name = "chicken-sheet-upload.csv",
  type = "spreadsheet"
)

## check out the new Sheet!
drive_browse(chicken_sheet)

## clean-up
drive_find("chicken.*upload") \%>\% drive_rm()

## Upload a file and, at the same time, star it
chicken <- drive_upload(
  drive_example("chicken.jpg"),
  starred = "true"
)

## Is is really starred? YES
purrr::pluck(chicken, "drive_resource", 1, "starred")

## Clean up
drive_rm(chicken)

## `overwrite = FALSE` errors if something already exists at target filepath
## THIS WILL ERROR!
drive_create("name-squatter")
drive_upload(
  drive_example("chicken.jpg"),
  name = "name-squatter",
  overwrite = FALSE
)

## `overwrite = TRUE` moves the existing item to trash, then proceeds
chicken <- drive_upload(
  drive_example("chicken.jpg"),
  name = "name-squatter",
  overwrite = TRUE
)

## Clean up
drive_rm(chicken)

## Upload to a Team Drive:
##   * your Google account must have Team Drive privileges, obviously
##   * the Team Drive (or Team Drive-hosted folder) MUST be captured as a
##     dribble first and provided via `path`
td <- team_drive_get("Marketing")
drive_upload("fascinating.csv", path = td)
}
}
\seealso{
Wraps the \code{files.create} endpoint:
\itemize{
\item \url{https://developers.google.com/drive/v3/reference/files/create}
}

MIME types that can be converted to native Google formats:
\itemize{
\item \url{https://developers.google.com/drive/v3/web/manage-uploads#importing_to_google_docs_types_wzxhzdk18wzxhzdk19}
}
}
