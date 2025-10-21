import type {
	SillyScript,
	SillyScriptCompileResultFailure,
	SillyScriptCompileResultSuccess
} from "sillyscript";

export function compileSillyScript(code: string): { kind: number, output: string } {
	// @ts-ignore The SillyScript class is available from a browser-compatible SillyScript.js, so we just assume it exists.
	const silly: SillyScript = new globalThis.SillyScript();
	const result = silly.compile(code, "playground.silly");
	if(result._hx_index === 0) {
		return {
			kind: 0,
			output: (result as SillyScriptCompileResultSuccess).content,
		}
	} else {
		let errorStrings = [];
		for(const error of (result as SillyScriptCompileResultFailure).errors) {
			errorStrings.push(silly.getErrorString(error, {
				_hx_index: 2,
				errorColor: "#ee5588",
				lineColor: "#447799",
				highlightColor: "white",
			}));
		}
		return {
			kind: 1,
			output: errorStrings.join("\n\n"),
		}
	}
}