# Prints a checksum per source file, matching tools/checksum.lua and tools/push.lua in Studio.
# checksum = (len, sum over bytes of b * (i % 251 + 1)) mod 2^31, CRLF normalised to LF,
# trailing newlines stripped (Studio drops them).
#   python tools/checksum.py            every file under src/
#   python tools/checksum.py Audio HUD  only paths containing one of the words
import sys, pathlib

BASES = {
    "Shared": "ReplicatedStorage.Shared",
    "Server": "ServerScriptService.Server",
    "Client": "StarterPlayer.StarterPlayerScripts",
    "First": "ReplicatedFirst",
}

root = pathlib.Path(__file__).resolve().parent.parent / "src"
words = sys.argv[1:]
for folder, base in BASES.items():
    for f in sorted((root / folder).glob("*.lua")):
        name = f.name[:-4]
        for suffix in (".server", ".client"):
            if name.endswith(suffix):
                name = name[: -len(suffix)]
        path = f"{base}.{name}"
        if words and not any(w in path for w in words):
            continue
        data = f.read_bytes().replace(b"\r\n", b"\n").rstrip(b"\n")
        s = 0
        for i, b in enumerate(data):
            s = (s + b * (i % 251 + 1)) % 2147483648
        print(f"{path} {len(data)} {s}")
