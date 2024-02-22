#!/usr/bin/env bats

load 'test_helper/bats-assert/load'
load 'test_helper/bats-support/load'


setup() {
  export SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID="1PC5NnN2YMkLzlQD-KmxDdjbgG4l4-3ZW"
  export SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID="1q05i4j4UhD3_Uq6DS2HHvxljGCyhynIP"
  export SMARTLING_LOCAL_DOWNLOAD_DIR="./test/smartling_local_download"
  mkdir -p ./test/smartling_local_download
  mkdir -p ./test/tmp
  mkdir -p ./test/tmp/invalid_folder_empty_subfolder/fr-FR # can't cgit commit empty folder
  original_dir="$(pwd)"
  export TEST=true
  source retrieve_from_smartling.sh
}

teardown() {
  unset SMARTLING_GDRIVE_FROM_TRANSLATION_FOLDER_ID
  unset SMARTLING_GDRIVE_ARCHIVE_FOLDER_ID
  unset SMARTLING_LOCAL_DOWNLOAD_DIR
  unset TEST
  cd "$original_dir"
  rm -r ./test/smartling_local_download
  rm -r ./test/tmp
}

@test "Test has_folders empty" {
  run has_folders "1sElngvJtELcCPbQY7pqs6gsFTCJ0QFcZ"
  [ "$status" -eq 1 ]
}

@test "Test has_folders files only" {
  run has_folders "180uLneKz2WbeTjoYVoa-S7yyMe_-NrvV"
  [ "$status" -eq 1 ]
}

@test "Test has_folders one folder" {
  run has_folders "1nFqw_9kxrp_qJgyp-MIVaFbdpLCTzl3i"
  [ "$status" -eq 0 ]
}

@test "Test has_folders many folders" {
  run has_folders "1yyPKBxEzW-vkutgVkCU8WDlDa7ON3lqj"
  [ "$status" -eq 0 ]
}

@test "Confirm get_some_folder_names gets reasonable names" {
  folder_names_sorted="$(get_some_folder_names "11QSMxR9cyaaj1NtJQv5IJ99lPg8DXzw8"|sort)"  # files and folders in that folder
  echo -n "$folder_names_sorted"
  expected_sorted_output="folder1
Validations.smartling.1.fr_FR"
  [ "$folder_names_sorted" = "$expected_sorted_output" ]
}

@test "Confirm get_a_folder_id gets right id" {
  folder_id="$(get_a_folder_id "11QSMxR9cyaaj1NtJQv5IJ99lPg8DXzw8" "Validations.smartling.1.fr_FR")"
  echo "$folder_id"
  expected_id="1mQIAeQBzWWx_sMCB8rJDlw-157XRjF3C"
  [ "$folder_id" = "$expected_id" ]
}

@test "Confirm is_valid passes valid folder" {
  run is_valid ./test/fixtures/valid_folder/
  [ "$status" -eq 0 ]
}

@test "Confirm is_valid fails dir without subfolder" {
  run is_valid ./test/fixtures/invalid_folder_no_subfolder
  [ "$status" -eq 1 ]
}

@test "Confirm is_valid fails dir empty subfolder" {
  run is_valid ./test/tmp/invalid_folder_empty_subfolder
  [ "$status" -eq 1 ]
}

@test "Confirm correct_format removes subfolder" {
  cp -r ./test/fixtures/valid_folder ./test/tmp/
  correct_format ./test/tmp/valid_folder
  [ -f  ./test/tmp/valid_folder/resource.properties ]
  [ -f  ./test/tmp/valid_folder/resource2.properties ]
  [ ! -d  ./test/tmp/valid_folder/fr-FR ]
  find ./test/tmp/valid_folder/
}
