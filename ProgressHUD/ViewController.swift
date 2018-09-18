//
//  ViewController.swift
//  ProgressHUD, https://github.com/massimobio/ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var styleSegmentedControl: NSSegmentedControl!
    @IBOutlet var maskSegmentedControl: NSSegmentedControl!
    @IBOutlet var positionSegmentedControl: NSSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showIndeterminate(_ sender: Any) {
        view.showProgressHUD(title: "Doing Stuff", message: "Completing something…", mode: .indeterminate, settings: demoSettings, duration: 2)
    }

    @IBAction func showDeterminateCircular(_ sender: Any) {
        view.showProgressHUD(title: "Determinate Progress", message: "Almost done…", mode: .determinate, settings: demoSettings)
        DispatchQueue.global(qos: .default).async {
            var progress = 0.0
            for _ in 0..<100 {
                usleep(10000)
                progress += 0.01
                self.view.setProgressHUDProgress(progress)
            }
            self.view.hideProgressHUD()

        }
    }

    @IBAction func showCustomView(_ sender: Any) {
        let image = NSImage(named: "unicorn")!
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        imageView.image = image
        view.showProgressHUD(title: "Custom View", message: "I am not a horse", mode: .custom(view: imageView), settings: demoSettings, duration: 2)
    }

    @IBAction func showTextOnly(_ sender: Any) {
        view.showProgressHUD(title: "Message 🎸", message: "Showing text only.\nOn multiple lines.\nSquashed much?", mode: .text, settings: demoSettings, duration: 2)
    }

    private var demoSettings: ProgressHUDSettings {
        var settings = ProgressHUDSettings()
        settings.mode = .indeterminate
        settings.maskType = hudMaskType
        settings.style = hudStyle
        settings.position = hudPosition
        return settings
    }

    private var hudStyle: ProgressHUDStyle {
        switch styleSegmentedControl.selectedSegment {
        case 0: return .light
        case 1: return .dark
        default: return .custom(foreground: .yellow, backgroud: .red)
        }
    }

    private var hudMaskType: ProgressHUDMaskType {
        switch maskSegmentedControl.selectedSegment {
        case 0: return .none
        case 1: return .clear
        case 2: return .black
        default: return .none
        }
    }

    private var hudPosition: ProgressHUDPosition {
        switch positionSegmentedControl.selectedSegment {
        case 0: return .top
        case 1: return .center
        default: return .bottom
        }
    }

}
