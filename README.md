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

#### *Language: JavaScript (Node.js environment)*

### A. **Explanation of `scrapeSECWebsite()` Function**

### Description

This function scrapes financial documents links from the SEC website for
specified companies.

#### Steps

1.  **Setup Puppeteer with StealthPlugin**: Initializes Puppeteer in
    headless mode with a stealth plugin to avoid detection.

2.  **Loop through Companies**: Iterates over a dictionary of company
    names and their corresponding entity names.

3.  **Build URL & Open New Page**: Constructs the URL for each company
    and opens a new page.

4.  **Page Navigation & Data Extraction**: Navigates to the URL, waits
    for content, and extracts relevant links from the table.

    - **Pagination Handling**: Loops through pages to get more links if
      available.

5.  **Filter & Process Links**: Processes each link, scraping and saving
    the text content.

6.  **Close Browser**: Closes the Puppeteer browser instance after
    processing all companies.

#### Additional Function: **`scrapeTextAndSaveToFile()`**

- **Purpose**: Scrapes text content from a given URL and saves it to a
  file.

- **Operations**: Opens the URL, extracts text, sanitizes it, finds
  fiscal year information, and saves to a file.

#### Dependencies

- **`fs`**: For file operations.

- **`sanitize-filename`**: To sanitize file names.

- **`puppeteer-extra`** and **`puppeteer-extra-plugin-stealth`**: For
  enhanced browser automation.

- **`string-strip-html`**: To strip HTML from scraped text.

### B. **Explanation of `scrapeRevenueWebsite()` Function**

#### Description

This function scrapes revenue data from a specified website for a list
of companies. The data is formatted into CSV and saved to a file.

#### Steps

1.  **Setup Puppeteer**: Initializes Puppeteer with a non-headless
    browser and a custom executable path.

2.  **Initialize CSV Data**: Sets up a CSV string header with “Company
    Name, Year, Revenue”.

3.  **Loop through Companies**: Iterates over a list of company names.

4.  **Modify Company Name & Build URL**: Converts each company name to a
    URL-friendly format.

5.  **Open New Page**: Opens a new browser page for each company URL.

6.  **Page Navigation & Wait**: Navigates to the URL and waits for
    content to load.

7.  **Data Extraction**: Executes a script in the page context to scrape
    table data for revenue.

    - **Extract Years and Revenue**: Grabs revenue data for years
      2011-2021, converting billions to numeric values.

8.  **Format & Add to CSV**: Formats the data per company and appends to
    the CSV string.

9.  **Close Browser**: Closes the Puppeteer browser instance.

10. **Save to File**: Writes the CSV data to a file named
    “company_revenue_data.csv”.

#### Dependencies

- **`fs`**: File System module for file operations.

- **`puppeteer`**: For browser automation.

### C. Scraping Code

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

### 5. Function to Run the 10K Reports Scraping Algorithm

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

### 7. Function to Run the Revenue Scraping Algorithm

``` javascript
async function scrapeRevenueWebsite() {
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: executablePath(),
  });

  let csvData = "Company Name,Year,Revenue\n";

  for (const companyName of companyNames) {
    let modified = companyName.replace(" ", "-");
    let url = `https://companiesmarketcap.com/${modified.toLowerCase()}/revenue/`;
  
    const page = await browser.newPage();

    await page.goto(url);
    await page.waitForTimeout(2000);

    const result = await page.evaluate(() => {
      const tableElement = document.querySelector(".table");
      let rowData = "";

      if (tableElement) {
        const tbody = tableElement.querySelector("tbody");
        if (tbody) {
          const rows = tbody.querySelectorAll("tr");

          rows.forEach((row) => {
            const cells = row.querySelectorAll("td");
            if (cells.length >= 2) {
              const year = cells[0].textContent.trim().substring(0, 4);
              if (year >= "2011" && year <= "2021") {
                let revenue = cells[1].textContent.trim();
                if (revenue.includes("B")) {
                  revenue = revenue.replace("B", "").replace("$", "").trim();
                  revenue = parseFloat(revenue) * 1e9; // Convert billion to numeric
                }
                rowData += `${year},${revenue}\n`;
              }
            }
          });
        } else {
          console.error("Tbody element not found inside the table");
        }
      } else {
        console.error("Table element not found");
      }
      return rowData;
    });

    csvData += result
      .split("\n")
      .map((line) => `${companyName},${line}`)
      .join("\n");
  }

  await browser.close();
  // Write CSV data to file
    fs.writeFileSync("company_revenue_data.csv", csvData);
}
```

### **8. Run 10K scraping function**

``` javascript
scrapeSECWebsite();
```

### **9. Run Revenue scraping function**

``` javascript
scrapeRevenueWebsite();
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
library(tidyverse)
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

