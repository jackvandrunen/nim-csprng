type
    RandomError = object of OSError


when defined(windows):
    import winlean

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
        result = newSeq[char](count)
        for i in countUp(0, count - 1, 1):
          if CryptGenRandom(cryptProv, DWORD(8), addr result[i]) == 0:
              raise newException(RandomError, "Call to CryptGenRandom failed")

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
