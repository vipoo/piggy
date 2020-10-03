import SerialPort from 'serialport'
import pkg from 'commander';
import path from 'path'
import os from 'os'
import fs from 'fs'
import { fileURLToPath } from 'url'
import ora from 'ora'

const { dirname }  = path
const __dirname = dirname(fileURLToPath(import.meta.url));
const { program } = pkg;

let fileData = undefined

const SOH = 0x01
const EOT = 0x04
const ACK = 0x06
const NAK = 0x15
const ETB = 0x17
const CAN = 0x18

const COMMAND_MODE = 1
const DATA_SEND_MODE = 2

let connection
let communicationMode = COMMAND_MODE
let commandBuffer = ''
let packetNumber = 0
let dataPtr = 0
let startTime

let checksum
let fileName
let spinner

let timeoutHandler
function resetTimeout() {
  clearTimeout(timeoutHandler)
  timeoutHandler = setTimeout(() => {
    spinner.fail('Client timed out');
    communicationMode = COMMAND_MODE
  }, 2000)
}

function abortTimeout() {
  clearTimeout(timeoutHandler)
}

function dispatchCommand(commandBuffer) {
  if(commandBuffer.startsWith('G ')) {
    dataPtr = 0
    packetNumber = 0
    communicationMode = DATA_SEND_MODE

    fileName = commandBuffer.slice(2).trim()
    const filePathName = path.join(program.directory, fileName)
    if (!fs.existsSync(filePathName)) {
      connection.write(new Uint8Array([NAK]))
      connection.write("File does not exist\r\n")
      communicationMode = COMMAND_MODE
      console.log(`File ${fileName} does not exists`)
      return
    }

    fileData = fs.readFileSync(filePathName)
    checksum = 0

    console.log(`Sending file TEST.TXT, length ${fileData.length}`)
    startTime = process.hrtime()
    connection.write(new Uint8Array([ACK]))

    resetTimeout()

    return
  }

  console.log('Bad command recieved', commandBuffer)
  connection.write(new Uint8Array([NAK]))
  connection.write("Bad command recieved\r\n")
}

function processCommand(data) {
  commandBuffer += data.toString();

  if (commandBuffer.endsWith('\r\n')) {
    console.log('Received command ', commandBuffer);

    dispatchCommand(commandBuffer)
    commandBuffer = ''
  }
}

function sendAPacket() {
  ++packetNumber

  const packetData = new Uint8Array(128)
  packetData.fill(26, 0, 129)
  packetData.set(fileData.slice(dataPtr, dataPtr + 128), 0)
  dataPtr += 128

  connection.write(new Uint8Array([SOH]))
  connection.write(packetData)

  for(const b of packetData)
    checksum += b
}

function dataSend(data) {
  for(const b of data)
    dataSendByte(b)
}

function dataSendByte(b) {
  if (b === NAK && packetNumber === 0) {
    spinner = ora(`Transmitting file ${fileName}`).start()

    while(dataPtr <= fileData.length)
      sendAPacket();

    connection.write(String.fromCharCode(EOT))
    connection.write(new Uint8Array([checksum % 256, checksum >> 8]))

    return
  }

  if (b === ACK && packetNumber > 0) {
    resetTimeout()
    return
  }

  if (b === EOT && packetNumber > 0) {
    communicationMode = COMMAND_MODE
    const hrend = process.hrtime(startTime);
    const time = hrend[0] + hrend[1] / 1000000000.0
    spinner.succeed(`Transmission Time: ${hrend[0]}s ${hrend[1] / 1000000}ms - rate of ${(fileData.length / 1024.0 / (time)).toPrecision(4)} kB/s`)
    abortTimeout()
    return
  }

  console.log('Unexpected data received');
  communicationMode = COMMAND_MODE
}

function main() {
  console.log(`Waiting for file transfer requests on PORT ${program.port} at baud rate ${program.baud} (8N1)`)
  connection = new SerialPort(program.port, {
    baudRate: program.baud,
    dataBits: 8,
    stopBits: 1,
    parity: 'none',
    rtscts: true
  })

  connection.on('error', (x) => console.log(x))

  connection.on('data', data => {
    // console.log(data)
    if (communicationMode == COMMAND_MODE)
      processCommand(data)
    else
      dataSend(data)
  })
}

function myParseInt(value, dummyPrevious) {
  // parseInt takes a string and an optional radix
  return parseInt(value);
}

program
  .option('-d, --directory <dir>', 'The working directory for files to transfer', 'cwd')
  .requiredOption('-p, --port <port>', 'The serial port to monitor - eg: COM6')
  .option('-b, --baud <rate>', 'The baud rate for serial comms', myParseInt, 115200 * 2)

program.parse(process.argv);

program.directory = program.directory === "cwd" ? __dirname : program.directory

main(program)
