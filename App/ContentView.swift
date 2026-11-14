import SwiftUI

struct ContentView: View {
    @ObservedObject var model: PresenceViewModel
    @ObservedObject var locationProbe: LocationPermissionProbe
    @State private var showLocationDiagnostics = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Apple Music

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apple Music")
                            .font(.headline)

                        HStack {
                            Text("Status")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(model.musicStatus)
                        }

                        Divider()

                        HStack(spacing: 12) {
                            if let artwork = model.embeddedArtwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityLabel("Embedded album artwork")
                            } else {
                                Image(systemName: "music.note")
                                    .frame(width: 84, height: 84)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(model.trackTitle)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)

                                if !model.artist.isEmpty {
                                    Text(model.artist)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )

                    // MARK: - Discord

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discord")
                            .font(.headline)

                        HStack(alignment: .top, spacing: 12) {
                            Text("Connection Status")
                                .foregroundStyle(.secondary)

                            Spacer()

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(
                                        model.isDiscordReady
                                        ? Color.green
                                        : Color.orange
                                    )
                                    .frame(width: 8, height: 8)

                                Text(model.discordStatus)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(3)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cover Artwork")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(model.artworkUploadStatus)
                                .font(.footnote)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            model.connectDiscord()
                        } label: {
                            Text(
                                model.isDiscordReady
                                ? "Discord Connected"
                                : "Connect to Discord"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isDiscordReady)

                        Button {
                            model.forceRefresh()
                        } label: {
                            Label(
                                "Update Discord with Current Song",
                                systemImage: "arrow.clockwise"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!model.isDiscordReady)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )

                    // MARK: - Auto Update

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(
                            "Auto Update",
                            isOn: $model.autoUpdate
                        )

                        Text(
                            "Automatically update Discord when the song changes in Apple Music."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Music Presence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationProbe.refresh()
                        showLocationDiagnostics = true
                    } label: {
                        Image(systemName: "location.circle")
                    }
                    .accessibilityLabel("Location Diagnostics")
                }
            }
            .sheet(isPresented: $showLocationDiagnostics) {
                NavigationStack {
                    Form {
                        Section("Location Permission") {
                            LabeledContent("Permission", value: locationProbe.statusText)
                            LabeledContent("Usage Description", value: locationProbe.hasUsageDescription ? "Available" : "Missing")
                            LabeledContent("Background Location", value: locationProbe.hasBackgroundLocation ? "Available" : "Missing")
                        }
                        Section {
                            Button("Request Location Permission") {
                                locationProbe.requestPermission()
                            }
                            Button("Refresh Status") {
                                locationProbe.refresh()
                            }
                        }
                    }
                    .navigationTitle("Location Diagnostics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showLocationDiagnostics = false }
                        }
                    }
                }
            }
        }
    }
}
