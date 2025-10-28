//
//  SimpleFocusWidgetBundle.swift
//  SimpleFocusWidget
//
//  Created by Zifeng Guo on 2025-10-18.
//

import WidgetKit
import SwiftUI

@main
struct SimpleFocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimpleFocusWidget()
        if #available(iOS 17.0, *) {
            SimpleFocusWidgetLiveActivity()
        }
    }
}
