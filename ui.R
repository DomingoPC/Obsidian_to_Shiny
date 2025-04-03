library(shiny)
library(shinythemes)
library(markdown)

# Path to Obsidian documents
doc_path = 'www/documents'

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


# Define UI
ui <- fluidPage(
  theme = shinytheme('slate'),
  titlePanel("Obsidian Notes Viewer"),
  
  # Layout: document input panel (sidebar) + document viewer (main)
  sidebarLayout(
    
    sidebarPanel(
      selectInput('file', 'Select Document', choice=doc_getter())
    ),
    
    mainPanel(
      uiOutput("doc_output") # Show doc_output (from server)
    )
  )
)