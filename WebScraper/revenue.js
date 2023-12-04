//Import required modules
import fs from "fs";
import sanitize from "sanitize-filename";
import puppeteer from "puppeteer-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";
import { stripHtml } from "string-strip-html";

// Import executablePath from puppeteer
import { executablePath } from "puppeteer";

// Set up StealthPlugin
puppeteer.use(StealthPlugin());

const companyNames = [
  "Albemarle",
    "3M",
    "Westlake Chemical",
    "PPG Industries",
    "Exxon Mobil",
    "Huntsman",
    "Celanese",
    "Honeywell",
];

async function scrapeSECWebsite() {
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

scrapeSECWebsite();
