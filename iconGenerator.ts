import svg2png from "svg2png"
import { readFile, readdir } from "fs/promises"
import { join } from "path"

let files = await readdir(join(__dirname, "Helldivers-2-Strategems-icons-svg"), {
	recursive: true,
})

console.log(files)