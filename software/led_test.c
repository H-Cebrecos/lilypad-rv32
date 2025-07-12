
#include <stdint.h>
#include "include/io.h"

extern volatile uint16_t led;

uint16_t shift = 0xAAAA;

void delay (void)
{
        for (uint32_t i = 0; i < 100000; i++)
        {             
                __asm__ __volatile__ ("nop\n");
        }
}

void main(void)
{        
        for(;;){
                if (shift != 0x00000000)
                {
                        write_led(shift);
                        shift <<= 1;
                        delay(); 
                }
                else
                {
                        shift = 1;         
                }
        };
}
