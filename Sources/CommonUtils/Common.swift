//
//  Common.swift
//

import Foundation

#if os(iOS)
import UIKit

public typealias PlatformView = UIView

#else
import AppKit

public typealias PlatformView = NSView

#endif
