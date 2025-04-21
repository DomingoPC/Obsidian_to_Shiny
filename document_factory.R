update_tags <- function(line, current_tags){
  # Tags have the format '#words'. Get all tags: 
  tags_found <- stringr::str_extract_all(line, '#\\w+')[[1]]
  
  # Check if tags are found
  if (!identical(tags_found, character(0))){
    # Tags found in this line -> Remove # and store them
    tags_found <- stringr::str_replace_all(tags_found, '#', '')
    
    # Return updated tags
    return(c(current_tags, tags_found))
  }
  
  # If no tags were found, return the same vector
  return(current_tags)
}

update_connections <- function(line, current_connections, folder_path){
  # Connections have the format '[[words|other]]. Get all connections:
  connections_found <- stringr::str_extract_all(
    string = line,
    pattern = '\\[\\[[^\\[\\]]+\\]\\]'
  )[[1]]
  
  # Check if connections were found in this text line
  if (!identical(connections_found, character(0))){
    # Connections found -> remove '`[[' and ']]' symbols
    connections_found <- stringr::str_replace_all(
      string = connections_found,
      pattern = '[\\[\\]]', # All '[' and ']' symbols
      replacement = ''
    )
    
    # From 'words|other' the second part is optional and has to be removed
    connections_found <- stringr::str_replace_all(
      string = connections_found,
      pattern = '\\|.+',
      replacement = ''
    )
    
    # Return updated connections
    return(
      c(current_connections, 
        file.path(folder_path, paste0(connections_found, '.md')))
    )
  }
  
  # If no connections were found, return the same vector
  return(current_connections)
}

parse_current_line <- function(line){
  # --- Remove tags ---
  parsed_line <- stringr::str_replace_all(line, '#\\w+', '')
  
  # --- Change connections by hlinks ---
  # [[document_name|display_name]] -> [[document_name]]
  # Pattern explanation: 
  #   · \\|         ->  starts with "|"
  #   · [^\\[\\]]+  ->  anything that's not "[" or "]"
  #   · \\]\\]      ->  ends with "]]"  
  parsed_line <- stringr::str_replace_all(parsed_line, '\\|[^\\[\\]]+\\]\\]', ']]')
  
  # [[document_name]] -> hlink
  # Pattern explanation:
  #   · \\[\\[        ->  Starts with "[["
  #   · ([^\\[\\]]+)  ->  Anything that's not "[" nor "]" (first group = '\\1')
  #   · \\]\\]        ->  Ends with "]]"
  #
  # Replacement explanation:
  #   · <a href='#'>  ->  Makes it look like a link
  #   · '\\1'         ->  Refers to the first group found in the pattern (the document name)
  #   · onclick="Shiny.setInputValue('linked_doc_click', '\\1')"  
  #       ->  communicate Shiny the user wants to read the document '\\1'
  
  parsed_line <- stringr::str_replace_all(
    string = parsed_line,
    pattern = '\\[\\[([^\\[\\]]+)\\]\\]',
    replacement = "<a href='#' class='note-link' data-id='\\1' onclick=\"Shiny.setInputValue('linked_doc_click', '\\1', {priority: 'event'}); return false;\">\\1</a>"
  )
  
  # Return parsed line
  return(parsed_line)
}


