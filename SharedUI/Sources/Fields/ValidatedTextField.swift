import SwiftUI

/// Semantic content hints for a `ValidatedTextField`, mapped to the platform's text-content
/// types internally. Keeping the public surface in our own enum avoids importing UIKit here.
public enum TextFieldContent {
    case username
    case email
    case password
    case newPassword
}

/// The keyboard layout a `ValidatedTextField` should request, mapped to the platform's
/// keyboard types internally. Native wrapper so callers never touch UIKit.
public enum TextFieldKeyboard {
    case `default`
    case email
}

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
    private let contentType: TextFieldContent?
    private let keyboardType: TextFieldKeyboard

    public init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        error: String? = nil,
        contentType: TextFieldContent? = nil,
        keyboardType: TextFieldKeyboard = .default
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
            VStack(spacing: 0) {
                field
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(height: 44)

                SharedUIAsset.secondaryText.swiftUIColor
                    .opacity(0.3)
                    .frame(height: 1)
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.bannerErrorForeground.swiftUIColor)
                    .accessibilityLabel(error)
            }
        }
    }

    /// The secure or plain field, with the content/keyboard hints mapped to platform types.
    /// The leading-dot literals resolve against the modifiers' inferred parameter types, so
    /// the UIKit `UITextContentType`/`UIKeyboardType` are never named here.
    @ViewBuilder
    private var field: some View {
        if isSecure {
            applyContentType(SecureField(placeholder, text: $text))
        } else {
            applyKeyboard(applyContentType(TextField(placeholder, text: $text)))
        }
    }

    @ViewBuilder
    private func applyContentType<V: View>(_ view: V) -> some View {
        switch contentType {
        case .username:    view.textContentType(.username)
        case .email:       view.textContentType(.emailAddress)
        case .password:    view.textContentType(.password)
        case .newPassword: view.textContentType(.newPassword)
        case nil:          view.textContentType(nil)
        }
    }

    @ViewBuilder
    private func applyKeyboard<V: View>(_ view: V) -> some View {
        switch keyboardType {
        case .default: view.keyboardType(.default)
        case .email:   view.keyboardType(.emailAddress)
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
