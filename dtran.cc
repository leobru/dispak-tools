/*
 * A disassembler for the BESM-6 executable binaries produced by
 * Pascal-Autocode.
 *
 * To produce pseudo-code that can be given to the "decompiler":
 * dtran -d pascompl.o > pascompl.out
 *
 * Copyright 2019 Leonid Broukhis
 */

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cstdarg>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <sys/stat.h>
#include "unistd.h"
#include <stdint.h>

/*
 * BESM-6 opcode types.
 */
typedef enum {
OPCODE_ILLEGAL,
OPCODE_STR1,		/* short addr */
OPCODE_STR2,		/* long addr */
OPCODE_IMM,		/* e.g. NTR */
OPCODE_REG1,		/* e.g. ATI */
OPCODE_JUMP,		/* UJ */
OPCODE_BRANCH,		/* UZA, U1A, VZM, V1M, VLM */
OPCODE_CALL,		/* VJM */
OPCODE_IMM64,		/* e.g. ASN */
OPCODE_ADDRMOD,		/* UTC, WTC */
OPCODE_REG2,		/* VTM, UTM */
OPCODE_IMMEX,		/* *50, ... */
OPCODE_ADDREX,		/* *64, *70, ... */
OPCODE_STOP,		/* *74 */
OPCODE_DEFAULT
} opcode_e;

struct opcode {
	const char *name;
	uint opcode;
	uint mask;
	opcode_e type;
} op[] = {
  /* name,	pattern,  mask,	    opcode type */
  { "ATX",	0x000000, 0x0bf000, OPCODE_STR1 },
  { "STX",	0x001000, 0x0bf000, OPCODE_STR1 },
  { "XTS",	0x003000, 0x0bf000, OPCODE_STR1 },
  { "A+X",	0x004000, 0x0bf000, OPCODE_STR1 },
  { "A-X",	0x005000, 0x0bf000, OPCODE_STR1 },
  { "X-A",	0x006000, 0x0bf000, OPCODE_STR1 },
  { "AMX",	0x007000, 0x0bf000, OPCODE_STR1 },
  { "XTA",	0x008000, 0x0bf000, OPCODE_STR1 },
  { "AAX",	0x009000, 0x0bf000, OPCODE_STR1 },
  { "AEX",	0x00a000, 0x0bf000, OPCODE_STR1 },
  { "ARX",	0x00b000, 0x0bf000, OPCODE_STR1 },
  { "AVX",	0x00c000, 0x0bf000, OPCODE_STR1 },
  { "AOX",	0x00d000, 0x0bf000, OPCODE_STR1 },
  { "A/X",	0x00e000, 0x0bf000, OPCODE_STR1 },
  { "A*X",	0x00f000, 0x0bf000, OPCODE_STR1 },
  { "APX",	0x010000, 0x0bf000, OPCODE_STR1 },
  { "AUX",	0x011000, 0x0bf000, OPCODE_STR1 },
  { "ACX",	0x012000, 0x0bf000, OPCODE_STR1 },
  { "ANX",	0x013000, 0x0bf000, OPCODE_STR1 },
  { "E+X",	0x014000, 0x0bf000, OPCODE_STR1 },
  { "E-X",	0x015000, 0x0bf000, OPCODE_STR1 },
  { "ASX",	0x016000, 0x0bf000, OPCODE_STR1 },
  { "XTR",	0x017000, 0x0bf000, OPCODE_STR1 },
  { "RTE",	0x018000, 0x0bf000, OPCODE_IMM },
  { "YTA",	0x019000, 0x0bf000, OPCODE_IMM64 },
  { "E+N",	0x01c000, 0x0bf000, OPCODE_IMM64 },
  { "E-N",	0x01d000, 0x0bf000, OPCODE_IMM64 },
  { "ASN",	0x01e000, 0x0bf000, OPCODE_IMM64 },
  { "NTR",	0x01f000, 0x0bf000, OPCODE_IMM },
  { "ATI",	0x020000, 0x0bf000, OPCODE_REG1 },
  { "STI",	0x021000, 0x0bf000, OPCODE_REG1 },
  { "ITA",	0x022000, 0x0bf000, OPCODE_REG1 },
  { "ITS",	0x023000, 0x0bf000, OPCODE_REG1 },
  { "MTJ",	0x024000, 0x0bf000, OPCODE_REG1 },
  { "M+J",	0x025000, 0x0bf000, OPCODE_REG1 },
  { "*50",	0x028000, 0x0bf000, OPCODE_IMMEX },
  { "*51",	0x029000, 0x0bf000, OPCODE_IMMEX },
  { "*52",	0x02a000, 0x0bf000, OPCODE_IMMEX },
  { "*53",	0x02b000, 0x0bf000, OPCODE_IMMEX },
  { "*54",	0x02c000, 0x0bf000, OPCODE_IMMEX },
  { "*55",	0x02d000, 0x0bf000, OPCODE_IMMEX },
  { "*56",	0x02e000, 0x0bf000, OPCODE_IMMEX },
  { "*57",	0x02f000, 0x0bf000, OPCODE_IMMEX },
  { "*60",	0x030000, 0x0bf000, OPCODE_ADDREX },
  { "*61",	0x031000, 0x0bf000, OPCODE_ADDREX },
  { "*62",	0x032000, 0x0bf000, OPCODE_IMMEX },
  { "*63",	0x033000, 0x0bf000, OPCODE_IMMEX },
  { "*64",	0x034000, 0x0bf000, OPCODE_ADDREX },
  { "*65",	0x035000, 0x0bf000, OPCODE_IMMEX },
  { "*66",	0x036000, 0x0bf000, OPCODE_IMMEX },
  { "*67",	0x037000, 0x0bf000, OPCODE_ADDREX },
  { "*70",	0x038000, 0x0bf000, OPCODE_ADDREX },
  { "*71",	0x039000, 0x0bf000, OPCODE_ADDREX },
  { "*72",	0x03a000, 0x0bf000, OPCODE_ADDREX },
  { "*73",	0x03b000, 0x0bf000, OPCODE_ADDREX },
  { "*74",	0x03c000, 0x0bf000, OPCODE_STOP },
  { "CTX",	0x03d000, 0x0bf000, OPCODE_ADDREX },
  { "*76",	0x03e000, 0x0bf000, OPCODE_IMMEX },
  { "*77",	0x03f000, 0x0bf000, OPCODE_IMMEX },
  { "UTC",	0x090000, 0x0f8000, OPCODE_ADDRMOD },
  { "WTC",	0x098000, 0x0f8000, OPCODE_ADDRMOD },
  { "VTM",	0x0a0000, 0x0f8000, OPCODE_REG2 },
  { "UTM",	0x0a8000, 0x0f8000, OPCODE_REG2 },
  { "UZA",	0x0b0000, 0x0f8000, OPCODE_BRANCH },
  { "U1A",	0x0b8000, 0x0f8000, OPCODE_BRANCH },
  { "UJ",	0x0c0000, 0x0f8000, OPCODE_JUMP },
  { "VJM",	0x0c8000, 0x0f8000, OPCODE_CALL },
  { "VZM",	0x0e0000, 0x0f8000, OPCODE_BRANCH },
  { "V1M",	0x0e8000, 0x0f8000, OPCODE_BRANCH },
  { "VLM",	0x0f8000, 0x0f8000, OPCODE_BRANCH },
/* This entry MUST be last; it is a "catch-all" entry that will match when no
 * other opcode entry matches during disassembly.
 */
  { "",		0x0000, 0x0000, OPCODE_ILLEGAL },
};

