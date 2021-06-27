#!/usr/bin/env bash

SELF="$(realpath "$0")"
SELF_DIR="$(dirname "$SELF")"
ARGS=("$@")
ARCHIVE=".archive"
CONFIG=".config"
SEP="~"
OUTPUT_FORMAT="%(title)s $SEP %(id)s.%(ext)s"
UPDATE_URL="https://raw.githubusercontent.com/tytydraco/meow/main/meow.sh"

# Disable when developing!
SELF_UPDATE=0

# Print a message to the user
# Arguments: <MESSAGE>
log() {
  echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
}

# Replaces self with an updated version if available,
# then restart it with the same arguments
self_update() {
  local new_path
  new_path="$SELF_DIR/.new"

  if ! curl -Ls "$UPDATE_URL" >"$new_path"; then
    log "Update check failed. Skipping..."
    rm -f "$new_path"
    return
  fi

  if ! cmp -s "$SELF" "$new_path"; then
    log "Updating..."
    mv "$new_path" "$SELF"
    chmod +x "$SELF"
    log "Executing new self..."
    exec "$SELF" "${ARGS[@]}"
  fi

  rm -f "$new_path"
}

# Generate a youtube-dl archive for all the files that
# already exist
generate_archive() {
  local uid

  rm -f "$ARCHIVE"

  for file in *."$FORMAT"; do
    uid="$(echo "$file" | sed s"/.*$SEP //" | sed "s/.$FORMAT//")"
    echo "youtube $uid" >>"$ARCHIVE"
  done
}

# Parses the URL environmental variable and downloads it accordingly.
# 1) Either the variable is an array of URLs
# 2) Or the variable is a single URL
download() {
  if [[ "$(declare -p URL)" =~ "declare -a" ]]
  then
    for url in "${URL[@]}"
    do
      download_url "$url"
    done
  else
    download_url "$URL"
  fi
}

# Downloads a URL
# Requires config to be sourced
# Arguments: <URL>
download_url() {
  local args
  args=(
    "--ignore-errors"
    "--download-archive $ARCHIVE"
    "--add-metadata"
    "--match-filter !is_live"
  )

  if [[ "$VIDEO" -ne 1 ]]; then
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
  [[ "$FORMAT" == @(mp3|m4a|mp4) ]] && args+=("--embed-thumbnail")

  #shellcheck disable=SC2068
  youtube-dl ${args[@]} -o "$OUTPUT_FORMAT" "$1"
}

# Enter and process a directory
# Sources configs, generates archives, downloads, and cleans up
# Arguments: <PATH>
process_folder() {
  log "Entering '$1'..."
  cd "$1" || return

  log "Sourcing configuration..."
  #shellcheck source=/dev/null
  source "$CONFIG"

  log "Generating archives..."
  generate_archive

  log "Downloading..."
  download

  log "Cleaning up..."
  rm -f "$ARCHIVE"
  unset URL
  unset FORMAT
  unset VIDEO

  log "Backing out..."
  cd - > /dev/null || return
}

# Discover and process folders recursively from a starting path
# Arguments: <PATH>
discover() {
  log "Discovering in '$1'..."

  find "$1" -name "$CONFIG" -type f -printf '%h\n' | while read -r folder; do
    process_folder "$folder"
  done
}

# Self update if necessary
bootstrap() {
  if [[ "$SELF_UPDATE" -eq 1 ]]; then
    log "Checking for updates..."
    self_update
  fi
}

bootstrap
# Discover from either our CWD or the user-provided path
discover "${1:-.}"

exit 0
