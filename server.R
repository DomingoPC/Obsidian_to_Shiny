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
nodes <- read.csv(file.path(doc_path, 'nodes.csv'))
edges <- read.csv(file.path(doc_path, 'edges.csv'))

# Use the tag column to separate in groups
nodes$group <- nodes$tag

# Sort the groups to sort the legend
custom_order <- c("Planets", "Species", "Sources", "No tag", "Not Written")

nodes$group <- factor(nodes$group, levels = custom_order)
nodes <- nodes[order(nodes$group), ]

# --- Dynamic menus ---
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
  
  # --- Download Document as PDF ---
  # Simulate Download Button Click
  observeEvent(input$export_pdf, {
    # Given document path
    file_path <- file.path(doc_path, paste0(input$file, '.md'))
    
    # Check if the document path leads to an actual file
    if (file.exists(file_path)){
      # Simulate Download Button Click
      input$export_pdf
    }
  })
  
  # Download as PDF
  output$export_pdf <- downloadHandler(
    filename = function() {
      paste0(input$file, Sys.Date(), ".html")
    },
    content = function(file) {
      file_path <- file.path(doc_path, paste0(input$file, '.md'))
      rmarkdown::render(file_path, output_format = 'html_document', output_file = file)
    }
  )
  
  
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
  
  # Go to selected document from graph
  observeEvent(input$goto_graph, {
    node_id <- input$selected_node # selected node id
    doc <- nodes$label[nodes$id == node_id] # corresponding document label
    
    # Check if it's a valid document
    tag <- nodes$tag[nodes$label == doc]
    
    if (!((tag == 'Not Written') || (length(tag) == 0))){
      # Update document selection
      updateSelectInput(session, 'file', selected = doc)
      
      # Move user to notes section
      updateTabItems(session, inputId = 'sidebar_menu', selected = 'notes')
    }
  })
  
  # --- Graph ---
  # Graph visualization
  output$note_network <- renderVisNetwork({
    visNetwork(nodes, edges, width = '100%') %>%
      
      # Global Nodes Parameters
      visNodes(
        shape = 'box',
        font = list(
          size = 20,      # Text size
          color = 'black',
          face = "arial", # Font family (can be "arial", "courier", "times", etc.)
          align = "center"   # Text alignment ("left", "right", "center")
        )) %>% 
      
      # Modify groups
      visGroups(groupname = 'Planets',
                shape = 'box',
                color = list(border = '#66A839', background = '#B0F580',
                             highlight = list(border = "#66A839", background = "#B0F580"), 
                             hover = list(background = "#66A839", border = "#B0F580")
                )) %>% 
      visGroups(groupname = 'Species',
                shape = 'box',
                color = list(border = 'red', background = 'pink',
                             highlight = list(border = "red", background = "pink"), 
                             hover = list(background = "red", border = "pink")
                )) %>% 
      visGroups(groupname = 'Sources',
                shape = 'box',
                color = list(border = '#8441F0', background = '#C8AEF2',
                             highlight = list(border = "#8441F0", background = "#C8AEF2"), 
                             hover = list(background = "#8441F0", border = "#C8AEF2")
                )) %>% 
      visGroups(groupname = 'No tag',
                shape = 'box',
                color = list(border = '#2B7CE9', background = '#D2E5FF',
                             highlight = list(border = "#2B7CE9", background = "#D2E5FF"), 
                             hover = list(background = "#2B7CE9", border = "#D2E5FF")
                )) %>% 
      visGroups(groupname = 'Not Written',
                shape = 'box',
                color = list(border = 'darkgray', background = 'lightgray',
                             highlight = list(border = "darkgray", background = "lightgray"), 
                             hover = list(background = "darkgray", border = "lightgray")
                )) %>% 
      
      # Click on node: only closest connected nodes are shown (others lose color)
      # Select node by id: necessary to add "Go to this document" button
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visEvents(select = "function(nodes) {Shiny.onInputChange('selected_node', nodes.nodes);}") %>% 
      
      # Legend to understand tags (node color)
      visLegend(position = 'right') %>% 
      
      # Add Physics to avoid Overlapping
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