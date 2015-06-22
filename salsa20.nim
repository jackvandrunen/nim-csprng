type
    ROUND_COUNT* = enum
        EIGHT = 8, TWELVE = 12, TWENTY = 20
    Salsa20* = ref object of RootObj
        iv: array[16, int32]
        key: array[16, int32]
        state: array[16, int32]
        rounds: ROUND_COUNT
        used: bool


const TAU = [int32(0x61707865), int32(0x3120646e), int32(0x79622d36), int32(0x6b206574)]
const SIGMA = [int32(0x61707865), int32(0x3320646e), int32(0x79622d32), int32(0x6b206574)]


proc `^=`[T](x: var T, y: T) {.gcSafe, noSideEffect, inline.} =
    x = x xor y

proc `|=`[T](x: var T, y: T) {.gcSafe, noSideEffect, inline.} =
    x = x or y


proc rotate(a, b: int32): int32 {.gcSafe, noSideEffect, inline.} =
    (a shl b) or (a shr (32 - b))


proc stringtoi32(input: string): int32 {.gcSafe, noSideEffect, inline.} =
    # little endian
    result = int32(0)
    result |= int32(input[0])
    result |= int32(input[1]) shl 8
    result |= int32(input[2]) shl 16
    result |= int32(input[3]) shl 24


proc i32tostring(input: int32): string {.gcSafe, noSideEffect, inline.} =
    # little endian
    result = newString(4)
    result[0] = char(input and 255)
    result[1] = char((input shr 8) and 255)
    result[2] = char((input shr 16) and 255)
    result[3] = char((input shr 24) and 255)


proc core(input: array[16, int32], rounds: ROUND_COUNT): array[16, int32] {.gcSafe, noSideEffect.} =
    var x = input
    for i in countDown(int(rounds), 2, 2):
        x[ 4] ^= rotate(x[ 0] + x[12], 7)
        x[ 8] ^= rotate(x[ 4] + x[ 0], 9)
        x[12] ^= rotate(x[ 8] + x[ 4],13)
        x[ 0] ^= rotate(x[12] + x[ 8],18)
        x[ 9] ^= rotate(x[ 5] + x[ 1], 7)
        x[13] ^= rotate(x[ 9] + x[ 5], 9)
        x[ 1] ^= rotate(x[13] + x[ 9],13)
        x[ 5] ^= rotate(x[ 1] + x[13],18)
        x[14] ^= rotate(x[10] + x[ 6], 7)
        x[ 2] ^= rotate(x[14] + x[10], 9)
        x[ 6] ^= rotate(x[ 2] + x[14],13)
        x[10] ^= rotate(x[ 6] + x[ 2],18)
        x[ 3] ^= rotate(x[15] + x[11], 7)
        x[ 7] ^= rotate(x[ 3] + x[15], 9)
        x[11] ^= rotate(x[ 7] + x[ 3],13)
        x[15] ^= rotate(x[11] + x[ 7],18)
        x[ 1] ^= rotate(x[ 0] + x[ 3], 7)
        x[ 2] ^= rotate(x[ 1] + x[ 0], 9)
        x[ 3] ^= rotate(x[ 2] + x[ 1],13)
        x[ 0] ^= rotate(x[ 3] + x[ 2],18)
        x[ 6] ^= rotate(x[ 5] + x[ 4], 7)
        x[ 7] ^= rotate(x[ 6] + x[ 5], 9)
        x[ 4] ^= rotate(x[ 7] + x[ 6],13)
        x[ 5] ^= rotate(x[ 4] + x[ 7],18)
        x[11] ^= rotate(x[10] + x[ 9], 7)
        x[ 8] ^= rotate(x[11] + x[10], 9)
        x[ 9] ^= rotate(x[ 8] + x[11],13)
        x[10] ^= rotate(x[ 9] + x[ 8],18)
        x[12] ^= rotate(x[15] + x[14], 7)
        x[13] ^= rotate(x[12] + x[15], 9)
        x[14] ^= rotate(x[13] + x[12],13)
        x[15] ^= rotate(x[14] + x[13],18)
    for i in countUp(0, 15, 1):
        result[i] = x[i] + input[i]


