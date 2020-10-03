#ifndef __HBIOS
#define __HBIOS

#include <stdint.h>

#define HCB_BIDUSR 0x8E  /* USER BANK (TPA) */
#define HCB_BIDBIOS 0x8D /* BIOS BANK (HBIOS, UBIOS) */

#define BF_CIO ((uint8_t)0x00)
#define BF_CIOIN (BF_CIO + 0)     /* CHARACTER INPUT */
#define BF_CIOOUT (BF_CIO + 1)    /* CHARACTER OUTPUT  */
#define BF_CIOIST (BF_CIO + 2)    /* CHARACTER INPUT STATUS */
#define BF_CIOOST (BF_CIO + 3)    /* CHARACTER OUTPUT STATUS */
#define BF_CIOINIT (BF_CIO + 4)   /* INIT/RESET DEVICE/LINE CONFIG */
#define BF_CIOQUERY (BF_CIO + 5)  /* REPORT DEVICE/LINE CONFIG */
#define BF_CIODEVICE (BF_CIO + 6) /* REPORT DEVICE INFO */

#define BF_VDA ((uint8_t)0x40)
#define BF_VDAINI (BF_VDA + 0)  /* INITIALIZE VDU */
#define BF_VDAQRY (BF_VDA + 1)  /* QUERY VDU STATUS */
#define BF_VDARES (BF_VDA + 2)  /* SOFT RESET VDU */
#define BF_VDADEV (BF_VDA + 3)  /* DEVICE INFO */
#define BF_VDASCS (BF_VDA + 4)  /* SET CURSOR STYLE */
#define BF_VDASCP (BF_VDA + 5)  /* SET CURSOR POSITION */
#define BF_VDASAT (BF_VDA + 6)  /* SET CHARACTER ATTRIBUTE */
#define BF_VDASCO (BF_VDA + 7)  /* SET CHARACTER COLOR */
#define BF_VDAWRC (BF_VDA + 8)  /* WRITE CHARACTER */
#define BF_VDAFIL (BF_VDA + 9)  /* FILL */
#define BF_VDACPY (BF_VDA + 10) /* COPY */
#define BF_VDASCR (BF_VDA + 11) /* SCROLL */
#define BF_VDAKST (BF_VDA + 12) /* GET KEYBOARD STATUS */
#define BF_VDAKFL (BF_VDA + 13) /* FLUSH KEYBOARD BUFFER */
#define BF_VDAKRD (BF_VDA + 14) /* READ KEYBOARD */

extern void printChar(const char ch) __z88dk_fastcall;
extern void print(const char *str) __z88dk_fastcall;

typedef struct {
  uint8_t driver;
  union {
    char chr;
    struct {
      uint8_t count;
      char *pBuffer;
    };
  };
} hbCioParams;

extern uint8_t hbCioIn(hbCioParams *) __z88dk_fastcall;
extern uint8_t hbCioIst(uint8_t) __z88dk_fastcall;
extern uint8_t hbCioOut(hbCioParams *) __z88dk_fastcall;
extern uint8_t hbCioInBlk(hbCioParams *) __z88dk_fastcall;

extern uint16_t hbSysGetTimer16();

typedef struct {
  uint8_t func;
  uint8_t unit;
  void *driverFnAddr;
  void *driverDataAddr;
} hbiosDriverEntry;
extern uint8_t hbSysGetVda(hbiosDriverEntry *pData) __z88dk_fastcall;

#define VDADEV_VDU ((uint8_t)0x00)  /* ECB VDU - MOTOROLA 6545 */
#define VDADEV_CVDU ((uint8_t)0x10) /* ECB COLOR VDU - MOS 8563 */
#define VDADEV_NEC ((uint8_t)0x20)  /* ECB UPD7220 - NEC UPD7220 */
#define VDADEV_TMS ((uint8_t)0x30)  /* N8 ONBOARD VDA SUBSYSTEM - TMS 9918 */
#define VDADEV_VGA ((uint8_t)0x40)  /* ECB VGA3 - HITACHI HD6445 */

typedef struct {
  uint8_t driver;
  uint8_t devType;
  uint8_t devNumber;
  uint8_t devMode;
  uint8_t devBaseIO;
} hbVdaDevParams;
extern uint8_t hbVdaDev(hbVdaDevParams *result) __z88dk_fastcall;

typedef struct {
  uint8_t destBank;
  uint8_t sourceBank;
  uint16_t byteCount;
  void *destAddr;
  void *sourceAddr;
} hbiosBankCopy;
extern uint8_t hbSysBankCopy(hbiosBankCopy *pData) __z88dk_fastcall;

typedef void (*intHandler)();
typedef struct {
  uint8_t vctIndex;
  union {
    uint8_t interruptMode;
  };
  union {
    intHandler intHandlerAddr;
    intHandler previousHandlerAddr;
  };

} hbSysParams;
extern uint8_t hbSysIntInfo(hbSysParams *) __z88dk_fastcall;
extern uint8_t hbSysIntSet(hbSysParams *) __z88dk_fastcall;

typedef struct {
  uint8_t functionCode;
  uint8_t driver;
  void *functionAddress;
  void *driverDataAddress;
} hbSysGetFunc;
extern uint8_t hbSysGetCioFn(hbSysGetFunc *) __z88dk_fastcall;
extern uint8_t hbSysGetVdaFn(hbSysGetFunc *) __z88dk_fastcall;
extern uint8_t hbDirect(hbSysGetFunc *) __z88dk_fastcall;
extern uint8_t hbSndReset(uint8_t driver) __z88dk_fastcall;

typedef struct {
  uint8_t biosBankId;
  uint8_t userBankId;
} hbSysGetBnkInfoParams;
extern uint8_t hbSysGetBnkInfo(hbSysGetBnkInfoParams *) __z88dk_fastcall;

extern uint8_t hbGetCurrentBank();
extern void hbSetCurrentBank(uint8_t) __z88dk_fastcall;

typedef struct {
  uint8_t driver;
  union {
    uint8_t volume;
    uint16_t note;
    uint8_t channel;
    uint16_t period;
  };
} hbSndParams;
extern uint8_t hbSndVolume(hbSndParams *pParams) __z88dk_fastcall;
extern uint8_t hbSndNote(hbSndParams *pParams) __z88dk_fastcall;
extern uint8_t hbSndPlay(hbSndParams *pParams) __z88dk_fastcall;
extern uint8_t hbSndPeriod(hbSndParams *pParams) __z88dk_fastcall;

extern uint8_t hbdInstallCioIn(uint8_t driverIndex) __z88dk_fastcall;
extern uint16_t hbdCioIn();

extern uint8_t hbdInstallCioOut(uint8_t driverIndex) __z88dk_fastcall;
extern uint8_t hbdCioOut(char) __z88dk_fastcall;

extern void *hbdCioIn_data;
extern uint16_t hbdCioIn_addr;

#endif
