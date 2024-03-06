#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# If any command has a non-zero exit status, print the error before exiting
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'if [ $? -ne 0 ]; then echo "ERROR: \"${last_command}\" command filed with exit code $?."; fi' EXIT

# This script reads Docker images from a file and pushes them to a Docker registry.

# Usage:
# 1. Create a file named images.txt and add the Docker images to be pushed to the registry.
# 2. Run the script using the following command:
#    bash docker-pull-retag-push.sh <new_image_prefix> <new_image_version>

# Example images.txt file:
# alpine:3.12
# nginx:1.19.0
# ubuntu:20.04

################################################################################
# Variables
################################################################################

# Define the file containing Docker images
images_file="images.txt"

# Define log file
log_file="docker_operations.log"

# Define dry_run variable, set to false to perform the operations
dry_run=false


################################################################################
# Functions
################################################################################

# Function to extract the last component of a string
extract_last_component() {
    local text="${1}"
    local last_component="${text##*/}"  # Extract substring after the last slash
    echo "${last_component}"
}

make_new_tag() {
    local image="${1}"
    local new_image_prefix="${2}"
    local new_image_version="${3}"
    # Extract image name without tag
    image_name=$(echo "${image}" | cut -d: -f1)
    # Extract the last component of the image name (after the last slash)
    image_name=$(extract_last_component "${image_name}")
    echo "${new_image_prefix}/${image_name}:${new_image_version}"
}


################################################################################
# Input
################################################################################

new_image_prefix="${1}"

# Check if new_image_prefix is provided
if [ -z "${new_image_prefix}" ]; then
    echo
    echo "Please provide a new image prefix."
    exit 1
fi

# Check if new_image_prefix contains a slash at the end, if so, remove it
if [[ "${new_image_prefix}" == */ ]]; then
    new_image_prefix="${new_image_prefix%/}"
fi

echo
echo "New image prefix: ${new_image_prefix}"

new_image_version="${2}"

# Check if new_image_version is provided
if [ -z "${new_image_version}" ]; then
    echo
    echo "Please provide a new image version."
    exit 1
fi

echo
echo "New image version: ${new_image_version}"


################################################################################
# General checks
################################################################################

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if images file exists
if [ ! -f "${images_file}" ]; then
    echo
    echo "${images_file} file not found."
    exit 1
fi


################################################################################
# Main
################################################################################

# Read Docker images from the file and store them in an array
echo
echo "Reading Docker images from ${images_file}..."
echo

docker_images=()
while IFS= read -r line; do
    docker_images+=("$line")
done < "${images_file}"

echo "Found ${#docker_images[@]} images to push to the registry."
echo

# Print the images to be pushed and their new tags
echo "Images to be pushed to the registry:"
echo

for image in "${docker_images[@]}"; do
    new_image=$(make_new_tag "${image}" "${new_image_prefix}" "${new_image_version}")
    echo "${image}"
    echo "    -> ${new_image}"
done

# Wait to continue
echo
read -p "Press Enter to continue or Ctrl+C to exit..."

# Print current date and time to log file
echo >> "${log_file}"
echo "--- Docker operations ---" >> "${log_file}"
echo "== Date: $(date)" >> "${log_file}"
echo >> "${log_file}"

# Loop through each image defined in the array
for image in "${docker_images[@]}"; do
    echo "Pulling ${image}"
    if [ "${dry_run}" = false ]; then
        docker pull "${image}" >> "${log_file}" 2>&1
    fi
    echo "Image has been successfully pulled."

    if [ $? -eq 0 ]; then
        new_image=$(make_new_tag "${image}" "${new_image_prefix}" "${new_image_version}")

        # Tagging the image with a new name
        echo "Tagging ${image} -> ${new_image}"
        # Run docker tag only if dry_run is false
        if [ "${dry_run}" = false ]; then
            docker tag "${image}" "${new_image}" >> "${log_file}" 2>&1
        fi

        # Pushing the tagged image to Docker registry
        echo "Pushing ${new_image}"
        if [ "${dry_run}" = false ]; then
            docker push "${new_image}" >> "${log_file}" 2>&1
        fi

        if [ $? -eq 0 ]; then
            echo "Image ${image} has been successfully pulled, tagged, and pushed as ${new_image}." | tee -a "${log_file}"
        else
            echo "Failed to push the tagged image ${new_image}." | tee -a "${log_file}"
        fi
    else
        echo "Failed to pull the image ${image}." | tee -a "${log_file}"
    fi
    echo
done

echo "All images have been pushed to the registry."
echo
echo "Log file: ${log_file}"
echo

# Exit with a success status
exit 0