documents_metadata <- function(input_path, output_path){
  # Get list of documents
  documents <- list.files(path=input_path, pattern='.md')
  n_documents <- length(documents) # to preallocate list
  
  # Initialize output list from number of documents
  metadata <- vector(mode = "list", length = n_documents)
  
  for (idx in 1:n_documents){
    # Get current document
    document <- documents[[idx]]
    
    # Initialize vectors to store information
    tags <- c()
    connections <- c()
    
    # Input: Open document with read permissions
    no_parsed_path <- file.path(input_path, document)
    r <- file(no_parsed_path, 'r')
    lines <- readLines(r, warn = F)
    
    # Output: Open docuement with write permissions
    parsed_path <- file.path(output_path, document)
    name <- basename(tools::file_path_sans_ext(parsed_path))
    w <- file(parsed_path, 'w')
    
    # The header must be the documents' name
    header <- paste('#', name)
    writeLines(header, w)
    
    # Extract information line by line
    for (line in lines){
      # --- Extract tags and connections ---
      # Find tags
      tags <- update_tags(line = line, current_tags = tags)
      
      # Find connections
      connections <- update_connections(line = line, 
                                        current_connections = connections,
                                        folder_path = output_path)
      
      # --- Parse document ---
      writeLines(parse_current_line(line), w)
    }
    
    # Close documents
    close(r); close(w)
    
    # Store information in metadata list
    metadata[[idx]] <- list(
      path = parsed_path,
      name = name,
      tags = tags,
      connections = unique(connections),
      connections_names = sapply(unique(connections), FUN = function(x){ basename(tools::file_path_sans_ext(x)) })
    )
  }
  
  return(metadata)
}

# --- Extract metadata ---
# Documents paths
original_documents_path <- 'documents to parse' # no yet parsed
parsed_documents_path <- 'www/documents' # final product

# Remove old files from output folder
unlink(file.path(parsed_documents_path, '*'))

# Apply function
metadata <- documents_metadata(
  input_path = original_documents_path,
  output_path = parsed_documents_path
)

# Convert to JSON
json_data <- jsonlite::toJSON(metadata, pretty=TRUE)
write(json_data, file.path(parsed_documents_path, 'metadata.json'))

# --- Use metadata to get tags list ---
tags_list <- list()
for (data_list in metadata){
  document_path <- data_list[['path']]
  document_tags <- data_list[['tags']]
  
  for (tag in document_tags){
    tags_list[[tag]] <- c(tags_list[[tag]], document_path)
  }
}

# Convert to JSON
json_tags <- jsonlite::toJSON(tags_list, pretty=T)
write(json_tags, file.path(parsed_documents_path, 'tags.json'))

# --- Graph info ---
# Get all documents (even non written, they appear only as connections)
nodes <- data.frame(
  id = integer(),
  label = character(),
  tag = character(),
  stringsAsFactors = FALSE
)

edges <- data.frame(
  from = integer(),
  to = integer()
)

next_id <- 1
for (doc in metadata){
  # Document names
  label <- doc$name
  connected_labels <- doc$connections_names
  
  # Add the document to nodes
  if (!(label %in% nodes$label)){
    # Add new document to node list
    nodes <- rbind(
      nodes,
      data.frame(
        id = next_id,
        label = label,
        tag = ifelse(length(doc$tags) != 0, doc$tags, 'No tag')
      )
    )
    
    # Update id for next document
    next_id <- next_id + 1
  } else {
    # If the document was already recorded from previous connections, update its tag
    nodes$tag[nodes$label == label] = ifelse(length(doc$tags) != 0, doc$tags, 'No tag')
  }
  
  # Process connections (if this document has any)
  if (!(length(connected_labels) == 0)){
    for (l in connected_labels){
      # Add to node list before adding to edges
      if (!(l %in% nodes$label)){
        nodes <- rbind(
          nodes, 
          data.frame(
            id = next_id,
            label = l, 
            tag = 'Not Written')
        )
        
        # Update id for next document
        next_id <- next_id + 1
      }
      
      # Store connection
      ids <- sapply(c(label, l), FUN = function(x){ nodes$id[nodes$label == x] })
      edges <- rbind(edges, data.frame(from = ids[[1]], to = ids[[2]]))
    }
  }
  
  
  
  
}

# Save tables as csv to use in server to build the graph
write.csv(nodes, file=file.path(parsed_documents_path, 'nodes.csv'))
write.csv(edges, file=file.path(parsed_documents_path, 'edges.csv'))
