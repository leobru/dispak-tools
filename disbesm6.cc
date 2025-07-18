#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cstdarg>
#include <sys/stat.h>
#include <unistd.h>
#include "encoding.h"
#include <map>
#include <set>
#include <vector>
#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
/*
 * BESM-6 opcode types.
 */
typedef enum {
OPCODE_ILLEGAL,
OPCODE_STR1,		/* short addr */
OPCODE_STR2,		/* long addr */
OPCODE_IMM,		/* e.g. РЕГ, РЖА */
OPCODE_REG1,		/* e.g. УИ */
OPCODE_IMM2,		/* e.g. СТОП */
OPCODE_JUMP,		/* ПБ */
OPCODE_BRANCH,		/* ПО, ПЕ, ПИО, ПИНО, ЦИКЛ */
OPCODE_CALL,		/* ПВ */
OPCODE_IMM64,		/* e.g. СДА */
OPCODE_IRET,		/* ВЫПР */
OPCODE_ADDRMOD,		/* МОДА, МОД */
OPCODE_REG2,		/* УИА, СЛИА */
OPCODE_IMMEX,		/* Э50, ... */
OPCODE_ADDREX,		/* Э60, Э70, ... */
OPCODE_RANGE,		/* Э64, Э71 */
OPCODE_STOP,		/* Э74 */
OPCODE_DEFAULT
} opcode_e;

/*
 * BESM-6 instruction subsets.
 */
#define NONE		0	/* not in instruction set */
#define BASIC		1	/* basic instruction set  */
#define PRIV		2	/* supervisor instruction */

struct opcode {
	const char *name;
	int opcode;
	int mask;
	opcode_e type;
	int extension;
} op[] = {
  /* name,	pattern,  mask,	opcode type,		insn type,    alias */
  { "зп",	0x000000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "зпм",	0x001000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "рег",	0x002000, 0x0bf000, OPCODE_IMM,		PRIV },
  { "счм",	0x003000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "сл",	0x004000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "вч",	0x005000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "вчоб",	0x006000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "вчаб",	0x007000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "сч",	0x008000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "и",	0x009000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "нтж",	0x00a000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "слц",	0x00b000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "знак",	0x00c000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "или",	0x00d000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "дел",	0x00e000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "умн",	0x00f000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "сбр",	0x010000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "рзб",	0x011000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "чед",	0x012000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "нед",	0x013000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "слп",	0x014000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "вчп",	0x015000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "сд",	0x016000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "рж",	0x017000, 0x0bf000, OPCODE_STR1,	BASIC },
  { "счрж",	0x018000, 0x0bf000, OPCODE_IMM,		BASIC },
  { "счмр",	0x019000, 0x0bf000, OPCODE_IMM64,	BASIC },
  { "кк\t26,",	0x01a000, 0x0bf000, OPCODE_IMM,		PRIV },
  { "увв",	0x01b000, 0x0bf000, OPCODE_IMM,		PRIV },
  { "слпа",	0x01c000, 0x0bf000, OPCODE_IMM64,	BASIC },
  { "вчпа",	0x01d000, 0x0bf000, OPCODE_IMM64,	BASIC },
  { "сда",	0x01e000, 0x0bf000, OPCODE_IMM64,	BASIC },
  { "ржа",	0x01f000, 0x0bf000, OPCODE_IMM,		BASIC },
  { "уи",	0x020000, 0x0bf000, OPCODE_REG1,	BASIC },
  { "уим",	0x021000, 0x0bf000, OPCODE_REG1,	BASIC },
  { "счи",	0x022000, 0x0bf000, OPCODE_REG1,	BASIC },
  { "счим",	0x023000, 0x0bf000, OPCODE_REG1,	BASIC },
  { "уии",	0x024000, 0x0bf000, OPCODE_REG1,	BASIC },
  { "сли",	0x025000, 0x0bf000, OPCODE_REG1,	BASIC },
/*  { "Э46",	0x026000, 0x0bf000, OPCODE_IMM,		BASIC },*/
  { "Э47",	0x027000, 0x0bf000, OPCODE_IMM,		BASIC },
  { "Э50",	0x028000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э51",	0x029000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э52",	0x02a000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э53",	0x02b000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э54",	0x02c000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э55",	0x02d000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э56",	0x02e000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э57",	0x02f000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э60",	0x030000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э61",	0x031000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э62",	0x032000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э63",	0x033000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э64",	0x034000, 0x0bf000, OPCODE_RANGE,	BASIC },
  { "Э65",	0x035000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э66",	0x036000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э67",	0x037000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э70",	0x038000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э71",	0x039000, 0x0bf000, OPCODE_RANGE,	BASIC },
  { "Э72",	0x03a000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э73",	0x03b000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э74",	0x03c000, 0x0bf000, OPCODE_STOP,	BASIC },
  { "Э75",	0x03d000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э76",	0x03e000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э77",	0x03f000, 0x0bf000, OPCODE_IMMEX,	BASIC },
/*  { "э20",	0x080000, 0x0f8000, OPCODE_STR2,	BASIC },
  { "э21",	0x088000, 0x0f8000, OPCODE_STR2,	BASIC },*/
  { "мода",	0x090000, 0x0f8000, OPCODE_ADDRMOD,	BASIC },
  { "мод",	0x098000, 0x0f8000, OPCODE_ADDRMOD,	BASIC },
  { "уиа",	0x0a0000, 0xff8000, OPCODE_IMM2,	PRIV },
  { "уиа",	0x0a0000, 0x0f8000, OPCODE_REG2,	BASIC },
  { "слиа",	0x0a8000, 0x0f8000, OPCODE_REG2,	BASIC },
  { "по",	0x0b0000, 0x0f8000, OPCODE_BRANCH,	BASIC },
  { "пе",	0x0b8000, 0x0f8000, OPCODE_BRANCH,	BASIC },
  { "пб",	0x0c0000, 0x0f8000, OPCODE_JUMP,	BASIC },
  { "пв",	0x0c8000, 0x0f8000, OPCODE_CALL,	BASIC },
  { "выпр",	0x0d0000, 0x0f8000, OPCODE_IRET,	PRIV },
  { "стоп",	0x0d8000, 0x0f8000, OPCODE_IMM2,	PRIV },
  { "пио",	0x0e0000, 0x0f8000, OPCODE_BRANCH,	BASIC },
  { "пино",	0x0e8000, 0x0f8000, OPCODE_BRANCH,	BASIC },
  { "дк\t30,",	0x0f0000, 0x0f8000, OPCODE_BRANCH,	BASIC },
  { "цикл",	0x0f8000, 0x0f8000, OPCODE_BRANCH,	BASIC },
/* This entry MUST be last; it is a "catch-all" entry that will match when no
 * other opcode entry matches during disassembly.
 */
  { "конк",	0x0000, 0x0000, OPCODE_ILLEGAL,		NONE },
};
#define AFTER_INSTRUCTION "\t"
#define ADDR(x) ((x) & 077777)

FILE *textfd, *relfd;
int bflag, rflag, srcflag, trim, verbose, pascal;
unsigned int loadaddr, codelen = 0, entryaddr = 0;

bool inrange(unsigned addr) {
    return addr >= loadaddr && addr < loadaddr + codelen;
}

typedef unsigned long long uint64;
typedef unsigned int uint32;

typedef std::map<uint32, uint32> Bases;
// Maps addresses to maps regs to values
std::map<uint32, Bases> bases;

const Bases & find_bases(uint32 addr) {
    static Bases dummy;
    auto it = bases.upper_bound(addr);
    if (it == bases.begin())
        return dummy;
    return (--it)->second;
}

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

/* Symbol table, dynamically allocated. */
struct nlist {
    std::string n_name;
    std::string n_mod;
    uint32      n_type;
    uint32      n_value;
    int 	n_used;
    bool hasname() const {
        return !n_name.empty();
    }
    bool dummy() { return n_type == 0 && n_value == 0 && n_name.empty(); }
    nlist() : n_type(0), n_value(0), n_used(0) { }
    nlist(const std::string& n, uint32 t, uint32 v) : n_name(n == "-" ? "" : n), n_type(t), n_value(v), n_used(0) { }
};
typedef std::vector<nlist> names_t;
names_t names[32769];
nlist dummy;
std::map<uint32, uint32> shorts;

bool hasname(uint32 addr) {
    for (auto & p : names[addr])
        if (p.hasname())
            return true;
    return false;
}

