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

# Load documents' tag
docs_tags <- sapply(metadata[['tags']], function(x){ ifelse(length(x)==0, 'No tag', x) })
docs_tags

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
    linked_docs <- tools::file_path_sans_ext(basename(linked_document_paths))
    linked_idx <- unlist(sapply(linked_docs, function(x){ nodes$id[nodes$label == x] }))
    
    for (to_id in linked_idx){
      edges <- rbind(edges,
                     data.frame(from = from_id, to = to_id, 
                                smooth = T))
    }
  }
}

# Dynamic menus
get_submenus <- function(tag){
  submenu_list <- list()
  doc_names <- basename(tools::file_path_sans_ext(index[[tag]]))
  
  # Create submenus
  for (name in doc_names){
    # tabName is tag◘document
    # ◘ (Alt+8) : to use a weird symbol as separator
    submenu <- menuSubItem(
      text = name,
      tabName = paste0(tag, '◘', name)
    )
    
    # Add submenu to the list
    submenu_list <- append(submenu_list, list(submenu))
  }
  
  # Return list of submenus
  return(
    menuItem(
      text = tag,
      # startExpanded = F,
      do.call(tagList, submenu_list) # spread list as different elements
    )
  )
}

# --- Define Server ---
server <- function(input, output, session) {
  # --- Dynamic Menus ---
  output$dynamic_planets_menu <- renderMenu({
    get_submenus(tag = 'Planets')
  })
  
  output$dynamic_species_menu <- renderMenu({
    get_submenus(tag = 'Species')
  })
  
  output$dynamic_sources_menu <- renderMenu({
    get_submenus(tag = 'Sources')
  })
  
  # --- Document selection ---
  # Update document selection based on selected tag
  observeEvent(input$tag, {
    # Documents under selected tag
    if (input$tag == 'No tag'){
      docs <- list.files(doc_path, pattern='.md', full.names=FALSE)
    } else {
      docs <- index[[input$tag]]
    }
    
    # Pretty names (no path or extension)
    docs_names <- basename(tools::file_path_sans_ext(docs))
    
    # Update choices
    updateSelectInput(session, 'file', choices = docs_names)
  })
  
  # Show selected document
  observeEvent(input$file, {
    # Given document path
    file_path <- file.path(doc_path, paste0(input$file, '.md'))
    
    # Check if the document path leads to an actual file
    if (file.exists(file_path)){
      content <- markdown::markdownToHTML(file_path, fragment.only = TRUE)
      
      # Update UI with the content found
      output$doc_output <- renderUI({HTML(content)})
    } else {
      # Show error if document not found
      output$doc_output <- renderUI({HTML("Document not found.")})
    }
  })
  
  # Update selected document from document links
  # linked_doc_click  ->  manually inserted in Markdown parsing
  observeEvent(input$linked_doc_click, {
    # Reset tags
    updateSelectInput(session, 'tag', selected = 'No tag')
    
    # Show selected document
    updateSelectInput(session, 'file', selected = input$linked_doc_click)
  })

  # Update selected document from sidebar_menu links
  observeEvent(input$sidebar_menu, {
    # Divide by '◘': [[1]] tag  [[2]] document
    sidebar_menu <- stringr::str_split(input$sidebar_menu, pattern='◘')[[1]]
    tag <- sidebar_menu[[1]]
    
    if (tag %in% names(index)){
      updateSelectInput(session, 'file', selected = sidebar_menu[[2]])
    }
      
    
  })
  
  # --- Graph ---
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