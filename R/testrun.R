install.packages("R.utils")
install.packages("finreportr")
install.packages("tidyverse")
install.packages("httr")
install.packages("XBRL")
install.packages("readxl")

library(readxl)
library(finreportr)
library(R.utils)
library(tidyverse)
library(httr)
library(XBRL)

options(HTTPUserAgent = "tjones77@terpmail.umd")
info.df <- AnnualReports("GOOG")

AnnualReportsTYLERFORK <- function(symbol, foreign = FALSE, save_files = TRUE) {
  
  options(stringsAsFactors = FALSE)
  
  if(foreign == FALSE) {
    url <- paste0("http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=", 
                  symbol, "&type=10-k&dateb=&owner=exclude&count=100")
  } else {
    url <- paste0("http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=", 
                  symbol, "&type=20-f&dateb=&owner=exclude&count=100")
  }
  
  filings <- xml2::read_html(url)
  
  ##   Generic function to extract info
  ExtractInfo <- function(html.node) {
    info <-
      filings %>%
      rvest::html_nodes(html.node) %>%
      rvest::html_text()
    return(info)
  }
  
  ##   Acquire filing name
  filing.name <- ExtractInfo("#seriesDiv td:nth-child(1)")
  
  ##   Error message for function
  if(length(filing.name) == 0) {
    stop("invalid company symbol or foreign logical")
  }
  
  ##   Acquire filing date
  filing.date <- ExtractInfo(".small+ td")
  
  ##   Acquire accession number
  accession.no.raw <- ExtractInfo(".small")
  
  accession.no <-
    gsub("^.*Acc-no: ", "", accession.no.raw) %>%
    substr(1, 20)
  
  ##   Create dataframe
  info.df <- data.frame(filing.name = filing.name, filing.date = filing.date, 
                        accession.no = accession.no)
  
  
  if (save_files) {
    # Create a directory to store the annual reports
    dir_name <- paste0(symbol, "_AnnualReports")
    dir.create(dir_name, showWarnings = FALSE)
    
    # Download and save each annual report as a text file
    for (i in 1:length(info.df$filing.name)) {
      if(trimws(info.df$filing.name[i]) == "10-K/A") {
        next
      }
      path <- paste0("tr:nth-child(", i + 1 , ") td:nth-child(2) a")
      
      urlToZipPath  <- filings %>%
        rvest::html_node(path) %>%
        rvest::html_attr("href")
      
      converted_string <- sub("\\index.htm$", "xbrl.zip", urlToZipPath)
     
   
      if(str_sub(converted_string, start = tail(unlist(gregexpr('\\.', converted_string)), n=1)+1) == "html"){
        converted_string = sub("\\-index.html$", ".txt", urlToZipPath)
      }
      
      report_url <- paste0("https://www.sec.gov", converted_string)
      file_name <- str_sub(converted_string, start = tail(unlist(gregexpr('/', converted_string)), n=1)+1)
      dest <- paste0(dir_name,"/",file_name)
      
      tryCatch(
        expr = {
          download.file(report_url, dest, mode = "wb")
         
        },
        error = function(e){
          message('Caught an error!')
          print(e)
        },
        warning = function(w){
          file_size <- file.info(dest)$size
          if (file_size == 0) {
            file.remove(dest)
          }
          converted_string2 <- sub("\\-xbrl.zip$", ".txt", report_url)
          file_name2 <- str_sub(converted_string2, start = tail(unlist(gregexpr('/', converted_string2)), n=1)+1)
          dest <- paste0(dir_name,"/",file_name2)
          download.file(converted_string2, dest, mode = "wb")
        },
        finally = {
          message('FILE DOWNLOAD COMPLETE\n')
        }
      )    
      
    }
    cat("Annual reports saved in directory:", dir_name, "\n")
  }
  return(info.df)
}

info.df <- AnnualReportsTYLERFORK("KO")


#Import FLIGHT data
dir.create("exceldata", showWarnings = FALSE)
folder <- paste0("exceldata","/","data")
download.file("https://ghgdata.epa.gov/ghgp/service/export?q=&tr=current&ds=E&ryr=2022&cyr=2022&lowE=-20000&highE=23000000&st=&fc=&mc=&rs=ALL&sc=0&is=11&et=&tl=&pn=undefined&ol=0&sl=0&bs=&g1=1&g2=1&g3=1&g4=1&g5=1&g6=0&g7=1&g8=1&g9=1&g10=1&g11=1&g12=1&s1=0&s2=0&s3=0&s4=0&s5=0&s6=0&s7=1&s8=0&s9=0&s10=0&s201=0&s202=0&s203=0&s204=0&s301=0&s302=0&s303=0&s304=0&s305=0&s306=0&s307=0&s401=0&s402=0&s403=0&s404=0&s405=0&s601=0&s602=0&s701=1&s702=1&s703=1&s704=1&s705=1&s706=1&s707=1&s708=1&s709=1&s710=1&s711=1&s801=0&s802=0&s803=0&s804=0&s805=0&s806=0&s807=0&s808=0&s809=0&s810=0&s901=0&s902=0&s903=0&s904=0&s905=0&s906=0&s907=0&s908=0&s909=0&s910=0&s911=0&sf=11001100&allReportingYears=yes&listExport=false", folder, mode = "wb")
excel_file_path <- "exceldata/data"

sheet_names <- excel_sheets(excel_file_path)
combined_df <- data.frame()

rows_to_skip <- 6  

columns_to_select <- c("REPORTING YEAR", "PARENT COMPANIES", "GHG QUANTITY (METRIC TONS CO2e)")  # Adjust with your column names
for (sheet in sheet_names) {
  sheet_data <- read_excel(excel_file_path, sheet = sheet, skip = rows_to_skip)
  combined_df <- bind_rows(combined_df, sheet_data)
}

View(combined_df)

your_dataframe <- combined_df %>%
  select(columns_to_select) %>%
  select("PARENT COMPANIES", everything()) %>%
  
write.csv(your_dataframe, "flightdataTest.csv", row.names=F)

#Filter to target companies

search_terms <- c("Westlake", "Occidental Petroleum","Mosaic","Albemarle", "Air Products", "PPG Industries", "Exxon Mobil","Huntsman","Celanese", "Honeywell")

filterframe <- your_dataframe %>%
  filter(sapply(search_terms, function(term) str_detect(`PARENT COMPANIES`, regex(term, ignore_case = TRUE))) %>% rowSums > 0) 

for (term in search_terms) {
  filterframe <- filterframe %>%
    mutate(`PARENT COMPANIES` = ifelse(
      str_detect(`PARENT COMPANIES`, regex(term, ignore_case = TRUE)),
      term,
      `PARENT COMPANIES`
    ))
}

filterframe <- filterframe %>%
  group_by(`PARENT COMPANIES`, `REPORTING YEAR`) %>%
  summarize(`GHG QUANTITY (METRIC TONS CO2e)` = sum(`GHG QUANTITY (METRIC TONS CO2e)`))

write.csv(filterframe, "flightCompanies.csv")
