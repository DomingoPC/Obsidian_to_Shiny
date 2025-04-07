library(shiny)
# library(shinythemes)
library(markdown)
library(visNetwork)
library(shinydashboard)

# Path to Obsidian documents
doc_path = 'www/documents'

# Tags list
# index <- jsonlite::fromJSON(file.path(doc_path, 'tags.json'))

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
ui <- dashboardPage(
  dashboardHeader(title = 'Magic Systems'),
  dashboardSidebar(
    # selectInput('tag', 'Filter by Tag', choice=c('No tag', names(index))),
    selectInput('file', 'Select Document', choice=doc_getter()), # updates in server
    
    # --- Pages ---
    sidebarMenu(
      id = 'sidebar_menu', # to observe and react
      menuItem(h4('Visualization')),
      menuItem("Notes", tabName = "notes", icon = icon("dashboard")),
      menuItem("Graph View", tabName = "graph", icon = icon("th")),
      menuItem(h4('Key Documents')),
      menuItemOutput('dynamic_planets_menu'),
      menuItemOutput('dynamic_species_menu'),
      menuItemOutput('dynamic_sources_menu')
    )
  ),
  
  
  dashboardBody(
    # Show items in left panel to choose from
    tabItems(
      # Notes Viewer
      tabItem(tabName = 'notes',
        fluidPage(uiOutput('doc_output'))
      ),
      
      # Graph Viewer
      tabItem(tabName = 'graph',
              fluidPage(
                # Button to go to the clicked document
                actionButton("goto_graph", "Go to Selected Document"),
                
                # The Graph
                visNetwork::visNetworkOutput("note_network", height = "600px"))
      )
    ),
  )
)
  
  
  