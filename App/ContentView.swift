import SwiftUI

struct ContentView: View {
    @ObservedObject var model: PresenceViewModel
    @ObservedObject var locationProbe: LocationPermissionProbe
    @State private var showAdvanced = false
    @State private var cloudURLDraft = ""
    @State private var cloudTokenDraft = ""

    private let accent = Color(red: 0.62, green: 0.47, blue: 1)
    private let panel = Color(red: 0.12, green: 0.12, blue: 0.17)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    playerCard
                    discordCard
                    artworkCard
                    settingsCard
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color(red: 0.055, green: 0.055, blue: 0.09).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("MUSIC PRESENCE")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.6)
                    .foregroundStyle(accent)
                Text("Apple Music × Discord")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 4)
            Circle()
                .fill(model.isDiscordReady ? .green : .orange)
                .frame(width: 8, height: 8)
            Text(model.isDiscordReady ? "LIVE" : "OFFLINE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.vertical, 6)
    }

    private var playerCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accent.opacity(0.12))
                if let image = model.embeddedArtwork {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(accent)
                }
            }
            .frame(width: 112, height: 112)
            .clipped()

            VStack(alignment: .leading, spacing: 7) {
                Text("NOW PLAYING")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(accent)
                Text(model.trackTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Text(model.artist)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                Text(model.musicStatus)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
    }

    private var discordCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Discord Presence", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(model.isDiscordReady ? "Connected" : "Disconnected")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(model.isDiscordReady ? .green : .orange)
            }
            Text(model.discordStatus)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
                .frame(height: 32, alignment: .topLeading)
            Button {
                if model.isDiscordReady { model.forceRefresh() }
                else { model.connectDiscord() }
            } label: {
                Label(model.isDiscordReady ? "Refresh Presence" : "Connect Discord",
                      systemImage: model.isDiscordReady ? "arrow.clockwise" : "link")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .cardStyle(panel)
    }

    private var artworkCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("Artwork Delivery", systemImage: "photo.stack")
                .font(.subheadline.weight(.bold))
            Picker("Image host", selection: Binding(
                get: { model.artworkProvider },
                set: { model.selectArtworkProvider($0) }
            )) {
                Text("Catbox").tag("Catbox")
                Text("PixelHost").tag("PixelHost")
                Text("Cloud").tag("Cloud")
            }
            .pickerStyle(.segmented)

            if model.artworkProvider == "Cloud" {
                VStack(alignment: .leading, spacing: 9) {
                    TextField("https://your-worker.workers.dev/upload", text: $cloudURLDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.footnote)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Worker upload token", text: $cloudTokenDraft)
                        .font(.footnote)
                        .textFieldStyle(.roundedBorder)
                    Button("Save cloud settings") {
                        model.saveCloudToken(cloudTokenDraft)
                        model.saveCloudEndpoint(cloudURLDraft)
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(accent)
                }
                .onAppear {
                    cloudURLDraft = model.cloudEndpoint
                    cloudTokenDraft = model.cloudToken
                }
            }

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "info.circle")
                    .foregroundStyle(accent)
                Text(model.artworkUploadStatus)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption)
            .frame(height: 34, alignment: .topLeading)
            .animation(nil, value: model.artworkUploadStatus)

            if let link = model.artworkPublicURL, let url = URL(string: link) {
                Link(destination: url) {
                    Label("Open uploaded artwork", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                }
                .tint(accent)
            }
        }
        .cardStyle(panel)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $model.autoUpdate) {
                Label("Automatic Discord updates", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(accent)

            Button {
                showAdvanced.toggle()
            } label: {
                HStack {
                    Label("Connection diagnostics", systemImage: "stethoscope")
                    Spacer()
                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            }

            if showAdvanced {
                Divider().overlay(.white.opacity(0.1))
                diagnostic("Discord", model.discordStatus)
                diagnostic("Music", model.musicStatus)
                diagnostic("Artwork host", model.artworkProvider)
                Text("Discord may reject an otherwise valid image URL.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .cardStyle(panel)
    }

    private func diagnostic(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(accent)
            Text(value).font(.caption).foregroundStyle(.white.opacity(0.7))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        Text("Embedded artwork is uploaded only to the selected image host. Cloud requires a separately deployed server.")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
}

private struct CompactCardStyle: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 20))
    }
}

private extension View {
    func cardStyle(_ color: Color) -> some View {
        modifier(CompactCardStyle(color: color))
    }
}
