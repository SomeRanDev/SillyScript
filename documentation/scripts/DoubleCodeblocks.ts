import * as fs from "fs";

type Section = {
	Chapter: Chapter,
};

type Chapter = {
	content: string,
	sub_items: undefined | Section[],
};

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

	processBook();
}

/**
 * Processes the input book contents and outputs the result to stdout.
 */
function processBook() {
	// Read stdin.
	// https://stackoverflow.com/a/56012724/8139481
	const input = fs.readFileSync(0, "utf-8");
	const [context, book] = JSON.parse(input);

	// Process all sections.
	for(const section of book.sections) {
		processSection(section);
	}

	// Print updated book to stdout
	console.log(JSON.stringify(book));
}

/**
 * Processes a Section object.
 */
function processSection(section: Section) {
	if(!section.Chapter) return;
	processChapter(section.Chapter);
}

/**
 * Processes a Chapter object.
 */
function processChapter(chapter: Chapter) {
	chapter.content = processContent(chapter.content);

	if(chapter.sub_items) {
		for(const item of chapter.sub_items) {
			processSection(item);
		}
	}
}

/**
 * Processes the content of a book as a string.
 * The returned string replaces the content string in the book.
 */
function processContent(content: string): string {
	return convertDoubleCodeblocks(content);
}

/**
 * Returns a copy of the string "word" with the first character
 * capatalized.
 */
function capitalize(word: string): string {
	if(word.length <= 0) return word;
	return word.charAt(0).toUpperCase() + word.slice(1);
}

/**
 * Convert the [doublecodeblock]...[/doublecodeblock] syntax
 * to its intended HTML content.
 */
function convertDoubleCodeblocks(input: string): string {
	return input.replace(
		/doublecodeblock:([\s\S]*?)?```(\w+)\s*([\s\S]*?)```[\r\n]+([\s\S]*?)?```(\w+)\s*([\s\S]*?)```/g,
		convertDoubleCodeblockMatch
	);
}

function convertDoubleCodeblockMatch(_match, preText1: string | undefined, lang1: string, code1: string, preText2: string | undefined, lang2: string, code2: string) {
	const preText1Trim = convertIndentedLines(preText1);
	const preText2Trim = convertIndentedLines(preText2);
	const lang1Trim = convertIndentedLines(lang1);
	const lang2Trim = convertIndentedLines(lang2);
	const code1Trim = convertIndentedLines(code1);
	const code2Trim = convertIndentedLines(code2);

	return `<table style="table-layout: fixed; width: 100%;">
<tr>
<th>${capitalize(lang1Trim)}</th>
<th>${capitalize(lang2Trim)}</th>
</tr>
<tr>
<td style="vertical-align:top">

${preText1Trim ? `<p>${preText1Trim}</p>\n\n` : ""}
\`\`\`${lang1Trim}
${code1Trim}
\`\`\`

</td>
<td style="vertical-align:top">

${preText2Trim ? `<p>${preText2Trim}</p>\n\n` : ""}
\`\`\`${lang2Trim}
${code2Trim}
\`\`\`

</td>
</tr>
</table>`;
}

function convertIndentedLines(linesString: string | null | undefined): string {
	if(!linesString) return "";

	return linesString.split(/[\n\r]+/).map(function(s) {
		if(s[0] === "\t") {
			return s.substr(1);
		}
		return s;
	}).join("\n").trim();
}

main();
