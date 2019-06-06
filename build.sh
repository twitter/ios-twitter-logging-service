#!/bin/sh

set -eu

function ci_lib() {
    NAME=$1
    xcodebuild -project TwitterLoggingService.xcodeproj \
               -scheme "TwitterLoggingService" \
               -destination "platform=iOS Simulator,name=${NAME}" \
               -sdk iphonesimulator \
               build test
}

function ci_demo() {
    NAME=$1
    xcodebuild -project TwitterLoggingService.xcodeproj \
               -scheme "ExampleLogger" \
               -destination "platform=iOS Simulator,name=${NAME}" \
               -sdk iphonesimulator \
               build
}

ci_lib "iPhone 8" && ci_demo "iPhone 8"
