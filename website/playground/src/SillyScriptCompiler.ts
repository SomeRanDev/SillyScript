// @ts-nocheck

export function compileSillyScript(code: string): { kind: int, output: string } {
	const silly = new sillyscript.SillyScript();
	const result = silly.compile(code, "playground.silly");
	if(result._hx_index === 0) {
		return {
			kind: 0,
			output: result.content,
		}
	} else {
		let errorStrings = [];
		for(const error of result.errors) {
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