proc i32tostring*(input: int32): string {.noSideEffect, inline.} =
    # little endian
    result = newString(4)
    result[0] = char(input and 255)
    result[1] = char((input shr 8) and 255)
    result[2] = char((input shr 16) and 255)
    result[3] = char((input shr 24) and 255)
