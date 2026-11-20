//
//  AvatarView.swift
//  durian.health
//

import SwiftUI

/// Circular profile picture from `User.image` (stored in MongoDB; for Google accounts
/// it's the Google profile photo URL). Falls back to the user's initials.
struct AvatarView: View {
    let user: User
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else if phase.error != nil {
                        initials
                    } else {
                        ProgressView()
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .background(Color.durianGreen.opacity(0.15))
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var initials: some View {
        Text(initialsText)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(Color.durianGreen)
    }

    private var initialsText: String {
        let source = user.name?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? user.email
        let words = source.split(separator: " ").prefix(2)
        let letters = words.count > 1 ? words.compactMap(\.first) : Array(source.prefix(1))
        return String(letters).uppercased()
    }

    /// Only http(s) URLs. Google photo URLs end in a size such as "=s96-c"; ask for a
    /// size that stays sharp on Retina screens.
    private var imageURL: URL? {
        guard let raw = user.image?.trimmingCharacters(in: .whitespaces), !raw.isEmpty,
              var url = URL(string: raw),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return nil }

        if url.host()?.hasSuffix("googleusercontent.com") == true,
           let range = raw.range(of: #"=s\d+-c$"#, options: .regularExpression),
           let resized = URL(string: raw.replacingCharacters(in: range, with: "=s\(Int(size * 3))-c")) {
            url = resized
        }
        return url
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    HStack {
        AvatarView(user: User(id: "1", name: "Farn Xin Yang", email: "farn@example.com", image: nil))
        AvatarView(user: User(id: "2", name: nil, email: "xy@example.com", image: nil), size: 40)
    }
}
