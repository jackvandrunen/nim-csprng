type
  ROUND_COUNT* = enum
    EIGHT = 8, TWELVE = 12, TWENTY = 20
  Salsa20* = ref object of RootObj
    iv: array[16, int32]
    key: array[16, int32]
    state: array[16, int32]
    rounds: int
    buffer: seq[int8]


const SIGMA = [int32(0x61707865), int32(0x3320646e), int32(0x79622d32), int32(0x6b206574)]

const i32Zero = int32(0)
const i32One  = int32(1)


proc `^=`[T](x: var T, y: T) {.noSideEffect, inline.} =
  x = x xor y


proc rol32(a, b: int32): int32 {.noSideEffect, inline.} =
  (a shl b) or (a shr (32 - b))


proc i32toi8(input: int32): array[4, int8] {.noSideEffect, inline.} =
  # little endian
  result[0] = cast[int8](uint8(input and 255))
  result[1] = cast[int8](uint8((input shr 8) and 255))
  result[2] = cast[int8](uint8((input shr 16) and 255))
  result[3] = cast[int8](uint8((input shr 24) and 255))


proc i8toi32*(input: openarray[int8]): int32 {.noSideEffect, inline.} =
  int32(input[0]) or (int32(input[1]) shl 8) or (int32(input[2]) shl 16) or (int32(input[3]) shl 24)


proc core(input: array[16, int32], rounds: int): array[16, int32] {.noSideEffect.} =
  var x = input
  for i in countDown(rounds, 2, 2):
    x[ 4] ^= rol32(x[ 0] +% x[12], 7)
    x[ 8] ^= rol32(x[ 4] +% x[ 0], 9)
    x[12] ^= rol32(x[ 8] +% x[ 4],13)
    x[ 0] ^= rol32(x[12] +% x[ 8],18)
    x[ 9] ^= rol32(x[ 5] +% x[ 1], 7)
    x[13] ^= rol32(x[ 9] +% x[ 5], 9)
    x[ 1] ^= rol32(x[13] +% x[ 9],13)
    x[ 5] ^= rol32(x[ 1] +% x[13],18)
    x[14] ^= rol32(x[10] +% x[ 6], 7)
    x[ 2] ^= rol32(x[14] +% x[10], 9)
    x[ 6] ^= rol32(x[ 2] +% x[14],13)
    x[10] ^= rol32(x[ 6] +% x[ 2],18)
    x[ 3] ^= rol32(x[15] +% x[11], 7)
    x[ 7] ^= rol32(x[ 3] +% x[15], 9)
    x[11] ^= rol32(x[ 7] +% x[ 3],13)
    x[15] ^= rol32(x[11] +% x[ 7],18)
    x[ 1] ^= rol32(x[ 0] +% x[ 3], 7)
    x[ 2] ^= rol32(x[ 1] +% x[ 0], 9)
    x[ 3] ^= rol32(x[ 2] +% x[ 1],13)
    x[ 0] ^= rol32(x[ 3] +% x[ 2],18)
    x[ 6] ^= rol32(x[ 5] +% x[ 4], 7)
    x[ 7] ^= rol32(x[ 6] +% x[ 5], 9)
    x[ 4] ^= rol32(x[ 7] +% x[ 6],13)
    x[ 5] ^= rol32(x[ 4] +% x[ 7],18)
    x[11] ^= rol32(x[10] +% x[ 9], 7)
    x[ 8] ^= rol32(x[11] +% x[10], 9)
    x[ 9] ^= rol32(x[ 8] +% x[11],13)
    x[10] ^= rol32(x[ 9] +% x[ 8],18)
    x[12] ^= rol32(x[15] +% x[14], 7)
    x[13] ^= rol32(x[12] +% x[15], 9)
    x[14] ^= rol32(x[13] +% x[12],13)
    x[15] ^= rol32(x[14] +% x[13],18)
  for i in countUp(0, 15, 1):
    result[i] = x[i] +% input[i]


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


proc newiv*(cipher: Salsa20, iv: array[2, int32]) {.noSideEffect.} =
  cipher.iv = cipher.key
  cipher.iv[6] = iv[0]
  cipher.iv[7] = iv[1]
  cipher.iv[8] = i32Zero
  cipher.iv[9] = i32Zero
  cipher.state = cipher.iv


proc clearbuffer*(cipher: Salsa20) {.noSideEffect.} =
  cipher.buffer = @[]


proc salsa20*(key: array[8, int32], iv: array[2, int32], rounds: ROUND_COUNT): Salsa20 {.noSideEffect.} =
  result = Salsa20(rounds: int(rounds), buffer: @[])
  result.newkey(key)
  result.newiv(iv)
  result.clearbuffer()

proc salsa20*(rounds: ROUND_COUNT): Salsa20 {.noSideEffect.} =
  result = Salsa20(rounds: int(rounds))


proc next*(cipher: Salsa20): array[16, int32] {.noSideEffect.} =
  result = core(cipher.state, cipher.rounds)
  cipher.state[8] += i32One
  if cipher.state[8] == i32Zero:
    cipher.state[9] += i32One


proc randbytes*(cipher: Salsa20, count: int): seq[int8] {.noSideEffect.} =
  result = newSeq[int8](count)
  var y = 0
  while cipher.buffer.len > 0 and y < count:
    result[y] = cipher.buffer.pop()
    inc y
  var output: array[16, int32]
  while y < count:
    output = cipher.next()
    for i in output:
      for b in i32toi8(i):
        if y >= count:
          cipher.buffer.insert(b, 0)
        else:
          result[y] = b
          inc y
