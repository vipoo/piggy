import SerialPort from 'serialport'
import pkg from 'commander';
import path from 'path'
import os from 'os'
import fs from 'fs'
import { fileURLToPath } from 'url'

const { dirname }  = path
const __dirname = dirname(fileURLToPath(import.meta.url));
const { program } = pkg;

const port = 'COM6'
const baud = 115200 * 2

// const fileData = Buffer.from("1234567890abcdef".repeat(60000/16));
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

function dispatchCommand(commandBuffer) {
  if(commandBuffer.startsWith('G ')) {
    dataPtr = 0
    packetNumber = 0
    communicationMode = DATA_SEND_MODE

    const fileName = commandBuffer.slice(2).trim()
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
  if (data[0] === NAK && packetNumber === 0) {
    console.log('Initiating data send');

    while(dataPtr <= fileData.length)
      sendAPacket();

    connection.write(String.fromCharCode(EOT))
    connection.write(new Uint8Array([checksum % 256, checksum >> 8]))

    return
  }

  if (data[0] === ACK && packetNumber > 0) {
    communicationMode = COMMAND_MODE
    const hrend = process.hrtime(startTime);
    const time = hrend[0] + hrend[1] / 1000000000.0
    console.info('\r\nTransmission Time: %ds %dms - rate of %d kB/s', hrend[0], hrend[1] / 1000000, fileData.length / 1024.0 / (time))
    console.log("Checksum", checksum & 0xFFFF)
    return
  }

  console.log('Unexpected data received');
  communicationMode = COMMAND_MODE
}

function main() {


  connection = new SerialPort(port, {
    baudRate: baud,
    dataBits: 8,
    stopBits: 1,
    parity: 'none',
    rtscts: true
  })

  connection.on('data', data => {
    // console.log(data)
    if (communicationMode == COMMAND_MODE)
      processCommand(data)
    else
      dataSend(data)
  })
}



program
  .option('-d, --directory <dir>', 'The working directory for files to transfer', 'cwd');

program.parse(process.argv);

program.directory = program.directory === "cwd" ? __dirname : program.directory

main(program)
