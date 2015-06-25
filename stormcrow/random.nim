type
    RandomError = object of OSError


when defined(windows):
    # Windows code partially adapted from nim-random:
    # (https://github.com/BlaXpirit/nim-random/blob/master/src/random/urandom.nim)
    # Whose license and copyright are reproduced below:
    #
    # Copyright (C) 2014-2015 Oleh Prypin <blaxpirit@gmail.com>
    #
    # This file is part of nim-random.
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in all
    # copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    # SOFTWARE.
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
