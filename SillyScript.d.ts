export class SillyScript {
	constructor();

	compile(code: string, filename: string): SillyScriptCompileResult;
	getErrorString(error: SillyScriptError, format: SillyScriptErrorFormat): string;
}

export interface SillyScriptCompileResult {
	_hx_index: number;
}

export interface SillyScriptCompileResultSuccess extends SillyScriptCompileResult {
	_hx_index: 0;
	content: string;
}

export interface SillyScriptCompileResultFailure extends SillyScriptCompileResult {
	_hx_index: 1;
	errors: SillyScriptError[];
}

export interface SillyScriptError {
}

export interface SillyScriptErrorFormat {
	_hx_index: number,
	errorColor: string,
	lineColor: string,
	highlightColor: string,
}
