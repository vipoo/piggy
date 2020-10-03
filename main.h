#ifndef __MAIN
#define __MAIN

void shutdown();

//SIO BUFFER IS AT 0x8000 to 0x80FF
#define diskBuffer1 ((uint8_t *)0x8200)
extern void prepDma();


#define SOH 0x01
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define ETB 0x17
#define CAN 0x18

#endif