typedef unsigned long long uint64;
typedef unsigned int uint32;


typedef unsigned int uint;

std::string strprintf(const char * fmt, ...) {
    std::string ret;
    char * str;
    va_list ap;
    va_start (ap, fmt);
    vasprintf(&str, fmt, ap);
    va_end(ap);
    ret = str;
    free(str);
    return ret;
}

static const char * gost_to_utf[] = {
    "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "+", "-", "/", ",", ".", " ",
    "⏨", "↑", "(", ")", "×", "=", "smc", "[", // s = semicolon
    "]", "*", "`", "'", "#", "<", ">", ":",
    "А", "Б", "В", "Г", "Д", "Е", "Ж", "З",
    "И", "Й", "К", "Л", "М", "Н", "О", "П",
    "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч",
    "Ш", "Щ", "Ы", "Ь", "Э", "Ю", "Я", "D",
    "F", "G", "I", "J", "L", "N", "Q", "R",
    "S", "U", "V", "W", "Z", "^", "≤", "≥",
    "∨", "&", "⊃", "~", "÷", "≡", "%", "$",
    "|", "—", "_", "!", "\"", "Ъ", "?", "′"
};

const unsigned char gost_to_itm [0140] =
{
/* 000-007 */   0000,   0001,   0002,   0003,   0004,   0005,   0006,   0007,
/* 010-017 */   0010,   0011,   0061,   0070,   0067,   0046,   0047,   0017,
/* 020-027 */   0176,   0143,   0076,   0051,   0072,   0057,   0045,   0053,
/* 030-037 */   0066,   0170,   0064,   0041,   0152,   0074,   0054,   0056,
/* 040-047 */   0230,   0323,   0223,   0313,   0322,   0220,   0317,   0321,
/* 050-057 */   0314,   0332,   0236,   0311,   0207,   0205,   0203,   0315,
/* 060-067 */   0215,   0216,   0201,   0225,   0326,   0227,   0316,   0331,
/* 070-077 */   0324,   0301,   0325,   0327,   0320,   0334,   0335,   0222,
/* 100-107 */   0226,   0213,   0214,   0232,   0211,   0206,   0235,   0212,
/* 110-117 */   0224,   0234,   0217,   0231,   0221,   0050,   0074,   0054,
/* 120-127 */   0060,   0071,   0055,   0145,   0065,   0075,   0062,   0042,
/* 130-137 */   0044,   0150,   0043,   0063,   0134,   0136,   0   ,   0   ,
};

const char * itm_to_utf[256];

void populate_itm() {
    itm_to_utf[0] = gost_to_utf[0];
    for (int i = 1; i < 0140; ++i) {
        if (gost_to_itm[i] == 0)
            continue;
        if (itm_to_utf[gost_to_itm[i]])
            fprintf(stderr, "GOST %03o maps to the same ITM as GOST %s\n",
                    i, itm_to_utf[gost_to_itm[i]]);
        else
            itm_to_utf[gost_to_itm[i]] = gost_to_utf[i];
    }
}

FILE * entries;

std::set<int> gostoff, itmoff, isooff, textoff;
int forced_code_off;
struct Dtran {
    uint head_len;
    uint code_len;
    uint total_len;
    uint main_off;
    uint code_off;
    uint basereg, baseop, baseaddr;
    bool nolabels, nooctal, nodlabels;

    bool code_map[32768];
    enum { fLOG, fINT, fGOST, fISO, fTEXT, fITM } format_map[32768];
    void fill_lengths() {
        head_len = 0;           // the binary is read to address 0
        total_len = ((memory[02011] && memory[02011] < 037) ? 
		memory[02011] : memory[02010]) * 02000 + 02000;
//        labels.resize(total_len);
        main_off = 02000; // memory[02011] & 077777;
        mklabel(main_off);
        std::fill(code_map, code_map+32768, false);
        code_off = std::max(main_off, find_code_offset());
        printf(" %s:,NAME, NEW DTRAN\n",
               get_gost_word(memory[1]).c_str());
        printf("C Memory size: %o\n", total_len);
        printf("C Code start: %o\n", code_off);
        printf("C Program start: %o\n", main_off);
	printf("C Compilation date: %s\n", get_gost_word(memory[2]).c_str());
        printf("C Aligning line numbers\nC to addresses\nC of literal constants\n");
        if (nolabels) {
            printf(" /:,BSS,\n");
        }
    }

