const puppeteer = require('puppeteer');

(async () => {
	let browser, page, message;

	try {
		browser = await puppeteer.launch();
		page = await browser.newPage();
		await page.goto('http://localhost/');

		await page.click('button');
		await page.click('button');
		await page.click('button');

		const element = await page.$('p');
		message = await page.evaluate(element => element.textContent, element);
	} finally {
		const testPassed = message === 'You\'ve pressed the button 3 times.';
		console.log((testPassed) ? `PASS: ${message}` : `FAIL: ${(message) ? message : '(no message displayed)'}`);

		if (process.env.TAKE_SCREENSHOT) {
			await page.screenshot({path: './screenshot.png'});
		}

		await browser.close();

		process.exit((testPassed) ? 0 : 1);
	}
})();
