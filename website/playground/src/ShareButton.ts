import { editor } from "./Editors";
import { toBinary } from "./StringEncoder";

export function setupShareButton() {
	const shareButton = document.getElementById("shareButton");
	if(!shareButton) return;
	shareButton.onclick = onShareButtonClick;

	const shareDialogCloseButton = document.getElementById("shareDialogCloseButton");
	if(!shareDialogCloseButton) return;
	shareDialogCloseButton.onclick = onShareDialogCloseButtonClick;

	const shareDialogCopyButton = document.getElementById("shareDialogCopyButton");
	if(!shareDialogCopyButton) return;
	shareDialogCopyButton.onclick = onShareDialogCopyButtonClick;
}

function onShareButtonClick() {
	if(!editor) return;

	const shareDialog = document.getElementById("shareDialog");
	if(!shareDialog || !(shareDialog instanceof HTMLDialogElement)) return;

	const shareLinkHolder = document.getElementById("shareLinkHolder");
	if(!shareLinkHolder || !(shareLinkHolder instanceof HTMLTextAreaElement)) return;

	shareLinkHolder.value = (
		window.location.origin +
		window.location.pathname +
		"?code=" + encodeURIComponent(toBinary(editor.state.doc.toString()))
	);
	shareDialog.showModal();
}

function onShareDialogCloseButtonClick() {
	const shareDialog = document.getElementById("shareDialog");
	if(shareDialog && shareDialog instanceof HTMLDialogElement) {
		shareDialog.close();
	}
}

function onShareDialogCopyButtonClick() {
	const shareLinkHolder = document.getElementById("shareLinkHolder");
	if(shareLinkHolder && shareLinkHolder instanceof HTMLTextAreaElement) {
		navigator.clipboard.writeText(shareLinkHolder.value);
	}
}
