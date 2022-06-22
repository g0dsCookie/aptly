#!/bin/bash

declare -A SOURCES

for publish_json in $(aptly publish list -json | jq -r '.[] | @base64'); do
    prefix="$(echo -n "${publish_json}" | base64 -d | jq -r '.Prefix')"
    distribution="$(echo -n "${publish_json}" | base64 -d | jq -r '.Distribution')"
    source_kind="$(echo -n "${publish_json}" | base64 -d | jq -r '.SourceKind')"
    read -ra sources <<<"$(echo -n "${publish_json}" | base64 -d | jq -r '.Sources[].Name')"

    if [[ "${source_kind}" != "snapshot" ]]; then
        echo "${prefix}-${distribution} has unknown SourceKind, skipping!"
        continue
    fi

    for source in "${sources[@]}"; do
        snap_source_kind="$(aptly snapshot show -json "${source}" | jq -r '.SourceKind')"
        if [[ "${snap_source_kind}" != "repo" ]]; then
            echo "${source} has unknown SourceKind, skipping!"
            continue
        fi
        if [[ -z "${SOURCES[${source}]:-}" ]]; then
            SOURCES[${source}]="${prefix};${distribution}"
        else
            SOURCES[${source}]="${SOURCES[${source}]},${prefix};${distribution}"
        fi
    done
done

for source in "${!SOURCES[@]}"; do
    echo "Updating ${source}"
    aptly mirror update "${source}"
    if aptly snapshot list -raw | grep -q "${source}-old"; then
        aptly snapshot drop "${source}-old"
    fi
    aptly snapshot rename "${source}" "${source}-old"
    aptly snapshot create "${source}" from mirror "${source}"
done

for source in "${!SOURCES[@]}"; do
    IFS=',' read -ra source_publishes <<<"${SOURCES[${source}]}"
    for publish in "${source_publishes[@]}"; do
        IFS=';' read -r prefix distribution <<<"${publish}"
        echo "Updating ${source}-${distribution}@${prefix}"
        aptly publish switch "${distribution}" "${prefix}" "${source}"
    done
done

echo "Cleaning up database"
aptly db cleanup
