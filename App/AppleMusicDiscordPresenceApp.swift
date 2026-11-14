import SwiftUI
import CoreLocation


@main
struct AppleMusicDiscordPresenceApp: App {

    @StateObject
    private var model =
        PresenceViewModel()


    @StateObject
    private var locationProbe =
        LocationPermissionProbe()


    var body: some Scene {

        WindowGroup {

            VStack(
                spacing: 0
            ) {

                // MARK: =========================
                // MARK: Location Debug
                // MARK: =========================

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text(
                        "Location Diagnostics"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Permission: \(locationProbe.statusText)"
                    )


                    Text(
                        "UsageDescription: \(locationProbe.hasUsageDescription ? "Available" : "Missing")"
                    )


                    Text(
                        "Background location: \(locationProbe.hasBackgroundLocation ? "Available" : "Missing")"
                    )


                    Button {

                        locationProbe
                            .requestPermission()

                    } label: {

                        Text(
                            "Request Location Permission"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )


                    Button {

                        locationProbe
                            .refresh()

                    } label: {

                        Text(
                            "Refresh Status"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )
                }
                .padding()
                .background(
                    .thinMaterial
                )


                Divider()


                // MARK: =========================
                // MARK: Original App
                // MARK: =========================

                ContentView(
                    model:
                        model
                )
            }
            .task {

                await model
                    .start()
            }
        }
    }
}


// MARK: =========================================
// MARK: Location Permission Probe
// MARK: =========================================

final class LocationPermissionProbe:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate
{

    @Published
    var statusText =
        "Checking"


    @Published
    var hasUsageDescription =
        false


    @Published
    var hasBackgroundLocation =
        false


    private let manager =
        CLLocationManager()


    override init() {

        super.init()


        manager.delegate =
            self


        refresh()
    }


    // MARK: =====================================
    // MARK: Refresh
    // MARK: =====================================

    func refresh() {

        let status =
            manager
                .authorizationStatus


        switch status {

        case .notDetermined:

            statusText =
                "notDetermined / Not Requested"


        case .authorizedWhenInUse:

            statusText =
                "authorizedWhenInUse / While Using App"


        case .authorizedAlways:

            statusText =
                "authorizedAlways / Always Allowed"


        case .denied:

            statusText =
                "denied / Denied"


        case .restricted:

            statusText =
                "restricted / 制限Available"


        @unknown default:

            statusText =
                "unknown"
        }


        // MARK: Usage Description

        let description =
            Bundle
                .main
                .object(
                    forInfoDictionaryKey:
                        "NSLocationWhenInUseUsageDescription"
                )
            as? String


        hasUsageDescription =
            !(description ?? "")
                .isEmpty


        // MARK: Background Mode

        let modes =
            Bundle
                .main
                .object(
                    forInfoDictionaryKey:
                        "UIBackgroundModes"
                )
            as? [String]
            ?? []


        hasBackgroundLocation =
            modes.contains(
                "location"
            )


        print(
            "[LocationProbe] ========================"
        )


        print(
            "[LocationProbe] status:",
            statusText
        )


        print(
            "[LocationProbe] usageDescription:",
            hasUsageDescription
        )


        print(
            "[LocationProbe] UIBackgroundModes:",
            modes
        )


        print(
            "[LocationProbe] ========================"
        )
    }


    // MARK: =====================================
    // MARK: Request Permission
    // MARK: =====================================

    func requestPermission() {

        refresh()


        let status =
            manager
                .authorizationStatus


        print(
            "[LocationProbe] BUTTON PRESSED"
        )


        switch status {

        case .notDetermined:

            /*
             ボタンを人間が押しているので
             アプリは確実にForeground。

             ここで直接要求する。
             */

            print(
                "[LocationProbe] requestWhenInUseAuthorization()"
            )


            manager
                .requestWhenInUseAuthorization()


        case .authorizedWhenInUse:

            statusText =
                "Location access already allowed while using the app"


            /*
             Background側の処理も開始。
             */

            BackgroundLocationKeeper
                .shared
                .start()


        case .authorizedAlways:

            statusText =
                "Always Allowed済み"


            BackgroundLocationKeeper
                .shared
                .start()


        case .denied:

            statusText =
                "Deniedされています。設定から変更が必要"


        case .restricted:

            statusText =
                "Location access is restricted by iOS"


        @unknown default:

            statusText =
                "Unknown permission status"
        }
    }


    // MARK: =====================================
    // MARK: Authorization Changed
    // MARK: =====================================

    func locationManagerDidChangeAuthorization(
        _ manager:
            CLLocationManager
    ) {

        DispatchQueue
            .main
            .async {

                self.refresh()


                switch
                    manager
                        .authorizationStatus {

                case .authorizedWhenInUse,
                     .authorizedAlways:

                    print(
                        "[LocationProbe] AUTHORIZED"
                    )


                    BackgroundLocationKeeper
                        .shared
                        .start()


                default:

                    break
                }
            }
    }
}
