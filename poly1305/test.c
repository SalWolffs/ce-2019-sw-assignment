#include <stdio.h>
#include "poly1305.h"
#include "../common/stm32wrapper.h"

#define INLEN 545

const unsigned char msg[INLEN] = {
  0xa7, 0x60, 0xff, 0x92, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0xc1, 0x07, 0xc1, 0x89, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0xe2, 0x58, 0x02, 0x0f, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0xd0, 0x39, 0x27, 0x1c, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x8f, 0x9c, 0xf2, 0x8e, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0xf2, 0xa0, 0xa0, 0x99, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0x7d, 0x8b, 0x52, 0x6d, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0xf8, 0x35, 0x9e, 0x9d, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x54, 0x93, 0xf1, 0xf7, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0xfa, 0xb3, 0xb5, 0x1b, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0xeb, 0x38, 0xc8, 0x41, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0x78, 0xca, 0x2c, 0x6d, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x08, 0xce, 0xe6, 0x1f, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x40, 0xe8, 0x45, 0x0d, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0xce, 0x94, 0xc9, 0x80, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0x64, 0x10, 0xb9, 0x5f, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x06, 0x7e, 0x4c, 0x56, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x49, 0xd7, 0x54, 0x2b, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0xd0, 0x00, 0x5f, 0x7f, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0x73, 0x68, 0x00, 0x1a, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x2a, 0xa0, 0x7d, 0xcd, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x3d, 0x1a, 0x3c, 0x92, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0x54, 0xea, 0xef, 0x95, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0x95, 0xb4, 0x41, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x35, 0x76, 0x76, 0x8a, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x75, 0x58, 0x1d, 0x5c, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0xca, 0x91, 0xc4, 0xf7, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0x04, 0x5f, 0x7a, 0xa2, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x3f, 0x20, 0x51, 0xa3, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x45, 0x71, 0xa8, 0x27, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0x63, 0x33, 0x57, 0x54, 0xcc, 0x40, 0xa5, 0x50, 0x64, 0xd5, 0x13, 0xb8, 0x82, 0x86, 0x8a, 0xc3, 
  0xe6, 0xe0, 0x37, 0x7b, 0x00, 0x00, 0x00, 0x00, 0x50, 0x91, 0x91, 0x3e, 0xe4, 0xd7, 0x26, 0x0c, 
  0x3b, 0xbc, 0x0b, 0x29, 0xdc, 0xc8, 0x40, 0x66, 0x64, 0x5a, 0xc4, 0xf2, 0xe8, 0xca, 0x40, 0xd6, 
  0x9e, 0x34, 0x3a, 0xdf, 0xd4, 0x84, 0x27, 0x8d, 0xf0, 0x74, 0x94, 0x90, 0x92, 0x8b, 0x40, 0x6c, 
  0x25};

const unsigned char cmp[POLY1305_BYTES] = {
  0xcc, 0x95, 0xf2, 0xc5, 0xca, 0x50, 0x38, 0xa9, 0xdb, 0xaf, 0x4e, 0xde, 0x36, 0xd8, 0x81, 0xff};

unsigned char tag[POLY1305_BYTES];

unsigned char key[POLY1305_KEYBYTES] = {
  0x57, 0x6c, 0x7c, 0x77, 0x6a, 0xc2, 0x93, 0xc6, 0x78, 0x3a, 0x4a, 0x48, 0xc9, 0x45, 0x20, 0x36};

int main(void)
{
  clock_setup();
  gpio_setup();
  usart_setup(115200);
  char outstr[20];

  send_USART_str((unsigned char*)"\n============ IGNORE OUTPUT BEFORE THIS LINE ============\n");
  
  crypto_onetimeauth_poly1305(tag,msg,INLEN,key);

  int i;
  for(i=0;i<POLY1305_BYTES;i++)
  {
    if(cmp[i] != tag[i])
    {
      send_USART_str((unsigned char*)"Test failed!\n");
      return -1;
    }
  }     

  send_USART_str((unsigned char*)"Test successful!\n");

  return 0;
}
