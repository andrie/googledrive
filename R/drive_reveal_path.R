drive_reveal_path <- function(file) {
  ## refresh file metadata
  ## TO DO: is this really necessary? it makes things slow
  if (is_dribble(file)) {
    file <- as_id(file)
  }
  file <- as_dribble(file)
  if (no_file(file)) return(dribble_with_path())

  team_drive <- NULL
  corpus <- NULL
  tid <- purrr::map_chr(file$drive_resource, "teamDriveId", .default = NA)
  tid <- unique(tid[!is.na(tid)])
  if (length(tid) > 0) {
    if (length(tid) == 1) {
      team_drive <- as_id(tid)
    } else {
      corpus <- "all"
    }
  }

  nodes <- rbind(
    file,
    drive_find(type = "folder", team_drive = team_drive, corpus = corpus),
    make.row.names = FALSE
  ) %>% promote("parents")
  nodes <- nodes[!duplicated(nodes$id), ]

  ROOT_ID <- root_id()
  x <- purrr::map(file$id, ~ pathify_one_id(.x, nodes, ROOT_ID))

  ## TO DO: if (verbose), message if a dribble doesn't have exactly 1 row?
  do.call(rbind, x)
}

pathify_one_id <- function(id, nodes, root_id) {
  if (id == "root") return(dribble_with_path_for_root())
  leaf <- nodes$id == id
  if (!any(leaf)) return(dribble_with_path())
  pathify_prune_unnest(nodes, root_id = root_id, leaf = leaf)
}



## basically does the same as above, but for files specified via path
## does the actual work for drive_get(path = ...)
dribble_from_path <- function(path = NULL,
                              team_drive = NULL,
                              corpus = NULL) {
  if (length(path) == 0) return(dribble_with_path())
  stopifnot(is_path(path))
  path <- rootize_path(path)

  nodes <- get_nodes(path, team_drive, corpus)
  if (nrow(nodes) == 0) return(dribble_with_path())

  ROOT_ID <- root_id()
  x <- purrr::map(path, ~ pathify_one_path(.x, nodes, ROOT_ID))

  ## TO DO: if (verbose), message if a dribble doesn't have exactly 1 row?
  do.call(rbind, x)
}

pathify_one_path <- function(op, nodes, root_id) {
  if (is_rootpath(op)) return(dribble_with_path_for_root())

  name <- last(split_path(op))
  leaf <- nodes$name == name
  if (grepl("/$", op)) {
    leaf <- leaf & is_folder(nodes)
  }
  if (!any(leaf)) return(dribble_with_path())
  out <- pathify_prune_unnest(nodes, root_id = root_id, leaf = leaf)

  target <- paste0(strip_slash(op), "/?$")
  if (is_rooted(op)) {
    target <- paste0("^", target)
  }
  out <- out[grepl(target, out$path), ]
  out
}


## given a vector of paths,
## retrieves metadata for all files that could be needed to resolve paths
get_nodes <- function(path,
                      team_drive = NULL,
                      corpus = NULL) {

  path_parts <- purrr::map(path, partition_path, maybe_name = TRUE)
  ## workaround for purrr <= 0.2.2.2
  name <- purrr::map(path_parts, "name")
  name <- purrr::flatten_chr(purrr::map_if(name, is.null, ~ NA_character_))
  #name <- purrr::map_chr(path_parts, "name", .default = NA)
  names <- unique(name)
  names <- names[!is.na(names)]
  names <- glue("name = {sq(names)}")
  folders <- "mimeType = 'application/vnd.google-apps.folder'"
  q_clauses <- or(c(folders, names))

  nodes <- drive_find(
    team_drive = team_drive,
    corpus = corpus,
    q = q_clauses,
    verbose = FALSE
  )

  if (any(is_rootpath(path))) {
    nodes <- rbind(nodes, root_folder())
  }

  promote(nodes, "parents")
}