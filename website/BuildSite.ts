import fs from "fs-extra";

async function main() {
	// Main Page
	fs.copy("assets/Logo.png", "main_page/Logo.png");

	// Documentation
	fs.copy("documentation/book", "main_page/documentation");

	// Playground
	if(!fs.existsSync("main_page/playground")) {
		fs.mkdir("main_page/playground");
	}
	function copyPlaygroundFile(name: string) {
		fs.copy("playground/" + name, "main_page/playground/" + name);
	}
	copyPlaygroundFile("index.html");
	copyPlaygroundFile("style.css");
	copyPlaygroundFile("out/main.bundle.js");
	fs.copy("assets/Logo.png", "main_page/playground/Logo.png");
	fs.copy("assets/CompileIcon.svg", "main_page/playground/CompileIcon.svg");
	fs.copy("../out/SillyScript.js", "main_page/playground/SillyScript.js");

	console.log("Copy success!");
}

main();
