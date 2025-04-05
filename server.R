library(shiny)
library(shinythemes)
library(markdown)
library(visNetwork)

# Necessary to read markdown file
doc_path <- 'www/documents'
doc_extension <- '.md'

# Tags list
index <- jsonlite::fromJSON(file.path(doc_path, 'tags.json'))

# --- Graph info ---
# Read metadata
metadata <- jsonlite::fromJSON(file.path(doc_path, 'metadata.json'))

# Load documents
docs_graph <- tools::file_path_sans_ext( # No extension
  basename(unlist(metadata[['path']])) # No path
)

# # Load documents' tag
# docs_tags <- sapply(metadata[['tags']], function(x){ ifelse(length(x)==0, 'No tag', x) })
# docs_tags

nodes <- data.frame(
  id = seq_along(docs_graph),
  label = docs_graph,
  tag = docs_tags
)

# Connections
edges <- data.frame(from = integer(), to = integer())

for (idx in seq_along(docs_graph)){
  from_id <- idx
  linked_document_paths <- metadata[['connections']][[idx]]
  
  # Skip unconnected files
  if (length(linked_document_paths) != 0){
    linked_docs <- tools::file_path_sans_ext(basename(liked_document_paths))
    linked_idx <- unlist(sapply(linked_docs, function(x){ nodes$id[nodes$label == x] }))
    
    for (to_id in linked_idx){
      edges <- rbind(edges,
                     data.frame(from = from_id, to = to_id, 
                                smooth = T))
    }
  }
}

# --- Define Server ---
server <- function(input, output, session) {
  # Update document selection based on selected tag
  observeEvent(input$tag, {
    # Documents under selected tag
    if (input$tag == 'No tag'){
      docs <- list.files(doc_path)
    } else {
      docs <- index[[input$tag]]
    }
    
    # Pretty names (no path or extension)
    docs_names <- basename(tools::file_path_sans_ext(docs))
    
    # Update choices
    updateSelectInput(session, 'file', choices = docs_names)
  })
  
  # Show selected document
  output$doc_output <- renderUI({
    req(input$file) # Get filename
    
    # Read Markdown File
    file_path <- paste(doc_path, '/', input$file, doc_extension, sep='')
    content <- markdown::markdownToHTML(file_path, fragment.only = TRUE)
    
    HTML(content)
  })
  
  # Graph visualization
  output$note_network <- renderVisNetwork({
    visNetwork(nodes, edges) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>% 
      # visLegend(enabled = TRUE) %>% # can be dinamically deactivated
      visOptions(selectedBy = "tag") %>%
      visNodes(
        font = list(
          size = 20,      # Text size
          color = 'black',
          # color = "#6B403C",  # Text color
          face = "arial", # Font family (can be "arial", "courier", "times", etc.)
          align = "center"   # Text alignment ("left", "right", "center")
        ),
        # color = list(
        #   background = '#ADEBB3', border = '#5FCFB6'
        #   ),
        shape = 'box') %>% 
      visLayout(
        randomSeed = 1,  # Set a fixed random seed for reproducibility
        improvedLayout = TRUE  # Enable improved layout for better distribution
      ) %>% 
      visPhysics(
        enabled = TRUE,              # Enable physics
        barnesHut = list(
          gravitationalConstant = -2000,
          centralGravity = 0.3,
          springLength = 100,
          springConstant = 0.01,
          damping = 0.1
        ),
        repulsion = list(
          nodeDistance = 500
        )
      )
    
  })
}