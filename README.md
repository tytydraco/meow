# meow
A youtube-dl wrapper for downloading music on removable media

# How-To
* Setup a directory for each playlist to download
* In each directory, create a .config file of this format:

```
URL="youtube URL here"
FORMAT="mp3"            # or opus, flac, mp4, etc
VIDEO=0                 # or 1 to use video format
```

* `./meow.sh`, optionally specifying a starting directory (defaults to CWD)

# Debugging
* If you see "invalid audio format specified", make sure your config file has the proper line endings for your system (LF on Unix, CRLF on Windows)

# Features
- Self-updating puller scipt
- Generates archives for existing tracks
- Low-profile
- Portable
- Cleans up after itself
