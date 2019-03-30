
import sys

def dbg_print(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def reg_num(reg):
    if reg[0] != 'r':
        print("invalid register", reg)
        return None
    n = int(reg[1:])
    if n >= 0 and n < 16:
        return n
    else:
        print("invalid register", reg)
        return None

def num(num):
    if num.startswith("0x") or num.startswith("-0x"):
        return int(num, 16)
    elif num.endswith("h"):
        return int(num[:-1], 16)
    elif num.startswith("0o") or num.startswith("-0o"):
        return int(num, 8)
    elif num.startswith("0b") or num.startswith("-0b"):
        return int(num, 2)
    elif num.endswith("b"):
        return int(num[:-1], 2)
    else:
        return int(num)

def ntb(number):
    dbg_print(number, bin(number))
    return int.to_bytes(number, 2, "big")

def bound(n, max_):
    if n >= 0 and n < max_:
        return n
    else:
        print("bad bound: needed 0 <=", n, "<", max_)
        return None

TWO_OPS = {
    'add': 1,
    'sub': 2,
    'or': 3,
    'nor': 4,
    'and': 5,
    'nand': 6,
    'xor': 7,
    'xnor': 8,
    'adc': 9,
    'sbb': 10,
    'cmp': 11,
}

JUMP_OPS = {
    'ja': 1, 'jnbe': 1,
    'jae': 2, 'jnb': 2, 'jnc': 2,
    'jb': 3, 'jnae': 3, 'jc': 3,
    'jbe': 4, 'jna': 4,
    'jg': 5, 'jnle': 5,
    'jge': 6, 'jnl': 6,
    'jl': 7, 'jnge': 7,
    'jle': 8, 'jng': 8,
    'jeq': 9, 'je': 9,
    'jne': 10,
    'jo': 11,
    'jno': 12,
    'jmp': 13,
}

def place_bits(parts):
    i_value = 0
    for part in parts:
        value, offset = part
        if value < 0:
            value = ~value
        i_value += (value << offset)


def assemble(instruction):
    tokens = instruction.replace(',', '').split()
    dbg_print(tokens)

    op = tokens[0]

    if op == "ld":
        d = reg_num(tokens[1])
        a = reg_num(tokens[2])
        return ntb((0b0100 << 12) + (d << 8) + (a << 4))
    elif op == "st":
        d = reg_num(tokens[2])
        a = reg_num(tokens[1])
        return ntb((0b0101 << 12) + (d << 8) + (a << 4))
    elif op == "ldi":
        d = reg_num(tokens[1])
        v = num(tokens[2])
        if v > -128 and v < 128:
            if v < 0:
                v = 256 + v
            return ntb((0b1000 << 12) + (d << 8) + v)
        elif (v > -32768 and v < 65536):
            return ntb((0b1001 << 12) + (d << 8)) + ntb(v)
        else:
            dbg_print("illegal ldi value, must be between -32767 and 65535")
            exit(1)
    elif op == "stop":
        return ntb(0)
    elif op in TWO_OPS:
        main_op = 0b0000
        o = TWO_OPS[op]
        d = reg_num(tokens[1])
        if tokens[2][0] == 'r':
            a = reg_num(tokens[2])
        else:
            dbg_print("immidiates not yet supported in 2ops")
            exit(1)

        return ntb((main_op << 12) + (o << 8) + (d << 4) + a)
    elif op in JUMP_OPS:
        o = JUMP_OPS[op]
        if tokens[1][0] == 'r':
            d = reg_num(tokens[1])
            return ntb((0b0001 << 12) + (o << 4) + d)
        else:
            d = num(tokens[1])
            if d < -127 or d > 127:
                dbg_print("immidiate jmp offset too big:", d)
                exit(1)
            if d < 0:
                d = 256 + d
            return ntb((0b0001 << 12) + (o << 8) + d)
    elif op == "mov":
        d = reg_num(tokens[1])
        a = reg_num(tokens[2])
        return ntb((0b1011 << 12) + (d << 8) + (a << 4))
    # elif op == "prbin":
    #     r = reg_num(tokens[1])
    #     return ntb((0b1111 << 12) + (0 << 4) + r)
    # elif op == "prhex":
    #     r = reg_num(tokens[1])
    #     return ntb((0b1111 << 12) + (1 << 4) + r)
    # elif op == "prdec":
    #     r = reg_num(tokens[1])
    #     return ntb((0b1111 << 12) + (2 << 4) + r)
    else:
        dbg_print("invalid opcode:", op)
        exit(1)

def prbin(number):
    return bin(number)[2:].zfill(8)

def main():
    if len(sys.argv) < 2:
        raise Exception("no argument")
    fl = sys.argv[1]
    asm = []
    with open(fl) as f:
        for line in f:
            instr = line.split(';')[0].strip()
            if len(instr) == 0:
                continue
            asm.append((instr, assemble(instr)))

    for instr in asm:
        l, n = instr
        for byte in n:
            print(hex(byte)[2:], end=" ")
        print("//", end=" ")
        for byte in n:
            print(prbin(byte), end=" ")
        print(l)
        
if __name__ == "__main__":
    main()

