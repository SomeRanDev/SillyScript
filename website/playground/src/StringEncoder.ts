// Code based on:
// https://stackoverflow.com/a/30106551

export function toBinary(string: string): string {
	const codeUnits = new Uint16Array(string.length);
	for (let i = 0; i < codeUnits.length; i++) {
		codeUnits[i] = string.charCodeAt(i);
	}
	return btoa(String.fromCharCode(...new Uint8Array(codeUnits.buffer)));
}

export function fromBinary(encoded: string): string {
	const binary = atob(encoded);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < bytes.length; i++) {
		bytes[i] = binary.charCodeAt(i);
	}
	return String.fromCharCode(...new Uint16Array(bytes.buffer));
}
