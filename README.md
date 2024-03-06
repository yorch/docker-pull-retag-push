# docker-pull-retag-push

This script is used to pull a docker image, retag it and push it to another registry.

## Usage

Create a file named `images.txt` and add the Docker images to be pull, retag and pushed to a registry.

Example `images.txt`:

```txt
your-registry/repo/image1:1.0.0
your-registry/repo/image2:1.0.0
your-registry/repo/image3:1.0.0
your-registry/repo/image4:1.0.0
```

Run the script:

```bash
./docker-pull-retag-push.sh <new_image_prefix> <new_image_version>
```

## Example

```bash
./docker-pull-retag-push.sh \
    another-registry/some-repo/subpath/ \
    1.0.0-new
```

This will pull the images from the `images.txt` file, retag them and push them to the `another-registry/some-repo/subpath/` registry with the `1.0.0-new` version.

The result will be:

```txt
another-registry/some-repo/subpath/image1:1.0.0-new
another-registry/some-repo/subpath/image2:1.0.0-new
another-registry/some-repo/subpath/image3:1.0.0-new
another-registry/some-repo/subpath/image4:1.0.0-new
```

## License

MIT
