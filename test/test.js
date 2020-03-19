const puppeteer = require('puppeteer');

(async () => {
	let message;
	try {
		const browser = await puppeteer.launch();
		const page = await browser.newPage();
		await page.goto('http://localhost/');

		await page.click('button');
		await page.click('button');
		await page.click('button');

		const element = await page.$('p');
		const message = await page.evaluate(element => element.textContent, element);

		await browser.close();
	} finally {
		const testPassed = message === 'You\'ve pressed the button 3 times.';
		console.log((testPassed) ? `PASS: ${message}` : `FAIL: ${(message) ? message : '(no message displayed)'}`);
		process.exit((testPassed) ? 0 : 1);
	}
})();
