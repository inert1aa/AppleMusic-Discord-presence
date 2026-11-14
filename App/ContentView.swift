import SwiftUI

struct ContentView: View {
    @ObservedObject var model: PresenceViewModel
    @ObservedObject var locationProbe: LocationPermissionProbe
    @State private var showLocationDiagnostics = false
    @State private var cloudURLDraft = ""
    @State private var cloudTokenDraft = ""
    @State private var showAdvanced = false

    private let accent = Color(red: 0.62, green: 0.47, blue: 1.0)
    private let panel = Color(red: 0.12, green: 0.12, blue: 0.17)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    connectionStrip
                    nowPlaying
                    discordPanel
                    artworkPanel
                    settingsPanel
                    advancedPanel
                    Text("Music Presence • Local artwork stays yours until uploaded to a public image host.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.38))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(Color(red: 0.055, green: 0.055, blue: 0.09).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("MUSIC PRESENCE")
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(accent)
                Text("Your music. On Discord.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "waveform")
                .font(.title2.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 50, height: 50)
                .background(panel, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var connectionStrip: some View {
        HStack(spacing: 12) {
            Label(model.musicStatus, systemImage: "music.note")
                .lineLimit(1)
            Spacer()
            Label(model.isDiscordReady ? "Discord Live" : "Discord Offline",
                  systemImage: model.isDiscordReady ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(model.isDiscordReady ? .green : .orange)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(14)
        .background(panel, in: RoundedRectangle(cornerRadius: 16))
    }

    private var nowPlaying: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(accent.opacity(0.12))
                if let image = model.embeddedArtwork {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(12)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 65))
                        .foregroundStyle(accent)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            VStack(spacing: 6) {
                Text(model.trackTitle)
                    .font(.title2.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(model.artist)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
                Text(model.musicStatus)
                    .font(.caption)
                    .foregroundStyle(accent)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(panel, in: RoundedRectangle(cornerRadius: 28))
    }

    private var discordPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Discord Presence", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(model.isDiscordReady ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(model.isDiscordReady ? "Connected" : "Offline")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.75))
            }
            Text(model.discordStatus)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
            Button {
                if model.isDiscordReady {
                    model.forceRefresh()
                } else {
                    model.connectDiscord()
                }
            } label: {
                Label(model.isDiscordReady ? "Refresh Discord Presence" : "Connect to Discord",
                      systemImage: model.isDiscordReady ? "arrow.clockwise" : "link")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 24))
    }

    private var artworkPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Artwork Delivery", systemImage: "photo.stack")
                .font(.headline)
            Text("Choose which free, no-account host sends your embedded covers to Discord.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Private artwork service")
                        .font(.caption.weight(.semibold))
                    TextField("https://your-worker.workers.dev/upload", text: $cloudURLDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Upload token", text: $cloudTokenDraft)
                        .textFieldStyle(.roundedBorder)
                    Button("Save cloud configuration") {
                        model.saveCloudToken(cloudTokenDraft)
                        model.saveCloudEndpoint(cloudURLDraft)
                    }
                    .buttonStyle(.bordered)
                    Text("Cloud hosting must be deployed separately. No server is included in the IPA.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .onAppear {
                    cloudURLDraft = model.cloudEndpoint
                    cloudTokenDraft = model.cloudToken
                }
            }
            Text(model.artworkUploadStatus)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
                .textSelection(.enabled)
            if let link = model.artworkPublicURL, let url = URL(string: link) {
                Link(destination: url) {
                    Label("View uploaded cover", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.medium))
                }
                .tint(accent)
                Text(link)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            Text("Catbox retains your existing working cover URLs. PixelHost uses a separate cache.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 24))
    }

    private var advancedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showAdvanced.toggle() }
            } label: {
                HStack {
                    Label("Diagnostics & Details", systemImage: "stethoscope")
                    Spacer()
                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                }
                .font(.headline)
                .foregroundStyle(.white)
            }
            if showAdvanced {
                LabeledContent("Artwork host", value: model.artworkProvider)
                LabeledContent("Connection", value: model.discordStatus)
                LabeledContent("Music", value: model.musicStatus)
                Text("A verified image URL does not guarantee Discord will render it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 24))
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Playback Settings", systemImage: "slider.horizontal.3")
                .font(.headline)
            Toggle("Automatically update Discord", isOn: $model.autoUpdate)
                .tint(accent)
            Text("Track changes are detected automatically while the app can access Apple Music playback.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 24))
    }
}
