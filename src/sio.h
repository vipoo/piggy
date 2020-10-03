#ifndef __SIO
#define __SIO

extern uint16_t sioIn();
extern uint8_t sioIst();
extern void sioOut(char c) __z88dk_fastcall;
extern uint8_t sioCfg[];

extern uint8_t dataLoss;
extern uint8_t sioCount;
extern uint16_t sioHead;
extern uint16_t sioTail;
extern void sioRtsOff();
extern void sioRtsOn();
extern uint8_t installSioHandler();
extern uint8_t uninstallSioHandler();

#endif
