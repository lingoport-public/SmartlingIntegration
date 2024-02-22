#!/usr/bin/env bats

load 'test_helper/bats-assert/load'
load 'test_helper/bats-support/load'

setup() {
  export PATH_TO_GDRIVE=$(which gdrive)
  export SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID="1Lmg1zmSF0eCW_FdmSuBTmcofD_WApLhV"
  mkdir -p ./test/smartling_local_upload
  mkdir -p ./test/tmp
  export SMARTLING_LOCAL_UPLOAD_DIR="./test/smartling_local_upload"
  original_dir="$(pwd)"
  export TEST=true
  source send_to_smartling.sh
}

teardown() {
  cd "$original_dir"
  unset PATH_TO_GDRIVE
  unset SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID
  rm -r "$SMARTLING_LOCAL_UPLOAD_DIR"
  rm -r "./test/tmp"
  unset SMARTLING_LOCAL_UPLOAD_DIR
  unset TEST
}

@test "Test inaccessible Google Drive folder" {
  export SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID='invalid_folder_id'
  run main
  [ "$status" -eq 1 ]
  [ "${lines[1]}" = "Error. Could not access gdrive folder 'invalid_folder_id'" ]
}

@test "Test with non-directory SMARTLING_LOCAL_UPLOAD_DIR" {
  export SMARTLING_LOCAL_UPLOAD_DIR="./non_existing_dir"
  run main
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Error. Upload directory ./non_existing_dir not found or not a directory" ]
}

@test "Test clean_unzip with valid zip file" {
  cp ./test/fixtures/valid_zip.zip ./test/tmp/
  cd ./test/tmp/
  run clean_unzip "valid_zip.zip"
  [ "$status" -eq 0 ]
  [ -d "./valid_zip" ] # Assuming the content is extracted to a folder named test
}

@test "Test clean_unzip with existing folder" {
  cp ./test/fixtures/valid_zip.zip ./test/tmp/
  mkdir ./test/tmp/valid_zip
  cd ./test/tmp/
  run clean_unzip "valid_zip.zip"
  [ "$status" -eq 0 ]
  backup_dir_exists="$(find . -ipath "*.bak.*" | wc -l)"
  find .
  [ "$backup_dir_exists" -eq 1 ]
}

@test "Test clean_unzip with existing folder twice" {
  cp ./test/fixtures/valid_zip.zip ./test/tmp/
  mkdir ./test/tmp/valid_zip
  cd ./test/tmp/
  run clean_unzip "valid_zip.zip"
  run clean_unzip "valid_zip.zip"
  [ "$status" -eq 0 ]
  backup_dir_exists="$(find . -ipath "*.bak.*" | wc -l)"
  find .
  [ "$backup_dir_exists" -eq 3 ]
}

@test "Test clean_unzip with non-existent zip file" {
  run clean_unzip "non_existent.zip"
  [ "$status" -eq 1 ]
  [ "${lines[1]}" = "Error. Folder non_existent not present after unzipping non_existent.zip at $(pwd)" ]
}

@test "Test exists_in_gdrive_folder with existing folder" {
  run exists_in_gdrive_folder "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" "existing_folder_for_test"
  [ "$status" -eq 0 ]
}

@test "Test exists_in_gdrive_folder with non-existing folder" {
  run exists_in_gdrive_folder "$SMARTLING_GDRIVE_TO_TRANSLATION_FOLDER_ID" "non_existing_folder"
  [ "$status" -eq 1 ]
}
