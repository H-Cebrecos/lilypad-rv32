#pragma once
#include <stdint.h>
#include <stdbool.h>

void putchar(char c);
void printf(const char *fmt, ...);

void write_led(uint16_t data);

void write_string(const char*);

void print_uint_b10(uint32_t n);
void print_uint_hex(uint32_t value);
int read_rx(); //returns -1 in case of empty fifo.
void write_tx(uint8_t byte);

uint8_t read_stat();

uint8_t get_rx();