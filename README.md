# Team Whistleblower’s FIRE Summit Presentation
Anant Agrawal, Tyler Jones, Ishaan Kalra

# <u>**Research Question**</u>**🧐**

Are companies who claim to place an emphasis on ESG initiatives
effective in reducing their air pollution emissions?

![](assets/1.png)

# <u>**Data Querying**</u>**🛠️**

## A. Treatment variable:

Our treatment variable is the “environmental sentiment score” extracted
from a company’s annual reports. To obtain this data, we begin by
accessing the SEC’s EDGAR database
(<https://www.sec.gov/edgar/search/>), which consolidates information
submitted by publicly traded firms.

We then employ sentiment analysis methods to evaluate the expressed
sentiments within these reports. The result is the environmental
sentiment score, a crucial component for our analysis.

### Querying for 10K Filings 📈

### **1. Prerequisites**

1.Node.js

2.NPM (Node Packet Manager)

### **2. Import Required Modules**

``` javascript
import fs from "fs";
import sanitize from "sanitize-filename";
import puppeteer from "puppeteer-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";
import { stripHtml } from "string-strip-html";
import { executablePath } from "puppeteer";
```

### **3. Set up Web Scraping Module**

``` javascript
puppeteer.use(StealthPlugin());
```

### **4. Setting up the Array of Companies to be scraped**

``` javascript
const companyNames = {
  // Albemarle: "ALB",
  // Mosaic: "MOS",
  // "3M": "MMM",
  // Westlake: "WLK",
  // "Air Products": "APD",
  PPG: "PPG",
  // "Exxon Mobil": "XOM",
  // Huntsman: "HUN",
  // Celanese: "CE", 
  // Honeywell: "HON",
};
```

### 5. Function to Run the Scraping Algorithm

``` javascript
async function scrapeSECWebsite() {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: executablePath(),
  });

  for (const companyName in companyNames) {
    const entityName = companyNames[companyName];
    let url = `https://www.sec.gov/edgar/search/#/q=${companyName}&dateRange=custom&category=form-cat1&entityName=${entityName.toUpperCase()}&startdt=2010-12-31&enddt=2021-12-31&filter_forms=10-K`;
    const page = await browser.newPage();
    try {
      let pageNum = 1;
      const maxPages = 3;
      while (pageNum <= maxPages) {

      url = url + '&page='+pageNum;
      await page.goto(url);
      await page.waitForTimeout(2000);

      await page.keyboard.press("Enter");

      await page.waitForTimeout(1000);

        const result = await page.evaluate(() => {
          const tableElement = document.querySelector("div#hits table.table");
          if (tableElement) {
            const tbody = tableElement.querySelector("tbody");
            if (tbody) {
              const links = Array.from(tbody.querySelectorAll("a"));
              return links.map((link) => ({
                href: link.href,
                text: link.textContent,
              }));
            } else {
              return "Tbody element not found inside the table";
            }
          } else {
            return "Table element not found";
          }
        });

        const filteredLinks = [];

        result.forEach((linkInfo) => {
          filteredLinks.push(linkInfo.href);
        });

        const yearArray = [];
        for (const href of filteredLinks) {
          if (href.includes("ex")) {
            console.log(href);
          } else {
            if (href.includes("#")) {
              const yearPattern = /\d{4}(?!10K)/;
              const matches = href.match(yearPattern);
              if (matches) {
                const year = matches[0];
                if (year != 1231 && yearArray.includes(year)) {
                  console.log(year);
                  console.log(href);
                  break;
                } else if (yearArray.length <= 12) {
                  const parts = href.split("#");
                  const selector = `a[href="#${parts[1]}"]`;
                  yearArray.push(year);
                  await page.click(selector);

                  const openFileLink = await page.$eval("a#open-file", (link) =>
                    link.getAttribute("href")
                  );
                  await page.waitForTimeout(300);

                  console.log("\n");
                  console.log("The actual link is: " + openFileLink);
                  await scrapeTextAndSaveToFile(openFileLink, year, companyName);
                  console.log("\n");

                  await page.waitForTimeout(100);
                  await page.click("button#close-modal");
                } else {
                  break;
                }
              }
            }
          }

          await page.waitForTimeout(100);
        }

        pageNum++;
      }
    } catch (error) {
      console.error("Error:", error);
    }
  }

  await browser.close();
}
```

### **6. Function to save the 10K Filings locally with a definite format**

``` javascript
async function scrapeTextAndSaveToFile(url, year, companyName) {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  try {
    const folderName =
      "/Users/ishaankalra/Documents/GitHub/fall-project-whistle-blowers/WebScraper/test" +
      companyName;

    if (!fs.existsSync(folderName)) {
      fs.mkdirSync(folderName);
    }

    await page.goto(url, { waitUntil: "networkidle2" });

    const textContent = await page.evaluate(() => {
      return document.body.textContent;
    });

    
    const sanitizedYear = sanitize(year);
    // const strippedResult = textContent.replace(/(<([^>]+)>)/gi, '');
    const strippedResult = stripHtml(textContent.toLowerCase());
    const strippedString = strippedResult.result;

    // Find and extract the fiscal year information
    const fiscalYearKeywords = ["fiscal year ended", "fiscal year"];
    let fiscalYear = null;

    for (const keyword of fiscalYearKeywords) {
      const startIndex = strippedString.indexOf(keyword);
      if (startIndex !== -1) {
        const yearMatch = strippedString
          .substr(startIndex + keyword.length)
          .match(/[0-9]{4}/);
        if (yearMatch) {
          fiscalYear = yearMatch[0];
          if (fiscalYear != null && fiscalYear === sanitizedYear) {
            fiscalYear = sanitizedYear;
          }
          break;
        }
      }
    }

    let fileName;
    if (fiscalYear) {
      fileName = `${folderName}/${fiscalYear}.txt`;
      fs.writeFileSync(fileName, strippedString, "utf-8");
      console.log(`Text content scraped and saved to ${fileName}`);
    } else if(fiscalYear === sanitizedYear){
      fileName = `${folderName}/${sanitizedYear}.txt`;
      console.log("Year same, no change need. \n");
    } else {
      console.log("Fiscal year information not found in the text.");
    }
  } catch (error) {
    console.error(`Error scraping and saving text: ${error}`);
  } finally {
    await browser.close();
  }
}
```

### **7. Run scraping function**

``` javascript
scrapeSECWebsite();
```

## B. Outcome variable:

Our outcome variable is greenhouse gas emissions from each target
chemical company.

This data is obtained from
“https://ghgdata.epa.gov/ghgp/main.do?site_preference=normal” which
reports greenhouse gases for every facility in the U.S for each year.

We transformed yearly facility emissions into total company emissions,
as shown in the code below.

### Querying for FLIGHT DATA 📉

### **1. Loading Required Libraries**

``` r
library(readxl)
library(finreportr)
library(R.utils)
```

    Loading required package: R.oo

    Loading required package: R.methodsS3

    R.methodsS3 v1.8.2 (2022-06-13 22:00:14 UTC) successfully loaded. See ?R.methodsS3 for help.

    R.oo v1.25.0 (2022-06-12 02:20:02 UTC) successfully loaded. See ?R.oo for help.


    Attaching package: 'R.oo'

    The following object is masked from 'package:R.methodsS3':

        throw

    The following objects are masked from 'package:methods':

        getClasses, getMethods

    The following objects are masked from 'package:base':

        attach, detach, load, save

    R.utils v2.12.2 (2022-11-11 22:00:03 UTC) successfully loaded. See ?R.utils for help.


    Attaching package: 'R.utils'

    The following object is masked from 'package:utils':

        timestamp

    The following objects are masked from 'package:base':

        cat, commandArgs, getOption, isOpen, nullfile, parse, warnings

``` r
library(tidyverse)
```

    ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
    ✔ dplyr     1.1.3     ✔ readr     2.1.4
    ✔ forcats   1.0.0     ✔ stringr   1.5.0
    ✔ ggplot2   3.4.4     ✔ tibble    3.2.1
    ✔ lubridate 1.9.3     ✔ tidyr     1.3.0
    ✔ purrr     1.0.2     

    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ tidyr::extract() masks R.utils::extract()
    ✖ dplyr::filter()  masks stats::filter()
    ✖ dplyr::lag()     masks stats::lag()
    ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors

``` r
library(httr)
library(XBRL)
```

### **2. Function to retrieve annual GHG FLIGHT Data**

``` r
# Import FLIGHT data as excel file
dir.create("exceldata", showWarnings = FALSE)
folder <- paste0("exceldata", "/", "data")
download.file("https://ghgdata.epa.gov/ghgp/service/export?q=&tr=current&ds=E&ryr=2022&cyr=2022&lowE=-20000&highE=23000000&st=&fc=&mc=&rs=ALL&sc=0&is=11&et=&tl=&pn=undefined&ol=0&sl=0&bs=&g1=1&g2=1&g3=1&g4=1&g5=1&g6=0&g7=1&g8=1&g9=1&g10=1&g11=1&g12=1&s1=0&s2=0&s3=0&s4=0&s5=0&s6=0&s7=1&s8=0&s9=0&s10=0&s201=0&s202=0&s203=0&s204=0&s301=0&s302=0&s303=0&s304=0&s305=0&s306=0&s307=0&s401=0&s402=0&s403=0&s404=0&s405=0&s601=0&s602=0&s701=1&s702=1&s703=1&s704=1&s705=1&s706=1&s707=1&s708=1&s709=1&s710=1&s711=1&s801=0&s802=0&s803=0&s804=0&s805=0&s806=0&s807=0&s808=0&s809=0&s810=0&s901=0&s902=0&s903=0&s904=0&s905=0&s906=0&s907=0&s908=0&s909=0&s910=0&s911=0&sf=11001100&allReportingYears=yes&listExport=false", folder, mode = "wb")
excel_file_path <- "exceldata/data"