    uint64 memory[32768];

/*
 * Read a 48-bit word at the current file position.
 */
uint64
freadw (FILE *fd)
{
    uint64 val = 0;
    int i;
    for (i = 0; i < 6; ++i) {
        val <<= 8;
        val |= getc (fd);
    }
    return val;
}

void mklabel(uint off) {
    labels[off] = strprintf("L%04o", off) ;
}

uint check_chain(uint prev) {
    uint prevop = (prev & 03700000) >> 15;
    if (prevop == 024 && (prev >> 20) == 13) {
        uint next_addr = prev & 077777;
        if (next_addr && next_addr < total_len) {
            mklabel(next_addr);
            return next_addr;
        }
    }
    return 0;
}

uint find_code_offset() {
    uint min_addr = total_len;
    std::vector<uint> todo;
    todo.push_back(main_off);
    if (entries) {
        int off;
        while(1 == fscanf(entries, "%i", &off)) {
            todo.push_back(off);
            mklabel(off);
        }
        fprintf(stderr, "Got %lu known entry points\n", todo.size());
    }
    
    // Looking for all opcodes '16 31 XXXXX' and finding the lowest
    // by transitive closure, ignoring '16 31 00000' as an indirect call.
    while (!todo.empty()) {
        uint cur = todo.back();
        todo.pop_back();
        if (code_map[cur]) continue;
        if (cur >= total_len) continue;
        
        code_map[cur] = true;
        if (cur < min_addr) min_addr = cur;
        uint64 word = memory[cur];
        uint insn[2];
        insn[0] = word >> 24;
        insn[1] = word & 0xFFFFFF;
        for (uint i = 0; i < 2; ++i) {
            uint cinsn = insn[i];
            uint next_addr;
            uint opcode = (cinsn & 03700000) >> 15;
            if (opcode == 031 || opcode == 034 || opcode == 035) { // VJM, VZM, V1M, any reg
                next_addr = cinsn & 077777;
                if (next_addr && next_addr < total_len) {
                    mklabel(next_addr);
                    todo.push_back(next_addr);
                }
                todo.push_back(cur+1);
                // (value _IN type) is 13,VTM,iffalse; 14,VJM,test
                if (opcode == 031 && (cinsn >> 20) == 14) {
                    uint prev = i == 1 ? insn[0] : memory[cur-1] & 0xFFFFFF;
                    if (uint next = check_chain(prev))
                        todo.push_back(next);
                }
                break;
            } else if (opcode == 030) { // UJ
                next_addr = cinsn & 077777;
                uint idx = cinsn >> 20;
                if (next_addr && next_addr < total_len && idx == 0) {
                    todo.push_back(next_addr);
                    mklabel(next_addr);
                    uint prev = i == 1 ? insn[0] : memory[cur-1] & 0xFFFFFF;
                    if (uint next = check_chain(prev))
                        todo.push_back(next);
                } else if ((next_addr == cur || next_addr == cur+1) && (cinsn >> 20) != 0) {
                    // This looks like a jump table.
                    for(uint t = next_addr; t < total_len; ++t) {
                        uint64_t entry = memory[t];
                        uint entop = (entry >> (24+15)) & 037;
                        uint entidx = entry >> (24+20);
                        if (entop == 030 && entidx == 0) { // A jump
                            todo.push_back(t);
                        } else
                            break;
                    }
                }
                break;
            } else if ((cinsn & 077600000) == 002600000 // U1A, UZA, 0 reg
                       || ((cinsn & 077700000) == 042600000)) { // 8,UZA - case stmt by branching with 8 as base
                next_addr = cinsn & 077777;
                if (next_addr && next_addr < total_len) {
                    todo.push_back(next_addr);
                    mklabel(next_addr);
                }
                if (i == 1) todo.push_back(cur + 1);
            } else if (i == 1)
                todo.push_back(cur + 1);
        }
    }
    return forced_code_off ? forced_code_off : min_addr;
}
    
void
mklabels(uint32 memaddr, uint32 opcode, bool litconst) {
    int arg1 = (opcode & 07777) + (opcode & 0x040000 ? 070000 : 0);
    int arg2 = opcode & 077777;
    int struc = opcode & 02000000;
    uint reg = opcode >> 20;
    uint op = struc ? (opcode >> 15) & 037 : (opcode >> 12) & 077;
    if (basereg && basereg == reg) {
        if (baseaddr == ~0u &&
            (opcode & 03700000) == 02400000) {
            baseaddr = opcode & 037777;
            baseop = opcode;
            fprintf(stderr, "@%05o Base register set to %05o\n", memaddr, baseaddr);
        } else if (struc) {
            // Must be the same opcode as used originally.
            if (memaddr < code_len && (baseaddr == ~0u || baseop != opcode)) {
                fprintf(stderr,
                        "@%05o Base register used in a long-address insn\n", memaddr);
//                exit(1);
            }
        } else if (baseaddr == ~0u) {
            fprintf(stderr,
                    "@%05o Base register used but not yet set\n", memaddr);
//            exit(1);
        } else if (memaddr < code_len && arg1 >= 010000) {
            fprintf(stderr,
                    "@%05o Base register used with a negative value (%04o)\n", memaddr, arg1);
//            exit(1);
        } else {
            uint off = (baseaddr + arg1) % 32768;
            if (off >= labels.size()) {
                fprintf(stderr, "@%05o Base offset %05o too large\n", memaddr, arg1);
//                exit(1);
            }
            if (labels[off].empty())
                labels[off] = litconst ? get_literal(off) : strprintf("L%04o", off);
        }
    } else if (!struc && !reg && arg1 >= 011 && arg1 < total_len && labels[arg1].empty()) {
        labels[arg1] = litconst ? get_literal(arg1) : strprintf("L%04o", arg1);
    } else if (struc && arg2 >= 011 && arg2 < total_len &&
               (op == 030 || op == 037 || op == 024) && reg != 10) {
        if (labels[arg2].empty() && (code_map[arg2] || reg == 11)) {
            // fprintf(stderr, "Labeling %05o due to %05o: %02o %02o %05o\n",
            // arg2, memaddr, reg, op, arg2);
            if (litconst && op == 024 && reg == 11)
                /* labels[arg2] = get_literal(arg2) */;
            else
                mklabel(arg2);
        }
    }
}

int get_opidx(uint32 opcode) {
    int i = -1;
    do {
	i = i + 1;
        if ((opcode & op[i].mask) == op[i].opcode)
            return i;
    } while (op[i].mask);
    return -1;
}
  
void
prinsn (uint32 memaddr, uint32 opcode)
{
    int i;

    uint reg = opcode >> 20;
    int arg1 = (opcode & 07777) + (opcode & 0x040000 ? 070000 : 0);
    int arg2 = opcode & 077777;
    int struc = opcode & 02000000;
    int arg = struc ? arg2 : arg1;
    static bool prev_addrmod = false;

    i = get_opidx(opcode);

    opcode_e type = op[i].type;
    std::string opname = op[i].name;
    if (type == OPCODE_ILLEGAL) {
        opname = struc ? strprintf("%2o", (opcode >> 15) & 037)
            : strprintf("%03o", (opcode >> 12) & 0177);
    } else if (!struc && basereg && reg == basereg) {
        reg = 0;
        if (baseaddr != ~0u) arg1 += baseaddr;
    }
    std::string operand;
    if (arg)
        operand = strprintf(struc ? "U%05o" : "U%04o", struc ? arg2 : arg1);
    if (struc && arg2 && arg2 < labels.size()) {
        uint off = arg2;
        bool good = code_off <= off && off <= total_len;
        if (!good || labels[off].empty() || ((opcode >> 15) & 037) == 025 || (reg != 0 && type == OPCODE_ADDRMOD))
            operand = strprintf("%d", off);
        else
            operand = labels[off];
    } else if (uint val = struc ? arg2 : arg1) {
        if (type == OPCODE_REG1 || val < 8 || prev_addrmod)
            operand = strprintf("%d", val);
        else if (type == OPCODE_IMM64) {
            operand = strprintf("64%+d", val-64);
        } else if (!struc && !reg && type != OPCODE_IMMEX &&
                   arg1 >= code_off && arg1 < code_len)
            operand = labels[arg1];
        else
            operand = strprintf(type != OPCODE_IMMEX && nooctal ?
                                "%d" : "%oB", val);
    }

    if (basereg && reg == basereg) {
        if (op[i].opcode == 02400000) {
            opname = "BASE";
        } else {
            reg = 0;
            operand = labels[(baseaddr + arg1) % 32768];
        }
    }

    if (nolabels && operand[0] == 'L' && !strchr(operand.c_str(), '+')) {
        char * end;
        int off = strtol(operand.c_str()+1, &end, 8);
        if (end - operand.c_str() > 4)
            operand = strprintf(nooctal ? "/+%d" : "/+%oB", off);
    }
    if (reg) printf("%d,", reg); else printf(",");
    printf("%s,%s\n", opname.c_str(), operand.c_str());
    prev_addrmod = type == OPCODE_ADDRMOD;
}

std::string get_literal(uint32 addr) {
    uint64 val = memory[addr];
    std::string ret;
    uint64 d = val & 0x7FFFFFFFFFFFull;
    if ((val >> 38) == 01000 && d != 0) {
        if (d > 10000)
            ret = strprintf("DIV%d", (1ull << 40)/(d-1));
        else
            ret = strprintf("mul(%d)", d);
    } else if (format_map[addr] == fGOST) {
        ret = strprintf("'%s'", get_gost_word(val).c_str());
    } else if (format_map[addr] == fISO) {
        ret = strprintf("'%s'", get_iso_word(val).c_str());
    } else if (format_map[addr] == fITM) {
        ret = strprintf("itm'%s'", get_itm_word(val).c_str());
    } else if (format_map[addr] == fTEXT) {
        ret = strprintf("\"%s\"", get_text_word(val).c_str());
    } else if (format_map[addr] == fINT) {
        int d = val;
        ret = strprintf("(%d)", d);
    } else if (textoff.count(addr)) {
        ret = strprintf("|%s|", get_text_word(val).c_str());
    } else {
        ret = strprintf("(%lloC)", val);
    }
    return ret;
}

