import SwiftUI

struct GameIntelView: View {
    let game: SlateGame
    @ObservedObject var vm: GameDetailViewModel
    @State private var noteText: String = ""
    @FocusState private var noteFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // MARK: - AI Trend Analysis
                trendsCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // MARK: - NRFI
                if let nrfi = vm.nrfi {
                    nrfiCard(nrfi)
                        .padding(.horizontal, 16)
                }

                // MARK: - Weather
                if let w = vm.weather {
                    weatherCard(w)
                        .padding(.horizontal, 16)
                }

                // MARK: - Umpire
                if let ump = vm.umpire?.homePlate {
                    umpireCard(ump)
                        .padding(.horizontal, 16)
                }

                // MARK: - Odds
                if let o = vm.odds {
                    oddsCard(o)
                        .padding(.horizontal, 16)
                }

                // MARK: - Scout Notes
                notesCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
        }
        .background(Color.brandBackground)
        .task {
            await vm.loadTrends()
            await vm.loadNotes()
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

    // MARK: - NRFI card
    private func nrfiCard(_ nrfi: NRFIDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("NRFI ANALYSIS")
                Spacer()
                if let lean = nrfi.lean, let conf = nrfi.confidence {
                    HStack(spacing: 4) {
                        Text(lean.uppercased())
                            .scaledFont(size: 11, weight: .bold, design: .monospaced)
                            .foregroundColor(lean.uppercased() == "NRFI" ? .brandGreen : .brandRed)
                        Text("\(conf)%")
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundColor(.brandTextDim)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((lean.uppercased() == "NRFI" ? Color.brandGreen : Color.brandRed).opacity(0.10))
                    .cornerRadius(6)
                }
            }

            HStack(spacing: 12) {
                nrfiTeam(abbr: game.away.abbr, data: nrfi.away)
                nrfiTeam(abbr: game.home.abbr, data: nrfi.home)
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func nrfiTeam(abbr: String, data: NRFIDetail.NRFITeamData?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(abbr)
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundColor(.brandText)
            if let scored = data?.scoredPct {
                statRow("SCORED 1st", "\(Int(scored * 100))%")
            }
            if let avg = data?.avgRuns {
                statRow("AVG RUNS/1st", String(format: "%.2f", avg))
            }
            if let tendency = data?.tendency {
                Text(tendency)
                    .scaledFont(size: 9, design: .monospaced)
                    .foregroundColor(.brandTextDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.brandSurface2)
        .cornerRadius(8)
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
                HStack(alignment: .top) {
                    Text(w.tempString)
                        .scaledFont(size: 36, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    Spacer()
                    if w.windspeed != nil {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(w.windLabel)
                                .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                                .foregroundColor(.brandCyan)
                            Text("WIND")
                                .scaledFont(size: 9, design: .monospaced)
                                .foregroundColor(.brandTextDim)
                        }
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let humidity = w.relativehumidity {
                        infoCell("HUMIDITY", "\(Int(humidity))%")
                    }
                    infoCell("ROOF", "Open Air")
                    if let rain = w.precipitation_probability {
                        infoCell("RAIN CHANCE", "\(Int(rain))%")
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
    private func umpireCard(_ ump: UmpireData.HomePlateUmpire) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOME PLATE UMPIRE")
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ump.name ?? "TBA")
                        .scaledFont(size: 15, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandText)
                    if let tendency = ump.stats?.tendency {
                        Text(tendency)
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundColor(.brandTextMuted)
                    }
                }
                Spacer()
                if let rating = ump.stats?.rating {
                    let isPitcher = rating.lowercased().contains("pitcher")
                    Text(isPitcher ? "PITCHER UMP" : "NEUTRAL UMP")
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .foregroundColor(isPitcher ? .brandCyan : .brandAmber)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background((isPitcher ? Color.brandCyan : Color.brandAmber).opacity(0.12))
                        .cornerRadius(5)
                }
            }
            HStack(spacing: 8) {
                if let kRate = ump.stats?.kRate { infoCell("K RATE", kRate) }
                if let bbRate = ump.stats?.bbRate { infoCell("BB RATE", bbRate) }
            }
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    // MARK: - Odds card
    private func oddsCard(_ o: OddsData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("ODDS & LINE MOVEMENT")
                Spacer()
                if let book = o.book {
                    Text(book)
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(.brandGreen)
                }
            }
            HStack(spacing: 12) {
                if let awayML = o.awayML, let homeML = o.homeML {
                    oddsCell("ML", "\(awayML) / \(homeML)")
                }
                if let total = o.total {
                    oddsCell("O/U", total)
                }
                if let awayRL = o.awaySpread, let homeRL = o.homeSpread {
                    oddsCell("RL", "\(awayRL) / \(homeRL)")
                }
            }
            .padding(12)
            .background(Color.brandSurface2)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.brandSurface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brandBorder, lineWidth: 1))
    }

    private func oddsCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .scaledFont(size: 9, design: .monospaced)
                .foregroundColor(.brandTextDim)
            Text(value)
                .scaledFont(size: 12, weight: .semibold, design: .monospaced)
                .foregroundColor(label == "O/U" ? .brandAmber : .brandText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scout notes card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("SCOUT NOTES")

            // Existing notes
            if !vm.notes.isEmpty {
                VStack(spacing: 6) {
                    ForEach(vm.notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.note ?? "")
                                .scaledFont(size: 12, design: .monospaced)
                                .foregroundColor(.brandTextMuted)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 4) {
                                if let user = note.username {
                                    Text(user)
                                        .scaledFont(size: 9, design: .monospaced)
                                        .foregroundColor(.brandTextDim)
                                }
                                Text("· \(note.displayDate)")
                                    .scaledFont(size: 9, design: .monospaced)
                                    .foregroundColor(.brandTextDim)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.brandSurface2)
                        .cornerRadius(7)
                    }
                }
            }

            // Note input
            HStack(spacing: 8) {
                TextField("Add a scout note…", text: $noteText, axis: .vertical)
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundColor(.brandText)
                    .focused($noteFieldFocused)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Color.brandSurface2)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                        noteFieldFocused ? Color.brandGreen.opacity(0.5) : Color.brandBorder,
                        lineWidth: 1
                    ))

                Button {
                    let text = noteText
                    noteText = ""
                    noteFieldFocused = false
                    HapticManager.light()
                    Task { await vm.saveNote(text) }
                } label: {
                    Group {
                        if vm.isSavingNote {
                            ProgressView().tint(.brandBackground)
                        } else {
                            Image(systemName: "arrow.up")
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(.brandBackground)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(noteText.isEmpty ? Color.brandTextDim : Color.brandGreen)
                    .cornerRadius(8)
                }
                .disabled(noteText.isEmpty || vm.isSavingNote)
            }
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
