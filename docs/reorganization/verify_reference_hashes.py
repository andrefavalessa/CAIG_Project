"""Read-only SHA-256 check of relocated reference artifacts; Python stdlib only.

Run from any directory. --require-local also requires ignored historical outputs.
A source-only clone skips the documented, locally retained ignored references.
"""
from pathlib import Path
import argparse
import hashlib
import json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-local', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    manifest = json.loads((Path(__file__).parent / 'reference_hashes.json').read_text())
    checked, skipped, failed = 0, [], []
    for item in manifest:
        path = root / item['newPath']
        if not path.is_file():
            if not item['tracked'] and not args.require_local:
                skipped.append(item['newPath'])
            else:
                failed.append(item['newPath'] + ': missing')
            continue
        with path.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        if digest != item['sha256']:
            failed.append(item['newPath'] + ': hash mismatch')
        checked += 1
    print(json.dumps(dict(checked=checked, skippedLocalFiles=len(skipped), failures=failed), indent=2))
    raise SystemExit(bool(failed))


if __name__ == '__main__':
    main()
