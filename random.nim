type
    RandomError = object of OSError


proc urandom*(count: int): seq[char] {.raises: [RandomError].} =
    var f: File
    try:
        f = open("/dev/urandom")
        result = newSeq[char](count)
        discard f.readChars(result, 0, count)
    except Exception:
        raise newException(RandomError, "Error reading from urandom")
    finally:
        f.close()
