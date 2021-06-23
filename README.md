# puller
A youtube-dl wrapper for downloading music on removable media

# How-To
* Setup a directory for each playlist to download
* Place puller.sh outside of these directories
* In each directory, create a .config file of this format:

```
URL="youtube URL here"
FORMAT="mp3"            # or opus, flac, mp4, etc
VIDEO=0                 # or 1 to use video format
```

* Execute puller.sh

# Debugging
* If you see "invalid audio format specified", make sure your config file has the proper line endings for your system (LF recommended)

# Features
- Auto-updating puller scipt
- Generates archives for existing tracks
- Low-profile
- Cleanup included
