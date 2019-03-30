
class Register(object):
    def __init__(self, num):
        self.num = num

class Raw(object):
    def __init__(self, bits, num):
        self.bits = bits
        self.num = num

def Num(is_valid):
    class NumV(object):
        is_valid = is_valid
        def __init__(self, value):
            if is_valid(value):
                self.value = value
            else:
                raise Exception("invalid value")
    return NumV

def FourBit(num):
    return num >= -8 and num < 8
def EightBit(num):
    return num >= -128 and num < 128

instructions = [
    [ ["stop"], [Raw(16, 0)] ],
    # 1op
    [ ["not",  Register], [Raw(4, 0), Raw(4, 0), Raw(4, 1), Register] ],
    [ ["inv",  Register], [Raw(4, 0), Raw(4, 0), Raw(4, 2), Register] ],
    [ ["push", Register], [Raw(4, 0), Raw(4, 0), Raw(4, 3), Register] ],
    [ ["pop",  Register], [Raw(4, 0), Raw(4, 0), Raw(4, 4), Register] ],
    [ ["inc",  Register], [Raw(4, 0), Raw(4, 0), Raw(4, 5), Register] ],
    [ ["dec",  Register], [Raw(4, 0), Raw(4, 0), Raw(4, 6), Register] ],
    [ ["call", Register], [Raw(4, 0), Raw(4, 0), Raw(4, 7), Register] ],

    # 2op
    [ ["add",  Register, Register], [Raw(4, 0), Raw(4, 1), Register, Register] ],
    [ ["sub",  Register, Register], [Raw(4, 0), Raw(4, 2), Register, Register] ],
    [ ["or",   Register, Register], [Raw(4, 0), Raw(4, 3), Register, Register] ],
    [ ["nor",  Register, Register], [Raw(4, 0), Raw(4, 4), Register, Register] ],
    [ ["and",  Register, Register], [Raw(4, 0), Raw(4, 5), Register, Register] ],
    [ ["nand", Register, Register], [Raw(4, 0), Raw(4, 6), Register, Register] ],
    [ ["xor",  Register, Register], [Raw(4, 0), Raw(4, 7), Register, Register] ],
    [ ["xnor", Register, Register], [Raw(4, 0), Raw(4, 8), Register, Register] ],
    [ ["adc",  Register, Register], [Raw(4, 0), Raw(4, 9), Register, Register] ],
    [ ["sbb",  Register, Register], [Raw(4, 0), Raw(4, 10), Register, Register] ],
    [ ["cmp",  Register, Register], [Raw(4, 0), Raw(4, 11), Register, Register] ],

    # jumps
    [ ["ja",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 1)] ],
    [ ["jnbe", Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 1)] ],
    [ ["jae",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 2)] ],
    [ ["jnb",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 2)] ],
    [ ["jnc",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 2)] ],
    [ ["jb",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 3)] ],
    [ ["jnae", Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 3)] ],
    [ ["jc",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 3)] ],
    [ ["jbe",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 4)] ],
    [ ["jna",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 4)] ],
    [ ["jg",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 5)] ],
    [ ["jnle", Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 5)] ],
    [ ["jge",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 6)] ],
    [ ["jnl",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 6)] ],
    [ ["jl",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 7)] ],
    [ ["jnge", Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 7)] ],
    [ ["jle",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 8)] ],
    [ ["jng",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 8)] ],
    [ ["jeq",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 9)] ],
    [ ["jne",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 10)] ],
    [ ["jo",   Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 11)] ],
    [ ["jno",  Register], [Raw(4, 1), Raw(4, 0), Register, Raw(4, 12)] ],

    [ ["ja",   Num(EightBit)], [Raw(4, 1), Raw(4, 1), Immidiate8] ],
    [ ["jnbe", Num(EightBit)], [Raw(4, 1), Raw(4, 1), Immidiate8] ],
    [ ["jae",  Num(EightBit)], [Raw(4, 1), Raw(4, 2), Immidiate8] ],
    [ ["jnb",  Num(EightBit)], [Raw(4, 1), Raw(4, 2), Immidiate8] ],
    [ ["jnc",  Num(EightBit)], [Raw(4, 1), Raw(4, 2), Immidiate8] ],
    [ ["jb",   Num(EightBit)], [Raw(4, 1), Raw(4, 3), Immidiate8] ],
    [ ["jnae", Num(EightBit)], [Raw(4, 1), Raw(4, 3), Immidiate8] ],
    [ ["jc",   Num(EightBit)], [Raw(4, 1), Raw(4, 3), Immidiate8] ],
    [ ["jbe",  Num(EightBit)], [Raw(4, 1), Raw(4, 4), Immidiate8] ],
    [ ["jna",  Num(EightBit)], [Raw(4, 1), Raw(4, 4), Immidiate8] ],
    [ ["jg",   Num(EightBit)], [Raw(4, 1), Raw(4, 5), Immidiate8] ],
    [ ["jnle", Num(EightBit)], [Raw(4, 1), Raw(4, 5), Immidiate8] ],
    [ ["jge",  Num(EightBit)], [Raw(4, 1), Raw(4, 6), Immidiate8] ],
    [ ["jnl",  Num(EightBit)], [Raw(4, 1), Raw(4, 6), Immidiate8] ],
    [ ["jl",   Num(EightBit)], [Raw(4, 1), Raw(4, 7), Immidiate8] ],
    [ ["jnge", Num(EightBit)], [Raw(4, 1), Raw(4, 7), Immidiate8] ],
    [ ["jle",  Num(EightBit)], [Raw(4, 1), Raw(4, 8), Immidiate8] ],
    [ ["jng",  Num(EightBit)], [Raw(4, 1), Raw(4, 8), Immidiate8] ],
    [ ["jeq",  Num(EightBit)], [Raw(4, 1), Raw(4, 9), Immidiate8] ],
    [ ["jne",  Num(EightBit)], [Raw(4, 1), Raw(4, 10), Immidiate8] ],
    [ ["jo",   Num(EightBit)], [Raw(4, 1), Raw(4, 11), Immidiate8] ],
    [ ["jno",  Num(EightBit)], [Raw(4, 1), Raw(4, 12), Immidiate8] ],

    [ ["ld", Register, IndirectRegsiter], [Raw(4, 4), Register, Register, Raw(4, 0)] ],
    [ ["st", IndirectRegister, Regsiter], [Raw(4, 5), Register, Register, Raw(4, 0)] ],

    [ ["ld", Register, IndirectRegsiter], [Raw(4, 4), Register, Register, Raw(4, 0)] ],
    [ ["st", IndirectRegister, Regsiter], [Raw(4, 5), Register, Register, Raw(4, 0)] ],

    [ ["ldi", Register, Num(EightBit)], [Raw(4, 8), Register, Immidiate8] ],
    [ ["ldi", Register, Num(SixteenBit)], [Raw(4, 9), Register, Raw(8, 0)] ], # + next word

    [ ["mov", Register, Register], [Raw(4, 11), Register, Register, Raw(4, 0)] ], # + pages
]
        