1.  The provided R code is designed to assess how positively or
negatively a company’s environmental goals are expressed in its annual
reports.

2.  It does this by looking at sentences in the reports that contain
words related to the environment and calculating an overall sentiment
score for those sentences.

3.  This score is based on a pre-defined list of words associated with
positive or negative sentiments. The range of the sentiment values are
-5 to 5, with -5 representing the most negative sentiment, and 5
representing the most positive.

4.  The code then calculates an average sentiment score to gauge the
overall tone of the environmental statements in the reports, which can
provide insights into a company’s commitment to environmental
sustainability.

### What does the score and code overall mean? 🧐

1.  All the functions used in this code about NLP are from the tidytext
    and SnowballC packages present in R. 

2.  The analysis begins with reading all the data from the 10K report
    and then creates a database with all the report lines. 

3.  The program checks for sentences with the words “environment”,
    “environmental” and “environmentally” and analyzes what sentiment
    each sentence depicts. 

4.  Finally, the code averages out the score of each sentence to give an
    aggregate ESG Score for that 10K.

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

### Sample Analysis 🔬

#### **Positive Sentiment on Environment**

1.  **Appreciation for Environment:** Emphasizes love and proactive
    environmental approaches in projects.

2.  **Reduction of Emissions:** Prioritizes lowering emissions as a key
    goal.

#### **Negative Sentiment on Environment**

1.  **Disregard for Environment:** Views environmental concerns as
    wasteful and detrimental to profits.

2.  **Sentiment Scoring:** Lower scores influenced by words like “cut”
    and “worrying,” despite strong negatives like “hate.”

#### **Sentiment Analysis**

- The first text scored +3, showing positive sentiment.

- The second text scored -1.33, reflecting negative sentiment.

- The analysis demonstrates the ability to detect overall sentiments in
  environmental contexts.

# <u>**Preliminary Results**</u> **💡**

Upon consolidating all the data, we can uncover the subtle nuances in
how a company, Westlake in this instance, has changed over the years in
terms of its sentiment towards the environment. This provides a window
into the company’s commitment to sustainable practices by comparing
changes in sentiment to changes in emissions as well as growing revenues
over the years. This allows us to see whether the companies sentiment
effects their emissions.

<u>**Language: R**</u>

The provided code creates a visual analysis for Westlake Chemical,
comparing normalized greenhouse gas (GHG) emissions per revenue with the
company’s Environmental, Social, and Governance (ESG) Score over time.
This approach offers a nuanced view of Westlake’s environmental impact
and sustainability commitment. By correlating GHG emissions (adjusted
for financial size) with ESG performance, the visualization can reveal
trends and potential discrepancies, highlighting the effectiveness of
the company’s sustainable practices and its actual environmental impact
in relation to its sustainability

``` r
#filter the final dataframe to just the Westlake company and normalize emissions with revenue
df2 <- df %>%
mutate(`GHG QUANTITY (METRIC TONS CO2e)` = `GHG QUANTITY (METRIC TONS CO2e)` / Revenue * 1000) %>%
filter(company =="Westlake")
  

my_plot <- ggplot(df2, aes(x = year)) +
  # First y-axis: GHG QUANTITY
  geom_line(aes(y = `GHG QUANTITY (METRIC TONS CO2e)`), color = "blue") +
  geom_point(aes(y = `GHG QUANTITY (METRIC TONS CO2e)`), color = "blue") +
  labs(y = "GHG Quantity  / Revenue", x = "Year") +
  geom_line(aes(y = `ESG_Score`), color = "red") +
   labs(y = "ESG Index",  title = "GHG/Revenue vs ESG Index (Westlake Chemical)") +
  # Add second y-axis
  scale_y_continuous(
    name = "GHG Quantity / Revenue (BLUE)",
     sec.axis = sec_axis(~.* 1, name = "ESG Index (RED)")
  ) +
  scale_x_continuous(breaks = seq(min(df2$year), max(df2$year), by = 1)) 
```

<img src="westlakegraph.png" width="684" />
