import * as fs from "fs";
import * as path from "path";

/**
 * Main
 */
function main() {
	const args = process.argv.slice(2);

	if(args.length > 0) {
		if(args[0] === "supports") {
			process.exit(0);
			return;
		}
	}

	const basePath = path.resolve(process.argv[1], "../../");
	fs.copyFileSync(path.join(basePath, "json.min.js"), path.join(basePath, "json2.min.js"));
	//fs.writeFileSync("./test.txt", JSON.stringify(process, "\t", 1));

	const input = fs.readFileSync(0, "utf-8");
	const [context, book] = JSON.parse(input);
	console.log(JSON.stringify(book));
}

main();
