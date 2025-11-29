""" SAASoundVHDL - hardware description of Philips SAA1099 device in VHDL and other languages
    Copyright (C) 2025  David Hooper (github.com/stripwax)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""


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
