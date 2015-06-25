type
    RandomError = object of OSError


when defined(windows):
    import winlean, utils

    type ULONG_PTR = int
    type HCRYPTPROV = ULONG_PTR
    var PROV_RSA_FULL {.importc, header: "<windows.h>".}: DWORD
    var CRYPT_VERIFYCONTEXT {.importc, header: "<windows.h>".}: DWORD

    {.push, stdcall, dynlib: "Advapi32.dll".}

    when useWinUnicode:
        proc CryptAcquireContext(
            phProv: ptr HCRYPTPROV, pszContainer: WideCString,
            pszProvider: WideCString, dwProvType: DWORD, dwFlags: DWORD
        ): WinBool {.importc: "CryptAcquireContextW".}
    else:
        proc CryptAcquireContext(
            phProv: ptr HCRYPTPROV, pszContainer: cstring, pszProvider: cstring,
            dwProvType: DWORD, dwFlags: DWORD
        ): WinBool {.importc: "CryptAcquireContextA".}

    proc CryptGenRandom(
        hProv: HCRYPTPROV, dwLen: DWORD, pbBuffer: pointer
    ): WinBool {.importc: "CryptGenRandom".}

    {.pop.}

    var cryptProv: HCRYPTPROV = 0

    let success = CryptAcquireContext(
        addr cryptProv, nil, nil, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT
    )
    if success == 0:
        raise newException(RandomError, "Call to CryptAcquireContext failed")

    proc urandom*(count: int): seq[char] {.raises: [RandomError].} =
        var output: int32
        var y = 0
        result = newSeq[char](count)
        while true:
            let success = CryptGenRandom(cryptProv, DWORD(size), addr output)
            if success == 0:
                raise newException(OSError, "Call to CryptGenRandom failed")
            for chr in i32tostring(output):
                result[y] = chr
                inc y
                if y >= count:
                    break

else:
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
