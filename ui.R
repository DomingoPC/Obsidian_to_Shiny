library(shiny)
library(shinythemes)
library(markdown)
library(visNetwork)

# Path to Obsidian documents
doc_path = 'www/documents'

# Tags list
index <- jsonlite::fromJSON(file.path(doc_path, 'tags.json'))

# Document names getter
doc_getter <- function(){
  return(
    # Remove file extension
    tools::file_path_sans_ext( 
      # List files in documents folder
      list.files(doc_path, pattern='.md', full.names=FALSE)
    )
  )
}


# --- Define UI ---
ui <- navbarPage( # To support multiple pages
  # Title and theme
  'Magic Systems',
  theme = shinytheme('slate'),
  
  # --- Notes viewer ---
  tabPanel('Notes Viewer',
           # Layout: document input panel (sidebar) + document viewer (main)
           sidebarLayout(
           
           sidebarPanel(
             h4('Document navigation'), # Title
             selectInput('tag', 'Filter by Tag', choice=c('No tag', names(index))),
             
             selectInput('file', 'Select Document', choice=doc_getter()) # updates in server
             ),
           
           mainPanel(
             uiOutput("doc_output") # Show doc_output (from server)
             )
           )
  ),
  
  # --- Graph Viewer ---
  tabPanel("Network",
           visNetwork::visNetworkOutput("note_network", height = "600px")
  )
)