#Name of each sheet
sheet_names <- excel_sheets(excel_file_path)

# Define the search term (company name)
search_term <- "PPG"
```

``` r
#Skip rows with irrelevant data
rows_to_skip <- 6  

#Filter to only the columns of data we are analyzing
columns_to_select <- c("REPORTING YEAR", "PARENT COMPANIES", "GHG QUANTITY (METRIC TONS CO2e)")  

#The file has a sheet for each year so we need to loop through to get all the data
for (sheet in sheet_names) {
  sheet_data <- read_excel(excel_file_path, sheet = sheet, skip = rows_to_skip)
  combined_df <- bind_rows(combined_df, sheet_data)
}

#Organized data to be emissions per year per parent company
your_dataframe <- combined_df %>%
  select(columns_to_select) %>%
  select("PARENT COMPANIES", everything()) %>%

#Filter to target companies
search_terms <- c("PPG Industries")

#Filter the data so that it only contains the search term (target company)
#Filters out all companies were the search substring is not found
filterframe <- your_dataframe %>%
  filter(sapply(search_terms, function(term) str_detect(`PARENT COMPANIES`, regex(term, ignore_case = TRUE))) %>% rowSums > 0) 

#Rename all the parent companies for each facility under one naming conventions
for (term in search_terms) {
  filterframe <- filterframe %>%
    mutate(`PARENT COMPANIES` = ifelse(
      str_detect(`PARENT COMPANIES`, regex(term, ignore_case = TRUE)),
      term,
      `PARENT COMPANIES`
    ))
}

