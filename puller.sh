#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1

ARCHIVE=".archive"
CONFIG=".config"
SEP="~"
OUTPUT_FORMAT="%(title)s $SEP %(id)s.%(ext)s"
UPDATE_URL="https://raw.githubusercontent.com/tytydraco/puller/main/puller.sh"

# Disable when developing!
SELF_UPDATE=1

self_update() {
    local self
    self="$(realpath "$0")"

    if ! curl -Ls "$UPDATE_URL" > ".new"
    then
        log "Update check failed. Skipping..."
        return
    fi

    if ! cmp -s "$self" ".new"
    then
        log "Updating..."
        mv ".new" "$self"
        chmod +x "$self"
        log "Executing new self..."
        exec "$self"
    fi

    rm ".new"
}

log() {
    echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
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
    unset VIDEO
}

prepare() {
    # shellcheck source=/dev/null
    source "$CONFIG"
}

download() {
    local args
    args=(
        "--ignore-errors"
        "--download-archive $ARCHIVE"
        "--add-metadata"
        "--match-filter !is_live"
    )

    if [[ "$VIDEO" -ne 1 ]]
    then
        args+=(
            "--extract-audio"
            "--audio-quality 0"
            "--audio-format $FORMAT"
        )
    else
        args+=(
            "--format $FORMAT"
        )
    fi

    # Only embed thumbnails for supported formats
    [[ "$FORMAT" == @(mp3|m4a|mp4) ]] && args+=( "--embed-thumbnail" )

    youtube-dl ${args[@]} -o "$OUTPUT_FORMAT" "$URL"
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
}

bootstrap() {
    if [[ "$SELF_UPDATE" -eq 1 ]]
    then
        log "Checking for updates..."
        self_update
    fi
}

# Takes path to root directory
discover() {
    local root
    root="$(pwd "$1")"
    log "Discovering in '$1'..."

    find "$root" -name "$CONFIG" -type f -printf '%h\n' | while read -r folder
    do
        process_folder "$folder"

        log "Backing out..."
        cd "$root" || return
    done
}

bootstrap
discover "${1:-.}"

exit 0
