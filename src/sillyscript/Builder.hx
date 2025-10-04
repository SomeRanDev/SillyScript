package sillyscript;

import haxe.io.Path;
import sys.io.Process;

/**
	Builds a SillyScript executable.
**/
function main() {
	final args = Sys.args();
	if(args.length < 1 || args.length > 2 || args[0] == "help") {
		help();
		return;
	}

	switch(args[0].toLowerCase()) {
		case "js": js();
		case "nodejs": nodejs();
		case "hl": hl(args);
		case other: {
			Sys.println("Unknown target: " + other);
			help();
		}
	}
}

function help() {
	final sb = new StringBuf();
	sb.add("\n~~~~~~~~~~~~~ SillyScript Builder ~~~~~~~~~~~~~\n\n");
	sb.add("Build for JavaScript (optionally for NodeJS)\n");
	sb.add(" ▹ haxe Builder.hxml js\n");
	sb.add(" ▹ haxe Builder.hxml nodejs\n");
	sb.add("\n");
	sb.add("Build native executable with Hashlink/C\n");
	sb.add(" ▹ haxe Builder.hxml hl <hl_path>\n");
	Sys.println(sb.toString());
}

function run(cmd: String, args: Array<String>) {
	Sys.println(">> " + cmd + " " + args.join(" "));
	final proc = new Process(cmd, args);
	final exitCode = proc.exitCode();
	if(exitCode != 0) {
		Sys.println("\nCommand failed. Error output:\n\n" + proc.stderr.readAll() + "\n");
		Sys.exit(1);
	}
	proc.close();
}

function js() {
	run("haxe", ["Compile.hxml", "-js", "out/SillyScript.js", "sillyscript.SillyScript"]);
	Sys.println("Successfully generated for NodeJS: ./out/SillyScript.js");
}

function nodejs() {
	run("haxe", ["Compile.hxml", "-lib", "hxnodejs", "-js", "out/SillyScript.js"]);
	Sys.println("Successfully generated for JavaScript: ./out/SillyScript.js");
}

function hl(args: Array<String>) {
	// Get path to Hashlink installation
	if(args.length < 2) {
		Sys.println("Expected path to Hashlink binary release for hl target.\nhttps://hashlink.haxe.org/#download");
		help();
		return;
	}
	final hlPath = args[1];

	// Convert Haxe to Hashlink/C
	run("haxe", ["Compile.hxml", "-hl", "out/c/main.c"]);
	Sys.println("Successfully generated for C: ./out/c/main.c");

	// Detect platform and build
	switch(Sys.systemName()) {
		case "Windows": {
			run("cl", [
				"/O2",
				"/FeSillyScript.exe",
				"/TC",
				"/I", "out/c",
				"/I", Path.join([hlPath, "include"]),
				"out/c/main.c",
				"/link",
				"/SUBSYSTEM:CONSOLE",
				"/LIBPATH:" + hlPath,
				"hl.lib", "libhl.lib"
			]);
		}

		case "Linux": {
			run("gcc", [
				"-O3",
				"-o", "SillyScript",
				"-I", "out/c",
				"-I", Path.join([hlPath, "src"]),
				"out/c/main.c",
				"-L" + hlPath,
				"-lhl"
			]);
		}

		case platform: {
			Sys.println("Unsupported platform for Hashlink: " + platform);
		}
	}
}