#define W_DATA		1
#define W_CODE		2
#define W_STARTBB	4
#define W_NORIGHT	8
#define W_GOST		16
#define W_UNSET         32
#define W_ADDR          64
#define W_REAL          128
#define W_NOEXEC        256
#define W_SETBASE       512
#define W_LITERAL       1024
#define W_HEX           2048
#define W_ISO           4096
#define W_TEXT          8192
#define W_DONE		(1<<31)

typedef struct actpoint_t {
	int addr, addrmod;
	int regvals[16];
	struct actpoint_t * next;
} actpoint_t;

actpoint_t * reachable = 0;

uint64 memory[32768];
uint32 mflags[32768];
std::map<int, std::string> reason;
std::vector<std::string> externs;
std::map<int, std::vector<std::string> > abs_ents;

void add_actpoint (int addr) {
    actpoint_t * old = reachable;
    if (mflags[addr] & W_UNSET)
        return;
    reachable = new actpoint_t;
    memset (&reachable->regvals[1], -1, sizeof(int)*15);
    reachable->regvals[0] = 0;
    reachable->addr = addr;
    reachable->addrmod = 0;
    reachable->next = old;
    for (auto i: find_bases(addr)) reachable->regvals[i.first] = i.second;
}

void copy_actpoint (actpoint_t * cur, int addr) {
    actpoint_t * old = reachable;
    reachable = new actpoint_t(*cur);
    reachable->addr = addr;
    reachable->addrmod = 0;
    reachable->next = old;
    for (auto i: find_bases(addr)) reachable->regvals[i.first] = i.second;
}

/*
 * Add a name to symbol table.
 */
void
addsym (const std::string & name, int type, uint32 val,
        const std::string & mod = std::string())
{
    if (type & W_SETBASE) {
        uint32 reg = type & 017;
        uint32 base = strtol(name.c_str(), nullptr, 8);
        bases[val][reg] = base;
        return;
    }
    if (type & W_CODE)
        add_actpoint(val);
    mflags[val] |= type & (W_UNSET|W_STARTBB|W_NOEXEC|W_LITERAL);
//    if (type & W_STARTBB)
//        mflags[val] |= type & W_DATA;
    if ((type & W_CODE) && name == "-") {
        return;
    }
    names[val].push_back(nlist(name, type, val));
    if (!mod.empty())
        names[val].back().n_mod = mod;
}

/*
 * Print all symbols located at the address.
 */
int
prsym (uint32 addr)
{
    int printed;
    int flags = 0;
    bool first = true;
    printed = 0;
    for (auto p : names[addr]) {
        flags |= p.n_type;
        if (p.hasname() && !(flags & W_UNSET)) {
            // Do not re-print the start name
            if (first && addr == loadaddr) {
                first = false;
                continue;
	    }
	    if (printed) {
                printf("\tноп\n%s", srcflag ? "" : "\t\t\t");
            }
            printf ("%s", p.n_name.c_str());
            ++printed;
        }
    }
    return flags;
}

/*
 * Collect all flags at the address.
 */
int flags(uint32 addr) {
    int flags = 0;
    for (auto p : names[addr]) {
        flags |= p.n_type;
    }
    return flags;
}

/*
 * Find a symbol nearest to the address.
 */
struct nlist *
findsym (uint32 addr)
{
    const int plusfuzz = 64, minusfuzz = 4;
    const int minaddr = addr <= plusfuzz ? 0 : addr-plusfuzz;
    for (uint32 a = addr; a > minaddr; --a) {
        for (auto & p : names[a]) {
            if (p.hasname() && !(p.n_type & W_UNSET)) {
                ++p.n_used;
                return &p;
            }
        }
    }
    const int maxaddr = addr+minusfuzz > 0100000 ? 0100000 : addr+minusfuzz;
    for (uint32 a = addr+1; a < maxaddr; ++a) {
        for (auto & p : names[a]) {
            if (p.hasname() && !(p.n_type & W_UNSET)) {
                ++p.n_used;
                return &p;
            }
        }
    }
    return &dummy;
}

/*
 * Print an absolute value, using an absolute entry, if appropriate.
 */
std::string
prabs (uint32 val) {
    // If the value exactly matches a unique absolute-valued entry, use its name.
    if (abs_ents.count(val) && abs_ents[val].size() == 1)
        return abs_ents[val][0];
    else {
        std::string ret;
        auto sym = findsym(val);
        if (sym != &dummy) {
            auto offset = val - sym->n_value;
            ret = sym->n_name;
            if (offset > 0) {
                ret += '+';
            } else if (offset < 0) {
                ret += '-';
                offset = - offset;
            }
            if (offset) ret += std::to_string(offset);
            return ret;
        }
        return strprintf("'%o'", val);
    }
}

struct FreeElt {
    char op;
    char type;                  // A - absolute, R - relative, E - external
    int val;
    FreeElt(char o, char t, int v) : op(o), type(t), val(v) { }
    std::string print(int cnt) const {
        std::string ret;
        if (cnt || op != '+')
            ret += op;
        switch (type) {
        case 'A':
            ret += val <= 64 ? strprintf("%d", val) :
                val >= 32768-64 ? strprintf("%d", (val % 32768) -32768) :
                prabs(val);
            break;
        case 'R': {
            auto sym = findsym (val);
            auto offset = val - sym->n_value;
            ret += sym->n_name;
            if (offset) ret += std::to_string(offset);
        } break;
        case 'E':
            ret += externs[val];
        }
        return ret;
    }
};

struct FreeExpr : public std::vector<FreeElt> {
    std::string print() const {
        std::string ret;
        for (uint i = 0; i < size(); ++i)
            ret += (*this)[i].print(i);
        return ret;
    };
    int absval() const {
        if (size() == 1 && (*this)[0].type == 'A')
            return (*this)[0].val;
        else
            return -1;
    }
};

// Indexed by address*2+right
std::map <int,  FreeExpr> freevars;
std::map<int, int> relocs;      // 1 - short addr, 2 - long addr

int reloc(int idx) {
    return relocs.count(idx) ? relocs[idx] : -1;
}

size_t utflen(const std::string& s) {
    size_t ret = 0;
    for(unsigned char c:s) {
        if (c < 0200 || c >= 0300) ++ret;
    }
    return ret;
}

std::string
prlist(const std::string & kind, const std::string& mod, std::vector<std::string>& list) {
    std::string ret;
    while (list.size()) {
        std::string s = mod + '\t' + kind;
        char delim = '\t';
        size_t len = utflen(s);
        while (list.size() && (len+1 + utflen(list.back()) <= 60)) {
            s += delim;
            s += list.back();
            len += utflen(list.back())+1;
            list.pop_back();
            delim = ',';
        }
        ret += s;
	ret += '\n';
    }
    return ret;
}

std::string prequs ()
{
    struct nlist *p;
    std::string ret;
    std::map<std::string, std::vector<std::string>> externs;
    for (auto & v : names) for (auto & p : v) {
        if (p.n_name.empty() || !p.n_used)
            continue;
        if (loadaddr <= p.n_value && p.n_value < loadaddr+codelen) {
            // Local symbol
            continue;
        }
        if (p.n_name.find_first_of("+-") != std::string::npos) {
            // Offset definition
            continue;
        }
        if (!p.n_mod.empty())
            externs[p.n_mod].push_back(p.n_name);
        else if (p.n_value > 0162) {
            printf(srcflag ? "" : "\t\t\t");
            printf ("%s\tэкв\t'%o'\n",  p.n_name.c_str(), p.n_value);
        }
    }
    for (auto & elt : externs) {
        ret += prlist("ВНЕШ", elt.first, elt.second);
    }
    return ret;
}

void prstart() {
    auto start = findsym(loadaddr);
    auto indent = srcflag ? "" : "\t\t\t";
    printf("%s%s\tСТАРТ\t'%o'\n", indent,
           start->n_value == loadaddr ? start->n_name.c_str() : "НЕИМЯ", loadaddr);
    if (srcflag) {
        printf("\tБ\n\tЕ\n\tМ\n");
    }
}

/*
 * Read 48-bit word at current file position.
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

/*
 * Print integer register name.
 */
std::string
prreg (int reg, bool paren)
{
    return strprintf(paren ? "(М%o)" : "М%o", reg);
}

