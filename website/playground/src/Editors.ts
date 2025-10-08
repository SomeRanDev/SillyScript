import { EditorState } from "@codemirror/state";
import { openSearchPanel, highlightSelectionMatches } from '@codemirror/search';
import { indentWithTab, history, defaultKeymap, historyKeymap } from '@codemirror/commands';
import { foldGutter, indentOnInput, indentUnit, bracketMatching, foldKeymap, syntaxHighlighting, defaultHighlightStyle } from '@codemirror/language';
import { closeBrackets, autocompletion, closeBracketsKeymap, completionKeymap } from '@codemirror/autocomplete';
import { lineNumbers, highlightActiveLineGutter, highlightSpecialChars, drawSelection, dropCursor, rectangularSelection, crosshairCursor, highlightActiveLine, keymap, EditorView } from '@codemirror/view';
import { json } from "@codemirror/lang-json";
import { oneDark } from "@codemirror/theme-one-dark";
import { fromBinary } from "./StringEncoder";

const DEFAULT_SILLY_SCRIPT_CODE = `1;
2;
3;
"Test";
false;`;

export let editor: EditorView | null = null;
export let jsonEditor: EditorView | null = null;

function getExtensions() {
	return [
		lineNumbers(),
		highlightActiveLineGutter(),
		highlightSpecialChars(),
		history(),
		foldGutter(),
		drawSelection(),
		indentUnit.of("	"),
		indentOnInput(),
		bracketMatching(),
		closeBrackets(),
		autocompletion(),
		rectangularSelection(),
		crosshairCursor(),
		highlightActiveLine(),
		highlightSelectionMatches(),
		keymap.of([
			indentWithTab,
			...closeBracketsKeymap,
			...defaultKeymap,
			...historyKeymap,
			...foldKeymap,
			...completionKeymap,
		]),
	];
}

export function setupSillyScriptEditor() {
	let editorElement = document.getElementById("editor");
	if(!editorElement) return;

	const urlParams = new URLSearchParams(window.location.search);
	const base64Code = urlParams.get("code");
	const initialCode = base64Code !== null ? decodeURIComponent(fromBinary(base64Code)) : DEFAULT_SILLY_SCRIPT_CODE;

	editor = new EditorView({
		state: EditorState.create({
			extensions: [
				...getExtensions(),
				json(),
				oneDark,
			],
			doc: initialCode,
		}),
		parent: editorElement,
	});
}

export function setupJsonEditor() {
	let editorElement = document.getElementById("jsonEditor");
	if(!editorElement) return;

	jsonEditor = new EditorView({
		state: createJsonEditorState(""),
		parent: editorElement,
	});
}

export function createJsonEditorState(code: string) {
	return EditorState.create({
		extensions: [
			...getExtensions(),
			EditorState.readOnly.of(true),
			json(),
			oneDark,
		],
		doc: code,
	});
}
