
### optional shinycssloader ###
library(shinyjs)
library(shinycssloaders)

appCSS <- "
#loading-content {
  position: absolute;
  background: #FFFFFF;
  opacity: 0.9;
  z-index: 100;
  left: 0;
  right: 0;
  height: 100%;
  text-align: center;
  color: #000000;
}
"

bootstrapPage(
  useShinyjs(),
  inlineCSS(appCSS),
  div(
    id = "loading-content",
    h1("Please Wait...")%>%withSpinner(proxy.height='300px',type=6)
  ),

  hidden(
  div(id="main-content",
dashboardPage(
  dashboardHeader(title = titleWarning("CV Shiny version 1"),
                  titleWidth = 700),
  
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      menuItem("Reports", tabName = "reportdata", icon = icon("hospital-o")),
      menuItem("Patients", tabName = "patientdata", icon = icon("user-md")),
      menuItem("Drugs", tabName = "drugdata", icon = icon("flask")),
      menuItem("Reactions", tabName = "rxndata", icon = icon("heart-o")),
      menuItem("About", tabName = "aboutinfo", icon = icon("info"), selected = TRUE),
      menuItem("Download", tabName = "download_tab", icon = icon("download"))
    ),
    
    div(style="display: inline-block; width: 60%;",
        radioButtons("name_type", "Drug name type:",
                     c("Brand Name" = "brand",
                       "Active Ingredient" = "ingredient"))),
    
    conditionalPanel(
      condition = "input.name_type == 'brand'",
      # cvshiny_selectinput_UI('search_brand', 'Brand Name (Canadian Trade Name)')),
      pickerInput("search_brand",
                     "Select one or multiple Brand Names (Canadian Trade Name)",
                     c("",topbrands),
                     options=list(`actions-box`=TRUE,
                                  `live-search`=TRUE,
                                  size=5),
                     choicesOpt = list(content=stringr::str_trunc(topbrands,width=50)),
                     multiple = TRUE)),
    conditionalPanel(
      condition = "input.name_type == 'ingredient'",
      textInput('search_drug','Type in an ingredient to get synonyms:',value='Start typing...'),
      pickerInput("search_ing", 
                     "Select one or multiple Active Ingredients",
                     c("Start typing to search..." = ""),
                     options=list(`actions-box`=TRUE,size=5),
                     multiple = TRUE)),
    
  
        # radioButtons("search_type", "Search type:",
        #              c("Exact" = "exact","Contains" = "contains"),inline=TRUE),
    
   
    div(style="display: inline-block; vertical-align:top; width: 52%",
        radioButtons("drug_inv", "Drug Involvement:",
                     c("Suspect",
                       "Concomitant",
                       "Any"))),
    div(style="display: inline-block; vertical-align:top; width: 80%",
        radioButtons("seriousness_type", "Seriousness:",
                     c("All",
                       "Serious(Excluding Death)",
                       "Death"))),
    div(style="height:80px;",sliderInput("search_age",
                "Set Age Range",
                min = 0,
                max = 125,
                value = c(0,125))),
        div(style="height:20px;",checkboxInput("min_age","Min age exclusive",value = FALSE)),
        div(style="height:60px;",checkboxInput("max_age","Max age exclusive",value = FALSE)),

    selectInput("search_gender",
                "Select Gender",
                c("All",
                  "Male",
                  "Female")),
    selectizeInput("search_rxn", 
                   "Preferred Term (PT)",
                   c("Start typing to search..." = ""),
                   multiple = TRUE),
   
    selectizeInput("search_soc",
                   "System Organ Class (SOC)",
                   c("Start typing to search..." = ""),
                   multiple = TRUE),
    # cvshiny_selectinput_UI('search_soc', 'System Organ Class'),
    fluidRow(
      column(12,
             dateRangeInput('daterange', 'Select date range',
                  format="yyyy-mm-dd",min ="1965-01-01", max = max_date, start = "2000-01-01", end = max_date ))),
      # hacky way to get borders correct
    conditionalPanel(
      condition = "input.search_rxn != 'disable'",
      tags$div(
        class="form-group shiny-input-container",
        actionButton("searchButton",
                     "Search",
                     width = '90%')
      ))), 
  
  dashboardBody(
    customCSS(),
    tabsetPanel(
    tabPanel('Time Series Plot',
    fluidRow(
      box(htmlOutput(outputId = "timeplot_title"),
          #htmlOutput(outputId = "timeplot"),
          lineChartOutput("mychart")%>%withSpinner(),
          "Reports by month from Canada Vigilance Adverse Reaction Online Database.",
          htmlOutput(outputId = "search_url"),
          width = 12,solidHeader = TRUE
      )
    )),
    tabPanel('Table for time series',
             selectizeInput("column_time",
                            "Select Columns",
                            choices=c('Serious(Excluding Death)','Death','Nonserious','Serious(Including Death)'),
                            selected=c('Nonserious','Serious(Including Death)'),
                            multiple = TRUE),

             DT::dataTableOutput('tb_main')
              )),
    tabItems(
      tabItem(tabName = "reportdata",
              fluidRow(
                pieTableUI("Reporter Type","reporterchart","reportertable",paste0("Indicates who reported the adverse reaction and their relationship to the patient. ",
                                                                                   "Slices may not be visible if they are too small."))%>%withSpinner(),
               
                pieTableUI("Seriousness", "seriouschart", "serioustable",paste0("A serious report contains a serious adverse reaction, determined by the reporter ",
                                                                                 "of the report at the time of reporting. Slices may not be visible if they are too small."))%>%withSpinner()

              ),
              fluidRow(
                box(h3("Reason(s) for Seriousness",
                       tipify(
                         el = icon("info-circle"), trigger = "hover click",
                         title = paste0("The serious condition which the adverse event resulted in. Total may sum to",
                                        " more than the total number of reports because reports can be marked serious for multiple reasons"))),
                    htmlOutput("seriousreasonsplot"),
                    width = 6)
                
              )
              ),
      tabItem(tabName = "patientdata",
              fluidRow(
                pieTableUI("Gender","sexchart","sextable", 
                           paste0("Gender of the patient as it was provided by the reporter. ",
                                  "Where the gender is unknown, the reporter is unaware of the gender. ",
                                  "Where the gender is not specified, the reporter did not specify the gender of the patient.")),

                pieTableUI("Age Group", "agechart", "agetable",
                           HTML(paste0(
                             "Age group of the patient when the adverse effect occurred.<br>",
                             "<br>Neonate: <= 25 days",
                             "<br>Infant: > 25 days to < 1 yr",
                             "<br>Child: >= 1 yr to < 13 yrs",
                             "<br>Adolescent: >= 13 yrs to < 18 yrs",
                             "<br>Adult: >= 18 yrs to <= 65 yrs",
                             "<br>Elderly: > 65 yrs"))),

                box(htmlOutput("agehisttitle"),
                    plotlyOutput("agehist"),
                    width = 6)
              )
      ),
      tabItem(tabName = "drugdata",
              fluidRow(
                barTableUI("Most Frequently Reported (Suspect and Concomitant) Drugs (Brand Name)", "alldrugchart","alldrugtable",
                           paste0("This plot includes all drugs present in the matching reports. ",
                                  "The search query filters unique reports, which may have one or more drugs associated with them.")),
                barTableUI("Most Frequently Reported Suspect Drugs (Brand Name)","suspecteddrugchart","suspecteddrugtable",
                           paste0("This plot includes all drugs present in the matching reports. ",
                                  "The search query filters unique reports, which may have one or more drugs associated with them. ",
                                  "The reporter suspects that the health product caused the adverse reaction."))),
              fluidRow(
                barTableUI("Most Frequently Reported Concomitant Drugs (Brand Name)","concomitantdrugchart","concomitantdrugtable",
                           paste0("This plot includes all drugs present in the matching reports. ",
                                  "The search query filters unique reports, which may have one or more drugs associated with them. ",
                                  "The health product is not suspected, but the patient was taking it at the time of the adverse reaction.")),

                 barTableUI("Reports per Indication (all reported drugs)","indicationchart","indicationtable",
                            paste0("Indication refers to the particular condition for which a health product was taken. ",
                                  "This plot includes the indications, when provided, for all drugs present in the matching reports. ",
                                   "The search query filters unique reports, which may have one or more drugs associated with them."))
              ),
              fluidRow(
                box(htmlOutput("drugcounttitle"),
                    htmlOutput("drugcount_plot"),
                    width = 12))
              ),
              
     
      tabItem(tabName = "rxndata",
              fluidRow(
                barTableUI("Most Frequent Adverse Events (Preferred Terms)","topptchart","toppttable",
                           paste0("MedDRA Preferred Term is a distinct descriptor (single medical concept) for a symptom, ",
                                  "sign, disease, diagnosis, therapeutic indication, investigation, surgical, or medical ",
                                  "procedure, and medical, social, or family history characteristic. For more rigorous analysis, ",
                                  "use disproportionality statistics.")),
 
                barTableUI("Most Frequent Adverse Events (HLT Terms)","tophltchart","tophlttable",
                           "For more rigorous analysis, use disproportionality statistics.")),
           
              fluidRow(
                pieTableUI("Report Outcome", "outcomechart", "outcometable",
                           paste0("The report outcome represents the outcome of the reported case as described by the reporter ",
                                  "at the time of reporting and does not infer a causal relationship. The report outcome is not ",
                                  "based on a scientific evaluation by Health Canada.")))),
            
      
      tabItem(tabName = "aboutinfo",
              box(
                width = 12,
                h2("About"),
                # using tags$p() and tags$a() inserts spaces between text and hyperlink...thanks R
                HTML(paste0(
                  "<p>",
                  "<strong>",
                  "<a href = \"https://www.canada.ca/en/health-canada/services/drugs-health-products/medeffect-canada/adverse-reaction-database/medeffect-canada-caveat-privacy-statement-interpretation-data-extract-vigilance-adverse-reaction-online-database.html\">",
                  "Before using, please read over the Canada Vigilance Adverse Reaction caveat document.",
                  "</a>",
                  "</strong>",
                  "</p>",
                  "<p>",
                  "This is a beta product. DO NOT use as sole evidence to support regulatory decisions or to make decisions regarding ",
                  "medical care. Always speak to your health care provider about the risks and benefits of Health Canada regulated Products.",
                  "</p>",
                  "<p>",
                  "This app has been developed by the Data Sciences Unit of RMOD at Health Canada as part of the Open Data Initiative. ",
                  "This is a prototype experiment that utilizes publically available data (Canada Vigilance Adverse Reaction Online Database) ", 
                  "and provide visualizations in an interactive format. Health Canada collects and maintains a high volume of adverse event ", 
                  "reports associated with different drugs and products. This app allows users to effortlessly interact with the reports ", 
                  "database, conduct searches and view results in highly interactive dashboards. To support innovation, coordination and ", 
                  "to support Canadians, this interface permits the users to export search results (with no limitation to the number of rows) ", 
                  "in various file formats such as CSV and Excel for further exploration and experimentation.",
                  "</p>",
                  "<br>",
                  "<p>",
                  paste0("<strong>Data last updated:", max_date, "</strong><br>"),
                  paste0("<strong>MedDRA Version:", max_meddra, "</strong><br>"),
                  "Data provided by the Canada Vigilance Adverse Reaction Online Database. The recency of the data is therefore ",
                  "dependent on when the data source is updated, and is the responsibility of the Canada Vigilance Program. ",
                  "Anonymous usage data are collected for application improvement purpose.",
                  "For more information, please refer to ",
                  "<a href = \"https://www.canada.ca/en/health-canada/services/drugs-health-products/medeffect-canada/adverse-reaction-database.html\">",
                  "https://www.canada.ca/en/health-canada/services/drugs-health-products/medeffect-canada/adverse-reaction-database.html</a>.",
                  "</p>"))),
                 aboutAuthors()), 
      tabItem(tabName = "download_tab",
              fluidRow(
                box(
                  column(
                    width = 3,
                    div(style="display: inline-block; width: 161px;",
                        selectInput("search_dataset_type",
                                    "Download Type",
                                    c("Report Data", "Drug Data", "Reaction Data"))
                        ),
                    div(style="display: inline-block; vertical-align: bottom; height: 54px;",
                        downloadButton(outputId = 'download_reports',
                                       label = 'Download')),
                    selectizeInput('select_column',
                                   "Select Columns",
                                   choices=c('Select columns to download'),
                                   multiple=T),
                    tags$b('Note: Export limit of 1,000. If your search result exceeds 1,000, only the first 1,000 reports will be downloaded')
                    # conditionalPanel(
                    #   "input.search_dataset_type == 'Report Data'",
                    #   uiOutput('column_select_data')),
                    # conditionalPanel(
                    #   "input.search_dataset_type == 'Drug Data'",
                    #   uiOutput('column_select_drug')),
                    # conditionalPanel(
                    #   "input.search_dataset_type == 'Reaction Data'",
                    #   uiOutput('column_select_reaction'))
                    ),
                  column(
                    width = 9,
                    tableOutput("current_search")
                  ),
                  width = 12)
              )
      )
    )
  )
))))


