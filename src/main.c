#include "main.h"
#include "cpm.h"
#include "hbios.h"
#include "sio.h"
#include "xstdio.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

static const char pFileName[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
static const char pFileExtension[4] = {0, 0, 0, 0};

uint8_t tmsCfg[14];

static hbSysGetBnkInfoParams bnkInfoParams;
static FCB configFCB;
static uint8_t currentBankId;

uint16_t checksum = 0;

const char *dataLossMessage = "Error: Data loss\r\n";

void flushBuffer() {
  uint16_t x = 0;
  while (x != 0xFF00)
    x = sioIn();
}

void verifyChecksum() {
  const uint8_t c1 = sioIn();
  const uint8_t c2 = sioIn();
  const uint16_t c = (((uint16_t)c2) << 8) + (uint16_t)c1;

  if (c != checksum)
    print("\r\nData integrity check failed.\r\n");
  else
    print("\r\nDone\r\n");
}

void logPacketError(uint16_t chr) { xprintf("Error: Expected a SOH %04X, %d, %d.\r\n", chr, dataLoss, sioCount); }

uint8_t readWritePacket() {
  const uint16_t chr = sioIn();

  if (chr == (uint16_t)SOH) {
    prepDma();
    fWrite(&configFCB);

    sioOut(ACK);
    return true;
  }

  if (chr == (uint16_t)EOT) {
    verifyChecksum();
    return false;
  }

  logPacketError(chr);
  shutdown();
  return false;
}

void printIncomingLine() {
  uint16_t c;
  while (true) {
    c = sioIn();
    if (c >> 8 != 0) {
      print("Uknown Communication Error\r\n");
      return;
    }
    printChar(c);

    if (c == '\n')
      return;
  }
}

void expectAck() {
  const char c = sioIn();
  if (c == NAK) {
    printIncomingLine();
    shutdown();
  }
  if (c != ACK) {
    xprintf("Error: Expected ACK but got %02X\r\n", c);
    shutdown();
  }
}

void sioOutString(const char *p) {
  char c;
  while (c = *p++) {
    sioOut(c);
  }
}

void copySioConfig() {
  hbSetCurrentBank(bnkInfoParams.biosBankId);
  memcpy(&sioCfg, hbdCioIn_data, 15);
  hbSetCurrentBank(currentBankId);
}

void parseCommandLine(MainArguments *pargs) __z88dk_fastcall {
  if (pargs->argc != 1) {
    print("\r\nUsage: getr <filename>\r\n\r\nOptions:  <filename> is name of file on remote system to download\r\n\r\n");
    exit(1);
  }

  char *token = strtok((char *)pargs->argv[0], ".");
  if (token == NULL || token[0] == 0 || strlen(token) > 8) {
    print("Bad filename.\r\n");
    exit(1);
  }

  strcpy(pFileName, token);
  token = strtok(NULL, ".");
  if (token == NULL || token[0] == 0 || strlen(token) > 3) {
    print("Bad filename.\r\n");
    exit(1);
  }

  strcpy(pFileExtension, token);
}

void initialiseCioAndSio() {
  hbdInstallCioIn(1);
  hbdInstallCioOut(1);
  copySioConfig();
  installSioHandler();
}

void issueGetCommand() {
  sioOutString("G ");
  sioOutString(pFileName);
  sioOut('.');
  sioOutString(pFileExtension);
  sioOutString("\r\n");

  expectAck();
}

void configureFileForWriting() {
  resetFCB(pFileName, pFileExtension, &configFCB);
  fDelete(&configFCB);
  fMake(&configFCB);
  fDmaOff(diskBuffer1);
}

static hbSysGetFunc vdaParams;
static hbVdaDevParams vdaDev;
#define TMSINTEN 5

void disableTmsInterupts() {
  vdaDev.driver = 0;
  hbVdaDev(&vdaDev);
  if (vdaDev.devType != VDADEV_TMS)
    return;

  vdaParams.driver = 0;
  vdaParams.functionCode = BF_VDAQRY;
  uint8_t x = hbSysGetVdaFn(&vdaParams);
  hbSetCurrentBank(bnkInfoParams.biosBankId);
  memcpy(tmsCfg, vdaParams.driverDataAddress, 14);
  hbSetCurrentBank(currentBankId);

  print("Pausing TMS interrupts\r\n");
  // clang-format off
  __asm
	  LD    A, (_tmsCfg + 7)
    RES	  TMSINTEN, A             ; // RESET INTERRUPT ENABLE BIT
	  LD	  (_tmsCfg + 7), A

    LD    A, (_tmsCfg + 5)
    OUT   (C), A

	  NOP
    NOP

    LD	  A, $81                    ; // SELECT REGISTER 1
	  OUT	  (C), A		                  ; // SELECT THE DESIRED REGISTER

  __endasm;
  // clang-format on
}

void enableTmsInterrupts() {
  if (vdaDev.devType != VDADEV_TMS)
    return;

  // clang-format off
  __asm
	  LD    A, (_tmsCfg + 7)
    SET	  TMSINTEN, A             ; // RESET INTERRUPT ENABLE BIT
	  LD	  (_tmsCfg + 7), A

    LD    A, (_tmsCfg + 5)
    OUT   (C), A

	  NOP
    NOP

    LD	  A, $81                    ; // SELECT REGISTER 1
	  OUT	  (C), A		                 ; // SELECT THE DESIRED REGISTER

  __endasm;
  // clang-format on
}

void main(MainArguments *pargs) __z88dk_fastcall {
  parseCommandLine(pargs);

  currentBankId = hbGetCurrentBank();
  hbSysGetBnkInfo(&bnkInfoParams);

  initialiseCioAndSio();

  disableTmsInterupts();

  flushBuffer();

  issueGetCommand();

  configureFileForWriting();

  print("Downloading: ");
  print(pFileName);
  print(".");
  print(pFileExtension);
  print("\r\n");

  sioOut(NAK);
  uint8_t count = 0;
  while (readWritePacket()) {
    if ((count++) % 64 == 0) {
      print(".");
    }
  }
  sioOut(EOT);

  fClose(&configFCB);

  uninstallSioHandler();
  enableTmsInterrupts();
}

void shutdown() {
  uninstallSioHandler();
  enableTmsInterrupts();
  exit(1);
}
