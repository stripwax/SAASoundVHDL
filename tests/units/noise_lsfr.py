"""Simple replication of the LSFR polynomial and outputs in Python, for validation"""

def xor(bit1, bit2):
    if bit1 != bit2:
        return "1"
    else:
        return "0"
    

bits = list("000000000000000001")
for j in range(5):
    for i in range(40):
        lsb = bits[-1]
        print(lsb, end='')
        bits = ["0"] + bits[:-1]
        bits[0] = xor(bits[0], lsb)
        bits[7] = xor(bits[7], lsb)
        #print(bits)
    print('')