    void pr1const(uint cur, bool litconst) {
    uint64 val = memory[cur];
    if (!nodlabels) {
        printf(" /%d:", cur);
    } else if (labels[cur].empty() ||
               (labels[cur][0] != 'L' && labels[cur][0] != '/')) {
        printf(" ");
    } else {
        printf(" %s:", labels[cur].c_str());
    }

    if (gostoff.count(cur)) {
        printf(",GOST, |%s| %s\n", get_gost_word(val).c_str(), get_bytes(val).c_str());
        return;
    }
    if (itmoff.count(cur)) {
        printf(",ITM, |%s| %s\n", get_itm_word(val).c_str(), get_bytes(val).c_str());
        return;
    }
    if (isooff.count(cur)) {
        printf(",ISO, |%s| %s\n", get_iso_word(val).c_str(), get_bytes(val).c_str());
        return;
    }
    if (textoff.count(cur)) {
        printf(",TEXT, |%s| %s\n", get_text_word(val).c_str(), get_bytes(val).c_str());
        return;
    }
    switch (format_map[cur]) {
    case fINT: printf(",INT,%d . 0%o\n", (int)val, (int)val); break;
    case fGOST: printf(",GOST, |%s| %s\n", get_gost_word(val).c_str(), get_bytes(val).c_str()); break;
    case fISO: printf(",ISO, |%s| %s\n", get_iso_word(val).c_str(), get_bytes(val).c_str()); break;
    case fTEXT: printf(",TEXT, |%s| %s\n", get_text_word(val).c_str(), get_bytes(val).c_str()); break;
    case fITM: printf(",ITM, |%s| %s\n", get_itm_word(val).c_str(), get_bytes(val).c_str()); break;
    case fLOG: printf(",LOG,%llo\n", val);
    }
}

void populate_formats() {
    for (uint cur = 011; cur < total_len; ++cur) {
        if (code_map[cur])
            continue;
        if (gostoff.count(cur) && isooff.count(cur)) {
            fprintf(stderr, "Make up your mind regarding offset %d (%#o)\n", cur, cur);
        } else if (gostoff.count(cur)) {
            format_map[cur] = fGOST;
        } else if (itmoff.count(cur)) {
            format_map[cur] = fITM;
        } else if (isooff.count(cur)) {
            format_map[cur] = fISO;
        } else {
            uint64 val = memory[cur];
            int gost_score = 0; // gostoff.count(-cur) ? 0 : is_valid_gost(val);
            int itm_score = 0; // itmoff.count(-cur) ? 0 : is_valid_itm(val);
            int iso_score = isooff.count(-cur) ? 0 : is_valid_iso(val);
            if (gost_score) 
                gost_score += 2*is_likely_gost(val) +
                    is_likely_gost(memory[cur-1]) +
                    is_likely_gost(memory[cur+1]);
    
            if (itm_score)
                itm_score += 2*is_likely_itm(val) +
                    is_likely_itm(memory[cur-1]) +
                    is_likely_itm(memory[cur+1]);

            if (iso_score)
                iso_score += 2*is_likely_iso(val) +
                    is_likely_iso(memory[cur-1]) +
                    is_likely_iso(memory[cur+1]);

            if ((val >> 24) == 064000000 || (val >> 24) == 064377777) {
                format_map[cur] = fINT;
            } else if (gost_score && gost_score > iso_score) {
                format_map[cur] = fGOST;                
            } else if (iso_score && iso_score >= gost_score) {
                format_map[cur] = fISO;
            } else if (is_likely_text(memory[cur])) {
                format_map[cur] = fTEXT;
            } else {
                format_map[cur] = is_likely_iso(memory[cur]) ? fISO : itm_score && val <=0xffffff ? fITM : fLOG;
            }
        }
    }
}

void prconst (bool litconst) {
    populate_formats();
    for (uint cur = 011; cur < code_off; ++cur) {
        pr1const(cur, litconst);
    }
}

void
prtext (bool litconst)
{
    uint32 addr = code_off;
    uint32 limit = total_len;
    populate_formats();
    for (uint32 cur = addr; cur < limit; ++cur) {
	if (code_map[cur]) {
        uint64 & opcode = memory[cur];
        mklabels(cur, opcode >> 24, litconst);
        mklabels(cur, opcode & 0xffffff, litconst);
	}
    }
    if (nolabels) {
        puts(" /:,BSS,");
    }
    for (; addr < limit; ++addr) {
        if (addr % 64 == 0)
            printf("C ---------- %05o ----------\n", addr);
        if (!code_map[addr] || isooff.count(addr) || gostoff.count(addr)) {
          pr1const(addr, litconst);
          continue;
        }
        uint64 opcode;
        if (!labels[addr].empty() &&
            (labels[addr][0] == 'L' || labels[addr][0] == '/')) {
            if (nolabels) {
                printf(" :");
            } else {
                printf(" %s:", labels[addr].c_str());
            }
        } else
            putchar(' ');
        opcode = memory[addr];
        prinsn (addr, opcode >> 24);
        // Do not print the non-insn part of a word
        // if it looks like a placeholder
        bool addrmod = ((opcode >> 24) & 03600000) == 02200000;
        opcode &= 0xffffff;
        if ((opcode == 0 && !addrmod) || opcode == 02200000) {
            opcode = memory[addr] >> 24;
            opcode &= 03700000;
            if (opcode != 03100000 &&
                labels[addr+1].empty()) {
                labels[addr+1] = " ";
            }
        } else {
            putchar(' ');
            prinsn (addr, opcode);
        }
    }
}
struct opfields { uint reg; bool struc; int op; };

inline opfields decode(uint opcode) {
    opfields ret;
    ret.reg = opcode >> 20;
    ret.struc = opcode & 02000000;
    ret.op = (opcode >> 15) & 037;
    return ret;
}

void prsyms(uint cur, uint start) {
    uint64 name = memory[start];
    uint line = memory[start+1];
    static const char * typestr[] = {
        "real", "int", "char", "scalar", "array", "other", "file", "type 7"
    };
    printf("Routine %s @%05o, line %d:\n",
           get_text_word(name).c_str(), cur, line);    
    typedef std::map<int, std::pair<uint64, uint64> > syms_t;
    syms_t syms;
    for (uint addr = start+2; memory[addr]; addr += 2) {
        syms[memory[addr+1] & 077777] =
            std::make_pair(memory[addr], memory[addr+1]);
    }
    for (syms_t::iterator it = syms.begin(); it != syms.end(); ++it) {
        uint64 flags = it->second.second;
        int type = (flags >> 15) & 7;
        int size = (flags >> 33);
        int offset = flags & 077777;
        printf("%s size %5o offset %05o - %s\n",
               get_text_word(it->second.first).c_str(),
               size, offset, typestr[type]);              
    }
    printf("\tthat is all\n");
}

// Pascal-monitor symbol table, if present, is pointed to at the beginning
// of each routine with "16 24 base 16 25 offset". This is unique enough.
void prsymtab() {
    uint32 addr = code_off;
    uint32 limit = total_len;
    uint prev_insn = 0;
    bool right = false;
    for (uint32 cur = addr; cur < limit; cur += !right) {
        uint insn = right ? memory[cur] & 0xffffff : memory[cur] >> 24;
        if (decode(insn).reg == 016 && decode(insn).struc &&
            decode(insn).op == 025 && decode(prev_insn).reg == 016 &&
            decode(prev_insn).struc && decode(prev_insn).op == 024) {
            uint start = (insn & 077777) + (prev_insn & 077777);
            if (start >= addr && start < limit)
                prsyms(cur, start);
        }
        prev_insn = insn;
        right = !right;
    }
}

Dtran(const char * fname, uint b, bool n, bool dl, bool o) :
    basereg(b), baseaddr(~0u), nolabels(n), nodlabels(dl), nooctal(o),
    labels(32768)
{

    unsigned int addr = 02000;
    struct stat st;

    FILE * textfd = fopen (fname, "r");
    if (! textfd) {
        fprintf (stderr, "dtran: %s not found\n", fname);
        exit(1);
    }
    stat (fname, &st);
    uint codelen = st.st_size / 6;

    if (codelen >= 32768) {
        fprintf(stderr, "File too large\n");
        exit(1);
    }
    while (!feof(textfd) && addr < 0100000) {
        memory[addr++] = freadw (textfd);
    }
    fill_lengths();
    if (codelen + addr < total_len) {
        fprintf(stderr, "File was too short: %d, expected %d\n", codelen, total_len);
        exit (EXIT_FAILURE);
    }

    while (memory[total_len-1] == 0) --total_len;

    symtab.resize(04000);
    fclose (textfd);
    label_patterns();
#if 0
    symtab[031] = "P/WOLN";
    symtab[034] = "P/MD";
    symtab[047] = "P/7A";
    symtab[055] = "P/RC";
    symtab[0100] = "P/A7";
    symtab[0101] = "P/WC";
    symtab[0102] = "P/6A";
    symtab[0104] = "P/WI";
    symtab[0110] = "P/IN";
    symtab[0111] = "P/SS";
    symtab[0057] = "P/TR"; // trunc
    symtab[0141] = "P/TR"; // trunc, same as 0057
    symtab[0136] = "P/0060"; // signed mult. correction
    symtab[0222] = "P/0026"; // get(input)
    symtab[0257] = "P/0030"; // put(output)
    symtab[0313] = "P/0032"; // rewrite(output)
    symtab[0337] = "P/0033"; // unpck
    symtab[0173] = "P/0023"; // pck
    symtab[0715] = "P/0040"; // put
    symtab[0760] = "P/0041"; // get
    symtab[0202] = "P/0024"; // intToReal, a no-op in P-M
    symtab[01675] = "P/0066"; // bind
    symtab[01361] = "P/0050"; // mapia
#endif
}
void label_patterns() {
  /* Register saving subroutine level N is 4 distinctive words:
   *  00037000300420007LL,   ,NTR, 3       ,ITA, 7
   *  07444000774440002LL, 15,MTJ, 7     15,MTJ, N
   *  00043001500430001LL,   ,ITS, 13      ,ITS, N-1
   *  03400000273000000LL,  7,ATX, 2     14, UJ,
   */
    uint64 psav[] = {
        00037000300420007LL,
        07444000774440000LL,
        00043001500430000LL,
        03400000273000000LL
    };
    uint min_pattern = 077777;
    for (int i = 2; i <= 6; ++i) {
        psav[1] = (psav[1] & ~7LL) | i;
        psav[2] = (psav[2] & ~7LL) | (i-1);
        std::string name = std::string("P/") +char('0'+i);
        uint addr = label_pattern(psav, sizeof(psav), name);
        if (addr != 0100000)
            fprintf(stderr, "Address of %s is %05o\n", name.c_str(), addr);
        if (addr < min_pattern) min_pattern = addr;
    }
    /* Register restoring subroutine from M to N, 2 <= M < N <= 6
     * has a sequence of level-by-level restoring insns,
     * ending with return insns. The max is from level 2 to level 6 = 5 words.
     */
    uint64 pret[5];
    uint64 first = 05444000000100002LL; // 11,MTJ,N   N,XTA,2
    uint64 mid =   00040000000100002LL; //   ,ATI,K   K,XTA,2
    uint64 last =  00040000073000000LL; //   ,ATI,M  14, UJ,

    for (uint64 m = 2; m < 6; ++m)
        for (uint64 n = m+1; n <= 6; ++n) {
            int p = 0;
            pret[p++] = first | (n << 24) | (n<<20);
            for (uint64 k = n-1; k > m; --k)
                pret[p++] = mid | (k << 24) | (k<<20);
            pret[p++] = last | (m<<24);
            uint addr = label_pattern(pret, p*sizeof(uint64),
                                      (std::string("P/") + char('0'+n))+char('0'+m));
            if (addr < min_pattern) min_pattern = addr;            
        }
    uint64 pe[] = {
        07657777676300001LL, // 15,UTM,-2   15,WTC,1
        00300000002200000LL  //  ,UJ,
    };
    
    uint64 pef[] = {
        03410000100360117LL, // 7,XTA,1     ,ASN,64+15
        00040001672200000LL, //  ,ATI,14  14,UTC,
        06710000002200000LL // 13,VJM,
    };
    uint addr = label_pattern(pef, 3*sizeof(uint64), "P/EF");
    if (addr < min_pattern) 
        min_pattern = addr;
    if (addr != 0100000) {
        labels[addr + 3] = "P/E";
        fprintf(stderr, "Address of P/E is %05o\n", addr + 3);
    }

    uint64 p1d[] = { 0, 0, 0, 0, 0, 0, 0,
      01403006014030060LL,
    };
    addr = label_pattern(p1d, 8*sizeof(uint64), "P/1D");
    if (addr < min_pattern) 
        min_pattern = addr;
    fprintf(stderr, "Address of P/1D is %05o\n", addr);

    code_len = min_pattern;
    fprintf(stderr, "User code ends @%05o\n", code_len);
}

uint label_pattern(void * pattern, size_t size, std::string name) {
    uint64* where = (uint64*)memmem(memory, sizeof(memory[0])*total_len, pattern, size);
    if (where) labels[where-memory] = name;
    return where ? where-memory : 0100000;
}

