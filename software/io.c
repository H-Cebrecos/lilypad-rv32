// generated with ChatGPT
#include "include/io.h"
#include <stdarg.h>

#define LED_ADDR 0xFFFFFFF0
#define UART_RX 0x00555500
#define UART_TX 0x00555504
#define UART_STAT 0x00555508

static volatile uint16_t *led = (volatile uint16_t *)LED_ADDR;
static volatile uint8_t *tx = (volatile uint8_t *)UART_TX;
static volatile uint8_t *stat = (volatile uint8_t *)UART_STAT;
static volatile uint8_t *rx = (volatile uint8_t *)UART_RX;

void write_led(uint16_t data)
{
        *led = data;
}

uint8_t read_stat()
{
        return *stat;
}

int read_rx()
{
        if ((*stat) & 0x01)
                return -1; // error: RX FIFO is empty
        else
                return *rx;
}

uint8_t get_rx()
{
        while ((*stat) & 0x01)
        {
                for (uint32_t i = 0; i < 100; i++)
                {
                        __asm__ __volatile__("nop\n");
                }
        }
        return *rx;
}

bool tx_fifo_full()
{
        return (*stat & 0x08) != 0;
}

void write_tx(uint8_t byte)
{
        *tx = byte;
}

void write_string(const char *s)
{
        while (*s)
        {
                putchar(*s);
                s++;
        }
}

void putchar(char c)
{
        while (tx_fifo_full())
        {
                // wait until TX FIFO is not full
        }
        write_tx((uint8_t)c);
}

void print_uint_b10(uint32_t n)
{
        char buf[10];  // Enough for 2^32-1 = 4294967295
        int i = 0;
    
        if (n == 0) {
            putchar('0');
            return;
        }
    
        while (n > 0) {
            buf[i++] = '0' + (n % 10);
            n /= 10;
        }
    
        while (i--) {
            putchar(buf[i]);
        }
}
void print_hex_digit(uint8_t digit)
{
        if (digit < 10)
                putchar('0' + digit);
        else
                putchar('A' + (digit - 10));
}

void print_uint_hex(uint32_t value)
{
        putchar('0');
        putchar('x');
        for (int shift = 28; shift >= 0; shift -= 4)
        {
                uint8_t nibble = (value >> shift) & 0xF;
                print_hex_digit(nibble);
        }
}
