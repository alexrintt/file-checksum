## File Checksum

File checksum is an old technique to verify the integrity of a file.

And this repository aims to provide an GUI for Windows and Linux to generate the MD5 and SHA file hashes (checksum).

Take for instance the SHA-256 hash of the initial version of this app is: **d046d6b1453e708b144ce791f745d15e087fa78fb0219bc51223ad02b5f2c1e2**.

Any other hash means it was modified some way.

## Installation

Currently this is app is only available for **Windows** and **Linux**.

### Windows

On Windows, just download the latest release on the **Releases** tab and open the `filechecksum.exe` file.

### Linux

1. Install dependencies:

```shell
sudo apt-get install libgcrypt20 libgtk-3-0 liblz4-1 liblzma5 libstdc++6
```

2. Download the latest release `linux-arm64-v0.1.0.zip`.

3. Double-click to open `filechecksum`.

## App screenshot and usage

Some desktop app screenshots:

<p align="center">
  <kbd><img src="https://user-images.githubusercontent.com/51419598/200956830-d0ad75fd-c928-417a-a43a-a5aeff8e452b.png" height="400" /></kbd>
  <kbd><img src="https://user-images.githubusercontent.com/51419598/200956761-0468db84-5191-474b-8cc5-4cb456468284.png" height="400" /></kbd>
</p>

Video usage:

https://user-images.githubusercontent.com/51419598/200956104-c5333af1-d813-4448-8801-4f88bc70a51b.mp4

## Build

- Windows:

```shell
flutter build windows
```

- Linux:

To build for Linux (.deb package), run:

```shell
# Generate Linux package files.
flutter build linux

# Helper package to bundle the package files into a .deb bundle.
dart pub global activate flutter_to_debian

# Generate the .deb bundle.
flutter_to_debian
```

(Optional) To find Linux dependencies:

```shell
flutter_to_debian dependencies
```

You must pack these dependencies into the `debian.yaml` file into the `depends` key separated by comma `,`.

<br>

<samp>

<h2 align="center">
  Open Source
</h2>
<p align="center">
  <sub>Copyright © 2022-present, Alex Rintt.</sub>
</p>
<p align="center">File Checksum <a href="https://github.com/alexrintt/filechecksum/blob/master/LICENSE">is MIT licensed 💖</a></p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/51419598/200957627-84a73ae0-2c5a-4563-994b-7fc9423f482a.png" width="35" />
</p>
  
</samp>
