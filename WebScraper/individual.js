import fs from "fs";
import puppeteer from "puppeteer-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";
import { strict as assert } from "assert";
import { stripHtml } from "string-strip-html";

// Set up StealthPlugin
puppeteer.use(StealthPlugin());

// Import executablePath from puppeteer
import { executablePath } from "puppeteer";

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: executablePath(),
  });
  const page = await browser.newPage();

  const url =
    "https://www.sec.gov/Archives/edgar/data/1807901/000119312521102234/d139974d10ka.htm";

  await page.goto(url, { waitUntil: "domcontentloaded" });

  // Wait for the page to load completely
  await page.waitForSelector("body");

  // Extract all text content from the page
  const textContent = await page.evaluate(() => {
    return document.body.textContent;
  });

  // Remove HTML tags from the text content
  // const strippedString = textContent.replace(/(<([^>]+)>)/gi, '');
  const strippedResult = stripHtml(textContent);
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
        break;
      }
    }
  }

  let fileName = `output.txt`;
  if (fiscalYear) {
    fileName = `${fiscalYear}.txt`;
  } else {
    console.log("Fiscal year information not found in the text.");
  }
  fs.writeFileSync(fileName, strippedString, "utf-8");
  console.log(`Text content scraped and saved to ${fileName}`);

  await browser.close();
})();
