import SerialPort from 'serialport'
import fs from 'fs'

const port = 'COM6'
const baud = 115200 * 2

// const data = fs.readFileSync("./xmsend.js")
// const data = fs.readFileSync("..\\RomWBW-Env\\RomWBW\\Binary\\RCZ80_dino.com");
//const data = fs.readFileSync("..\\RomWBW-Env\\RomWBW\\Source\\Doc\\Architecture.md")
const data = Buffer.from("1234567890abcdef".repeat(75000/16));

let dataPtr = 0

const SOH = 0x01
const EOT = 0x04
const ACK = 0x06
const NAK = 0x15
const ETB = 0x17
const CAN = 0x18

let packetNumber = 0

function checkSumOf(data) {
  let result = 0
  for(let i = 0; i < data.length; i++) {
    result = (result + data[i]) % 256
  }

  return result;
}

function sendAPacket(connection) {
  ++packetNumber
  const pL = packetNumber
  const pH = 255 - packetNumber

  process.stdout.write(".");

  const packetData = new Uint8Array(128)
  packetData.fill(26, 0, 129)
  packetData.set(data.slice(dataPtr, dataPtr + 128), 0)
  dataPtr += 128

  connection.write(new Uint8Array([SOH, pL, pH]))
  connection.write(packetData)
  connection.write(new Uint8Array([checkSumOf(packetData)]))
}

async function main() {

  const connection = new SerialPort(port, {
    baudRate: baud,
    dataBits: 8,
    stopBits: 1,
    parity: 'none',
    rtscts: true
  })

  let startTime = process.hrtime()

  console.log("Waiting for data");
  connection.on('data', d => {
    // console.log(`received ${d.length} bytes`, d, d.toString())

    if (d[0] === NAK && packetNumber === 0) {
      console.log("Receieved first NAK", packetNumber, dataPtr);
      const hrend = process.hrtime(startTime);
      console.info('Execution time (hr): %ds %dms', hrend[0], hrend[1] / 1000000)
      startTime = process.hrtime()

      sendAPacket(connection);

      return
    }

    if (d[0] === ACK && packetNumber > 0) {
      if(dataPtr > data.length) {
        console.log("Done")
        connection.write(String.fromCharCode(EOT))
        connection.flush()

        const hrend = process.hrtime(startTime);
        console.info('Execution time (hr): %ds %dms - rate of %d kB/s', hrend[0], hrend[1] / 1000000, data.length / 1024.0 / hrend[0])

        setTimeout(() => process.exit(0))
      }

      sendAPacket(connection);
    }
  })
}

main();
