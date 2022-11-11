> **Note** currently this app is only available for **Windows** and **Linux**.

## File Checksum

File checksum is an old technique to verify the integrity of a file.

And this repository aims to provide an GUI for Windows and Linux to generate the MD5 and SHA file hashes (checksum).

## Windows installation

On Windows, just download the latest release on the **Releases** tab and open the `filechecksum.exe` file.

## Linux installation

1. Install dependencies:

```shell
sudo apt-get install libgcrypt20 libgtk-3-0 liblz4-1 liblzma5 libstdc++6
```

2. Download the latest release `linux-arm64-v0.1.0.zip`.

3. Double-click to open `filechecksum`.

## App screenshot and usage

Since the Flutter framework relies on custom paiting, the appearence (GUI) looks the same on Windows and Linux.

<p align="center">
  <kbd><img src="https://user-images.githubusercontent.com/51419598/200956830-d0ad75fd-c928-417a-a43a-a5aeff8e452b.png" height="400" /></kbd>
  <kbd><img src="https://user-images.githubusercontent.com/51419598/200956761-0468db84-5191-474b-8cc5-4cb456468284.png" height="400" /></kbd>
</p>

https://user-images.githubusercontent.com/51419598/200956104-c5333af1-d813-4448-8801-4f88bc70a51b.mp4

## Build binaries on Windows

Make sure you have a [configured Flutter environment for Windows](https://docs.flutter.dev/get-started/install/windows).

Then you can generate the `.exe` by running:

```shell
flutter build windows
```

The generated bundle output is: `<project-root>\build\windows\runner\Release`.

## Build binaries on Linux:

Make sure you have a [configured Flutter environment for Linux](https://docs.flutter.dev/get-started/install/linux).

To build for Linux, run:

```shell
flutter build linux
```

(Optional) To find Linux dependencies:

```shell
flutter_to_debian dependencies
```

The generated bundle output is: `<project-root>/build/linux/x64/release`.

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
