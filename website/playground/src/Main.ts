import { setupSillyScriptEditor, setupJsonEditor } from "./Editors";
import { setupCompileButton } from "./CompileButton";
import { setupShareButton } from "./ShareButton";
import { TabManager } from "./Tabs";

const tabs = new TabManager();
tabs.setup();

setupSillyScriptEditor();
setupJsonEditor();
setupCompileButton(tabs);
setupShareButton();

const jsonOutput = document.getElementById("jsonOutput");
if(jsonOutput) {
	jsonOutput.innerHTML = "Nothing compiled yet. Click Compile to press CTRL/CMD + S.";
}
