library(shiny)
library(shinythemes)
library(markdown)

# Necessary to read markdown file
doc_path <- 'www/documents'
doc_extension <- '.md'

# Define Server
server <- function(input, output) {
  
  output$doc_output <- renderUI({
    req(input$file) # Get filename
    
    # Read Markdown File
    file_path <- paste(doc_path, '/', input$file, doc_extension, sep='')
    content <- markdown::markdownToHTML(file_path, fragment.only = TRUE)
    
    HTML(content)
  })
}