import SwiftUI

/// A text field that shows an inline error message below when `error` is non-nil.
///
/// Usage:
/// ```swift
/// ValidatedTextField(
///     placeholder: "Email",
///     text: $email,
///     error: viewModel.emailError,
///     isSecure: false
/// )
/// ```
public struct ValidatedTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let error: String?
    private let isSecure: Bool

    public init(
        placeholder: String,
        text: Binding<String>,
        error: String? = nil,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.error = error
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.roundedBorder)
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
        ValidatedTextField(
            placeholder: "Email",
            text: .constant(""),
            error: "Enter a valid email address.",
            isSecure: false
        )

        ValidatedTextField(
            placeholder: "Password",
            text: .constant("secret"),
            error: nil,
            isSecure: true
        )
    }
    .padding()
}
