import { nodeResolve } from "@rollup/plugin-node-resolve";
import typescript from "@rollup/plugin-typescript";
export default {
	input: "./src/Main.ts",
	output: {
		file: "./out/main.bundle.js",
		format: "iife",
	},
	plugins: [nodeResolve(), typescript()],
};