    std::string get_utf8(uint unic) {
        std::string ret;
        if (unic < 0x80) {
            ret = char(unic);
	} else
	if (unic < 0x800) {
            ret = char(unic >> 6 | 0xc0);
            ret += char((unic & 0x3f) | 0x80);
	} else {
            ret = char(unic >> 12 | 0xe0);
            ret += char(((unic >> 6) & 0x3f) | 0x80);
            ret += char ((unic & 0x3f) | 0x80);
        }
        return ret;
    }

    std::string get_gost_char (unsigned char ch) {
        if (ch < 0140)
            return gost_to_utf[ch];
        else
            return strprintf("_%03o", ch);
    }
    std::string get_itm_char (unsigned char ch) {
        return itm_to_utf[ch] ? itm_to_utf[ch] : "#@#";
    }

#if 1
    std::string get_iso_char (unsigned char ch) {
	ch &= 0177;
        if (ch >= 040 && ch < 0140) { std::string ret; return ret=ch; }
	if (ch < 040 || ch >= 0177) return strprintf("_%03o", ch);
        return std::string(&"ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ\177"[2*(ch-0140)], 2);
    }

    std::string get_iso_word(uint64 word) {
        std::string ret;
	if (word < 256) return get_iso_char(word);
        for (uint i = 40; i <= 40; i-=8) {
            ret += get_iso_char(word >> i);
        }
        return ret;
    }
#endif
    std::string get_text_char (unsigned char ch) {
        static const char * text_to_utf[] = {
            " ", ".", "Б", "Ц", "Д", "Ф", "Г", "И",
            "(", ")", "*", "Й", "Л", "Я", "Ж", "/",
            "0", "1", "2", "3", "4", "5", "6", "7",
            "8", "9", "Ь", ",", "П", "-", "+", "Ы",
            "З", "A", "B", "C", "D", "E", "F", "G",
            "H", "I", "J", "K", "L", "M", "N", "O",
            "P", "Q", "R", "S", "T", "U", "V", "W",
            "X", "Y", "Z", "Ш", "Э", "Щ", "Ч", "Ю"
        };
        return text_to_utf[ch & 63];
    }

