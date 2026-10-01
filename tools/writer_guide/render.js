// Render guide.html to PDF with headless Chromium (Playwright). Usage: node render.js in.html out.pdf
const { chromium } = require('/opt/node-tools/node_modules/playwright');
(async () => {
  const [, , input, output] = process.argv;
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.goto('file://' + require('path').resolve(input), { waitUntil: 'load' });
  await page.pdf({
    path: output, format: 'A4', printBackground: true, preferCSSPageSize: true, outline: true, tagged: true,
    displayHeaderFooter: true,
    headerTemplate: '<div></div>',
    footerTemplate: '<div style="font-size:8px;width:100%;text-align:center;color:#7b6f60;font-family:serif">Six Worlds: A Writer\'s Guide &nbsp;·&nbsp; <span class="pageNumber"></span></div>',
    margin: { top: '20mm', bottom: '20mm', left: '18mm', right: '18mm' },
  });
  await browser.close();
})();
