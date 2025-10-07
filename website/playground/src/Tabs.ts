import { jsonEditor } from "./Editors";

export class TabManager {
	tabIndicator: HTMLElement | null;
	generateJsonTab: HTMLElement | null;
	outputErrorsTab: HTMLElement | null;
	jsonEditorHolder: HTMLElement | null;
	errorOutputContainer: HTMLElement | null;

	constructor() {
		this.tabIndicator = document.getElementById("tabIndicator");
		this.generateJsonTab = document.getElementById("generateJsonTab");
		this.outputErrorsTab = document.getElementById("outputErrorsTab");

		this.jsonEditorHolder = document.getElementById("jsonEditorHolder");
		this.errorOutputContainer = document.getElementById("errorOutputContainer");
	}

	setup() {
		if(this.generateJsonTab) {
			this.generateJsonTab.onclick = this.goToJsonTab.bind(this);
		}
		if(this.outputErrorsTab) {
			this.outputErrorsTab.onclick = this.goToOutputTab.bind(this);
		}
	}

	goToJsonTab() {
		this.setTab(true);
	}

	goToOutputTab() {
		this.setTab(false);
	}

	setTab(isLeft: boolean) {
		this.tabIndicator?.classList.remove(isLeft ? "right" : "left");
		this.tabIndicator?.classList.add(isLeft ? "left" : "right");

		if(isLeft) {
			this.generateJsonTab?.classList.add("active");
			this.outputErrorsTab?.classList.remove("active");
		} else {
			this.outputErrorsTab?.classList.add("active");
			this.generateJsonTab?.classList.remove("active");
		}

		if(this.jsonEditorHolder) this.jsonEditorHolder.style.display = isLeft ? "" : "none";
		if(this.errorOutputContainer) this.errorOutputContainer.style.display = isLeft ? "none" : "";
	}
}
