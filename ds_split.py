import struct

def ds_split(val):
    hi = struct.unpack('f', struct.pack('f', val))[0]
    lo = val - hi
    return hi, lo

# edit these two lines
cr = -0.1982900426243459
ci = -1.1009837150956097

crHi, crLo = ds_split(cr)
ciHi, ciLo = ds_split(ci)

print(f"const float crHi = {crHi:.14g};")
print(f"const float crLo = {crLo:.17g};")
print(f"const float ciHi = {ciHi:.14g};")
print(f"const float ciLo = {ciLo:.17g};")