    std::string get_text_word(uint64 word) {
        std::string ret;
        for (uint i = 42; i <= 42; i-=6) {
            ret += get_text_char(word >> i);
        }
        return ret;
    }

    std::string get_gost_word(uint64 word) {
        std::string ret;
        for (uint i = 40; i <= 40; i-=8) {
            ret += get_gost_char(word >> i);
        }
        return ret;
    }
    std::string get_itm_word(uint64 word) {
        std::string ret;
        for (uint i = 40; i <= 40; i-=8) {
            ret += get_itm_char(word >> i);
        }
        return ret;
    }
    std::string get_bytes(uint64 word) {
        std::string ret;
        for (uint i = 40; i <= 40; i-=8) {
            ret += strprintf("%03o ", int(word >> i) & 0377);
        }
        return ret;
    }

#if 1
    bool is_likely_iso (uint64 word) {
	int zeromask = 0;
        for (uint i = 0; i < 48; i += 8) {
            uint val = (word >> i) & 0377;
            if (val != 0 && (val < 040 || val >= 0177))
                return false;
	    if (val == 0) zeromask |= 1 << (i/8);
        }
        return zeromask != 63 &&
	 (zeromask == 0 || ((zeromask+1) & zeromask) == 0 || zeromask == 62);
    }
    bool is_valid_iso (uint64 word) {
	return is_likely_iso(word);
    }
#endif

