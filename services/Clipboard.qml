pragma Singleton

import Quickshell
import Quickshell.Io

// Clipboard history from cliphist (the dots already run `wl-paste --watch
// cliphist store`). Each entry keeps cliphist's own list line, which is what
// `cliphist decode` / `cliphist delete` take on stdin.
Singleton {
    id: root

    property list<var> entries: []
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/caelestia-shell-plus/clipboard`

    // "[[ binary data 12 KiB png 800x600 ]]"
    readonly property var imagePattern: /^\[\[ binary data .* (png|jpe?g|gif|bmp|webp) (\d+)x(\d+) \]\]$/

    function refresh(): void {
        lister.running = true;
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
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line]);
    }

    function remove(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry.line]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", cacheDir]);
        entries = [];
    }

    // Decoded image path for a thumbnail. The shell decodes on first use.
    // ponytail: the cache only empties on wipe; prune by age if it grows large.
    function thumbnailPath(entry: var): string {
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
}