std::string     // non-empty - relocatable (printed), empty - absolute (needs to be printed elsewhere)
praddr (uint32 address, bool known_reloc,
	int data_offset_as_number, int offset_as_number)
{
    struct nlist *sym;
    int offset;
    std::string ret;
    sym = findsym (address);
    if (sym == &dummy && known_reloc) {
        offset = address - loadaddr;
        ret = findsym(loadaddr)->n_name;
        if (offset >= 0) {
            ret += '+';
        } else {
            ret += '-';
            offset = - offset;
        }
        ret += std::to_string(offset);
        return ret;
    }
    // As we don't distinguish index regs and stack/frame regs yet,
    // we avoid using data syms along with any regs
    offset = address - sym->n_value;
    // Allow symbolic addresses if explicitly defined
    if (!known_reloc && sym->n_type && offset != 0 && (offset_as_number || data_offset_as_number)) {
        --sym->n_used;
        sym = &dummy;
    }
    if (!known_reloc && address < 0100 && offset != 0) {
        --sym->n_used;
        sym = &dummy;
    }
    if (sym != &dummy) {
        ret = sym->n_name;
        if (address == sym->n_value) {
            return ret;
        }
        if (offset >= 0) {
            if (!sym->n_name.empty())
                ret += '+';
        } else {
            ret += '-';
            offset = - offset;
        }
        ret += std::to_string(offset);
        return ret;
    }
    return std::string();
}

const opcode & getop(uint32 code) {
    int i;
    for (i=0; op[i].mask; i++)
        if ((code & op[i].mask) == op[i].opcode)
            return op[i];
    return op[i];
}

/*
 * Print instruction code.
 * Return 0 on error.
 */
void
prcode (uint32 memaddr, uint32 opcode)
{
    int i;

    switch (getop(opcode).type) {
    case OPCODE_STR1:
    case OPCODE_ADDREX:
    case OPCODE_RANGE:
    case OPCODE_IMM:
    case OPCODE_IMMEX:
    case OPCODE_IMM64:
    case OPCODE_REG1:
        printf ("%02o %03o %04o ", opcode >> 20, (opcode >> 12) & 0177, opcode & 07777);
        break;
    case OPCODE_REG2:
    case OPCODE_ADDRMOD:
    case OPCODE_STR2:
    case OPCODE_IMM2:
    case OPCODE_JUMP:
    case OPCODE_IRET:
    case OPCODE_BRANCH:
    case OPCODE_CALL:
        printf ("%02o %02o %05o ", opcode >> 20, (opcode >> 15) & 037, opcode & 077777);
        break;
    default:
        printf("%08o  ", opcode);
    }
}

/*
 * Print the memory operand.
 * Return 0 on error.
 */
std::string
properand (uint32 instaddr, uint32 reg, uint32 offset, int explicit0, uint32 base_reg = 0)
{
    if (offset == 0 && freevars.count(instaddr)) {
        return freevars[instaddr].print() + (reg ? prreg (reg, true) : "");
    }
    bool inrange = offset >= loadaddr && offset < loadaddr + codelen;
    bool verysmall = offset < 020 || offset >= 077700;
    bool have_base = base_reg != 0;
    bool base_modif = explicit0 && have_base;
    int data_offset_as_number = !inrange || (verysmall && reg != 0 && !have_base);
    int offset_as_number = !inrange || reg != 0 && !have_base && (offset < 020 || offset >= 077700);
    if (have_base && base_reg == 0)
        base_reg = reg;
    uint32 base_val = 0;
    if (base_reg) {
        auto b = find_bases(instaddr/2);
        base_val = b[base_reg];
    }
    if (!base_modif && have_base) {
        offset += base_val;
	offset &= 077777;
    }
    bool utc_base = base_reg && reg != base_reg;
    std::string ret;
    bool rel =
        (reloc(instaddr) > 0 &&
         !(ret = praddr (offset, true, false, false)).empty()) ||
        (have_base ? offset >= loadaddr && offset < loadaddr + codelen : true) &&
        !(ret = praddr (offset, false, data_offset_as_number, offset_as_number)).empty();
    if (have_base && !rel && base_val < loadaddr && offset < loadaddr && offset >= base_val) {
        auto sym = findsym(offset);
        if (sym != &dummy) {
            return praddr (offset, false, data_offset_as_number, offset_as_number) +
            "-base" +
            prreg (reg, true);
        }
    } else if (!rel) {
        if (offset == base_val) {
                offset = base_val = 0;
        }
        if(offset) {
            if (offset < 040)
                ret = std::to_string(offset);
            else if (offset >= 077700)
                ret = strprintf("%d", offset-0100000);
            else {
                ret = prabs(offset);
            }
        } else if (explicit0)
            ret = '0';
    }
    if (!ret.empty() && (utc_base || (base_val && !rel))) {
        if (ret != "base")
            ret += "-base";
        else
            ret = "";
    }
    if (reg && (reg != base_reg || base_modif || !have_base || !rel)) {
        ret += prreg (reg, true);
    }
    return ret;
}

std::string
prinsn (uint32 memaddr, uint32 opcode, int right)
{
    std::string ret;
    int reg = opcode >> 20;
    int arg1 = (opcode & 07777) + (opcode & 0x040000 ? 070000 : 0);
    int arg2 = opcode & 077777;
    static uint32 utc_base = 0;
    auto op = getop(opcode);
    opcode_e type = op.type;
    auto b = find_bases(memaddr);
    uint32 base_reg = utc_base ? utc_base : (reg && b.count(reg)) ? reg : 0;
    utc_base = base_reg && (opcode & 0xfffff) == 0x90000 ? base_reg : 0;
    uint32 instaddr = memaddr*2 + right;
    ret = op.name;
    if (!right && type == OPCODE_CALL)
        ret += "л";
    if (!strchr(op.name, '\t'))
        ret += AFTER_INSTRUCTION;
    if (freevars.count(instaddr)) {
        auto & fv = freevars[instaddr];
        if (fv.absval() == -1 || !reg || !base_reg) {
            if (fv.absval() != 0)
                ret += fv.print();
            if (reg) {
                ret += prreg (reg, true);
            }
            return ret;
        }
    }
    switch (type) {
    case OPCODE_REG1:
        if (arg1) {
            if (arg1 <= 037)
                ret += prreg (arg1, false);
            else
                ret += strprintf("'%o'", arg1);
        }
        if (reg) {
            ret += prreg (reg, true);
        }
        break;
    case OPCODE_ADDREX:
    case OPCODE_RANGE:
    case OPCODE_STR1:
        ret += properand (memaddr*2+right, reg, arg1, 0, base_reg);
        break;
    case OPCODE_REG2:
    case OPCODE_STR2:
    case OPCODE_ADDRMOD: {
        bool explicit_reg = op.type == OPCODE_REG2;
        if (reg != base_reg)
            explicit_reg = false;
        ret += properand (memaddr*2+right, reg, arg2, explicit_reg, base_reg);
    } break;
    case OPCODE_BRANCH:
    case OPCODE_JUMP:
    case OPCODE_IRET:
    case OPCODE_CALL:
        ret += properand (memaddr*2+right, reg, arg2, 0, base_reg);
        break;
    case OPCODE_IMMEX:
    case OPCODE_IMM:
    case OPCODE_STOP: {
        bool need0 = false;
        if (strchr(op.name, '\t'))
            need0 = true;
        if (arg1 || need0) ret += strprintf ("'%o'", arg1);
        if (reg) {
            ret += prreg (reg, true);
        }
    } break;
    case OPCODE_IMM64:
        arg1 &= 0177;
        if (arg1) {
            ret += "64";
            if (arg1 -= 64) ret += strprintf ("%+d", arg1);
        }
        if (reg) {
            ret += prreg (reg, true);
        }
        break;
    case OPCODE_IMM2:
        if (arg2) ret += std::to_string(arg2);
        if (reg) {
            ret += prreg (reg, true);
        }
        break;
    case OPCODE_ILLEGAL:
        ret += strprintf ("в'%08o'", opcode);
        break;
    default:
        ret = "???";
    }
    return ret;
}

bool is_good_gost(int s)
{
    return (s < 020) || (s == 025) || (s >= 037 && s < 0115);
}

bool is_good_iso(int s) {
    // Allow letters (Latin not matching Cyrillic), digits and space
    if (strchr("ABEKMHOPCTYX", s))
        return false;
    return (s == ' ') || ('0' <= s && s <= '9') ||
        ('A' <= s && s <= 'Z') || ('`' <= s && s <= '}');
}

