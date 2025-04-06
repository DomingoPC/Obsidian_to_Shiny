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
    w <- file(parsed_path, 'w')
    
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
      tags = tags,
      connections = unique(connections)
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

