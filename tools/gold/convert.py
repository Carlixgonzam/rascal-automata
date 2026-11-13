import re, sys
out = []
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    name = re.search(r'Z = "(.*)"', text).group(1)
    nodes = re.findall(r'N\((\d+)\) = "(.*)"', text)
    start = re.search(r'I = (\d+)@', text).group(1)
    edges = re.findall(r'E\((\d+),(\d+)\) = "(.*)"', text)
    lines = ["tm " + name, "  start " + start]
    lines += ["  %s: %s" % (n, code) for n, code in nodes]
    for a, b, cond in sorted(edges, key=lambda e: (int(e[0]), int(e[1]))):
        lines.append("  %s -> %s" % (a, b) if cond == "" else "  %s -%s-> %s" % (a, cond, b))
    out.append("\n".join(lines))
print("\n\n".join(out))
