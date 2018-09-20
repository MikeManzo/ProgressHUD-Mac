# ProgressHUD
`ProgressHUD` is a clean and easy-to-use HUD meant to display the progress of an ongoing task on macOS. 
 
[![Build Status](https://travis-ci.com/massimobio/ProgressHUD.svg?token=2EEVFqEqxnnpFcQYpwaE&branch=master)](https://travis-ci.com/massimobio/ProgressHUD)
[![macOS](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/mojave/)
[![Swift 4.2](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@MassimoBi0lcati-blue.svg)](https://twitter.com/MassimoBi0lcati) 
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

Displays a simple HUD containing an optional progress indicator or cusom view and optional title and message.
The ProgressHUD spans over the entire view it is attached to.

 ![Indeterminate](hud-indeterminate.gif)
 
## Features

- [x] Easy to use API as extension to NSView
- [x] Sensible defaults for one line instantiation
- [x] Highly customizable theme and settings
- [x] Option to prevent user operations on components below the view.

## Requirements

- macOS 10.11+
- Xcode 10

## Installation

#### CocoaPods
- [ ] TODO

#### Manually
1. Download and drop  ```ProgressHUD.swift```  in your project.  
2. Congratulations!  

## Usage example

One liner:
```swift
view.showProgressHUD(title: "Error", message: "Message",  mode: .error, duration: 2)
```
Basic customization:
```swift
view.showProgressHUD(title: "Doing Stuff",
                     message: "Completing something…",
                     mode: .indeterminate,
                     style: .light,
                     maskType: .black,
                     position: .center,
                     duration: 2)
```
Advanced customization:
```swift
var settings = ProgressHUDSettings()
settings.titleFont = NSFont.boldSystemFont(ofSize: 20)
settings.messageFont = NSFont.systemFont(ofSize: 18)
settings.opacity = 0.8
settings.spinnerSize = 40
settings.margin = 10
settings.padding = 8
settings.cornerRadius = 15
settings.dismissible = false
settings.square = true

let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
imageView.image = NSImage(named: "unicorn")!
view.showProgressHUD(title: "Custom View",
                     message: "I am not a horse",
                     mode: .custom(view: imageView),
                     style: hudStyle,
                     maskType: hudMaskType,
                     position: hudPosition,
                     duration: 4,
                     settings: settings)
```
Setting the duration to 0 shows the ProgressHUD indefinitely. To Hide it:
```swift
view.hideProgressHUD()
```
For determinate progress indication use the following after showing the ProgressHUD with duration 0:
```swift
view.setProgressHUDProgress(progress)
```
(can be called safely from a background thread.)

## Todo's

- [ ] Add support for Cocoapods
- [ ] Look into Mojave's dark mode
- [ ] Add tests

## Contribute

We would love you for any contribution to **ProgressHUD**, check the ``LICENSE`` file for more info.

## Meta

Massimo Biolcati – [@MassimoBi0lcati](https://twitter.com/MassimoBi0lcati)  [@iRealProApp](https://twitter.com/iRealProApp) 

`ProgressHUD` is distributed under the terms and conditions of the [MIT license](https://github.com/massimobio/ProgressHUD/blob/master/LICENSE.md).