   bool is_likely_text(uint64 word) {
        // Of all groups of 6 bits, they should be left-
        // or right-aligned, there must be no spaces in the middle,
        // and no unused codes or Cyrillics.
        int seen0 = 0, seen_char = 0;
        bool last0 = false;
        for (uint i = 42; i <= 42; i-=6) {
            uint val = (word >> i) & 077;
            switch (val) {
            case 001 ... 011:
            case 013 ... 016:
            case 032 ... 034:
            case 037:
            case 040:
            case 073 ... 077:
                return false;
            case 0:
                if (seen_char && seen0 && !last0) return false;
                ++seen0;
                last0 = true;
                break;
            default:
                if (seen_char && seen0 && last0) return false;
                ++seen_char;
                last0 = false;
            }
        }
        return seen_char > 1;
    }


    bool is_valid_gost (uint64 word) {
        for (uint i = 0; i < 48; i += 8) {
            uint val = (word >> i) & 0377;
            switch (val) {
                case 0377: case 0143: case 0162: case 0172:
		case 0146:
                case 0175: case 0214:
                    break;
		case 020: case 021: case 024: case 034: /* unlikely chars */
			return false;	
                default:
                    if (val >= 0116)
			return false;
                }
        }
        return true;
    }
    bool is_likely_gost (uint64 word) {
	int total = 0, zeros = 0;
        for (uint i = 0; i < 48; i += 8) {
            uint val = (word >> i) & 0377;
	    // trailing zeros not counted
            if (total && val == 0) ++zeros,++total;
	    if (val) ++total;
            switch (val) {
                case 0377: case 0143: case 0162: case 0172:
		case 0146:
                case 0175: case 0214:
                    break;
            case 020: case 021: case 024: case 034: /* unlikely chars */
			return false;	
                default:
                    if (val >= 0116)
			return false;
                }
        }
        return (word >> 40) || (word >> 32) && total-zeros > 2;
    }
    bool is_valid_itm(uint64 word) {
        for (uint i = 0; i < 48; i += 8) {
            uint val = (word >> i) & 0377;
            if (!itm_to_utf[val])
                return false;
        }
        return true;
    }

   
    bool is_likely_itm(uint64 word) {
	int total = 0, zeros = 0;
        for (uint i = 0; i < 48; i += 8) {
            uint val = (word >> i) & 0377;
	    // trailing zeros not counted
            if (total && val == 0) ++zeros,++total;
	    if (val) ++total;
            if (!itm_to_utf[val])
                return false;
        }
        return (word >> 40) || (word >> 32) && total-zeros > 2;
    }

