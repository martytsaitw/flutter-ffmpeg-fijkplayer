# Merge Script
 
# http://code.hootsuite.com/an-introduction-to-creating-and-distributing-embedded-frameworks-in-ios/

# 1
# Set bash script to exit immediately if any commands fail.
set -e
 
# 2
# Setup some constants for use later on.
FRAMEWORK_NAME="runffmpeg"

SRCROOT=`pwd`
 
# 3
# If remnants from a previous build exist, delete them.
if [ -d "${SRCROOT}/build" ]; then
rm -rf "${SRCROOT}/build"
fi
 
# 4
# Build the framework for device and for simulator (using
# all needed architectures).
xcodebuild -target "${FRAMEWORK_NAME}" -configuration Release -arch arm64 only_active_arch=no defines_module=yes -sdk "iphoneos"
xcodebuild -target "${FRAMEWORK_NAME}" -configuration Release -arch x86_64 only_active_arch=no defines_module=yes -sdk "iphonesimulator"
 
# 5
# Remove .framework file if exists on Desktop from previous run.
#if [ -d "${HOME}/Desktop/${FRAMEWORK_NAME}.framework" ]; then
#rm -rf "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"
#fi
 
# 6
# Copy the device version of framework to Desktop.
#cp -r "${SRCROOT}/build/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"
 
# 7
# Replace the framework executable within the framework with
# a new version created by merging the device and simulator
# frameworks' executables with lipo.
lipo -create -output "${SRCROOT}/build/lib${FRAMEWORK_NAME}.a" "${SRCROOT}/build/Release-iphoneos/lib${FRAMEWORK_NAME}.a" "${SRCROOT}/build/Release-iphonesimulator/lib${FRAMEWORK_NAME}.a"

# 8
# Copy the Swift module mappings for the simulator into the 
# framework.  The device mappings already exist from step 6.
# cp -r "${SRCROOT}/build/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${HOME}/Desktop/${FRAMEWORK_NAME}/${FRAMEWORK_NAME}.swiftmodule"
 
# 9
# Delete the most recent build.
#if [ -d "${SRCROOT}/build" ]; then
#rm -rf "${SRCROOT}/build"
#fi