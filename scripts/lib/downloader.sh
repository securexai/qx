#!/bin/bash

# Secure downloader module for QX installation script
# Provides secure downloads with checksum verification and retry logic

# Secure download with checksum verification
secure_download() {
    local url="$1"
    local output="$2"
    local expected_sha256="$3"
    local max_retries="${4:-3}"
    local timeout="${5:-300}"

    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        # Create secure temporary file
        local temp_file
        temp_file=$(mktemp -t qx-download.XXXXXX)
        chmod 600 "$temp_file"

        log_debug "Downloading: $url"
        log_debug "Temporary file: $temp_file"

        # Download with progress and timeout
        if curl --progress-bar \
                --fail \
                --max-time "$timeout" \
                --retry 2 \
                --retry-delay 1 \
                --retry-max-time 60 \
                --location \
                --output "$temp_file" \
                "$url" 2>&1 | while IFS= read -r line; do
                    log_debug "Download: $line"
                done; then

            # Verify file size
            if [ ! -s "$temp_file" ]; then
                log_error "Downloaded file is empty"
                rm -f "$temp_file"
                retry_count=$((retry_count + 1))
                continue
            fi

            # Verify checksum if provided
            if [ -n "$expected_sha256" ]; then
                local actual_sha256
                actual_sha256=$(sha256sum "$temp_file" | cut -d' ' -f1)

                if [ "$actual_sha256" != "$expected_sha256" ]; then
                    log_error "Checksum mismatch for $(basename "$output")"
                    log_error "Expected: $expected_sha256"
                    log_error "Actual: $actual_sha256"
                    rm -f "$temp_file"
                    retry_count=$((retry_count + 1))
                    continue
                fi
            fi

            # Move to final location
            mkdir -p "$(dirname "$output")"
            mv "$temp_file" "$output"
            log_success "Successfully downloaded: $(basename "$output")"
            return 0
        else
            log_error "Download failed for $(basename "$output")"
        fi

        # Clean up temp file
        rm -f "$temp_file"
        retry_count=$((retry_count + 1))

        if [ $retry_count -lt $max_retries ]; then
            local wait_time=$((retry_count * retry_count))
            log_warn "Retrying in ${wait_time}s... ($retry_count/$max_retries)"
            sleep "$wait_time"
        fi
    done

    log_failure "Failed to download after $max_retries attempts: $url"
    return 1
}

# Parallel download manager
parallel_download() {
    local -n downloads_ref=$1
    local max_parallel="${2:-3}"
    local pids=()
    local active=0
    local total=${#downloads_ref[@]}
    local completed=0

    log_info "Starting $total downloads with max $max_parallel parallel"

    for download in "${downloads_ref[@]}"; do
        # Wait for available slot
        while [ $active -ge $max_parallel ]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    wait "${pids[$i]}"
                    unset "pids[$i]"
                    active=$((active - 1))
                    completed=$((completed + 1))
                    log_progress "$completed" "$total" "Downloads completed"
                fi
            done
            sleep 0.1
        done

        # Start download in background
        (
            secure_download $download
        ) &
        pids+=($!)
        active=$((active + 1))
    done

    # Wait for remaining downloads
    for pid in "${pids[@]}"; do
        wait "$pid"
        completed=$((completed + 1))
        log_progress "$completed" "$total" "Downloads completed"
    done

    log_info "All downloads completed"
}

# Verify checksum of existing file
verify_checksum() {
    local file="$1"
    local expected_sha256="$2"

    if [ ! -f "$file" ]; then
        log_error "File does not exist: $file"
        return 1
    fi

    local actual_sha256
    actual_sha256=$(sha256sum "$file" | cut -d' ' -f1)

    if [ "$actual_sha256" = "$expected_sha256" ]; then
        log_debug "Checksum verified for: $(basename "$file")"
        return 0
    else
        log_error "Checksum verification failed for: $(basename "$file")"
        log_error "Expected: $expected_sha256"
        log_error "Actual: $actual_sha256"
        return 1
    fi
}

# Check if URL is accessible
check_url() {
    local url="$1"
    local timeout="${2:-10}"

    if curl --head --fail --max-time "$timeout" --silent "$url" >/dev/null 2>&1; then
        log_debug "URL is accessible: $url"
        return 0
    else
        log_debug "URL is not accessible: $url"
        return 1
    fi
}