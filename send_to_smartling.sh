#!/bin/bash


# Input Vars
# SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID
# SMARTLING_LOCAL_UPLOAD_DIR

set +x # Overwrite jenkins default

die() {
    echo -e >&2 "$@"
    exit 1
}

validations() {
    path_to_gdrive="$(which gdrive)"
    if [[ -z "$path_to_gdrive" ]] ; then
        die "Error. gdrive executable not found. Is it installed on the system and present in your PATH?.\n\n PATH='$PATH'"
    fi

    if [[ ! -x "$path_to_gdrive" ]] ; then
        die "Error. gdrive found but not executable"
    fi

    if [[ -z "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" ]] ; then
        die "Error. Please define var SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID"
    fi

    if [[ -z "$SMARTLING_LOCAL_UPLOAD_DIR" ]] ; then
        die "Error. Please define var SMARTLING_LOCAL_UPLOAD_DIR"
    fi

    if ! gdrive files list --query "'$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID' in parents" > /dev/null ; then
        die "Error. Could not access gdrive folder '$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID'"
    fi

    if ! [[ -d "$SMARTLING_LOCAL_UPLOAD_DIR" ]] ; then
        die "Error. Upload directory $SMARTLING_LOCAL_UPLOAD_DIR not found or not a directory"
    fi
}

clean_unzip() {
    zipfile="$1"
    foldername="${zipfile%.zip}"
    while read -r existing_folder ; do
        if [[ -z "$existing_folder" ]] ; then
            continue
        fi
        changed="$(stat -c '%z' "$existing_folder")"
        mv "$existing_folder" "$existing_folder.bak.$changed"
    done <<< "$(find . -maxdepth 1 -iname "$foldername" -type d '!' -iname "*.bak.*")"
    unzip "$zipfile"
    if [[ -z "$(find . -maxdepth 1 -iname "$foldername" -type d)" ]] ; then
        die "Error. Folder $foldername not present after unzipping $zipfile at $(pwd)"
    fi
}

exists_in_gdrive_folder() {
    gdrive_folder="$1"
    name="$2"
    results="$(gdrive files list --skip-header --query "name = '$name' and '$gdrive_folder' in parents")"
    if [[ -z "$results" ]] ; then
        return 1
    fi
    return 0
}

main() {
(
validations

cd "$SMARTLING_LOCAL_UPLOAD_DIR" || die "Error. Could not cd to $SMARTLING_LOCAL_UPLOAD_DIR"

while read -r zipfile ; do
    if [[ -z "$zipfile" ]] ; then
        continue
    fi
    zipfile="$(basename "$zipfile")"
    zipdir="${zipfile%.zip}"
    clean_unzip "$zipfile"
    if exists_in_gdrive_folder "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" "${zipdir}" ; then
        echo "NOTE: ${zipdir} already present in gdrive. Not uploading."
    else
        gdrive files upload --recursive --parent "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" "$zipdir" || die "Error. Error occurred while uploading $zipdir to $SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID"
        if exists_in_gdrive_folder "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" "${zipdir}" ; then
            rm -r "$zipdir"
            rm "$zipfile"
        fi
    fi
done <<< "$(find . -maxdepth 1 -name "*.zip")"
)

}

if [[ -z "$TEST" ]] ; then
    main
fi
