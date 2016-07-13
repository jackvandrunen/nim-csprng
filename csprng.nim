import private/salsa20

type SeedError* = object of Exception

const SeedLength* = 40

var generator = salsa20(TWENTY)
var seeded = false

proc rand*(count: int): seq[int8] {.raises: [SeedError].} =
  if seeded:
    result = generator.randbytes(count)
  else:
    raise newException(SeedError, "CSPRNG has not been seeded")

proc seed*(s: array[SeedLength, int8]): bool =
  generator.newkey([i8toi32(s[0..3]), i8toi32(s[4..7]), i8toi32(s[8..11]),
                    i8toi32(s[12..15]), i8toi32(s[16..19]), i8toi32(s[20..23]),
                    i8toi32(s[24..27]), i8toi32(s[28..31])])
  generator.newiv([i8toi32(s[32..35]), i8toi32(s[36..39])])
  generator.clearbuffer()
  seeded = true
  result = seeded

proc seed*(s: openarray[int8]): bool =
  if s.len == SeedLength:
    var ss: array[SeedLength, int8]
    for i in 0..SeedLength - 1:
      ss[i] = s[i]
    result = seed(ss)
  elif s.len < SeedLength:
    var ss: array[SeedLength, int8]
    for i in 0..s.len - 1:
      ss[i] = s[i]
    if seed(ss):
      result = seed(rand(SeedLength))
    else:
      result = false
  else:
    result = false
