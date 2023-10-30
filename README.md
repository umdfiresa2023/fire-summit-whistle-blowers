# Team Whistleblower’s FIRE Summit Presentation
Anant Agrawal, Tyler, Ishaan Kalra

# <u>**Research Question**</u>

Are companies who claim to place an emphasis on ESG initiatives
effective in reducing their air pollution emissions?

![](assets/1.png)

# <u>***Data Querying***</u>

## Querying for 10K Filings

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

## Querying for FLIGHT DATA

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

### **2. Setting User Agent for HTTP Requests**

``` r
options(HTTPUserAgent = "xyz@abc.com")
```

### **3. Retrieving Annual Reports Information**

``` r
info.df <- AnnualReports("GOOG")
```

### **4. Function to retrieve GHG reports**

# <u>***Data Wrangling***</u>

## Outcome variable

## **Treatment variable**

## **Control variables**
