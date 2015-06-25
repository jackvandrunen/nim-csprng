type
    ROUND_COUNT* = enum
        EIGHT = 8, TWELVE = 12, TWENTY = 20
    Salsa20* = ref object of RootObj
        iv: array[16, int32]
        key: array[16, int32]
        state: array[16, int32]
        rounds: int
        used: bool
    KeyLengthError* = object of Exception
    NonceLengthError* = object of Exception
    EndOfStreamError* = object of Exception


const TAU = [int32(0x61707865), int32(0x3120646e), int32(0x79622d36), int32(0x6b206574)]
const SIGMA = [int32(0x61707865), int32(0x3320646e), int32(0x79622d32), int32(0x6b206574)]

const i32Zero = int32(0)
const i32One  = int32(1)


proc `^=`[T](x: var T, y: T) {.noSideEffect, inline.} =
    x = x xor y


proc rol32(a, b: int32): int32 {.noSideEffect, inline.} =
    (a shl b) or (a shr (32 - b))


proc toChar(input: int8): char {.noSideEffect, inline.} =
    char(input and 255)


proc toI8(input: uint8): int8 {.noSideEffect, inline.} =
    cast[int8](input)


proc toI8(input: char): int8 {.noSideEffect, inline.} =
    cast[int8](input)


proc stringtoi32(input: string): int32 {.noSideEffect, inline.} =
    # little endian
    int32(input[0]) or (int32(input[1]) shl 8) or (int32(input[2]) shl 16) or (int32(input[3]) shl 24)


proc i32tostring(input: int32): string {.noSideEffect, inline.} =
    # little endian
    result = newString(4)
    result[0] = char(input and 255)
    result[1] = char((input shr 8) and 255)
    result[2] = char((input shr 16) and 255)
    result[3] = char((input shr 24) and 255)


proc i32toi8(input: int32): array[4, int8] {.noSideEffect, inline.} =
    # little endian
    result[0] = toI8(uint8(input and 255))
    result[1] = toI8(uint8((input shr 8) and 255))
    result[2] = toI8(uint8((input shr 16) and 255))
    result[3] = toI8(uint8((input shr 24) and 255))


proc core(input: array[16, int32], rounds: int): array[16, int32] {.noSideEffect.} =
    var x = input
    for i in countDown(rounds, 2, 2):
        x[ 4] ^= rol32(x[ 0] + x[12], 7)
        x[ 8] ^= rol32(x[ 4] + x[ 0], 9)
        x[12] ^= rol32(x[ 8] + x[ 4],13)
        x[ 0] ^= rol32(x[12] + x[ 8],18)
        x[ 9] ^= rol32(x[ 5] + x[ 1], 7)
        x[13] ^= rol32(x[ 9] + x[ 5], 9)
        x[ 1] ^= rol32(x[13] + x[ 9],13)
        x[ 5] ^= rol32(x[ 1] + x[13],18)
        x[14] ^= rol32(x[10] + x[ 6], 7)
        x[ 2] ^= rol32(x[14] + x[10], 9)
        x[ 6] ^= rol32(x[ 2] + x[14],13)
        x[10] ^= rol32(x[ 6] + x[ 2],18)
        x[ 3] ^= rol32(x[15] + x[11], 7)
        x[ 7] ^= rol32(x[ 3] + x[15], 9)
        x[11] ^= rol32(x[ 7] + x[ 3],13)
        x[15] ^= rol32(x[11] + x[ 7],18)
        x[ 1] ^= rol32(x[ 0] + x[ 3], 7)
        x[ 2] ^= rol32(x[ 1] + x[ 0], 9)
        x[ 3] ^= rol32(x[ 2] + x[ 1],13)
        x[ 0] ^= rol32(x[ 3] + x[ 2],18)
        x[ 6] ^= rol32(x[ 5] + x[ 4], 7)
        x[ 7] ^= rol32(x[ 6] + x[ 5], 9)
        x[ 4] ^= rol32(x[ 7] + x[ 6],13)
        x[ 5] ^= rol32(x[ 4] + x[ 7],18)
        x[11] ^= rol32(x[10] + x[ 9], 7)
        x[ 8] ^= rol32(x[11] + x[10], 9)
        x[ 9] ^= rol32(x[ 8] + x[11],13)
        x[10] ^= rol32(x[ 9] + x[ 8],18)
        x[12] ^= rol32(x[15] + x[14], 7)
        x[13] ^= rol32(x[12] + x[15], 9)
        x[14] ^= rol32(x[13] + x[12],13)
        x[15] ^= rol32(x[14] + x[13],18)
    for i in countUp(0, 15, 1):
        result[i] = x[i] + input[i]


