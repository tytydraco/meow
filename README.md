# meow
A youtube-dl wrapper for downloading music on removable media

# How-To
* Set up a directory for each playlist to download
* In each directory, create a .config file of this format:

```
BINARY=youtube-dl       # (optional) binary to use for youtube-dl
COOKIES=../cookies.txt  # (optional) path to cookies file to download restricted videos
PPARGS="-b:a 20K"       # (optional) post-processor arguments for ffmpeg
URL="youtube URL here"	# or an array of URLs
VIDEO=false             # (optional) or true to use video format
```

* `./meow.sh`, optionally specifying a starting directory (defaults to CWD)

# Debugging
* If you see "invalid audio format specified", make sure your config file has the proper line endings for your system (LF on Unix, CRLF on Windows)

# Features
- Self-updating puller script
- Generate archives for existing tracks
- Low-profile
- Portable
- Cleans up after itself
