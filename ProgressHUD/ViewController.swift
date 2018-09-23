//
//  ViewController.swift
//  ProgressHUD, https://github.com/massimobio/ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private var locationSegmentedControl: NSSegmentedControl!
    @IBOutlet private var modeSegmentedControl: NSSegmentedControl!
    @IBOutlet private var styleSegmentedControl: NSSegmentedControl!
    @IBOutlet private var maskSegmentedControl: NSSegmentedControl!
    @IBOutlet private var positionSegmentedControl: NSSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showHUD(_ sender: Any) {

        // set ProgressHUD defaults according to user selected options
        ProgressHUD.shared.style = hudStyle
        ProgressHUD.shared.maskType = hudMaskType
        ProgressHUD.shared.position = hudPosition
        ProgressHUD.shared.containerView = locationSegmentedControl.selectedSegment == 0 ? view : nil

        switch modeSegmentedControl.selectedSegment {

        case 0: // Indeterminate
            ProgressHUD.shared.mode = .indeterminate
            ProgressHUD.show(withStatus: "Indeterminate Progress…")
            ProgressHUD.dismiss(delay: 2)

        case 1: // Determinate
            ProgressHUD.shared.mode = .determinate
            ProgressHUD.show(withStatus: "Determinate Progress…")
            DispatchQueue.global(qos: .default).async {
                var progress = 0.0
                for _ in 0..<100 {
                    usleep(10000)
                    progress += 0.01
                    ProgressHUD.show(progress: progress, status: "Determinate Progress…")
                }
                ProgressHUD.dismiss(delay: 1)
            }

        case 2: // Error
            ProgressHUD.shared.mode = .error
            ProgressHUD.show(withStatus: "Something bad happened!")
            ProgressHUD.dismiss(delay: 2)

        case 3: // Success
            ProgressHUD.shared.mode = .success
            ProgressHUD.show(withStatus: "Everything worked out in the end")
            ProgressHUD.dismiss(delay: 2)

        case 4: // Text Only
            ProgressHUD.shared.mode = .text
            ProgressHUD.show(withStatus: "Showing text only.\nOn multiple lines.\nSquashed much?")
            ProgressHUD.dismiss(delay: 2)

        case 5: // Custom View
            let image = NSImage(named: "unicorn")!
            let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            imageView.image = image
            ProgressHUD.shared.mode = .custom(view: imageView)
            ProgressHUD.show(withStatus: "I'm not a horse")
            ProgressHUD.dismiss(delay: 2)

        default:
            break
        }
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
        default: return .custom(color: NSColor.green.withAlphaComponent(0.6))
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
