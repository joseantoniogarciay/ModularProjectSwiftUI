import SwiftUI
import UIKit

/// A text or secure field with an inline error message below it.
///
/// Usage:
/// ```swift
/// ValidatedTextField(
///     placeholder: "Email",
///     text: $email,
///     isSecure: false,
///     error: emailError
/// )
/// ```
public struct ValidatedTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let isSecure: Bool
    private let error: String?
    private let contentType: UITextContentType?
    private let keyboardType: UIKeyboardType

    public init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        error: String? = nil,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.error = error
        self.contentType = contentType
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .textFieldStyle(.roundedBorder)
            .textContentType(contentType)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel(error)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ValidatedTextField(placeholder: "Email", text: .constant(""))
        ValidatedTextField(
            placeholder: "Password",
            text: .constant(""),
            isSecure: true,
            error: "This field is required."
        )
    }
    .padding()
}
