library(shiny)
library(markdown)
library(visNetwork)
library(shinydashboard)

# Theme
library(fresh)

obsidian_theme <- create_theme(
  adminlte_color(
    light_blue = "#3771BC",  # accent (buttons, highlights)
    aqua = "#74c7ec",
    green = "#a6e3a1",
    red = "#f38ba8",
    yellow = "#f9e2af"
  ),
  adminlte_sidebar(
    dark_bg = "#111111",      # dark sidebar
    dark_hover_bg = "#313244",# hover effect
    dark_color = "#cdd6f4"    # text color
  ),
  adminlte_global(
    content_bg = "#1e1e2e",   # main background
    box_bg = "red",       # box background
    # box_bg = "#313244",       # box background
    info_box_bg = "#313244"
  )
)




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
    # --- Pages ---
    sidebarMenu(
      id = 'sidebar_menu', # to observe and react
      
      menuItem(h4('Document Selection')),
      # Select document to display (updates in server)
      selectInput('file', label = NULL, 
                  choice = doc_getter(),
                  selected = 'Main Page'),
      
      # Download document on display
      downloadButton("export_pdf", "Download as HTML", 
                     style = "
                     background-color: #ffffff; color: #333333; 
                     text-align: left;
                     border: 1px solid #cccccc; border-radius: 4px; 
                     padding: 6px 12px;
                     width: calc(100% - 30px); margin-bottom: 10px;
                     margin-left: auto; margin-right: auto;
                     display: block;
                     ",
                     class = "btn-sidebar"),
      
      menuItem(h4('Visualization')),
      menuItem("Explore Notes", tabName = "notes", icon = icon("book")),
      menuItem("Network View", tabName = "graph", icon = icon("th")),
      
      menuItem(h4('Key Documents')),
      menuItemOutput('dynamic_planets_menu'),
      menuItemOutput('dynamic_species_menu'),
      menuItemOutput('dynamic_sources_menu')
    )
  ),
  
  dashboardBody(
    # dashboardthemes::shinyDashboardThemes(theme = "grey_dark"),
    use_theme(obsidian_theme),
    tags$style(HTML("
    .box-body, .info-box-content, .tab-content {
      color: #FFFFFF !important;
    }
    
    select.dropdown {
    background-color: #313244 !important;
    color: #cdd6f4 !important;
    border: 1px solid #45475a !important;
    border-radius: 4px !important;
    padding: 2px 6px !important;
  }

  select.dropdown option {
    background-color: #313244 !important;
    color: #cdd6f4 !important;
  }
  ")),
    
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
  
  
  