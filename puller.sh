#!/usr/bin/env bash
shopt -s globstar
cd "$(dirname "$0")" || exit 1

ARCHIVE=".archive"
CONFIG=".config"
NEW_SELF='.new'
SEP="~"
OUTPUT_FORMAT="%(title)s $SEP %(id)s.%(ext)s"
SELF=$(basename "$0")
SELF_URL="https://raw.githubusercontent.com/tytydraco/puller/main/puller.sh"

self_update() {
    curl -Ls "$SELF_URL" > "$NEW_SELF"
    
    if ! cmp -s "$SELF" "$NEW_SELF"
    then
        cp "$NEW_SELF" "$SELF"
		rm "$NEW_SELF"
		chmod +x "./$SELF"
        exec "./$SELF"
    fi
	
	rm "$NEW_SELF"
}

log() {
    echo -e "\e[1m\e[93m[*] $*\e[39m\e[0m"
}

generate_archive() {
    local uid

    for file in *."$FORMAT"
    do
        uid="$(echo "$file" | sed s"/.*$SEP //" | sed "s/.$FORMAT//")"
        echo "youtube $uid" >> "$ARCHIVE"
    done
}

cleanup() {
    rm -f "$ARCHIVE"
    unset URL
    unset FORMAT
    unset QUALITY
}

prepare() {
    # shellcheck source=/dev/null
    source "$CONFIG"
}

download() {
    youtube-dl \
        --ignore-errors \
        --extract-audio \
        --download-archive "$ARCHIVE" \
        --audio-format "$FORMAT" \
        --audio-quality "$QUALITY" \
        --embed-thumbnail \
        --add-metadata \
        --match-filter "!is_live" \
        --no-overwrites \
        --no-post-overwrites \
        -o "$OUTPUT_FORMAT" \
        "$URL"
}

process_folder() {
    log "Entering '$1'..."
    cd "$1" || return

    log "Sourcing configuration..."
    prepare

    log "Generating archives..."
    generate_archive

    log "Downloading..."
    download

    log "Cleaning up..."
    cleanup

    log "Backing out..."
    cd ..
}

log "Starting self-upgrade..."
self_update

find . -name "$CONFIG" -type f -printf '%h\n' | while read -r folder
do
    process_folder "$folder"
done

exit 0
