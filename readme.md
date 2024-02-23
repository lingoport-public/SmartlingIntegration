# # GDrive File Management Scripts

These scripts are designed to facilitate file transfers between local directories and Google Drive, for the lingoport-smartling integration.

## Prerequisites

Before using these scripts, ensure the following prerequisites are met:

- Google Drive command-line utility (`gdrive`) is installed, configured with appropriate account details and permissions, and available in your system's PATH.
- Necessary Google Drive folder IDs and a local directory path are properly configured in each script.

See https://github.com/glotlabs/gdrive for download of gdrive and instructions to configure permissions.

Please follow the instructions in depth and be sure you can manually run gdrive commands on the target host (as the planned script user) before using these scripts.

## Configuration

Set/export values for variables `SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID`, `SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID`, `SMARTLING_LOCAL_DOWNLOAD_DIR`, `SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID`, and `SMARTLING_LOCAL_UPLOAD_DIR` with Google Drive folder IDs and local directory paths.

To get a folder ID, browse to the folder in your browser and look at the url. It will be something like: 
https://drive.google.com/drive/u/0/folders/1PC5NnN2YMkLzlQD-KmxDdjbgG4l4-3ZW

The long bit at the end, here 1P....3ZW , is the folder id.

## Usage

### Upload Script (`send_to_smartling.sh`)

This script uploads zipped folders from a local directory to a specified Google Drive folder. It checks for existing folders in the destination, unzips files, and performs a clean-up by removing the local copy after successful upload.

#### Steps:

1. Validate environment and parameters.
2. Navigate to the upload directory.
3. Process each `.zip` file: unzip, upload to Google Drive, and clean up.


### Download Script (`retrieve_from_smartling.sh`)

This script downloads files from a specified Google Drive folder, validates the downloaded content, restructures the files from Smartling's format to LRM's format (remove a nested subdir), zips them, and then moves the originals on Google Drive to an archive folder on gdrive.

#### Steps:

1. Validate environment and parameters.
2. Navigate to the download directory.
3. Check for folders in the Google Drive source folder.
4. Download, validate, and restructure folders.
5. Zip and remove the local folders after processing.
6. Move original folders to an archive location in Google Drive.

## Error Handling

Both scripts include error handling to ensure smooth execution. They will terminate with an error message if certain critical steps fail.


# TESTING

Using bats: https://github.com/bats-core/bats-core

Libraries added as git submodules to this repo, checkout all submodules before running tests

test helper is: ./test.sh

tests use some specific internal gdrive folders currently with Michael+Roger as editors. Please ask if you need access, or for details on the folder set up if you would like to create your own version. See the test/*.bats files for explicit ids.
