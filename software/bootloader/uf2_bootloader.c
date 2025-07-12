#include <stdint.h>
#include <stdbool.h>
#include "../include/io.h"
#include <stddef.h>

#define IN_RANGE(val, lo, hi) ((val) >= (lo) && (val) <= (hi))

#define RAM_START 0x00010000
#define RAM_END 0x00014000

// specification of the UF2 format on https://github.com/microsoft/uf2
#define magic0 0x0A324655
#define magic1 0x9E5D5157
#define magicF 0x0AB16F30

#define flagFamilyIdPresent 0x00002000
#define familyId 0x7AB170D8 // random value.

const char *welcome_msg =
    "\r\n"
    "== Bootloader v1.0 ==\r\n"
    "Send UF2 file over UART to program device.\r\n"
    "\r\n"
    "Format:\r\n"
    " - Device Family ID: 0x7AB170D8\r\n"
    " - Block max data size is 256B\r\n"
    "\r\n"
    "Memory Map:\r\n"
    " - RAM       : start - 0x10000 (16 KB)\r\n"
    " - Entry     : First block's target address\r\n"
    "\r\n"
    "Waiting for program upload...\r\n";

const char *bad_magic = "Error: bad magic number.\n";

typedef struct /* __attribute__((packed)) */ UF2Block
{
        uint32_t magicStart0;
        uint32_t magicStart1;
        uint32_t flags;
        uint32_t targetAddr;
        uint32_t payloadSize;
        uint32_t blockNo;
        uint32_t numBlocks;
        uint32_t familyID;
        uint32_t data[119];
        uint32_t magicEnd;
} UF2Block;

static bool validate_block(UF2Block *block)
{
        if (block->magicStart0 != magic0)
        {
                write_string(bad_magic);
                return false;
        }
        if (block->magicStart1 != magic1)
        {
                write_string(bad_magic);
                return false;
        }
        if (block->flags != flagFamilyIdPresent)
        {
                write_string("Error: flags\n");
                return false;
        }
        if (block->familyID != familyId)
        {
                write_string("Error: incorrect family ID\n");
                return false;
        }
        if (block->magicEnd != magicF)
        {
                write_string(bad_magic);
                write_string("read: ");
                print_uint_hex(block->magicEnd);
                return false;
        }
        if (block->payloadSize > 256)
        {
                write_string("Error: payload size over 256.\n");
                return false;
        }
        if (!IN_RANGE(block->targetAddr, RAM_START, RAM_END - block->payloadSize))
        {
                write_string("Error: block address is outside RAM region.\n");
                return false;
        }

        return true;
}

void write_block_mssg(UF2Block *block)
{
        write_string("received block: ");
        print_uint_b10((block->blockNo + 1));
        write_string("/");
        //print_uint_b10(block->numBlocks);
        write_string(" @ addr: ");
        print_uint_hex(block->targetAddr);
        write_string(" ... ");
}

void write_to_mem(UF2Block *block)
{
        uint32_t *dst = (uint32_t *)(block->targetAddr);
        uint32_t *data = block->data;
        for (uint32_t i = 0; i < 64; i++)
        {
                dst[i] = data[i];
        }
        
}

void jump_to(uint32_t addr)
{

        __asm__ volatile
        (
            "la sp, __ram_end\n" // Set stack pointer to __ram_end
            "jr  %0\n"            // Jump to addr
            :
            : "r"(addr)
            : "memory"
        );
}

uint32_t get_word()
{
        uint32_t word = 0;
        word |= get_rx();
        word |= (get_rx() << 8);
        word |= (get_rx() << 16);
        word |= (get_rx() << 24);
        return word;
}

static UF2Block block;
static uint32_t entry = 0;
static uint32_t blocks = 0;
static uint32_t num_blocks = 0;
void main()
{
        
        write_string(welcome_msg);
        do
        {
                block.magicStart0 = get_word();
                block.magicStart1 = get_word();
                block.flags = get_word();
                block.targetAddr = get_word();
                block.payloadSize = get_word();
                block.blockNo = get_word();
                block.numBlocks = get_word();
                block.familyID = get_word();
                for (int i = 0; i < 119; i++)
                {
                        block.data[i] = get_word();
                }
                block.magicEnd = get_word();

                write_block_mssg(&block);
                blocks++;
                if (validate_block(&block))
                {
                        if (block.blockNo == 0){
                                entry = block.targetAddr;
                                num_blocks = block.numBlocks;
                        }
                        write_to_mem(&block);
                        write_string("block loaded.\n");
                }
                else
                {
                        write_string("Invalid, skipping block.\n");
                }

        } while (blocks < num_blocks);

        write_string("\n\njumping to address: "); print_uint_hex(entry);

        jump_to(entry);
}