proc reset*(cipher: Salsa20) {.noSideEffect.} =
    cipher.state = cipher.iv


proc newkey*(cipher: Salsa20, key: array[8, int32]) {.noSideEffect.} =
    cipher.key = [i32Zero, i32Zero, i32Zero, i32Zero, i32Zero, i32Zero,
                  i32Zero, i32Zero, i32Zero, i32Zero, i32Zero, i32Zero,
                  i32Zero, i32Zero, i32Zero, i32Zero]
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

proc newkey*(cipher: Salsa20, key: array[4, int32]) {.noSideEffect.} =
    cipher.key = [i32Zero, i32Zero, i32Zero, i32Zero, i32Zero, i32Zero,
                  i32Zero, i32Zero, i32Zero, i32Zero, i32Zero, i32Zero,
                  i32Zero, i32Zero, i32Zero, i32Zero]
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


proc newiv*(cipher: Salsa20, iv: array[2, int32]) {.noSideEffect.} =
    cipher.iv = cipher.key
    cipher.iv[6] = iv[0]
    cipher.iv[7] = iv[1]
    cipher.iv[8] = i32Zero
    cipher.iv[9] = i32Zero
    cipher.reset()


proc salsa20*(key: array[8, int32], iv: array[2, int32], rounds: ROUND_COUNT): Salsa20 {.noSideEffect.} =
    result = Salsa20(rounds: int(rounds), used: false)
    result.newkey(key)
    result.newiv(iv)

proc salsa20*(key: array[4, int32], iv: array[2, int32], rounds: ROUND_COUNT): Salsa20 {.noSideEffect.} =
    result = Salsa20(rounds: int(rounds), used: false)
    result.newkey(key)
    result.newiv(iv)

proc salsa20*(key, iv: string, rounds: ROUND_COUNT): Salsa20 {.noSideEffect, raises: [KeyLengthError, NonceLengthError].} =
    if iv.len != 8:
        raise newException(NonceLengthError, "Nonce must be 64 bits (8 bytes)")
    result = Salsa20(rounds: int(rounds), used: false)
    case key.len:
    of 32:
        var keyarray: array[8, int32]
        var y = 0
        for i in countUp(0, 28, 4):
            keyarray[y] = stringtoi32(key.substr(i, i+3))
            inc y
        result.newkey(keyarray)
    of 16:
        var keyarray: array[4, int32]
        var y = 0
        for i in countUp(0, 12, 4):
            keyarray[y] = stringtoi32(key.substr(i, i+3))
            inc y
        result.newkey(keyarray)
    else:
        raise newException(KeyLengthError, "Key must be either 256 bits (32 bytes) or 128 bits (16 bytes)")
    result.newiv([stringtoi32(iv.substr(0, 3)), stringtoi32(iv.substr(4, 7))])


proc next*(cipher: Salsa20): array[16, int32] {.noSideEffect.} =
    result = core(cipher.state, cipher.rounds)
    cipher.state[8] += i32One
    if cipher.state[8] == i32Zero:
        cipher.state[9] += i32One


proc randbytes*(cipher: Salsa20, count: int): string {.noSideEffect, raises: [EndOfStreamError].} =
    if cipher.used:
        raise newException(EndOfStreamError, "A block of <64 bytes has already been read.")
    result = newString(count)
    var y = 0
    var output: array[16, int32]
    block outputloop:
        while true:
            output = cipher.next()
            for i in output:
                for chr in i32tostring(i):
                    result[y] = chr
                    inc y
                    if y >= count:
                        if count mod 64 != 0:
                            cipher.used = true
                        break outputloop


proc randints*(cipher: Salsa20, count: int): seq[int8] {.noSideEffect, raises: [EndOfStreamError].} =
    if cipher.used:
        raise newException(EndOfStreamError, "A block of <64 bytes has already been read.")
    result = newSeq[int8](count)
    var y = 0
    var output: array[16, int32]
    block outputloop:
        while true:
            output = cipher.next()
            for i in output:
                for j in i32toi8(i):
                    result[y] = j
                    inc y
                    if y >= count:
                        if count mod 64 != 0:
                            cipher.used = true
                        break outputloop


proc encrypt*(cipher: Salsa20, message: string): string {.noSideEffect, raises: [EndOfStreamError].} =
    var stream = cipher.randints(message.len)
    result = newString(message.len)
    for i in countUp(0, message.len - 1):
        result[i] = toChar(toI8(message[i]) xor stream[i])


proc decrypt*(cipher: Salsa20, message: string): string {.noSideEffect, inline, raises: [EndOfStreamError].} =
    cipher.encrypt(message)
