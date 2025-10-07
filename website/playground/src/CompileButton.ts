import { EditorState } from "@codemirror/state";
import { createJsonEditorState, editor, jsonEditor } from "./Editors";
import { compileSillyScript } from "./SillyScriptCompiler";
import { TabManager } from "./Tabs";

export function setupCompileButton(tabs: TabManager) {
	const compileButton = document.getElementById("compileButton");
	if(!compileButton) return;
	compileButton.onclick = () => onCompileButtonClick(tabs);
}

function onCompileButtonClick(tabs: TabManager) {
	if(!editor) return;

	const code = editor.state.doc.toString();
	const result = compileSillyScript(code);

	// Update JSON output
	const jsonOutputString = result.kind === 0 ? result.output : "";
	jsonEditor?.setState(createJsonEditorState(jsonOutputString));

	// Update error output
	const errorOutputString = result.kind === 1 ? result.output : "";
	const errorOutputContainer = document.getElementById("errorOutputContainer");
	if(errorOutputContainer) {
		errorOutputContainer.innerHTML = errorOutputString;
	}

	switch(result.kind) {
		case 0: {
			tabs.goToJsonTab();
			break;
		}
		case 1: {
			tabs.goToOutputTab();
			break;
		}
	}
}
