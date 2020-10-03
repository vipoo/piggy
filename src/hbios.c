#include "hbios.h"

static hbCioParams cioParams;

void printChar(const char ch) __z88dk_fastcall {
  cioParams.driver = 0;
  cioParams.chr = ch;
  hbCioOut(&cioParams);
}

void print(const char *str) __z88dk_fastcall {
  cioParams.driver = 0;
  while (*str) {
    cioParams.chr = *str++;
    hbCioOut(&cioParams);
  }
}
