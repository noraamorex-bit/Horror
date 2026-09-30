#!/usr/bin/env python3
"""
place_flags.py - sets place settings that Rojo can't write yet, straight into a built .rbxl.

Right now: AssetService.AllowInsertFreeAssets = true ("Allow Loading Third Party Assets"), so
the game can load free Creator Store models at runtime (src/server/World/Props.luau).
The place must already contain an AssetService instance (default.project.json lists it).

usage: python3 tools/place_flags.py HomeAlone.rbxl
"""
import struct, sys
import lz4.block

def read_chunks(data):
    pos = 32
    chunks = []
    while pos < len(data):
        name = data[pos:pos + 4]
        clen, ulen, _ = struct.unpack_from('<III', data, pos + 4)
        body = data[pos + 16: pos + 16 + (clen or ulen)]
        chunks.append((name, clen, ulen, body, data[pos:pos + 16 + (clen or ulen)]))
        pos += 16 + (clen or ulen)
        if name == b'END\0':
            break
    return chunks

def payload(c):
    name, clen, ulen, body, raw = c
    if clen == 0:
        return body
    if body[:4] == b'\x28\xb5\x2f\xfd':
        raise SystemExit('zstd chunks not supported')
    return lz4.block.decompress(body, uncompressed_size=ulen)

def rstring(b, p):
    n = struct.unpack_from('<I', b, p)[0]
    return b[p + 4:p + 4 + n].decode(), p + 4 + n

def main(path):
    data = open(path, 'rb').read()
    chunks = read_chunks(data)
    class_id, count = None, 0
    for c in chunks:
        if c[0] == b'INST':
            b = payload(c)
            cid = struct.unpack_from('<I', b, 0)[0]
            cname, p = rstring(b, 4)
            if cname == 'AssetService':
                class_id = cid
                count = struct.unpack_from('<I', b, p + 1)[0]
    if class_id is None:
        raise SystemExit('no AssetService in the place')
    for c in chunks:
        if c[0] == b'PROP':
            b = payload(c)
            cid = struct.unpack_from('<I', b, 0)[0]
            pname, _ = rstring(b, 4)
            if cid == class_id and pname == 'AllowInsertFreeAssets':
                print('already set')
                return
    pname = b'AllowInsertFreeAssets'
    body = struct.pack('<I', class_id) + struct.pack('<I', len(pname)) + pname + bytes([0x02]) + bytes([1] * count)
    chunk = b'PROP' + struct.pack('<III', 0, len(body), 0) + body
    out = bytearray(data[:32])
    for c in chunks:
        if c[0] == b'PRNT':
            out += chunk
        out += c[4]
    out += data[32 + sum(len(c[4]) for c in chunks):]
    open(path, 'wb').write(bytes(out))
    print('AllowInsertFreeAssets = true (%d AssetService)' % count)

if __name__ == '__main__':
    main(sys.argv[1])
