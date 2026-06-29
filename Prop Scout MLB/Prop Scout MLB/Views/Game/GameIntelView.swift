import SwiftUI

struct GameIntelView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // MARK: - Weather
                if let w = vm.weather {
                    weatherCard(w)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    placeholderCard("WEATHER · \(game.venue?.uppercased() ?? "STADIUM")", "Loading…")
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                // MARK: - Park Factors
                parkFactorsCard
                    .padding(.horizontal, 16)

                // MARK: - Umpire
                umpireCard(vm.umpire?.homePlate)
                    .padding(.horizontal, 16)

                // MARK: - AI Trend Analysis
                trendsCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
        .task {
            await vm.loadTrends()
        }
    }

    // MARK: - AI Trend Analysis card
    private var trendsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("AI TREND ANALYSIS")
                Spacer()
                Image(systemName: "cpu")
                    .scaledFont(size: 10)
                    .foregroundColor(.brandPurple)
                Text("SCOUT AI")
                    .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandPurple)
            }

            if vm.isLoadingTrends {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.brandPurple)
                    Text("Generating analysis…")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)

            } else if let summary = vm.trends?.summary, !summary.isEmpty {
                Text(summary)
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

            } else if let err = vm.trendsError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.brandAmber)
                        .scaledFont(size: 12)
                    Text(err)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                    Spacer()
                    Button {
                        Task { await vm.loadTrends() }
                    } label: {
                        Text("Retry")
                            .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                            .foregroundColor(.brandGreen)
                    }
                }

            } else {
                // Not yet triggered — show generate button
                Button {
                    Task { await vm.loadTrends() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .scaledFont(size: 12)
                        Text("Generate Analysis")
                            .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                    }
                    .foregroundColor(.brandPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.brandPurple.opacity(0.10))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.brandPurple.opacity(0.25), lineWidth: 1))
                }
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Park Factors card
    private var parkFactorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("PARK FACTORS · \(game.venue?.uppercased() ?? "STADIUM")")
                Spacer()
                Text("\(game.home.abbr) · Hitter-Friendly")
                    .scaledFont(size: 9, weight: .semibold, design: .monospaced)
                    .foregroundColor(.brandAmber)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.brandAmber.opacity(0.15))
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    parkFactorCell("HR FACTOR", "1.07x")
                    parkFactorCell("HIT FACTOR", "1.03x")
                    parkFactorCell("K FACTOR", "0.99x")
                }
                Text("Multi-year FanGraphs avg · >1.0 = hitter-friendly · affects HIT, TR & NRFI props")
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextDim)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func parkFactorCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .foregroundColor(.brandCyan)
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    // MARK: - Weather card
    private func weatherCard(_ w: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("WEATHER · \(game.venue?.uppercased() ?? "")")

            if w.isDome == true {
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .foregroundColor(.brandTextDim)
                    Text("Dome stadium — weather not applicable")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundColor(.brandTextDim)
                }
            } else {
                // Temperature
                Text(w.tempString)
                    .scaledFont(size: 36, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)

                // Weather metrics grid (2x2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let humidity = w.relativehumidity {
                        infoCell("HUMIDITY", "\(Int(humidity))%")
                    } else {
                        infoCell("HUMIDITY", "—")
                    }

                    infoCell("ROOF", "Open Air")

                    if let rain = w.precipitation_probability {
                        infoCell("RAIN CHANCE", "\(Int(rain))%")
                    } else {
                        infoCell("RAIN CHANCE", "—")
                    }

                    if w.windspeed != nil {
                        infoCell("WIND", w.windLabel)
                    } else {
                        infoCell("WIND", "—")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Umpire card
    private func umpireCard(_ ump: UmpireData.HomePlateUmpire?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HOME PLATE UMPIRE")

            // Header: Name + Status badges
            HStack(spacing: 8) {
                Text(ump?.name ?? "TBD")
                    .scaledFont(size: 15, weight: .bold, design: .monospaced)
                    .foregroundColor(.brandText)

                Spacer()

                // Score status badge
                if let status = ump?.stats?.scoreStatus {
                    let bgColor: Color = status == "ACCURATE" ? .brandGreen :
                                        status == "BIASED" ? .brandRed :
                                        .brandAmber
                    Text(status)
                        .scaledFont(size: 8, weight: .bold, design: .monospaced)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(bgColor)
                        .cornerRadius(4)
                } else {
                    // Default badge when data unavailable
                    Text("NEUTRAL UMP")
                        .scaledFont(size: 8, weight: .bold, design: .monospaced)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.brandAmber)
                        .cornerRadius(4)
                }
            }

            // Scorecard live + Game status
            VStack(alignment: .leading, spacing: 4) {
                if ump?.stats?.scorecardLive == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .scaledFont(size: 9)
                        Text("SCORECARD LIVE")
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                    }
                    .foregroundColor(.brandGreen)
                }

                if let gameStatus = ump?.stats?.gameStatus {
                    Text(gameStatus)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                } else {
                    // Default status when awaiting assignment
                    Text("Awaiting assignment")
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundColor(.brandTextMuted)
                }
            }

            // Performance metrics (2x2 grid) - only show if data available
            if ump?.stats?.accuracy != nil || ump?.stats?.consistency != nil {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        if let accuracy = ump?.stats?.accuracy {
                            metricCell("ACCURACY", accuracy)
                        }
                        if let vsExp = ump?.stats?.vsExp {
                            metricCell("VS EXP", vsExp)
                        }
                    }

                    HStack(spacing: 10) {
                        if let consistency = ump?.stats?.consistency {
                            metricCell("CONSISTENCY", consistency)
                        }
                        if let favor = ump?.stats?.favorPerGame {
                            metricCell("FAVOR/GM", favor)
                        }
                    }
                }
            }

            // K Rate + BB Rate grid
            HStack(spacing: 10) {
                infoCell("K RATE", ump?.stats?.kRate ?? "—")
                infoCell("BB RATE", ump?.stats?.bbRate ?? "—")
            }

            // Tendency
            if let tendency = ump?.stats?.tendency {
                Text(tendency)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundColor(.brandTextMuted)
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(size: 14, weight: .bold, design: .monospaced)
                .foregroundColor(.brandCyan)
            Text(label)
                .scaledFont(size: 8, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.brandSurface2)
        .cornerRadius(6)
    }

    // MARK: - Placeholder card
    private func placeholderCard(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title)
            Text(text)
                .scaledFont(size: 12, design: .monospaced)
                .foregroundColor(.brandTextDim)
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Shared helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundColor(.brandTextDim)
            .kerning(1.2)
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .scaledFont(size: 9, design: .monospaced)
                .foregroundColor(.brandTextDim)
            Text(value)
                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.brandSurface2)
        .cornerRadius(7)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .scaledFont(size: 9, design: .monospaced)
                .foregroundColor(.brandTextDim)
            Spacer()
            Text(value)
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(.brandText)
        }
    }
}