#Combine all the facility emissions together for the company
filterframe <- filterframe %>%
  group_by(`PARENT COMPANIES`, `REPORTING YEAR`) %>%
  summarize(`GHG QUANTITY (METRIC TONS CO2e)` = sum(`GHG QUANTITY (METRIC TONS CO2e)`))
```

# <u>**Data Wrangling**</u> **📊**

1.  The provided R code is designed to assess how positively or
    negatively a company’s environmental goals are expressed in its
    annual reports.

2.  It does this by looking at sentences in the reports that contain
    words related to the environment and calculating an overall
    sentiment score for those sentences.

3.  This score is based on a pre-defined list of words associated with
    positive or negative sentiments.

4.  The code then calculates an average sentiment score to gauge the
    overall tone of the environmental statements in the reports, which
    can provide insights into a company’s commitment to environmental
    sustainability.

``` r
library(textdata)
library(tidyverse)
library(dplyr)
library(tidytext)
library(SnowballC)

# reading the text file 

# To find for multiple years we can use for loop
# (file in c("2011.txt", "2012.txt", "2013.txt", "2014.txt", "2015.txt",
#              "2016.txt", "2017.txt", "2018.txt", "2019.txt", "2020.txt",)){

file = "2011.txt"

test_data <- readLines(file)
  
