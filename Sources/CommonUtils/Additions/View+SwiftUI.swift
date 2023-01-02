//
//  View+SwiftUI.swift
//  
//
//  Created by Ilya Kuznetsov on 31/12/2022.
//

import SwiftUI

public extension View {
    
    var asAny: AnyView { AnyView(self) }
}