proc newkey*(cipher: Salsa20, key: array[8, int32]) {.gcSafe, noSideEffect.} =
    cipher.key = [int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0)]
    cipher.key[0]  = SIGMA[0]
    cipher.key[1]  = key[0]
    cipher.key[2]  = key[1]
    cipher.key[3]  = key[2]
    cipher.key[4]  = key[3]
    cipher.key[5]  = SIGMA[1]
    cipher.key[10] = SIGMA[2]
    cipher.key[11] = key[4]
    cipher.key[12] = key[5]
    cipher.key[13] = key[6]
    cipher.key[14] = key[7]
    cipher.key[15] = SIGMA[3]

proc newkey*(cipher: Salsa20, key: array[4, int32]) {.gcSafe, noSideEffect.} =
    cipher.key = [int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0), int32(0)]
    cipher.key[0]  = TAU[0]
    cipher.key[1]  = key[0]
    cipher.key[2]  = key[1]
    cipher.key[3]  = key[2]
    cipher.key[4]  = key[3]
    cipher.key[5]  = TAU[1]
    cipher.key[10] = TAU[2]
    cipher.key[11] = key[0]
    cipher.key[12] = key[1]
    cipher.key[13] = key[2]
    cipher.key[14] = key[3]
    cipher.key[15] = TAU[3]


proc newiv*(cipher: Salsa20, iv: array[2, int32]) {.gcSafe, noSideEffect.} =
    cipher.iv = cipher.key
    cipher.iv[6] = iv[0]
    cipher.iv[7] = iv[1]
    cipher.iv[8] = int32(0)
    cipher.iv[9] = int32(0)
    cipher.state = cipher.iv


proc salsa20*(key: array[8, int32], iv: array[2, int32], rounds: ROUND_COUNT): Salsa20 {.gcSafe, noSideEffect.} =
    result = Salsa20(rounds: rounds, used: false)
    result.newkey(key)
    result.newiv(iv)

proc salsa20*(key: array[4, int32], iv: array[2, int32], rounds: ROUND_COUNT): Salsa20 {.gcSafe, noSideEffect.} =
    result = Salsa20(rounds: rounds, used: false)
    result.newkey(key)
    result.newiv(iv)


proc randints*(cipher: Salsa20): array[16, int32] {.gcSafe, noSideEffect.} =
    result = core(cipher.state, cipher.rounds)
    cipher.state[8] += int32(1)
    if cipher.state[8] == int32(0):
        cipher.state[9] += int32(1)


proc randbytes*(cipher: Salsa20, count: int): string {.gcSafe, noSideEffect.} =
    result = newString(count)
    var y = 0
    var output: array[16, int32]
    block outputloop:
        while true:
            output = cipher.randints()
            for i in output:
                for chr in i32tostring(i):
                    result[y] = chr
                    inc y
                    if y >= count:
                        break outputloop


# proc encrypt*(cipher: Salsa20, message: string): string {.gcSafe, noSideEffect.} =
#     var stream = cipher.getbytes(message.len)
#     result = newString(message.len)
#     for i in countUp(0, message.len - 1):
#         result = message[i] xor stream[i]


# for i in core([int32(0),int32(1),int32(2),int32(3),int32(4),int32(5),int32(6),int32(7),int32(8),int32(9),int32(10),int32(11),int32(12),int32(13),int32(14),int32(15)], TWENTY):
#     echo cast[uint32](i)


import hex


var bleh = salsa20([int32(0x0), int32(0x0), int32(0x0), int32(0x0), int32(0x0), int32(0x0), int32(0x0), int32(0x0)], [int32(0x0), int32(0x0)], TWENTY)
echo hex.encode(bleh.randbytes(64))
# for i in bleh.randints():
#     echo cast[uint32](i)
