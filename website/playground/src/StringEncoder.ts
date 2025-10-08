// Code loosely based on:
// https://stackoverflow.com/a/30106551

import { deflate, inflate } from "pako";

function uint8ToBase64(u8: Uint8Array): string {
	let binary = "";
	const length = u8.length;
	for(let i = 0; i < length; i++) {
		binary += String.fromCharCode(u8[i]);
	}
	return btoa(binary);
}

function base64ToUint8Array(base64: string): Uint8Array {
	const binary = atob(base64);
	const length = binary.length;
	const bytes = new Uint8Array(length);
	for(let i = 0; i < length; i++) {
		bytes[i] = binary.charCodeAt(i);
	}
	return bytes;
}

export function toBinary(input: string): string {
	const length = input.length;
	const codeUnits = new Uint16Array(length);
	for(let i = 0; i < length; i++) {
		codeUnits[i] = input.charCodeAt(i);
	}
	const inputBytes = new Uint8Array(codeUnits.buffer);
	const compressed: Uint8Array = deflate(inputBytes, { level: 9 });
	return uint8ToBase64(compressed);
}

export function fromBinary(encoded: string): string {
	const compressed: Uint8Array = base64ToUint8Array(encoded);
	const outputBytes: Uint8Array = inflate(compressed);
	const codeUnits = new Uint16Array(outputBytes.buffer);

	let result = "";
	const length = codeUnits.length;
	for(let i = 0; i < length; i++) {
		result += String.fromCharCode(codeUnits[i]);
	}
	return result;
}
