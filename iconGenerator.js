//Bun recommended, but does work with nodejs

import svg2png from "svg2png"
// import ico from "ico-endec"
import { readFile, writeFile, readdir, rm, mkdir } from "fs/promises"
import { join } from "path"

// type File = {
// 	name: string,
// 	svgContent: Buffer,
// 	pngLContent: Buffer,
// 	pngSContent: Buffer
// }

console.log("Enumerating files...");

let fileDirents = await Promise.all(await readdir("Helldivers-2-Stratagems-icons-svg", {
	recursive: true,
	withFileTypes: true
}));

fileDirents = fileDirents.filter(f=>f.isFile() && f.name.endsWith(".svg"));

fileDirents.push(...await Promise.all(await readdir("customIcons", { withFileTypes: true })))

fileDirents.sort((a, b)=> a.name < b.name ? -1 : 1);
fileDirents.unshift({
	name: "icon.svg",
	parentPath: "",
});

let files = await Promise.all(fileDirents.map(async f=>({
	name: f.name.replace(".svg", ""),
	svgContent: await readFile(join(f.parentPath, f.name))
})));

console.log(`Converting ${files.length} svgs to png data...`);

await Promise.all(files.map(async f=>{
	f.pngLContent = await svg2png(f.svgContent, {width: 100, height: 100});
	f.pngSContent = await svg2png(f.svgContent, {width: 30, height: 30});
	console.info(`Finished: ${f.name}`);
}));

// console.log("Packing pngs into ico file...");
// let icoBuffer: Buffer = ico.encode(files.map(f=>f.pngContent));
// console.log("Writing packed file...")

// await writeFile("strategems.ico", icoBuffer);

function toID(name) {
	let output = name;
	output = output.replace(/StA-X3|\./g, "");
	output = output.replace(/[-_ ](.)/g, (m, c)=>c.toUpperCase());
	if(output[1].toUpperCase() != output[1]) { //If it doesn't start with an initialism
		output = output.replace(/^(.)/, (m,c)=>c.toLowerCase());
	}
	return output.trim();
}

console.log("Writing pngs...");
try {
	await rm("iconsLarge", { recursive: true });
	await rm("iconsSmall", { recursive: true });
} catch(e) {}
await mkdir("iconsLarge", { recursive: true });
await mkdir("iconsSmall", { recursive: true });
await Promise.all(files.map(async (f,i)=>writeFile(join("iconsLarge", `${toID(f.name)}.png`), f.pngLContent)))
await Promise.all(files.map(async (f,i)=>writeFile(join("iconsSmall", `${toID(f.name)}.png`), f.pngSContent)))

console.log("Done!");