pragma Singleton

import Quickshell
import Quickshell.Io

// Clipboard history from cliphist (the dots already run `wl-paste --watch
// cliphist store`). Each entry keeps cliphist's own list line, which is what
// `cliphist decode` / `cliphist delete` take on stdin.
//
// Starring an entry saves its full content as a file in starDir, outside
// cliphist, so stars survive the history's own limit and a wipe.
Singleton {
    id: root

    property list<var> entries: []
    property list<var> stars: []
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/caelestia-shell-plus/clipboard`
    readonly property string starDir: `${Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"}/caelestia-shell-plus/clipboard-stars`
    readonly property var imageExt: /\.(png|jpe?g|gif|bmp|webp)$/

    // "[[ binary data 12 KiB png 800x600 ]]"
    readonly property var imagePattern: /^\[\[ binary data .* (png|jpe?g|gif|bmp|webp) (\d+)x(\d+) \]\]$/

    function refresh(): void {
        lister.running = true;
        starLister.running = true;
    }

    function parse(text: string): list<var> {
        return text.split("\n").filter(l => l.includes("\t")).map(line => {
            const tab = line.indexOf("\t");
            const preview = line.slice(tab + 1);
            const img = preview.match(imagePattern);
            return {
                line,
                id: line.slice(0, tab),
                text: img ? "" : preview,
                image: img ? {
                    ext: img[1],
                    width: +img[2],
                    height: +img[3]
                } : null
            };
        });
    }

    function copy(entry: var): void {
        if (entry.starred)
            return Quickshell.execDetached(["sh", "-c", 'wl-copy < "$1"', "sh", entry.path]);
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line]);
    }

    function remove(entry: var): void {
        if (entry.starred)
            return unstar(entry);
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry.line]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", cacheDir]);
        entries = [];
    }

    function star(entry: var): void {
        const ext = entry.image ? `.${entry.image.ext}` : "";
        starrer.command = ["sh", "-c", 'mkdir -p "$2" && printf "%s" "$1" | cliphist decode > "$2/$(date +%s%N)$3"', "sh", entry.line, starDir, ext];
        starrer.running = true;
    }

    function unstar(entry: var): void {
        Quickshell.execDetached(["rm", "-f", entry.path]);
        stars = stars.filter(e => e.path !== entry.path);
    }

    // Decoded image path for a thumbnail. The shell decodes on first use.
    // ponytail: the cache only empties on wipe; prune by age if it grows large.
    function thumbnailPath(entry: var): string {
        if (entry.starred)
            return entry.path;
        return `${cacheDir}/${entry.id}.${entry.image.ext}`;
    }

    function decodeCommand(entry: var): list<string> {
        return ["sh", "-c", 'mkdir -p "$2" && { [ -s "$3" ] || printf "%s" "$1" | cliphist decode > "$3"; }', "sh", entry.line, cacheDir, thumbnailPath(entry)];
    }

    Process {
        id: lister

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    Process {
        id: starrer

        onExited: starLister.running = true
    }

    // One "name<TAB>preview" line per star, newest first
    Process {
        id: starLister

        command: ["sh", "-c", 'cd "$1" 2>/dev/null || exit 0; ls -t | while read -r f; do printf "%s\\t%s\\n" "$f" "$(head -c 300 "$f" | tr "\\n\\t" "  ")"; done', "sh", root.starDir]
        stdout: StdioCollector {
            onStreamFinished: root.stars = text.split("\n").filter(l => l.includes("\t")).map(line => {
                const tab = line.indexOf("\t");
                const name = line.slice(0, tab);
                const img = name.match(root.imageExt);
                return {
                    starred: true,
                    id: `star:${name}`,
                    path: `${root.starDir}/${name}`,
                    text: img ? "" : line.slice(tab + 1),
                    image: img ? {
                        ext: img[1]
                    } : null
                };
            })
        }
    }
}
