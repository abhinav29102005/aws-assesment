from pathlib import Path
import sys, zipfile
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1] if len(sys.argv)>1 else root/'source-bundles')
out.mkdir(parents=True,exist_ok=True)
for folder in sorted(root.glob('[0-9][0-9]-*')):
    with zipfile.ZipFile(out/(folder.name+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(folder.rglob('*')):
            if p.is_file() and not any(x in p.relative_to(folder).parts for x in ['.git','node_modules','reports','dist']):
                z.write(p,p.relative_to(folder))
    print(out/(folder.name+'.zip'))
