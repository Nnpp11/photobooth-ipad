import SwiftUI

struct ConsentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventStore: EventStore

    @State private var disclaimerAccepted = false
    @State private var galleryConsent: GalleryConsent = .undecided
    @State private var email = ""
    @State private var firstName = ""
    @State private var surveyAnswer = ""
    @State private var appeared = false
    @State private var showEmailField = false

    enum GalleryConsent { case undecided, yes, no }

    private var event: Event? { eventStore.activeEvent }
    private var canContinue: Bool {
        disclaimerAccepted && galleryConsent != .undecided
    }

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()
            DS.Gradient.goldSubtle.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    header
                    disclaimerSection
                    gallerySection
                    personalSection
                    if let question = event?.customQuestion, !question.isEmpty {
                        customQuestionSection(question)
                    }
                    continueButton
                    Spacer(minLength: DS.Spacing.xxl)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(DS.Animation.smooth.delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header
    var header: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(DS.Gradient.gold)
            Text("Avant de continuer")
                .font(DS.Font.display(32, weight: .thin))
                .foregroundColor(DS.Color.offWhite)
        }
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.1), value: appeared)
    }

    // MARK: - Disclaimer
    var disclaimerSection: some View {
        ConsentCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Label("Conditions d'utilisation", systemImage: "doc.text")
                    .font(DS.Font.label(15, weight: .semibold))
                    .foregroundColor(DS.Color.gold)

                Text("En participant au photobooth, vous acceptez que votre image soit utilisée dans le cadre de cet événement. Vous pouvez à tout moment demander la suppression de vos photos.")
                    .font(DS.Font.caption(14))
                    .foregroundColor(DS.Color.muted)
                    .lineSpacing(4)

                Button {
                    withAnimation(DS.Animation.fast) {
                        disclaimerAccepted.toggle()
                    }
                } label: {
                    HStack(spacing: DS.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(disclaimerAccepted ? DS.Color.gold : DS.Color.muted, lineWidth: 1.5)
                                .frame(width: 26, height: 26)
                            if disclaimerAccepted {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(DS.Gradient.gold)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DS.Color.background)
                            }
                        }
                        Text("J'accepte les conditions d'utilisation de l'image")
                            .font(DS.Font.label(14))
                            .foregroundColor(disclaimerAccepted ? DS.Color.offWhite : DS.Color.muted)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(DS.Animation.smooth.delay(0.2), value: appeared)
    }

    // MARK: - Gallery Consent
    var gallerySection: some View {
        ConsentCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Label("Galerie de l'événement", systemImage: "photo.stack")
                    .font(DS.Font.label(15, weight: .semibold))
                    .foregroundColor(DS.Color.gold)

                Text("Souhaitez-vous que votre photo apparaisse dans la galerie partagée de l'événement ?")
                    .font(DS.Font.caption(14))
                    .foregroundColor(DS.Color.muted)
                    .lineSpacing(4)

                HStack(spacing: DS.Spacing.md) {
                    ConsentChoiceButton(
                        title: "Oui, afficher",
                        icon: "eye",
                        isSelected: galleryConsent == .yes
                    ) { withAnimation(DS.Animation.fast) { galleryConsent = .yes } }

                    ConsentChoiceButton(
                        title: "Non, garder privé",
                        icon: "eye.slash",
                        isSelected: galleryConsent == .no
                    ) { withAnimation(DS.Animation.fast) { galleryConsent = .no } }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(DS.Animation.smooth.delay(0.3), value: appeared)
    }

    // MARK: - Personal Info
    var personalSection: some View {
        ConsentCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Label("Vos informations (optionnel)", systemImage: "person")
                    .font(DS.Font.label(15, weight: .semibold))
                    .foregroundColor(DS.Color.gold)

                HStack(spacing: DS.Spacing.md) {
                    StyledTextField(
                        placeholder: "Prénom",
                        text: $firstName,
                        icon: "person.fill"
                    )

                    Button {
                        withAnimation(DS.Animation.fast) { showEmailField.toggle() }
                    } label: {
                        Label("Email", systemImage: showEmailField ? "envelope.fill" : "envelope")
                            .font(DS.Font.label(13))
                            .foregroundColor(showEmailField ? DS.Color.gold : DS.Color.muted)
                            .padding(.horizontal, DS.Spacing.md)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(DS.Color.surfaceHigh)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                                            .strokeBorder(showEmailField ? DS.Color.gold.opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                            )
                    }
                }

                if showEmailField {
                    StyledTextField(
                        placeholder: "votre@email.com",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(DS.Animation.smooth.delay(0.4), value: appeared)
    }

    // MARK: - Custom Question
    func customQuestionSection(_ question: String) -> some View {
        ConsentCard {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Label(question, systemImage: "questionmark.bubble")
                    .font(DS.Font.label(15, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
                StyledTextField(placeholder: "Votre réponse…", text: $surveyAnswer, icon: "pencil")
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(DS.Animation.smooth.delay(0.45), value: appeared)
    }

    // MARK: - Continue Button
    var continueButton: some View {
        Button {
            saveConsentAndContinue()
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Text(canContinue ? "Récupérer ma photo" : "Répondez aux questions requises")
                    .font(DS.Font.label(17, weight: .semibold))
                if canContinue {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(canContinue ? DS.Color.background : DS.Color.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(canContinue ? AnyShapeStyle(DS.Gradient.gold) : AnyShapeStyle(DS.Color.surface))
                    .shadow(
                        color: canContinue ? Color(hex: "#C9A84C").opacity(0.3) : .clear,
                        radius: 12, y: 4
                    )
            )
            .animation(DS.Animation.smooth, value: canContinue)
        }
        .disabled(!canContinue)
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .animation(DS.Animation.smooth.delay(0.5), value: appeared)
    }

    func saveConsentAndContinue() {
        if var session = appState.currentSession {
            session.disclaimerAccepted = disclaimerAccepted
            session.consentPublic = galleryConsent == .yes
            session.guestEmail = email
            session.guestFirstName = firstName
            session.surveyAnswer = surveyAnswer
            appState.currentSession = session
        }
        appState.navigate(to: .share)
    }
}

// MARK: - Consent Card
struct ConsentCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .strokeBorder(DS.Color.gold.opacity(0.15), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Consent Choice Button
struct ConsentChoiceButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(DS.Font.label(14))
            }
            .foregroundColor(isSelected ? DS.Color.background : DS.Color.offWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(isSelected ? AnyShapeStyle(DS.Gradient.gold) : AnyShapeStyle(DS.Color.surfaceHigh))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Styled Text Field
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DS.Color.gold)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(DS.Font.label(14))
                .foregroundColor(DS.Color.offWhite)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, DS.Spacing.md)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(DS.Color.surfaceHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .strokeBorder(text.isEmpty ? Color.clear : DS.Color.gold.opacity(0.4), lineWidth: 1)
                )
        )
    }
}