bool is_good_iso_with_even_parity(int s) {
    int parity = (s & 0x55) + ((s & 0xAA) >> 1);
    parity = (parity & 0x33) + ((parity & 0xCC) >> 2);
    parity = (parity & 0xF) + (parity >> 4);
    if (parity & 1)
        return false;
    s &= 0x7F;
    // Allow control characters including NUL here
    return (s = 0xFF) || (s < 0x20) || is_good_iso(s);
}
bool maybe_addr(uint32 val) {
    if (val > 077777)
        return false;
    if (val <= 01000) {
        return false;
    }
    auto sym = findsym(val);
    if (sym != &dummy) --sym->n_used;
    return (bflag || (val >= loadaddr && val < loadaddr + codelen)) &&
        findsym(val) != &dummy && findsym(val)->n_value == val;
}

void split_bytes(uint64 val, unsigned char bytes[6]) {
    int i;
    for (i = 0; i < 6; ++i) {
        bytes[i] = (val >> (40-8*i)) & 0xff;
    }
}
void split_bytes(uint32 addr, unsigned char bytes[6]) {
    split_bytes(memory[addr], bytes);
}

int count_good(unsigned char bytes[6], bool (*is_good)(int)) {
    int good = 0, i;
    for (i = 0; i < 6; ++i) {
        good += is_good(bytes[i]);
    }
    return good;
}

bool nonconst(int cmdaddr) {
    if (reloc(cmdaddr) > 0)
        return true;
    if (freevars.count(cmdaddr) && (freevars[cmdaddr].size() > 1 || freevars[cmdaddr][0].type != 'A'))
        return true;
    return false;
}
std::string proct(uint32 val) {
        if (val <= 7) return std::string(1, char(val + '0'));
        return strprintf("'%o'", val);
}

bool is_short_gost(uint32 flags, uint32 val) {
    return (flags & W_GOST) ||
	(val && is_good_gost(val & 0377) &&
	 is_good_gost((val >> 8) & 0377) &&
	 is_good_gost((val >> 16) & 0377));
}

bool printable(uint32 byte) {
    switch (byte) {
    case 0135: // hard sign
    case 0136: // degree/question mark
    case 0131: // horizontal line
    case 0115: // overline
    case 0032: case 0033: // opening/closing quote
    case 0137: // apostrophe/prime
    case 0020: // lower ten
        return false;
    default:
        return byte < 0140;
    }
}

bool printable_iso(uint32 byte) {
    return byte != '@' && ' ' <= byte && byte <= '\176';
}

std::string gostlit(unsigned char bytes[6], bool forced, int good_gost = 0) {
    bool bad_seen = false;
    bool print_all_bytes = false;
    std::string ret;
    if (forced || good_gost >= 4) {
	std::string s;
	for (int i = 0; i < 6; ++i) {
	    if (printable(bytes[i]))
		s += gost_to_utf8 (bytes[i]);
	    else { bad_seen = true; s += '0'; }
	}
	if (s == "000000") {
	    ret = bad_seen ? "" : "в'0'";
	} else if (s.length() >= 6 && s.substr(s.length()-5, 5) == "00000") {
	    ((ret = "м40п'") += s.substr(0, s.length()-5)) += "'";
	} else {
	    ret = strprintf("п'%s'", s.c_str()+s.find_first_not_of('0'));
	}
    } else
	print_all_bytes = true;
    if (bad_seen || print_all_bytes) {
	for (int i = 0; i < 6; ++i) {
	    if (print_all_bytes || !printable(bytes[i])) {
		if (bytes[i] != 0) {
		    if (i != 5) ret += strprintf("м%d", 40-i*8);
		    ret += strprintf("в'%03o'", bytes[i]);
		}
	    }
	}
    }
    return ret;
}


std::string isolit(unsigned char bytes[6], bool forced) {
    bool bad_seen = false;
    bool print_all_bytes = false;
    std::string ret;
    if (forced) {
	std::string s;
	for (int i = 0; i < 6; ++i) {
	    if (printable_iso(bytes[i]))
		s += unicode_to_utf8 (koi7_to_unicode[bytes[i]]);
	    else { bad_seen = true; s += '@'; }
	}
	if (s == "@@@@@@") {
	    ret = "";
	} else if (s.length() >= 6 && s.substr(s.length()-5, 5) == "@@@@@") {
	    ((ret = "м40д'") += s.substr(0, s.length()-5)) += "'";
	} else {
	    ret = strprintf("д'%s'", s.c_str()+s.find_first_not_of('@'));
	}
    } else
	print_all_bytes = true;
    if (bad_seen || print_all_bytes) {
	for (int i = 0; i < 6; ++i) {
	    if (print_all_bytes || !printable_iso(bytes[i])) {
		if (bytes[i] != 0) {
		    if (i != 5) ret += strprintf("м%d", 40-i*8);
		    ret += strprintf("в'%03o'", bytes[i] ^ '@');
		}
	    }
	}
    }
    return ret;
}

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

void prshort(uint32 val, int cmdaddr, uint32 flags = 0) {
    bool good_addr = val && maybe_addr(val);
    int reg = val >> 20;
    bool data = !nonconst(cmdaddr) && !(flags & W_ADDR);
    if (data) {
	if (shorts.count(cmdaddr/2-1) && is_short_gost(flags, val ^ shorts[cmdaddr/2-1])) {
	    unsigned char bytes1[6], bytes2[6];
	    val ^= shorts[cmdaddr/2-1];
	    split_bytes(uint64(val), bytes1);
	    split_bytes(uint64(shorts[cmdaddr/2-1]), bytes2);
            printf("конк\t%s%s",
		   gostlit(bytes1, true).c_str(),
		   gostlit(bytes2, true).c_str());
	    shorts[cmdaddr/2] = val;
	} else if (is_short_gost(flags, val)) {
	    unsigned char bytes[6];
	    split_bytes(uint64(val), bytes);
            printf("конк\t%s", gostlit(bytes, true).c_str());
	    shorts[cmdaddr/2] = val;
        } else if (!rflag && good_addr) {
            printf("конк\tA(%s)\tвозм.", praddr(val, true, false, false).c_str());
        } else {
            printf("конк\tв'%08o'", val);
        }

    } else {
        int rel = reloc(cmdaddr);
        if (rel == 1 || flags & W_ADDR) {
            printf("кк\t%s,%s", proct((val >> 12) & 077).c_str(),
                   properand(cmdaddr, reg, (val & 07777) + (val & 01000000 ? 070000 : 0), true).c_str());
        } else if (rel == 2 && good_addr)
            printf("конк\tA(%s)", praddr(val, true, false, false).c_str());
        else
            printf("дк\t%s,%s", proct((val >> 15) & 037).c_str(), properand(cmdaddr, reg, val & 077777, true).c_str());
    }
}

std::string literal(uint32 addr, int flags = 0) {
    flags |= mflags[addr];
    uint64 val = memory[addr];
    if (flags & W_REAL) {
	bool denorm = !(((val >> 39) ^ (val >> 40)) & 1);
	double d = ldexp((long long)val << 23, (val >> 41) - 64 - 63);
	return strprintf ("е'%.12g' %s", d, denorm ? "denorm" : "");
    }
    if (flags & W_HEX) {
        return strprintf("х'%lX'", val);
    }
    std::string ret;
    unsigned char bytes[6];
    split_bytes(addr, bytes);
    int good_gost = count_good(bytes, is_good_gost);
    int good_iso = count_good(bytes, is_good_iso);
    int i;
    if (!(flags & W_ISO) && (good_gost == 6 || (flags & W_GOST))) {
	return gostlit(bytes, flags & W_GOST, good_gost);
    }
    if (good_iso == 6 || (flags & W_ISO)) {
        return isolit(bytes, flags & W_ISO);
    }
    ret = val == 0xffffffffffffLL ? "в'-1'" :
	val < 256 ? strprintf ("в'%03llo'", val) :
	(val & 0xffffffffffLL) == 0 ? strprintf("м40в'%03llo'", val >> 40) :
	(val & 0177777777) == 0100000000 ? strprintf("м24в'%03llo'", val >> 24) :
	(val >> 24) == 0 ? strprintf("в'%08llo'", val) :
	strprintf ("в'%016llo'", val);
    if (flags & W_TEXT)
      ret += "TEXT " + get_text_word(val);
    int good_iso_with_parity = count_good(bytes, is_good_iso_with_even_parity);
    if (good_iso == 6) {
	std::string s;
	for (i = 0; i < 6; ++i) {
	    s += unicode_to_utf8 (koi7_to_unicode[bytes[i]]);
	}
	((ret += " ISO '") += s) += "'";
    } else if (good_iso_with_parity == 6) {
	std::string s;
	int fake = 0;
	for (i = 0; i < 6; ++i) {
	    int c = bytes[i] & 0x7F;
	    fake += (c == 0) || (c == 0x7F);
	    if (c < 0x20)
		(s += '^') += char(c + 0x40);
	    else
		s += unicode_to_utf8 (koi7_to_unicode[c]);
	}
	if (fake <= 3 && !srcflag)
	    ((ret += " PARITY ISO '") += s) += "'";
    }
    return ret;
}

