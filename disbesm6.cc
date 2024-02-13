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
OPCODE_ADDREX,		/* Э64, Э70, ... */
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
  { "Э63",	0x033000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э64",	0x034000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э65",	0x035000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э66",	0x036000, 0x0bf000, OPCODE_IMMEX,	BASIC },
  { "Э67",	0x037000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э70",	0x038000, 0x0bf000, OPCODE_ADDREX,	BASIC },
  { "Э71",	0x039000, 0x0bf000, OPCODE_ADDREX,	BASIC },
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
int bflag, rflag, srcflag, trim;
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
#define W_DONE		(1<<31)

typedef struct actpoint_t {
	int addr, addrmod;
	int regvals[16];
	struct actpoint_t * next;
} actpoint_t;

actpoint_t * reachable = 0;

uint64 memory[32768];
uint32 mflags[32768];
std::vector<std::string> externs;

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
    mflags[val] |= type & (W_UNSET|W_STARTBB|W_NOEXEC);
    if (type & W_STARTBB)
        mflags[val] |= type & W_DATA;
    if ((type & W_CODE) && name == "-")
        return;
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

    printed = 0;
    for (auto p : names[addr]) {
        flags |= p.n_type;
        if (p.hasname() && !(flags & W_UNSET)) {
            if (printed) {
                printf("\tноп\n\t\t\t");
            }
            // Do not re-print the start name
            if (printed || addr != loadaddr)
                printf ("%s", p.n_name.c_str());
            ++printed;
        }
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
                strprintf("'%o'", val);
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

void prext(const std::string& mod, std::vector<std::string>& list) {
    while (list.size()) {
        std::string s = mod + "\tВНЕШ";
        char delim = '\t';
        size_t len = utflen(s);
        while (list.size() && (len+1 + utflen(list.back()) <= 60)) {
            s += delim;
            s += list.back();
            len += utflen(list.back())+1;
            list.pop_back();
            delim = ',';
        }
        printf("%s\n", s.c_str());
    }
}

void prequs ()
{
    struct nlist *p;
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
        prext(elt.first, elt.second);
    }
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

/*
 * Print instruction code.
 * Return 0 on error.
 */
void
prcode (uint32 memaddr, uint32 opcode)
{
    int i;

    for (i=0; op[i].mask; i++)
        if ((opcode & op[i].mask) == op[i].opcode)
            break;
    switch (op[i].type) {
    case OPCODE_STR1:
    case OPCODE_ADDREX:
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
properand (uint32 instaddr, uint32 reg, uint32 offset, int explicit0)
{
    if (offset == 0 && freevars.count(instaddr)) {
        return freevars[instaddr].print() + (reg ? prreg (reg, true) : "");
    }
    bool inrange = offset >= loadaddr && offset < loadaddr + codelen;
    bool verysmall = offset < 020 || offset >= 077700;
    auto b = find_bases(instaddr/2);
    bool have_base = b.count(reg);
    bool base_modif = explicit0 && have_base;
    int data_offset_as_number = !inrange || (verysmall && reg != 0 && !have_base);
    int offset_as_number = !inrange || reg != 0 && !have_base && (offset < 020 || offset >= 077700);
    if (!base_modif && have_base) {
        offset += b[reg];
	offset &= 077777;
    }

    std::string ret;
    bool rel =
        (reloc(instaddr) > 0 &&
         !(ret = praddr (offset, true, false, false)).empty()) ||
        (have_base ? offset >= loadaddr && offset < loadaddr + codelen : true) &&
        !(ret = praddr (offset, false, data_offset_as_number, offset_as_number)).empty();
    if (have_base && !rel && b[reg] < loadaddr && offset < loadaddr && offset >= b[reg]) {
        auto sym = findsym(offset);
        if (sym != &dummy) {
            return praddr (offset, false, data_offset_as_number, offset_as_number) +
            "-base" +
            prreg (reg, true);
        }
    }
    if (!rel && !base_modif && have_base) {
        offset -= b[reg];
        offset &= 077777;
    }
    if (!rel) {
        if(offset) {
            if (offset < 040)
                ret = std::to_string(offset);
            else if (offset >= 077700)
                ret = strprintf("%d", offset-0100000);
            else
                ret = strprintf("'%o'", offset);
        } else if (explicit0)
            ret = '0';
    }
    if (reg && (base_modif || !have_base || !rel)) {
        ret += prreg (reg, true);
    }
    return ret;
}

std::string
prinsn (uint32 memaddr, uint32 opcode, int right)
{
    int i;
    std::string ret;
    int reg = opcode >> 20;
    int arg1 = (opcode & 07777) + (opcode & 0x040000 ? 070000 : 0);
    int arg2 = opcode & 077777;

    for (i=0; op[i].mask; i++)
        if ((opcode & op[i].mask) == op[i].opcode)
            break;
    opcode_e type = op[i].type;
    if (op[i].opcode == 0xa0000 && reg == 0) {
        type = OPCODE_IMM;
    }
    ret = op[i].name;
    if (!strchr(op[i].name, '\t'))
        ret += AFTER_INSTRUCTION;
    if (freevars.count(memaddr*2+right)) {
        ret += freevars[memaddr*2+right].print();
        if (reg) {
            ret += prreg (reg, true);
        }
        return ret;
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
    case OPCODE_STR1:
        ret += properand (memaddr*2+right, reg, arg1, 0);
        break;
    case OPCODE_REG2:
    case OPCODE_STR2:
    case OPCODE_ADDRMOD:
        ret += properand (memaddr*2+right, reg, arg2, op[i].type == OPCODE_REG2);
        break;
    case OPCODE_BRANCH:
    case OPCODE_JUMP:
    case OPCODE_IRET:
    case OPCODE_CALL:
        ret += properand (memaddr*2+right, reg, arg2, 0);
        break;
    case OPCODE_IMMEX:
    case OPCODE_IMM:
    case OPCODE_STOP: {
        bool need0 = false;
        if (strchr(op[i].name, '\t'))
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
    return (s < 020) || (s == 025) || (s >= 040 && s < 0115);
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

void prshort(uint32 val, int cmdaddr) {
    bool good_gost = val && is_good_gost(val & 0377) && is_good_gost((val >> 8) & 0377) && is_good_gost((val >> 16) & 0377);
    bool good_addr = val && maybe_addr(val);
    int reg = val >> 20;
    bool data = !nonconst(cmdaddr);
    if (data) {
        if (good_gost) {
            std::string s = gost_to_utf8((val >> 16) & 0377);
            s += gost_to_utf8((val >> 8) & 0377);
            s += gost_to_utf8(val & 0377);
            printf("конк\tп'%s'", s.c_str());
        } else if (!rflag && good_addr) {
            printf("конк\tA(%s)\tвозм.", praddr(val, true, false, false).c_str());
        } else {
            printf("конк\tв'%08o'", val);
        }
    } else {
        int rel = reloc(cmdaddr);
        if (rel == 1) {
            printf("кк\t'%o',%s", (val >> 12) & 077,
                   properand(cmdaddr, reg, (val & 07777) + (val & 01000000 ? 070000 : 0), true).c_str());
        } else if (rel == 2 && good_addr)
            printf("конк\tA(%s)", praddr(val, true, false, false).c_str());
        else 
            printf("дк\t'%o',%s", (val >> 15) & 037, properand(cmdaddr, reg, val & 077777, true).c_str());        
    }
}

bool printable(uint32 byte) {
    return byte < 0140 && byte != 0136 && byte != 0115;
}

void prconst (uint32 addr, uint32 limit)
{
    int flags = 0;
    do {
        unsigned char bytes[6];
        int i;
        int good_gost;
        if (srcflag == 0) {
            printf ("%5o %016llo", addr, memory[addr]);
            putchar ('\t');
        }
        flags |= prsym (addr);
        split_bytes(addr, bytes);
        good_gost = count_good(bytes, is_good_gost);
        bool rel_l = nonconst(addr*2);
        bool rel_r = nonconst(addr*2+1);

        if (!rel_l && !rel_r && flags & W_REAL) {
            uint64 val = memory[addr];
            bool denorm = !(((val >> 39) ^ (val >> 40)) & 1);
            double d = ldexp((long long)val << 23, (val >> 41) - 64 - 63);
            printf ("\tконд\tе'%.12g' %s\n", d, denorm ? "denorm" : "");
        } else if (!rel_l && !rel_r && (flags & W_GOST || good_gost == 6)) {
            int i;
            bool bad_seen = false;
            bool print_all_bytes = false;
            printf ("\tконд\t");
            if (good_gost >= 4) {
                std::string s;
                for (i = 0; i < 6; ++i) {
                    if (printable(bytes[i]))
                        s += gost_to_utf8 (bytes[i]);
                    else { bad_seen = true; s += '0'; }
                }
                if (good_gost == 6 || s != "000000")
                    if (s == "000000")
                        printf("в'0'");
                    else
                        printf("п'%s'", s.c_str());
            } else
                print_all_bytes = true;
            if (bad_seen || print_all_bytes) {
                for (i = 0; i < 6; ++i) {
                    if (print_all_bytes || !printable(bytes[i])) {
                        if (bytes[i] != 0) {
                            if (i != 5) printf("м%d", 40-i*8);
                            printf("в'%03o'", bytes[i]);
                        }
                    }
                }
            }
            printf("\n");
        } else {
            uint32 left = memory[addr] >> 24;
            uint32 right = memory[addr] & 0xFFFFFF;
            bool left_addr = left && (rel_l ||  maybe_addr(left));
            bool right_addr = right && (rel_r || maybe_addr(right));
            if (!rel_l && !rel_r && !left_addr && !right_addr) {
                int good_iso, good_iso_with_parity;
                printf ("\tконд\tв'%016llo'", memory[addr]);
                good_iso = count_good(bytes, is_good_iso);
                good_iso_with_parity = count_good(bytes, is_good_iso_with_even_parity);
                if (good_iso == 6) {
                    std::string s;
                    for (i = 0; i < 6; ++i) {
                        s += unicode_to_utf8 (koi7_to_unicode[bytes[i]]);
                    }
                    printf(" ISO '%s'", s.c_str());
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
                    if (fake <= 3)
                        printf(" PARITY ISO '%s'", s.c_str());
                }
                putchar('\n');
            } else if (rel_l || rel_r) {
                putchar('\t'); prshort(left, addr*2); putchar('\n');
                printf(srcflag ? "" : "\t\t\t");
                putchar('\t'); prshort(right, addr*2+1); putchar('\n');
            } else if (left == 0 && right_addr) {
                printf("\tконд\tA(%s)\tвозм.\n", findsym(right)->n_name.c_str());
            } else {
                if (left_addr) {
                    printf("\tконк\tA(%s)\tвозм.\n", findsym(left)->n_name.c_str());                    
                } else {
                    printf("\tконк\tв'%08o'\n", left);
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
        mflags[arg] |= W_STARTBB;
    }
    copy_actpoint (cur, cur->addr + 1);
    // Assuming no tricks are played; usually does not hurt,
    // used in Pascal-Autocode
    if (reg)
        reachable->regvals[reg] = cur->addr + 1;
}

void analyze_jump (actpoint_t * cur, int reg, int arg, int addr, int limit)
{
    if (arg != -1 && cur->regvals[reg] != -1) {
        arg = ADDR(arg + cur->regvals[reg]);
        if (arg >= addr && arg < limit) {
            copy_actpoint (cur, arg);
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
            mflags[arg] |= W_STARTBB;
        }
    } else if (cur->regvals[reg] != -1) {
        arg = ADDR(arg + cur->regvals[reg]);
        if (arg >= addr && arg < limit && !(mflags[arg] & W_UNSET)) {
            copy_actpoint (cur, arg);
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
        if (arg != -1 && cur->regvals[reg] != -1)
            mflags[ADDR(cur->regvals[reg] + arg)] |= W_DATA;
        // Memory contents are not tracked
        cur->addrmod = -1;
        break;
    }
}

// Returns whether the control may pass to the next instruction
int analyze_insn (actpoint_t * cur, int right, int addr, int limit) {
    int opcode, arg1, arg2, reg, i;
    if (cur->addr < addr || cur->addr > limit)
        return 0;
    if (right)
        opcode = memory[cur->addr] & 0xffffff;
    else
        opcode = memory[cur->addr] >> 24;
    for (i=0; op[i].mask; i++)
        if ((opcode & op[i].mask) == op[i].opcode)
            break;
    if (cur->addrmod == -1) {
        arg1 = arg2 = -1;
    } else {
        arg1 = ADDR((opcode & 07777) + (opcode & 0x040000 ? 070000 : 0) + cur->addrmod);
        arg2 = ADDR(opcode + cur->addrmod);
    }
    cur->addrmod = 0;
    reg = opcode >> 20;
    switch (op[i].type) {
    case OPCODE_CALL:
        // Deals with passing control to the next instruction within
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        analyze_call (cur, reg, arg2, addr, limit);
        return 0;
    case OPCODE_JUMP:
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        analyze_jump (cur, reg, arg2, addr, limit);
        return 0;
    case OPCODE_BRANCH:
        analyze_branch (cur, op[i].opcode, reg, arg2, addr, limit);
        return 1;
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
        analyze_regop1 (cur, op[i].opcode, reg, arg1);
        return 1;
    case OPCODE_REG2:
        analyze_regop2 (cur, op[i].opcode, reg, arg2);
        return 1;
    case OPCODE_ADDRMOD:
        analyze_addrmod (cur, op[i].opcode, reg, arg2);
        return 1;
    case OPCODE_STR1:
        if (cur->regvals[reg] != -1 && arg1 != -1)
            mflags[ADDR(arg1 + cur->regvals[reg])] |= W_DATA;
        return 1;
    case OPCODE_ADDREX:
        if (cur->regvals[reg] != -1 && arg1 != -1)
            mflags[ADDR(arg1 + cur->regvals[reg])] |= W_DATA;
        // fall through
    case OPCODE_IMMEX:
        cur->regvals[016] = -1;
        if (!right)
            mflags[cur->addr] |= W_NORIGHT;
        return 1;
    default:
        return 1;
    }
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
                    if (!s.empty())
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
            prsym (addr);
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
                (opcode != 0 && opcode != 02200000)) {
                if (srcflag == 0) {
                    printf("      ");
                    prcode (addr, opcode);
                    putchar ('\t');
                }
                putchar ('\t');
                if (mflags[addr] & W_NORIGHT)                    
                    prshort (opcode, addr*2+1);
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
        } else {
            prconst (addr, limit);
        }
    }
}

int gettype(const std::string & str) {
    switch (str[0]) {
    case 'D': case 'd': return W_DATA;
    case 'C': case 'c': return W_CODE;
    case 'G': case 'g': return W_DATA|W_GOST;
    case 'B': case 'b': return W_CODE|W_STARTBB;
    case 'R': case 'r': return W_REAL;
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
    while (fsym >> addr >> typestr >> name) {
        std::string mod;
        std::getline(fsym, mod);
        size_t ent = mod.find("entry");
        int type = 0;
        if (ent != ~0ull) {
            size_t s = mod.find_first_not_of(" \t", ent+5);
            size_t e = mod.find_first_of(" \t\n", s);
            mod = mod.substr(s, e-s);
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
    }
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
                sprintf(buf, "G%05o", addr); // Instead of A to avoid lat/cyr confusion
                addsym(buf, W_CODE, addr);
            }
        } else if (mflags[addr] & W_DATA) {
            sym = findsym(addr);
            if (sym->n_value != addr) {
                char buf[8];
                sprintf(buf, "D%05o", addr);
                addsym(buf, W_DATA, addr);
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
    prstart();
    analyze (entryaddr, loadaddr, loadaddr + codelen);
    make_syms(loadaddr, loadaddr + codelen);
    prsection (loadaddr, loadaddr + codelen);
    for (auto i : find_bases(loadaddr + codelen)) {
        if (i.second >= loadaddr + codelen)
            prsection (i.second, i.second +01000);
    }
    prequs ();
    printf("%s\tФИНИШ\n", srcflag ? "" : "\t\t\t");
    fclose (textfd);
}

struct Module {
    FILE * fd;
    Module(FILE * f) : fd(f), chunks_read(0) {
        readHeader();        
    }
    std::string debemsh(uint64 val) {
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
    void read_entries() {
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
                            loadaddr, val);
                continue;
            }
            if (val & 0100000) {
                printf("%s%s\tЭКВ\t'%o'\n", srcflag ? "" : "\t\t\t", cur.c_str(), val & 077777);
            } else {
                addsym(cur, 0, val & 077777);
            }
            printf("%s\tВХОДН\t%s\n", srcflag ? "" : "\t\t\t", cur.c_str());
        }
    }
    void read_externs() {
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
            while (name.back() == '\0' || name.back() == ' ')
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
            prext(elt.first, elt.second);
        }
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
                    if (is_abs && !is_asn && !is_ecode)
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
    m.read_entries();
    m.read_externs();
    prstart();
    analyze (entryaddr, loadaddr, loadaddr + codelen);
    make_syms(loadaddr, loadaddr + codelen);
    prsection (loadaddr, loadaddr + codelen);
    for (auto i : find_bases(loadaddr + codelen)) {
        if (i.second >= loadaddr + codelen)
            prsection (i.second, i.second +01000);
    }
    prequs ();
    printf("%s\tФИНИШ\n", srcflag ? "" : "\t\t\t");
    fclose (textfd);
}

int
main (int argc, char **argv)
{
    char *cp;
    bflag = 1;
    int opt, addr;
    while ((opt = getopt(argc, argv, "rbsta:e:R:n:")) != -1) {
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
    return (0);
}
