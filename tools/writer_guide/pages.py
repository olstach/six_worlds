#!/usr/bin/env python3
"""Find the page of every TOC heading in a rendered PDF (pass 1) so pass 2 can print real page numbers.
usage: pages.py guide.pdf guide.toc.json pages.json"""
import json, re, subprocess, sys
pdf, tocf, out = sys.argv[1:4]
n = int(re.search(r"Pages:\s+(\d+)", subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout).group(1))
norm = lambda s: re.sub(r"\s+", " ", s).strip()
pages = [norm(subprocess.run(["pdftotext", "-f", str(i), "-l", str(i), pdf, "-"], capture_output=True, text=True).stdout) for i in range(1, n + 1)]
toc = json.load(open(tocf))
# skip the TOC pages themselves: start after the page that contains the "Welcome, Alice" heading
start = next(i for i, t in enumerate(pages) if "Welcome, Alice" in t and "Contents" not in t[:40] and i > 0)
res, cur = {}, start
missing = []
for e in toc:
    lab = norm(e["label"])
    for i in range(cur, n):
        if lab in pages[i]:
            res[e["id"]] = i + 1
            cur = i
            break
    else:
        missing.append(lab)
json.dump(res, open(out, "w"))
print(f"{n} pages; located {len(res)}/{len(toc)} headings; missing: {missing[:5]}")