void prconst (uint32 addr, uint32 limit)
{
    int flags = 0;
    do {
        unsigned char bytes[6];
        int i;
        int good_gost, good_iso;
        if (srcflag == 0) {
            printf ("%5o %016llo", addr, memory[addr]);
            putchar ('\t');
        }
        // Erase "weak" flags which must not spill onto next words
        flags &= ~W_HEX;
        flags |= prsym (addr);
        split_bytes(addr, bytes);
        good_gost = count_good(bytes, is_good_gost);
        good_iso = count_good(bytes, is_good_iso);
        bool rel_l = nonconst(addr*2);
        bool rel_r = nonconst(addr*2+1);
        uint32 ex_addr = mflags[addr] & W_ADDR;
        uint32 forced = flags & (W_HEX|W_REAL|W_ISO|W_TEXT);
        if (!rel_l && !rel_r && forced) {
            printf ("\tконд\t%s\n", literal(addr, forced).c_str());
        } else if (!ex_addr && !rel_l && !rel_r &&
                   ((flags & W_GOST && !(flags & W_ISO) || good_gost == 6))) {
            printf ("\tконд\t%s\n", literal(addr, W_GOST).c_str());
        } else if (!ex_addr && !rel_l && !rel_r &&
                   (flags & W_ISO || good_iso == 6)) {
            printf ("\tконд\t%s\n", literal(addr, W_ISO).c_str());
        } else {
            uint32 left = memory[addr] >> 24;
            uint32 right = memory[addr] & 0xFFFFFF;
            bool left_addr = left && (ex_addr || rel_l ||  maybe_addr(left));
            bool right_addr = right && (ex_addr || rel_r || maybe_addr(right));
            if (!rel_l && !rel_r && (rflag || (!left_addr && !right_addr))) {
                printf ("\tконд\t%s\n", literal(addr).c_str());
            } else if (ex_addr || rel_l || rel_r) {
                putchar('\t'); prshort(left, addr*2, ex_addr); putchar('\n');
                printf(srcflag ? "" : "\t\t\t");
                putchar('\t'); prshort(right, addr*2+1, ex_addr); putchar('\n');
            } else if (left == 0 && right_addr) {
                printf("\tконд\tA(%s)\tвозм.\n", findsym(right)->n_name.c_str());
            } else {
                if (left_addr) {
                    printf("\tконк\tA(%s)\tвозм.\n", findsym(left)->n_name.c_str());
                } else {
                    putchar('\t'); prshort(left, addr*2); putchar('\n');
                    // printf("\tконк\tв'%08o'\n", left);
                }
                printf(srcflag ? "" : "\t\t\t");
                if (right_addr) {
                    printf("\tконк\tA(%s)\tвозм.\n", findsym(right)->n_name.c_str());
                } else {
                    printf("\tконк\tв'%08o'\n", right);
                }
            }
        }
        mflags[addr] |= W_DONE;
    } while ((mflags[++addr] & (W_CODE|W_DATA)) == 0 &&
             addr < limit && memory[addr] != 0);
}

void analyze_call (actpoint_t * cur, int reg, int arg, int addr, int limit)
{
    if (arg != -1 && arg >= addr && arg < limit) {
        copy_actpoint (cur, arg);
        if (reg)
            reachable->regvals[reg] = cur->addr+1;
        if (!(mflags[arg] & W_STARTBB))
	    reason[arg] += strprintf("CALL @%05o, ", cur->addr);
        mflags[arg] |= W_STARTBB;
    }
    copy_actpoint (cur, cur->addr + 1);
    // Assuming no tricks are played; usually does not hurt,
    // used in Pascal-Autocode
    if (pascal && reg)
        reachable->regvals[reg] = cur->addr + 1;
}

void analyze_jump (actpoint_t * cur, int reg, int arg, int addr, int limit)
{
    if (arg != -1 && cur->regvals[reg] != -1) {
        arg = ADDR(arg + cur->regvals[reg]);
        if (arg >= addr && arg < limit) {
            copy_actpoint (cur, arg);
            if (!(mflags[arg] & W_STARTBB))
		reason[arg] += strprintf("JUMP @%05o, ", cur->addr);
            mflags[arg] |= W_STARTBB;
        }
    }
}

void analyze_branch (actpoint_t * cur, int opcode, int reg, int arg, int addr, int limit) {
    if (arg == -1)
        return;
    if (opcode >= 0x0e0000) {
        if (arg >= addr && arg < limit && !(mflags[arg] & W_UNSET)) {
            copy_actpoint (cur, arg);
            if (!(mflags[arg] & W_STARTBB))
		reason[arg] += strprintf("BR1 @%05o, ", cur->addr);
            mflags[arg] |= W_STARTBB;
        }
    } else if (cur->regvals[reg] != -1) {
        arg = ADDR(arg + cur->regvals[reg]);
        if (arg >= addr && arg < limit && !(mflags[arg] & W_UNSET)) {
            copy_actpoint (cur, arg);
            if (!(mflags[arg] & W_STARTBB))
		reason[arg] += strprintf("BR2 @%05o, ", cur->addr);
            mflags[arg] |= W_STARTBB;
        }
    }
}

void analyze_regop1 (actpoint_t * cur, int opcode, int reg, int arg)
{
    if (arg == -1)
        return;

    switch (opcode) {
    case 0x021000:	// уим
#if 0
        // No use tracking the stack ptr usage of M17
        if (cur->regvals[017] != -1) {
            --cur->regvals[017];
        }
#endif
        // fall through
    case 0x020000:	// уи
        if (cur->regvals[reg] == -1)
            break;
        arg += cur->regvals[reg];
        arg &= 037;	// potentially incorrect for user programs
        if (arg != 0 && arg <= 15) {
            // ACC value not tracked yet
            if (bases.count(arg))
                fprintf(stderr, "Base reg kept after ATI @%05o\n", cur->addr);
            else
                cur->regvals[arg] = -1;
        }
        break;
    case 0x022000:	// счи
        // ACC value not tracked yet
        break;
    case 0x023000:	// счим
#if 0
        if (cur->regvals[017] != -1) {
            ++cur->regvals[017];
        }
#endif
        break;
    case 0x024000:	// уии
        arg &= 037;
        if (arg != 0 && arg <= 15) {
            cur->regvals[arg] = cur->regvals[reg];
            if (bases.count(arg)) fprintf(stderr, "Base reg erased @%05o\n", cur->addr);

        }
        break;
    case 0x025000:	// сли
        arg &= 037;
        if (arg != 0 && arg <= 15 && cur->regvals[arg] != -1) {
            if (cur->regvals[reg] == -1) {
                cur->regvals[arg] = -1;
                if (bases.count(arg)) fprintf(stderr, "Base reg erased @%05o\n", cur->addr);

            } else {
                cur->regvals[arg] += cur->regvals[reg];
                cur->regvals[arg] &= 077777;
            }
        }
        break;
    }
}

void analyze_regop2 (actpoint_t * cur, int opcode, int reg, int arg)
{
    switch (opcode) {
    case 0x0a0000:	// уиа
        if (reg) {
            if (bases.count(reg) && arg == -1)
                fprintf(stderr, "Base reg kept after VTM @%05o\n", cur->addr);
            else
                cur->regvals[reg] = arg;
        }
        break;
    case 0x0a8000:	// слиа
        if (reg && cur->regvals[reg] != -1) {
            cur->regvals[reg] = arg == -1 ? -1 :
                ADDR(cur->regvals[reg] + arg);
        }
        break;
    }
}

void analyze_addrmod (actpoint_t * cur, int opcode, int reg, int arg)
{
    switch (opcode) {
    case 0x090000:	// мода
        if (cur->regvals[reg] != -1)
            cur->addrmod = arg == -1 ? -1 :
                ADDR(cur->regvals[reg] + arg);
        else
            cur->addrmod = -1;
		break;
    case 0x098000:	// мод
        if (arg != -1 && cur->regvals[reg] != -1) {
            int aex = ADDR(arg + cur->regvals[reg]);
            if (!(mflags[aex] & W_DATA))
		reason[aex] += strprintf("WTC @%05o, ", cur->addr);
            mflags[aex] |= W_DATA;
         }
        // Memory contents are not tracked
        cur->addrmod = -1;
        break;
    }
}

