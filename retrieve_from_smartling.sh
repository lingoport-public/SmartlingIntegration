#!/bin/bash

# Input Vars
# SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID
# SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID
# SMARTLING_LOCAL_DOWNLOAD_DIR

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

    if [[ -z "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID" ]] ; then
        die "Error. Please define var SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID"
    fi

    if [[ -z "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID" ]] ; then
        die "Error. Please define var SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID"
    fi

    if [[ -z "$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID" ]] ; then
        die "Error. Please define var SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID"
    fi

    if [[ -z "$SMARTLING_LOCAL_DOWNLOAD_DIR" ]] ; then
        die "Error. Please define var SMARTLING_LOCAL_DOWNLOAD_DIR"
    fi

    if ! gdrive files list --query "'$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID' in parents" > /dev/null ; then
        die "Error. Could not access gdrive folder '$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID'"
    fi

    if ! gdrive files list --query "'$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID' in parents" > /dev/null ; then
        die "Error. Could not access gdrive folder '$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID'"
    fi

    if [[ "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID" == "$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID" ]] ; then
       die "Error. LRM_FROM_TRANSLATIONS folder id must be different from the Archive folder id."
    fi

    if ! [[ -d "$SMARTLING_LOCAL_DOWNLOAD_DIR" ]] ; then
        die "Error. Upload directory $SMARTLING_LOCAL_DOWNLOAD_DIR not found or not a directory"
    fi
}

has_folders() {
    gdrive_folder="$1"
    results="$(gdrive files list --full-name --skip-header --query "mimeType = 'application/vnd.google-apps.folder' and '$gdrive_folder' in parents")"
    if [[ -z "$results" ]] ; then
        return 1
    fi
    return 0
}

# gdrive files list won't return everything if there are sufficient results,
# this may be a partial list
get_some_folder_names() {
    gdrive_folder="$1"
    gdrive files list --full-name --skip-header --query "mimeType = 'application/vnd.google-apps.folder' and '$gdrive_folder' in parents" --field-separator '_____' | awk -v FS="_____" '{print $2}'
}


# Get the first folder id from 1 or more matching folders under the matching
# parent folder
get_a_folder_id() {
    gdrive_parent_folder="$1"
    foldername="$2"
    gdrive files list --max 1 --full-name --skip-header --query "name = '$foldername' and mimeType = 'application/vnd.google-apps.folder' and '$gdrive_parent_folder' in parents" --field-separator '_____' | awk -v FS="_____" '{print $1}'
}

is_valid() {
    foldername="$1"
    if [[ ! -d "$foldername" ]] ; then
        return 1
    fi
    # should have a single subfolder with all content
    # E.g.
    # MyGroup.MyProject.My_Locale/my-locale/filea.properties
    # MyGroup.MyProject.My_Locale/my-locale/fileb.properties

    # Check a single subdir under main dir
    if [[ "$(find "$foldername" -mindepth 1 -maxdepth 1 -type d | wc -l)" -ne 1 ]] ; then
        return 1
    fi

    # At least one file in the subdir
    if [[ "$(find "$foldername" -mindepth 2 -type f | wc -l)" -lt 1 ]] ; then
        return 1
    fi

    return 0
}

correct_format() {
    foldername="$1"
    subfolder="$(find "$foldername" -mindepth 1 -maxdepth 1 -type d)"
    mv "$subfolder"/* "$foldername/"
    rm -r "$subfolder"
}

main() {
(
validations

cd "$SMARTLING_LOCAL_DOWNLOAD_DIR" || die "Error. Could not cd to $SMARTLING_LOCAL_DOWNLOAD_DIR"

# Smartling leaves each file in its own folder after translation
# so multiple folders in gdrive like
# from_tranlation/MyGroup.MyProject.My_Locale (id: abcxyz) (content: my-locale/filea.properties)
# from_tranlation/MyGroup.MyProject.My_Locale (id: cdelse) (content: my-locale/fileb.properties)
# from_tranlation/MyGroup.MyProject.My_Locale (id: defbcg) (condent: my-locale/filec.properties)
warnings=()
while has_folders "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID" ; do
    while read -r foldername ; do
        if [[ -z "$foldername" ]] ; then
            continue
        fi
        folderid="$(get_a_folder_id "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID" "$foldername")"
        if [[ -z "$folderid" ]] ; then
            die "Error. Could not get folder id for folder $foldername under $SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID ."
        fi
        gdrive files download --overwrite  --recursive "$folderid" || die "Error. Failed while attempted to download folder $folderid."
        if [[ ! -d "$foldername" ]] ; then
            die "Error. Failed while attempted to download folder $folderid. Folder not present after download attempt."
        fi
        if ! is_valid "$foldername" ; then
            gdrive files move "$folderid" "$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID" || die "Error. Failed to archive $folderid after download."
            die "Error: Folder $foldername found but is invalid. Expecting another subdirectory that contains all files."
        fi
        gdrive files move "$folderid" "$SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID" || die "Error. Failed to archive $folderid after download."
    done <<< "$(get_some_folder_names "$SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID")"
done

while read -r folder ; do
    foldername="$(basename "$folder")"
    if ! is_valid "$foldername" ; then
        warnings+=("WARN: Folder $foldername found but is invalid. Expecting another subdirectory that contains all files.")
        continue
    fi
    correct_format "$foldername"
    zip -r "$foldername.zip" "$foldername"
    rm -r "$foldername"
done <<< "$(find . -mindepth 1 -maxdepth 1 -type d)"

for warning in "${warnings[@]}" ; do
    echo -e >&2 "$warning"
done
)
}

if [[ -z "$TEST" ]] ; then
    main
fi