df <- tibble(text = test_data)
  
test_data_sentences <- df %>%
    unnest_tokens(output = "sentence",
                  token = "sentences",
                  input = text) 
  
#the total score of emotions
total_score <- 0

#the total score of emotions
  total_score <- 0
  
  #for loop because words used separately as environment/environmental/environmentally
  for(term in c("environment", "environmental", "environmentally")) {
    
    #considering the environment related sentences
    env_sentences <- test_data_sentences[grepl(term, test_data_sentences$sentence), ]
    
    count <- 0
    for(i in env_sentences) { 
      for (j in i){
        count <- count + 1
      }
    }
    # Further Tokenize the text by word
    env_tokens <- env_sentences %>%
      unnest_tokens(output = "word", token = "words", input = sentence) %>%
      anti_join(stop_words)
    
    afinnframe<-get_sentiments("afinn")
    # Use afinn to find the overall sentiment score
    affin_score <- env_tokens %>% 
      inner_join(afinnframe, by = c("word" = "word")) %>%
      summarise(sentiment = sum(value))
    
    total_score = total_score + affin_score
  }
  
  total_score = total_score / count
#}
# End of for loop
```

# <u>**Preliminary Results**</u> **💡**

Upon consolidating all the data, we can uncover the subtle nuances in
how a company, PPG in this instance, has changed over the years in terms
of its sentiment towards the environment. This provides a window into
the company’s commitment to sustainable practices by comparing changes
in sentiment to changes in emissions. This allows us to see whether the
companies sentiment effects their emissions.

``` r
#filter to a target company
filterframe2 <- filterframe %>%
  filter(`PARENT COMPANIES` == "PPG Industries")

#alias the sentiment analysis dataframe
esg_df <- results_df

#Rename columns to help merge
colnames(esg_df)[colnames(esg_df) == "REPORTING.YEAR"] <- "REPORTING YEAR"
colnames(esg_df)[colnames(esg_df) == "sentiment"] <- "ESG_Score"

#Merge yearly sentiment analysis of environmental terms with yearly emissions
merge_df <- merge(filterframe2, esg_df, by.x = "REPORTING YEAR", by.y = "REPORTING YEAR", all.x = TRUE) %>%
  filter(`REPORTING YEAR` %in% c(2011,2012,2013, 2014,2015,2016,2017,2018,2019,2020))

#Create graph with two Y-axises
#
my_plot <- ggplot(merge_df, aes(x = `REPORTING YEAR`)) +
  # First y-axis: GHG QUANTITY
  geom_line(aes(y = `GHG QUANTITY (METRIC TONS CO2e)`), color = "blue") +
  geom_point(aes(y = `GHG QUANTITY (METRIC TONS CO2e)`), color = "blue") +
  
  geom_text(
    aes(x = `REPORTING YEAR`, y = `GHG QUANTITY (METRIC TONS CO2e)`, 
        label = paste("(", `REPORTING YEAR`, ",", `GHG QUANTITY (METRIC TONS CO2e)`, "         )"),
        angle = 50,
        hjust = -.05,   
        vjust = -.01
        
    ), size = 2 ) +
  
  labs(y = "GHG Quantity (Metric Tons CO2e)", x = "Year") +
  
  #Second y-axis: ESG_Score
  geom_line(aes(y = `ESG_Score` * 10000000), color = "red") +
 
  labs(y = "ESG Index",  title = "GHG vs ESG Index") +
  
  scale_y_continuous(
    name = "GHG Quantity",
    sec.axis = sec_axis(~./10000000, name = "ESG Index")
  ) +

  scale_x_continuous(breaks = seq(min(merge_df$`REPORTING YEAR`), max(merge_df$`REPORTING YEAR`), by = 1)) 
```

<img src="assets/my_plot.png" width="6600" />