// Returns whether the control may pass to the next instruction
int analyze_insn (actpoint_t * cur, int right, int addr, int limit) {
    int opcode, arg1, arg2, reg;
    if (cur->addr < addr || cur->addr > limit)
        return 0;
    if (right)
        opcode = memory[cur->addr] & 0xffffff;
    else
        opcode = memory[cur->addr] >> 24;
    if (cur->addrmod == -1) {
        arg1 = arg2 = -1;
    } else {
        arg1 = ADDR((opcode & 07777) + (opcode & 0x040000 ? 070000 : 0) + cur->addrmod);
        arg2 = ADDR(opcode + cur->addrmod);
    }
    cur->addrmod = 0;
    reg = opcode >> 20;
    auto opc = getop(opcode);
    switch (opc.type) {
    case OPCODE_CALL:
        // Deals with passing control to the next instruction within
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        if (reg)
            analyze_call (cur, reg, arg2, addr, limit);
        else
            analyze_jump (cur, reg, arg2, addr, limit);
        return 0;
    case OPCODE_JUMP:
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        analyze_jump (cur, reg, arg2, addr, limit);
        return 0;
    case OPCODE_BRANCH:
        analyze_branch (cur, opc.opcode, reg, arg2, addr, limit);
        break;
    case OPCODE_ILLEGAL:
        // mflags[cur->addr] |= W_DATA;
        return 0;
    case OPCODE_STOP:
    case OPCODE_IRET:
        // Usually tranfers control outside of the program being disassembled
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        return 0;
    case OPCODE_REG1:
        analyze_regop1 (cur, opc.opcode, reg, arg1);
        break;
    case OPCODE_REG2:
        analyze_regop2 (cur, opc.opcode, reg, arg2);
        break;
    case OPCODE_ADDRMOD:
        analyze_addrmod (cur, opc.opcode, reg, arg2);
        break;
    case OPCODE_STR1:
        if (cur->regvals[reg] != -1 && arg1 != -1) {
            int aex = ADDR(arg1 + cur->regvals[reg]);
            if (!(mflags[aex] & W_DATA))
		reason[aex] += strprintf("STR1 @%05o, ", cur->addr);
            mflags[aex] |= W_DATA;
        }
        break;
    case OPCODE_RANGE:
        if (cur->regvals[reg] != -1 && arg1 != -1) {
            int aex = ADDR(arg1 + cur->regvals[reg]);
            mflags[aex] |= W_DATA;
            if (opc.opcode != 0710000 || memory[aex] != ((1LL<<48)-1))
                mflags[aex] |= W_ADDR;
        }
        goto immex;
    case OPCODE_ADDREX:
        if (cur->regvals[reg] != -1 && arg1 != -1) {
            int aex = ADDR(arg1 + cur->regvals[reg]);
            if (!(mflags[aex] & W_DATA))
		reason[aex] += strprintf("EX @%05o, ", cur->addr);
            mflags[aex] |= W_DATA;
        }
        // fall through
    case OPCODE_IMMEX: immex:
        cur->regvals[016] = -1;
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        break;
    default:
        break;
    }
    return mflags[cur->addr] & W_NOEXEC ? 0 : 1;
}

void okno(actpoint_t * cur) {
    fprintf(stderr, "Addr = %05o", cur->addr);
    for (int i = 1; i < 16; ++i) {
        if (cur->regvals[i] != -1)
            fprintf(stderr, " M%o=%05o", i, cur->regvals[i]);
    }
    fprintf(stderr, "\n");
}


/* Basic blocks are followed as far as possible first */
void analyze (uint32 entry, uint32 addr, uint32 limit)
{
    addsym ("-", W_CODE, entry);
    for (auto i : find_bases(entry))
        reachable->regvals[i.first] = i.second;
    while (reachable) {
        actpoint_t * cur = reachable;
        reachable = cur->next;
        if (mflags[cur->addr] & W_NOEXEC) {
            free(cur);
            continue;
        }
        if (mflags[cur->addr] & W_CODE) {
            // fprintf(stderr, "Already seen\n");
            free (cur);
            continue;
        }
        mflags[cur->addr] |= W_CODE;
        /* Left insn */
        if (! analyze_insn (cur, 0, addr, limit)) {
            free (cur);
            continue;
        }
        /* Right insn */
        if (analyze_insn (cur, 1, addr, limit)) {
            // Put 'cur' back with the next address
            if (++cur->addr == 0100000 || mflags[cur->addr] & W_NOEXEC) {
                // Loss of control
                free (cur);
            } else {
                cur->next = reachable;
                reachable = cur;
            }
        } else {
            free (cur);
        }
    }
}

void prbss (uint32 addr, uint32 limit)
{
    int bss = 1;
    if (mflags[addr] & W_LITERAL) {
	// Possible in case of =B'0'
	return;
    }
    while (addr + bss < limit && memory[addr+bss] == 0 && mflags[addr+bss] == 0 &&
           findsym(addr+bss)->n_value != addr+bss) {
        mflags[addr+bss] |= W_DONE;
        ++bss;
    }
    if (addr + bss != limit || hasname(addr)) {
        if (srcflag == 0) {
            printf ("%5o            \t", addr);
        }
        prsym (addr);
        printf ("\tпам\t%d\n", bss);
    }
}

void print_short_const(uint32 addr, uint32 opcode, bool left) {
    if (!srcflag) {
        printf (left ? "%5o%c" : "      ", addr, mflags[addr] & W_STARTBB ? ':' : ' ');
        prcode (addr, opcode);
        putchar ('\t');
    }
    if (left) prsym (addr);
    putchar ('\t');
    prshort(opcode, addr*2 + !left);
    putchar ('\n');
}

void
prsection (uint32 addr, uint32 limit)
{
    uint64 opcode;
    auto indent = srcflag ? "" : "\t\t\t";
    auto prevbases = &find_bases(0);
    for (; addr < limit; ++addr) {
        if (mflags[addr] & W_DONE)
            continue;
        auto curbases = &find_bases(addr);
        if (prevbases != curbases) {
            for (auto i : *prevbases) {
                printf("%s\tотмен\t(М%o)\n", indent, i.first);
            }
            for (auto i : *curbases) {
                auto base = findsym(i.second);
                auto& s = base->n_name;
                printf("%s\tупотр\t%s", indent, s.c_str());
                if (base->n_value != i.second) {
                    if (!s.empty() && s[0] != '-')
                        putchar('+');
                    printf("%d", i.second -  base->n_value);
                }
                printf("(М%o)\n", i.first);
            }
            prevbases = curbases;
        }
        if ((mflags[addr] & (W_CODE|W_DATA)) == (W_CODE|W_DATA))
            printf ("* next insn used as data\n");
        bool rel_l = nonconst(addr*2);
        bool rel_r = nonconst(addr*2+1);
        if (mflags[addr] & W_CODE) {
            opcode = memory[addr];
            if (!srcflag) {
                printf ("%5o%c", addr, mflags[addr] & W_STARTBB ? ':' : ' ');
                prcode (addr, opcode >> 24);
                putchar ('\t');
            }
            uint32 flags = prsym (addr);
            putchar ('\t');
            fputs(prinsn (addr, opcode >> 24, 0).c_str(), stdout);
            printf ("\n");
            // Do not print the non-insn part of a word
            // if it looks like a placeholder
            opcode &= 0xffffff;
            if (opcode == 02200000 && (mflags[addr+1] && W_STARTBB)) {
                auto sym = findsym(addr+1);
                if (sym->n_value != addr+1 || !sym->hasname()) {
                    printf("%s\tпам\t0\n", srcflag ? "" : "\t\t\t");
                }
                continue;
            }
            if (! (mflags[addr] & W_NORIGHT) ||
                rel_r || (opcode != 0 && opcode != 02200000)) {
                if (srcflag == 0) {
                    printf("      ");
                    prcode (addr, opcode);
                    putchar ('\t');
                }
                putchar ('\t');
                if (mflags[addr] & W_NORIGHT)
                    prshort (opcode, addr*2+1, flags);
                else
                    fputs(prinsn (addr, opcode, 1).c_str(), stdout);
                putchar ('\n');
            }
        } else if (!rel_l && !rel_r && memory[addr] == 0 && (!rflag || relocs[addr*2] == -2)) {
            prbss (addr, limit);
        } else if (rel_l || rel_r) {
            opcode = memory[addr];
            print_short_const(addr, opcode >> 24, true);
            print_short_const(addr, opcode & 0xFFFFFF, false);
        } else if (!(mflags[addr] & W_LITERAL)) {
            prconst (addr, limit);
        }
    }
}

