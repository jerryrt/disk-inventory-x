# Disk Inventory X

Disk Inventory X is a disk usage utility for macOS. It shows the sizes of
files and folders in a treemap, together with a Finder-like list and
statistics by file kind, so it is easy to see what takes up space on a
volume.

This repository continues [Disk Inventory X by Tjark Derlien][upstream],
which is no longer maintained, for current versions of macOS on Apple
silicon.

[upstream]: https://gitlab.com/tderlien/disk-inventory-x

## Requirements

- macOS 15 Sequoia or later
- a Mac with Apple silicon (the application is built for arm64 only)

## Building

The treemap view lives in the [TreeMapView][treemapview] submodule, so
clone recursively:

    git clone --recursive https://github.com/jerryrt/disk-inventory-x.git

or, in an existing clone:

    git submodule update --init

Open `Disk Inventory X.xcodeproj` in Xcode, or build from the command line:

    xcodebuild -project "Disk Inventory X.xcodeproj" \
        -scheme "Disk Inventory X" -configuration Release build

[treemapview]: https://gitlab.com/tderlien/treemapview-framework

### Project file

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
from `project.yml`. The generated project is committed, so XcodeGen is only
needed after changing `project.yml` or adding or removing files:

    xcodegen generate

### Code signing

The committed settings sign ad hoc, which is enough to build and run
locally. To sign with your own team, create `Config/Local.xcconfig`, which
is ignored by git:

    DEVELOPMENT_TEAM = ABCDE12345
    CODE_SIGN_IDENTITY = Apple Development

A build for distribution has to be exported with a Developer ID
certificate and notarized.

## Source layout

| Path | Contents |
| --- | --- |
| `DiskInventoryX/` | application sources (Objective-C, ARC) |
| `DiskInventoryX/Resources/` | interface files, images and localizations (English, German, French, Spanish) |
| `TreeMapView/` | treemap view, submodule (manual reference counting) |
| `Config/` | build configuration files |
| `documentation/` | release notes, known bugs and development notes |
| `artwork/` | source images of the application icon |

## License

Disk Inventory X is free software, distributed under the terms of the GNU
General Public License version 3 or (at your option) any later version. See
[COPYING](COPYING).

Disk Inventory X was created by Tjark Derlien. See the credits in the
application's About panel for everyone who contributed to the original
application.
