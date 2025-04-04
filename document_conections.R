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

update_connections <- function(line, current_connections, folder_route){
  # Connections have the format '[[words|other]]. Get all connections:
  connections_found <- stringr::str_extract_all(
    string = line,
    pattern = '\\[\\[[^\\[\\]]+\\]\\]'
  )[[1]]
  
  print(connections_found)
  
  # Check if connections were found in this line
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
        file.path(folder_route, paste0(connections_found, '.md')))
    )
  }
  
  # If no connections were found, return the same vector
  return(current_connections)
}

documents_metadata <- function(folder_route, output_route=folder_route){
  # Get list of documents
  documents <- list.files(path=folder_route, pattern='.md')
  n_documents <- length(documents)
  
  # Initialize output list from number of documents
  metadata <- vector(mode = "list", length = n_documents)
  
  for (idx in 1:n_documents){
    # Get current document
    document <- documents[[idx]]
    
    # Initialize vectors to store information
    tags <- c()
    connections <- c()
    
    # Open document with read permissions
    route <- file.path(folder_route, document)
    d <- file(route, 'r')
    lines <- readLines(d, warn = F)
    
    # Extract information line by line
    for (line in lines){
      # Find tags
      tags <- update_tags(line = line, current_tags = tags)
      
      # Find connections
      connections <- update_connections(line = line, 
                                        current_connections = connections,
                                        folder_route = folder_route)
    }
    
    # Close document
    close(d)
    
    # Store information in metadata list
    metadata[[idx]] <- list(
      route = route,
      tags = tags,
      connections = connections
    )
  }
  
  return(metadata)
}

# Apply function
documents_route <- 'www/documents'
metadata <- documents_metadata(documents_route)

# Convert to JSON
json_data <- jsonlite::toJSON(metadata, pretty=TRUE)
write(json_data, paste(documents_route, 'metadata.json'))