int gettype(const std::string & str) {
    switch (str[0]) {
    case 'D': case 'd': return W_DATA;
    case 'C': case 'c': return W_CODE;
    case 'G': case 'g': return W_DATA|W_GOST;
    case 'I': case 'i': return W_DATA|W_ISO;
    case 'H': case 'h': return W_DATA|W_HEX;
    case 'L': case 'l': return W_DATA|W_LITERAL;
    case 'B': case 'b': return W_CODE|W_STARTBB;
    case 'R': case 'r': return W_DATA|W_REAL;
    case 'T': case 't': return W_DATA|W_TEXT;
    case 'U': case 'u': return W_UNSET;
    case 'A': case 'a': return W_CODE|W_NOEXEC;
    }
    return -1;
}

void
readsymtab (char *fname)
{
    std::string addr;
    std::string typestr;
    std::string name;
    int line = 1;
    bool err = false;
    std::ifstream fsym(fname);
    if (!fsym.is_open()) {
        std::cerr << "dis: failed to open " << fname << '\n';
        return;
    }
    addsym("", 0, 32768);
    addsym("", 0, 0);
    try { while (fsym >> addr >> typestr >> name) {
        std::string mod;
        std::getline(fsym, mod);
        size_t ent = mod.find("entry");
        int type = 0;
        if (ent != ~0ull) {
            size_t s = mod.find_first_not_of(" \t", ent+5);
            size_t e = s == ~0ull ? ~0ull : mod.find_first_of(" \t\n", s);
            mod = e == ~0ull ? "" : mod.substr(s, e-s);
        }
        if (typestr != "0" && (type = atoi(typestr.c_str())) == 0)
            type = gettype(typestr);
        if (type == -1) {
            err = true;
            break;
        }
        if (addr.find_first_not_of("01234567-") != std::string::npos) {
            err = true;
            break;
        }
        if (addr.find('-') == std::string::npos)
            addsym(name, type, strtol(addr.c_str(), nullptr, 8), mod);
        else {
            char * s;
            int start = strtol(addr.c_str(), &s, 8);
            int finish = strtol(s+1, nullptr, 8);
            if (start < 0 || finish < 0 || start > finish) {
                err = true;
                break;
            }
            for (; start <= finish; ++start)
                addsym(name, type, start, mod);
        }
	++line;
    } } catch (...) { err = true; }
    if (err || fsym.fail() && !fsym.eof()) {
        std::cerr << "disbesm6: error reading symbol table, line " << line << '\n';
        std::cerr << "last read: <" << addr << "> <" << typestr << "> <" << name << ">\n";
    }
}

void make_syms(uint32 addr, uint32 limit)
{
    for (; addr < limit; ++addr) {
        struct nlist * sym;
        if (mflags[addr] & W_UNSET)
            continue;
        if ((mflags[addr] & (W_STARTBB|W_CODE)) == (W_STARTBB|W_CODE)) {
            sym = findsym(addr);
            if (sym->n_value != addr) {
                char buf[8];
                sprintf(buf, "G%05o", addr & 077777); // Instead of A to avoid lat/cyr confusion
                addsym(buf, W_CODE, addr);
            }
        } else if (mflags[addr] & W_DATA) {
            sym = findsym(addr);
            if (sym->n_value != addr) {
                addsym(mflags[addr] & W_LITERAL ? "=" + literal(addr, flags(addr)) : strprintf("D%05o", addr), W_DATA, addr);
            } else if (mflags[addr] & W_LITERAL) {
		std::cerr << "Address " << strprintf("%05o", addr) << " is literal, remove its name\n";
	    }
        }
    }
}

void
disbin (char *fname)
{
    unsigned int addr;
    struct stat st;

    textfd = fopen (fname, "r");
    if (! textfd) {
        fprintf (stderr, "dis: %s not found\n", fname);
        return;
    }
    stat (fname, &st);
    addr = loadaddr;
    codelen = st.st_size / 6;
    if (!srcflag) {
        printf ("         File: %s\n", fname);
        printf ("         Type: Binary\n");
        printf ("         Code: %d (%#o) words\n", (int) st.st_size, codelen);
        printf ("      Address: %#o\n", loadaddr);
        printf ("\n");
    }
    while (!feof(textfd) && addr < 0100000) {
        memory[addr++] = freadw (textfd);
    }
    if (trim) {
        while (memory[loadaddr+codelen-1] == 0)
            --codelen;
    }
    if (loadaddr == 0) {
        ++loadaddr;
        --codelen;
    }
    prstart();
    analyze (entryaddr, loadaddr, loadaddr + codelen);
    make_syms(loadaddr, loadaddr + codelen);
    prsection (loadaddr, loadaddr + codelen);
    for (auto i : find_bases(loadaddr + codelen)) {
        if (i.second >= loadaddr + codelen)
            prsection (i.second, i.second +01000);
    }
    fputs(prequs ().c_str(), stdout);
    printf("%s\tФИНИШ\n", srcflag ? "" : "\t\t\t");
    fclose (textfd);
}

