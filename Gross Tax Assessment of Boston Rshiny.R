library(shiny) #Package is used to make the app reactive and more user friendly 
library(dplyr) #Package is used for data manipulation
library(ggplot2)  #Package is a data visualization package
library(plotly)  #Package is helpful in making interactive and publication quality visualizations

#Creating UI component of SHINY APP

ui<-  fluidPage(
  sidebarLayout(
    sidebarPanel ( 
      fileInput(
        "file1",
        "Upload the dataset",
        multiple = TRUE,
        accept = c("text/csv",
                   "text/comma-separated-values,text/plain",
                   ".csv")
      ),
      checkboxGroupInput("property", "Select Property Type",
                         choices = list("COMMERCIAL" = "C", "RESIDENTIAL 1 FAMILY" ="R1", "RESIDENTIAL 2 FAMILY" = "R2", "RESIDENTIAL 3 FAMILY"= "R3", "RESIDENTIAL 4 FAMILY" ="R4"),
                         selected ="C"),
      conditionalPanel(condition = "input.ma != 'nf'",sliderInput("year", "Range Choice",
                                                                  min = 1800, max = 2018,value = c(1860,2018)))
      
  
    ),
    
    mainPanel(tabsetPanel(id = 'ma',
                          # Output layout
                          tabPanel("Gross Tax over the years",value ='am',
                                   plotlyOutput("PLOT_A")),
                          tabPanel(" Gross Tax with different Assessed Values of Land ",value = 'ps',
                                   plotlyOutput("PLOT_B")
                          )
                          
    ))))

#Creating SERVER component of SHINY APP

server <- function(input, output, session) {
  options(shiny.maxRequestSize=100*1024^2)      #Since file size is greater than 5 MB
  clean_dataset <-reactive ({
    req(input$file1)
    data <- read.csv(input$file1$datapath )
    return(data)})
  
  
  clean_data_filter <-reactive({
    selected <-c(input$property)
    clean_data = clean_dataset()
    clean_data_filtered <- subset(clean_data, clean_data$LU%in%selected)
    return(clean_data_filtered)
  })
  
  
  
  #Plotting Gross Tax in Boston 
  output$PLOT_A <- renderPlotly({
    cleaned_data = clean_data_filter()
    cleaned_data <- subset(cleaned_data, YR_BUILT > input$year[1] & YR_BUILT < input$year[2])
    cleaned_data_1 <- cleaned_data %>% group_by(YR_BUILT) %>% summarise(MedianGROSS_TAX = median(GROSS_TAX))
    cleaned_data_1 <- arrange(cleaned_data_1, YR_BUILT,MedianGROSS_TAX) 
    
    plot_ly(cleaned_data_1, x = ~YR_BUILT, y = ~MedianGROSS_TAX, type = 'scatter', mode = 'lines+markers',
            name = 'Assessed Land Value')%>%
     
      layout(title = 'Median Gross Tax over the Years',
            yaxis = list(title = 'Median Gross Tax Value',showgrid =FALSE),
             xaxis = list(title = 'Year',showgrid =FALSE ))})
  
  #Plotting Median Assessed Value of Land with Median Gross Tax
  
  output$PLOT_B <- renderPlotly({
    
    cleaned_data_1 = clean_data_filter()
    cleaned_data_1 <- cleaned_data_1 %>% group_by(GROSS_TAX) %>% summarise(Median_AV_LAND = median(AV_LAND), Median_GROSS_TAX= median(GROSS_TAX))
    
    fit <- lm(cleaned_data_1$Median_AV_LAND ~ cleaned_data_1$Median_GROSS_TAX, data = cleaned_data_1)
    
    plot_ly(cleaned_data_1, x = ~Median_GROSS_TAX, y = ~Median_AV_LAND,
            marker = list(size = 10,
                          color = 'rgba(255, 182, 193, .9)',
                          line = list(color = 'rgba(152, 0, 0, .8)',
                                      width = 2))) %>%
      layout(title = 'Gross Tax variation with Median Assessed Values of Land',
             yaxis = list(title = 'Median Assessed Values of Land',showgrid =FALSE),
             xaxis = list(title = ' Median Gross Tax',showgrid =FALSE)
             
             
      )%>%
      add_markers(y = ~Median_AV_LAND)%>%
      add_lines(x= ~Median_GROSS_TAX, y= fitted(fit))
    
  })
}

shinyApp(ui, server)