//
//  WetConditionsWarning.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct WetConditionsWarning: View {
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Warning: Park may be too Wet")
                .foregroundColor(.yellow)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
}
