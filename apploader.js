import fs from 'fs'
import util from 'util'
import childProcess from 'child_process'
import path from 'path'
import os from 'os'
import { fileURLToPath } from 'url'

const { dirname }  = path
const __dirname = dirname(fileURLToPath(import.meta.url));
const mainSection = 'code_crt_init'
const _fileAt100 = "/100"
const _fileAt200 = "/200"
const _loaderAsm = '/loader.asm'

function exec(command) {
  //console.log(`$: ${command}`)

  return new Promise((res, rej) => {
    const p = childProcess.spawn(command, [], {
      stdio: 'inherit',
      shell: '/bin/bash'
    })

    p.on('close', code => code ? rej(new Error(`Exit with code ${code}`)) : res())
  })

}

function convertBitmapByte(hits, index) {
  let byte = 0
  for(let i = 0; i < 8; i++) {
    const hit = hits.some(x => x === index + i)
    if (hit)
      byte |= Math.pow(2, 7 - i)
  }

  return byte
}

function convertToBitmap(hits, dataLength) {
  const length_ = parseInt(dataLength / 8)
  const length = dataLength % 8 > 0 ? length_ + 1 : length_
  const data = Buffer.alloc(length + 2)

  for(let i = 0; i < length; i++) {
    const byte = convertBitmapByte(hits, i * 8)
    data[i + 2] = byte
  }

  data[0] = length & 255
  data[1] = length >> 8
  return data
}

async function main(directory, ...options) {
  const output = options.find(x => x.startsWith('-o')) || options.find(x => x.startsWith('--output')).slice(7)
  const fileName = output.slice(2)

  const fileAt100 = `${directory}/${_fileAt100}`
  const fileAt200 = `${directory}/${_fileAt200}`
  const loaderAsm = `${directory}/${_loaderAsm}`

  const pageAlign = options.find(x => x == '--page-align')

  options = options
    .filter(x => !x.startsWith('-o'))
    .filter(x => !x.startsWith('--output'))
    .filter(x => !x.startsWith('--page-align'))
    .map(x => `"${x}"`)
    .join(' ')

  await exec(`z80asm -DORGIN100 -o"${fileAt100}" -b ${options}`)
  await exec(`z80asm -DORGIN200 -o"${fileAt200}" -b ${options}`)

  const data1 = fs.readFileSync(`${fileAt100}_${mainSection}.bin`)
  const data2 = fs.readFileSync(`${fileAt200}_${mainSection}.bin`)

  if (data1.length != data2.length)
    throw new Error("File length are different")

  const hits = []
  for(let i=0; i < data1.length; i++) {
    if (data1[i] !== data2[i])
      hits.push(i - 1)
  }

  //console.log('assembled filename:', fileName)
  const relocFileName = `${directory}/100.reloc`

  const data = convertToBitmap(hits, data2.length)

  fs.writeFileSync(relocFileName, data)

  const x = path.join(__dirname, 'loader.asm')
  fs.writeFileSync(loaderAsm, fs.readFileSync(x))

  const defines = pageAlign ? "-DPAGEALIGN" : ""

  await exec(`gpp --includemarker "; #include line: %, file:%" -n ${defines} -o ${directory}/loader.asmpp ${loaderAsm}`)

  await exec(`z80asm -r=256 -o"${fileName}" -b "${directory}/loader.asmpp"`)
}

fs.mkdtemp(path.join(os.tmpdir(), 'x-'), async (err, directory) => {
  main(directory, ...[...process.argv].slice(2)).catch(err => {
    // console.log(err.stack)
    console.log("");
    process.exit(1)
  })
})