struct Module {
    FILE * fd;
    Module(FILE * f) : fd(f), chunks_read(0) {
        readHeader();
    }
    std::string debemsh(uint64 val) {
	const char * abekmhopctyx = "ABEKMHOPCTYX";
	const char * awekmnorstuh = "awekmnorstuh";
        unsigned char bytes[6];
        split_bytes(val, bytes);
        std::string s;
        for (int i = 0; i < 6; ++i) {
            uint byte = bytes[i];
            switch (byte) {
            case 0100 ... 0137:
                byte -= 040;
                break;
            case 0240 ... 0337:
                byte -= 0140;
                break;
            }
	    // Cyrillify
	    if (const char * p = index(abekmhopctyx, byte))
		byte = awekmnorstuh[p-abekmhopctyx];
            s += unicode_to_utf8 (koi7_to_unicode[byte]);
        }
        return s;
    }
    void read_chunk() {
        for (int i = 0; i < 12; ++i) {
            chunk[i] = freadw(fd);
        }
        if (++chunks_read % 85 == 0) {
            // Align to a zone boundary
            for (int i = 0; i < 4; ++i)
                (void) freadw(fd);
        }

    }
    void readHeader() {
        // Header structure:
        // 0 - unknown (seen: 1)
        // 1 - module name
        // 2 - load address
        // 3 - min reloc address
        // 4 - max reloc address
        // 5 - number of chunks
        // 6 - program length
        // 7 - (upper: ?; lower: entries)
        // 8 - (upper: ?; lower: externs)
        read_chunk();
        name = debemsh(chunk[1]);
        while (name.back() == ' ') name.pop_back();
        loadaddr = chunk[2] & 077777;
        addsym(name, 0, loadaddr);
        codelen = chunk[6] & 077777;
        chunks = chunk[5] & 077777;
        entries_cnt = chunk[7] & 077777;
        entries_chunks = chunk[7] >> 24;
        externs_cnt = chunk[8] & 077777;
        externs_chunks = chunk[8] >> 24;
    }
    uint get_addr() {
        return ((chunk[10] & 0177) << 8) | (chunk[11] & 0377);
    }
    void read_chunks() {
        int prev_addr = loadaddr;
        for (uint i = 0; i < chunks; ++i) {
            read_chunk();
            int addr  = get_addr();
            for (; prev_addr < addr; )
                relocs[(prev_addr++)*2] = -2;
            prev_addr = analyze_chunk();
        }
    }
    std::string read_entries() {
        std::string ret;
        std::vector<std::string> ents;
        for (uint i = 0; i < entries_cnt; ++i) {
            if (i % 6 == 0)
                read_chunk();
            std::string cur = debemsh(chunk[i%6*2]);
            while (cur.back() == ' ')
                cur.pop_back();
            uint64 val = chunk[i%6*2+1];
            // If the entry matches the module name, addresses must match
            if (cur == name) {
                if (val != loadaddr)
                    fprintf(stderr, "Module address mismatch, start %05o, entry %05o\n",
                            loadaddr, int(val));
                continue;
            }
            if (val & 0100000) {
                ret += strprintf("%s%s\tЭКВ\t'%o'\n",
                                 srcflag ? "" : "\t\t\t", cur.c_str(), int(val) & 077777);
                abs_ents[int(val) & 077777].push_back(cur);
            } else {
                addsym(cur, 0, val & 077777);
            }
	    ents.push_back(cur);
        }
        return ret + prlist("ВХОД", "", ents);
    }
    std::string read_externs() {
        std::string ret;
        std::map<std::string, std::vector<std::string>> extdecls;
        externs.push_back("");
        for (uint i = 0; i < externs_cnt; ++i) {
            if (i % 6 == 0)
                read_chunk();
            std::string mod = debemsh(chunk[i%6*2]);
            std::string name = debemsh(chunk[i%6*2+1]);
            bool extrd = mod.back() == '\0';
            while (!mod.empty() && (mod.back() == '\0' || mod.back() == ' '))
                mod.pop_back();
            while (!name.empty() && (name.back() == '\0' || name.back() == ' '))
                name.pop_back();
            // Assuming all externs are unique so far
            externs.push_back(extrd ? name+mod : name);
            if (!extrd) {
                extdecls[mod].push_back(name);
            }
//            printf("Extern %d: %s\n", i+1, externs.back().c_str());
        }
        for (auto & elt : extdecls) {
            std::reverse(elt.second.begin(), elt.second.end());
            ret += prlist("ВНЕШ", elt.first, elt.second);
        }
	return ret;
    }
    // Returns the first address which does not belong to the chunk
    int analyze_chunk() {
        uint addr = get_addr();
        addr *= 2;
        FreeExpr free;
        bool in_continuation = false;
        for (uint i = 0; i < 20; ++i) {
            uint64 cmd = (chunk[i/2] >> (i % 2 ? 0 : 24)) & 0xFFFFFF;
            int arg1 = (cmd & 07777) + (cmd & 0x040000 ? 070000 : 0);
            int arg2 = cmd & 077777;
            bool long_addr = flag(i, 3);
            int arg = long_addr ? arg2 : arg1;
            bool is_ext = flag(i, 4);
            bool is_abs = flag(i, 2);
            bool has_cont = flag(i, 1);
//            printf("%05o Looking at %s\t\tflags %d %d %d %d\n", addr/2,
//                   prinsn(addr/2, cmd, addr & 1).c_str(), has_cont, is_abs, long_addr, is_ext);
            if (!in_continuation) {
                if (addr % 2 == 0 && cmd == 0 && !has_cont && long_addr && is_ext) {
                    // Starting a BSS region, the chunk is terminated
                    return addr/2;
                }
                // True instruction
                if (addr % 2)
                    memory[addr/2] = (memory[addr/2] & 0xFFFFFF000000LL) | cmd;
                else
                    memory[addr/2] = cmd << 24;
                if (!has_cont) {
                    // Without externs
                    uint opcode = (cmd >> 12) & 0377;
                    bool is_asn = opcode == 036;
                    bool is_ecode = (opcode >= 050 && opcode <= 057) || (opcode == 062 || opcode == 063);
		    bool is_reg1 = opcode >= 040 && opcode <= 045;
                    if (is_abs && !is_asn && !is_ecode && !is_reg1)
                        freevars[addr].push_back(FreeElt('+', 'A', arg));
                    relocs[addr] = is_abs ? 0 : long_addr ? 2 : 1;
                } else if (has_cont && is_abs)
                    relocs[addr] = long_addr ? 2 : 1;
                free.clear();
            } else {
                if (!is_abs) relocs[addr] = 1 + long_addr;
                free.push_back(FreeElt(char((cmd >> 16)-040), is_ext ? 'E' : is_abs ? 'A' : 'R', arg2));
            }
            in_continuation = has_cont;
            if (!has_cont) {
                // No more continuation
                if (!free.empty())
                    freevars[addr] = free;
                ++addr;
            }
        }
        return addr/2;
    }
    bool flag(int cmdnum, int flagnum) {
        uint32 mask = 0;
        switch (flagnum) {
        case 1:                 // 1: has continuation
            mask = (chunk[10] >> 28) & 0xFFFFF;
            break;
        case 2:                 // 1: offset is absolute
            mask = (chunk[10] >> 8) & 0xFFFFF;
            break;
        case 3:                 // 1: long address instr
            mask = (chunk[11] >> 28) & 0xFFFFF;
            break;
        case 4:                 // 1: extern ref
            mask = (chunk[11] >> 8) & 0xFFFFF;
            break;
        }
        return (mask >> (19-cmdnum)) & 1;
    }
    uint64 chunk[12];           // scratch
    std::string name;
    uint loadaddr;
    uint codelen;
    uint chunks;
    uint entries_cnt, entries_chunks;
    uint externs_cnt, externs_chunks;
    uint chunks_read;
};

// Reads BEMSH modules
void
disobj (char *fname)
{
    textfd = fopen (fname, "r");
    if (! textfd) {
        fprintf (stderr, "disbesm6: %s not found\n", fname);
        exit(1);
    }

    Module m(textfd);
    loadaddr = m.loadaddr;
    codelen = m.codelen;

    if (!srcflag) {
        printf ("       Module: %s\n", m.name.c_str());
        printf ("         Type: Object\n");
        printf ("         Code: %#o words\n", codelen);
        printf ("      Address: %#o\n", loadaddr);
        printf ("      Entries: %d\n", m.entries_cnt);
        printf ("      Externs: %d\n", m.externs_cnt);
        printf ("\n");
    }
    m.read_chunks();
    auto ents = m.read_entries();
    auto exts = m.read_externs();
    prstart();
    analyze (entryaddr, loadaddr, loadaddr + codelen);
    make_syms(loadaddr, loadaddr + codelen);
    prsection (loadaddr, loadaddr + codelen);
    for (auto i : find_bases(loadaddr + codelen)) {
        if (i.second >= loadaddr + codelen)
            prsection (i.second, i.second +01000);
    }
    fputs(prequs ().c_str(), stdout);
    fputs(ents.c_str(), stdout);
    fputs(exts.c_str(), stdout);
    printf("%s\tФИНИШ\n", srcflag ? "" : "\t\t\t");
    fclose (textfd);
}

int
main (int argc, char **argv)
{
    char *cp;
    bflag = 1;
    int opt, addr;
    while ((opt = getopt(argc, argv, "rbsta:e:R:n:vp")) != -1) {
        switch (opt) {
            case 'r':   /* -r: disassemble object file */
                rflag++;
                break;
            case 'b':	/* -b: disassemble binary file */
                bflag++;
                break;
            case 's':
                srcflag = 1;
                break;
            case 't':
                trim = 1;
                break;
            case 'a':       /* -aN: load address */
                loadaddr = 0;
                cp = optarg;
                while (*cp >= '0' && *cp <= '7') {
                    loadaddr <<= 3;
                    loadaddr += *cp - '0';
                    ++cp;
                }
                break;
            case 'e':       /* -eN: entry address */
                cp = optarg;
                addr = 0;
                while (*cp >= '0' && *cp <= '7') {
                    addr <<= 3;
                    addr += *cp - '0';
                    ++cp;
                }
                if (entryaddr)
                    add_actpoint(addr);
                else
                    entryaddr = addr;
                break;
            case 'n':
                readsymtab(optarg);
                break;
            case 'R': {	/* -RN=x: forced base reg/addr */
                unsigned basereg = 0, baseaddr = 0;
                cp = optarg;
                while (*cp >= '0' && *cp <= '7') {
                    basereg <<= 3;
                    basereg += *cp - '0';
                    ++cp;
                }
                if (basereg == 0 || basereg > 017) {
                    fprintf(stderr, "Bad base reg %o, need 1 <= R <= 017\n", basereg);
                    exit(1);
                }
                if (*cp != '=') {
                    fprintf(stderr, "Bad format for base reg, need -RN=x\n");
                    exit(1);
                }
                ++cp;
                while (*cp >= '0' && *cp <= '7') {
                    baseaddr <<= 3;
                    baseaddr += *cp - '0';
                    ++cp;
                }
                bases[loadaddr][basereg] = ADDR(baseaddr);
            } break;
            case 'v':
                verbose = 1;
                break;
            case 'p':
                pascal = 1;
                break;
        default:
            fprintf (stderr, "Usage: disbesm6 [-r] [-b] [-aN] [-eN] [-nSymtab] file\n");
            return (1);
        }
    }
    if (optind != argc-1) {
        fprintf (stderr, "Usage: disbesm6 [-r] [-b] [-aN] [-eN] [-nSymtab] file\n");
        return (1);
    }
    if (rflag)
        disobj (argv[optind]);
    else
        disbin (argv[optind]);
    if (verbose) {
        for (auto it : reason) {
            printf("%05o: %s\n", it.first, it.second.c_str());
        }
    }
    return (0);
}