    std::vector<std::string> symtab;
    std::vector<std::string> labels;

};

int
main (int argc, char **argv)
{
    int basereg = 0;
    bool nolabels = false, nodlabels = false, nooctal = false, litconst = false;

    const char * usage = "Usage: %s [-l] [-e] [-o] [-c] [-Rbase] [-d] objfile\n";
    char opt;
    FILE * gost = NULL;
    FILE * itm = NULL;
    FILE * ascii = NULL;
    FILE * text = NULL;

    while ((opt = getopt(argc, argv, "cdelnoR:E:G:I:A:T:f:")) != -1) {
        switch (opt) {
        case 'l':
            // To produce a compilable assembly code,
            // not needed for decompile.
            nolabels = true;
            break;
        case 'o':
            // If not used, the output will match DTRAN closely,
            // if used, the offsets will always be printed in decimal.
            nooctal = true;
            break;
        case 'n':
            // If set, the /NNNN labels for data will not be printed.
            nodlabels = true;
            break;
        case 'c':
            litconst = true;
            // References to the const section printed as literals;
            // used for decompilation.
            break;
        case 'R':	/* -RN (decimal) use reg N as base */
            // Say -R8 for decompilation
            basereg = 0;
            while (*optarg >= '0' && *optarg <= '9') {
                basereg *= 10;
                basereg += *optarg - '0';
                ++optarg;
            }
            if (basereg == 0 || basereg > 017) {
                fprintf(stderr, "Bad base reg %o, need 1 <= R <= 15\n",
                        basereg);
                exit(1);
            }
            break;
        case 'E':               // A file with a list of entry points
            if ((entries = fopen(optarg, "r")) == NULL) {
                fprintf(stderr, "Bad entry points file %s\n", optarg);
                exit(1);
            }
            break;
	case 'G':		// A file with a list of offsets of GOST literals
	    if ((gost = fopen(optarg, "r")) == NULL) {
                fprintf(stderr, "Bad GOST offsets file %s\n", optarg);
                exit(1);
            }
            break;
	case 'I':		// A file with a list of offsets of ITM literals
	    if ((itm = fopen(optarg, "r")) == NULL) {
                fprintf(stderr, "Bad ITM offsets file %s\n", optarg);
                exit(1);
            }
            break;
	case 'A':		// A file with a list of offsets of ASCII/ISO literals
	    if ((ascii = fopen(optarg, "r")) == NULL) {
                fprintf(stderr, "Bad ASCII offsets file %s\n", optarg);
                exit(1);
            }
            break;
	case 'T':		// A file with a list of offsets of TEXT literals
	    if ((text = fopen(optarg, "r")) == NULL) {
                fprintf(stderr, "Bad TEXT offsets file %s\n", optarg);
                exit(1);
            }
            break;
		
        case 'd':
            // Decompilation all-in-one mode.
            nooctal = true;
            litconst = true;
            basereg = 8;
            break;
        case 'f':
	    // Forced code offset
	    if (1 != sscanf(optarg, "%i", &forced_code_off)) {
		fprintf(stderr, "Bad forced code offset %s\n", optarg);
		exit(1);
	    }
	    break;
        default: /* '?' */
            fprintf(stderr, usage, argv[0]);
            exit(EXIT_FAILURE);
        }
    }

    if (optind >= argc) {
        fprintf (stderr, usage, argv[0]);
        exit (EXIT_FAILURE);
    }
    if (ascii) {
        int off;
        while(1 == fscanf(ascii, "%i", &off)) {
            isooff.insert(off);
        }
        fprintf(stderr, "Got %lu known ASCII/ISO offsets\n", isooff.size());
    }
    if (text) {
        int off;
        while(1 == fscanf(text, "%i", &off)) {
            textoff.insert(off);
        }
        fprintf(stderr, "Got %lu known TEXT offsets\n", textoff.size());
    }
    if (gost) {
        int off;
        while(1 == fscanf(gost, "%i", &off)) {
            gostoff.insert(off);
        }
        fprintf(stderr, "Got %lu known GOST offsets\n", gostoff.size());
    }
    if (itm) {
        int off;
        while(1 == fscanf(itm, "%i", &off)) {
            itmoff.insert(off);
        }
        fprintf(stderr, "Got %lu known ITM offsets\n", itmoff.size());
    }
    populate_itm();
    fprintf(stderr, "Decompiling file %s\n", argv[optind]);
    Dtran dtr(argv[optind], basereg, nolabels, nodlabels, nooctal);
    
    // dtr.prconst(litconst);
    dtr.prtext(litconst);
    dtr.prsymtab();
    printf(" ,END,\n");
    return 0;
}
