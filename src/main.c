#include "main.h"
#include "cpm.h"
#include "hbios.h"
#include "sio.h"
#include "xstdio.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

static const char pFileName[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
static char pFileExtension[4] = {0, 0, 0, 0};

static hbCioParams cioParams0;
static hbCioParams cioParams1;
static hbSysGetBnkInfoParams bnkInfoParams;
static FCB configFCB;
static hbSysGetFunc sysParams;
static int dotCount = 0;

uint16_t checksum = 0;

const char *dataLossMessage = "Error: Data loss\r\n";

void flushBuffer() {
  while (sioIst()) {
    sioIn();
  }
}

void waitForPacketHeader() {
  cioParams1.chr = 0;

  uint16_t count = 65000;
  while (count++ > 0 && !sioIst()) {
    for (int i = 1; i < 1000; i++)
      ;
  }

  if (!sioIst()) {
    xprintf("Expectred SOH - but no data recieved\r\n");
    shutdown();
  }

  const uint16_t x = sioIn();
  cioParams1.chr = x;

  if (x != (uint16_t)SOH) {
    xprintf("Expected SOH but got %04X\r\n", x);
    shutdown();
  }
}

uint8_t readWritePacket() {
  const uint16_t chr = sioIn();

  if (chr == (uint16_t)SOH) {
    prepDma();
    fWrite(&configFCB);

    return true;
  }

  if (chr == (uint16_t)EOT) {

    const uint8_t c1 = sioIn();
    const uint8_t c2 = sioIn();

    const uint16_t c = (((uint16_t)c2) << 8) + (uint16_t)c1;

    if (c != checksum) {
      print("Data integrity check failed.\r\n");
      return false;
    }

    print("\r\nDone\r\n");
    return false;
  }

  xprintf("Error: Expected a SOH %04X, %d, %d.\r\n", chr, dataLoss, sioCount);
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
  const uint8_t currentBankId = hbGetCurrentBank();
  hbSysGetBnkInfo(&bnkInfoParams);
  hbSetCurrentBank(bnkInfoParams.biosBankId);
  memcpy(&sioCfg, hbdCioIn_data, 15);
  hbSetCurrentBank(currentBankId);
}

void main(MainArguments *pargs) __z88dk_fastcall {
  cioParams0.driver = 0;
  cioParams1.driver = 1;

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

  hbdInstallCioIn(1);
  hbdInstallCioOut(1);

  copySioConfig();

  installSioHandler();
  flushBuffer();

  sioOutString("G ");
  sioOutString(pFileName);
  sioOutString(".");
  sioOutString(pFileExtension);
  sioOutString("\r\n");

  expectAck();

  resetFCB(pFileName, pFileExtension, &configFCB);
  fDelete(&configFCB);
  uint8_t exists = fMake(&configFCB);
  fDmaOff(diskBuffer1);
  print("Downloading: ");
  print(pFileName);
  print(".");
  print(pFileExtension);
  print("\r\n");

  sioOut(NAK);

  uint8_t count = 0;

  while (readWritePacket()) {
    if ((count++) % 64 == 0) {
      cioParams0.chr = '.';
      hbCioOut(&cioParams0);
    }
  }

  sioOut(ACK);

  xprintf("Checksum = %u\r\n", checksum);

  fClose(&configFCB);

  uninstallSioHandler();
}

void shutdown() {
  uninstallSioHandler();
  exit(1);
}
