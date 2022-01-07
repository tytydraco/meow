#!/usr/bin/env bash

shopt -s globstar

SELF="$(realpath "$0")"
SELF_DIR="$(dirname "$SELF")"
_SHELL="${SHELL:-bash}"
ARGS=("$@")
ARCHIVE=".archive"
CONFIG=".config"
SEP="~"
OUTPUT_FORMAT="%(title)s $SEP %(id)s.%(ext)s"
UPDATE_URL="https://raw.githubusercontent.com/tytydraco/meow/main/meow.sh"
ENV_VARIABLES=("BINARY" "COOKIES" "URL" "VIDEO")
ARIA2_ARGS="-j 4 -x 4 -s 4 -k 1M"

DEFAULT_BINARY="youtube-dl"
FEATURE_ARIA2=false

# Disable when developing!
SELF_UPDATE=true

# Print a message to the user
# Arguments: <MESSAGE>
log() {
  echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
}

# Print an error message to the user
# Arguments: <MESSAGE>
err() {
  echo -e "\e[1m\e[31m ! $*\e[39m\e[0m"
}

# Replaces self with an updated version if available,
# then restart it with the same arguments
self_update() {
  local new_path
  new_path="$SELF_DIR/.new"

  if ! curl -Ls "$UPDATE_URL" >"$new_path"
  then
    log "Update check failed. Skipping..."
    rm -f "$new_path"
    return
  fi

  if ! cmp -s "$SELF" "$new_path"
  then
    log "Updating..."
    mv "$new_path" "$SELF"
    chmod +x "$SELF"
    log "Executing new self..."
    exec "$_SHELL" "$SELF" "${ARGS[@]}"
  fi

  rm -f "$new_path"
}

# Generate a youtube-dl archive for all the files that already exist
generate_archive() {
  local uid
  local archive

  # Find files in the format of "name sep id.ext"
  for file in *"$SEP"*.*
  do
    uid="$(echo "$file" | sed "s/.*$SEP //; s/\..*//")"
    archive+=("youtube $uid")
  done

  printf "%s\n" "${archive[@]}" > "$ARCHIVE"
}

# Parses the URL environmental variable and downloads it accordingly
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
# Arguments: <URL>
download_url() {
  local args
  args=(
    "--ignore-errors"
    "--download-archive" "$ARCHIVE"
    "--add-metadata"
    "--match-filter" "!is_live"
  )

  if [[ "$VIDEO" != "true" ]]
  then
    args+=(
      "--extract-audio"
      "--audio-quality" "0"
    )
  fi

  [[ -n "$COOKIES" ]] && args+=("--cookies" "$COOKIES")

  if [[ "$FEATURE_ARIA2" == true ]]
  then
    args+=(
      "--external-downloader" "aria2c"
      "--external-downloader-args" "$ARIA2_ARGS"
    )
  fi

  "${BINARY:-"$DEFAULT_BINARY"}" "${args[@]}" -o "$OUTPUT_FORMAT" "$1"
}

# Remove half-downloaded files from the current directory
clean_orphans() {
  rm -f -- **/"$ARCHIVE"
  rm -f -- **/*.part
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

  if [[ -z "$URL" ]]
  then
    err "Configuration incomplete. Skipping..."
  else
    log "Generating archives..."
    generate_archive

    log "Downloading..."
    download
  fi

  log "Cleaning up..."
  clean_orphans

  for env_var in "${ENV_VARIABLES[@]}"
  do
    unset "$env_var"
  done

  log "Backing out..."
  cd - > /dev/null || return
}

# Discover and process folders recursively from a starting path
# Arguments: <PATH>
discover() {
  local folder

  log "Discovering in '$1'..."

  for config in "$1"/**/"$CONFIG"
  do
    folder="$(dirname "$config")"
    process_folder "$folder"
  done
}

# Determine which FEATURE_* flags to enable based on the host system
determine_features() {
  command -v aria2c &> /dev/null && FEATURE_ARIA2=true
}

if [[ "$SELF_UPDATE" == "true" ]]
then
  log "Checking for updates..."
  self_update
fi

determine_features
discover "${1:-.}"

exit 0
