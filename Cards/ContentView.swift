import SwiftUI
import AVFoundation
import CoreImage

enum CodeType: String, Codable {
    case barcode
    case qrcode
}

class LoyaltyCard: Identifiable, ObservableObject, Codable, Equatable {
    var id = UUID()
    var storeName: String
    var codeData: String
    var codeType: CodeType
    var notes: String?

    init(storeName: String, codeData: String, codeType: CodeType, notes: String? = nil) {
        
        self.storeName = storeName
        self.codeData = codeData
        self.codeType = codeType
        self.notes = notes
    }
    
    static func == (lhs: LoyaltyCard, rhs: LoyaltyCard) -> Bool {
        return lhs.id == rhs.id &&
           lhs.storeName == rhs.storeName &&
           lhs.codeData == rhs.codeData &&
           lhs.codeType == rhs.codeType &&
           lhs.notes == rhs.notes
    }
}

struct LoyaltyCardDetailView: View {
    var card: LoyaltyCard
    var onDelete: () -> Void
    
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator"),
              let data = data else { return nil }
        
        filter.setValue(data, forKey: "inputMessage")
        
        guard let output = filter.outputImage,
              let cgImage = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return UIImage(cgImage: cgImage)
    }

    
    var body: some View {
        VStack {
            Text(card.storeName)
                .font(.title2)
                .bold()
                .padding()
           
        
            if let barcodeImage = generateBarcode(from: card.codeData) {
                Image(uiImage: barcodeImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(maxWidth: .infinity)
                    .scaledToFit()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 1)
                    .padding()
                
                } else {
                Text("Failed to generate barcode")
                    .foregroundColor(.red)
            }
            
            Text(card.codeData)
                .font(.caption)
                .foregroundColor(.secondary)
            
        
            Spacer()
            
            Button(role: .destructive, action: {
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
            
        }
        .padding()
        .navigationTitle("Card Details")
        
        Spacer()
    }
}

struct LoyaltyCardView: View {
    var card: LoyaltyCard
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text(card.storeName)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text(card.codeData)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}


struct AddLoyaltyCardView: View {var onAdd: (LoyaltyCard) -> Void
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    
    @State private var cardName: String = ""
    @State private var cardCode: String = ""
    
    let canadianLoyaltyCards = [
        "Costco Membership",
        "Walmart Rewards",
        "Scene+",
        "PC Optimum",
        "Air Miles",
        "Canadian Tire Triangle Rewards",
        "Metro Moi",
        "SAQ Inspire",
        "IKEA Family",
        "H&M Membership",
        "Sephora Beauty Insider",
        "MyMcDonald’s Rewards",
        "Starbucks Rewards",
        "Rakuten Points",
        "Nike Membership",
        "Lululemon Membership",
        "Pet’s Rewards"
    ]
    
    var filteredSuggestions: [String] {
        if cardName.isEmpty { return [] }
        return canadianLoyaltyCards.filter {
            $0.lowercased().contains(cardName.lowercased())
        }
    }


    private func handleSubmit() {
        guard !cardName.trimmingCharacters(in: .whitespaces).isEmpty , !cardCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let newCard = LoyaltyCard(storeName: cardName, codeData: cardCode, codeType: .barcode)
        onAdd(newCard)
    }
    

    var body: some View {
        VStack {
            Text("Add your card")
                .font(.title2)
                .padding()
                .bold()
            
            TextField("Card Name", text: $cardName)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .disableAutocorrection(true)
            

            TextField("Barcode Text", text: $cardCode)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .disableAutocorrection(true)

            
            Button("Submit") {
                handleSubmit()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            

            Spacer()
        }.padding()
    }
}

struct ContentView: View {
    @State private var loyaltyCards: [LoyaltyCard] = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var selectedCard: LoyaltyCard? = nil
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    
    @State private var showingAddCardView = false
    
    private func addNewCard(_ card: LoyaltyCard) {
        loyaltyCards.append(card)
    }
    
    private func deleteCard(_ card: LoyaltyCard) {
        loyaltyCards.removeAll { $0.id == card.id }
    }
    
    func saveLoyaltyCards(_ cards: [LoyaltyCard]) {
        do {
            let data = try JSONEncoder().encode(cards)
            UserDefaults.standard.set(data, forKey: "loyaltyCards")
        } catch {
            print("Failed to save loyalty cards: \(error)")
        }
    }
    
    func loadLoyaltyCards() -> [LoyaltyCard] {
        guard let data = UserDefaults.standard.data(forKey: "loyaltyCards") else { return [] }
        do {
            return try JSONDecoder().decode([LoyaltyCard].self, from: data)
        } catch {
            print("Failed to load cards: \(error)")
            return []
        }
    }
    
    var body: some View {
        TabView {
            //header
            VStack {
                HStack {
                    Text("Wallet").bold().font(.title )
                    
                    Spacer()
                    
                    Button(action: {showingAddCardView = true}) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                    }
                }
                ScrollView {
                    //grid showing all loyalty cards
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(loyaltyCards) { card in
                            LoyaltyCardView(card: card)
                                .onTapGesture {
                                    selectedCard = card
                                    
                                    //update brightness so it is easier to scan
                                    originalBrightness = UIScreen.main.brightness
                                    UIScreen.main.brightness = 1
                                }
                        }
                    }
                }
               
                Spacer()
            }
            .padding()
            .sheet(item: $selectedCard, onDismiss: {
                UIScreen.main.brightness = originalBrightness
            }) { card in
                LoyaltyCardDetailView(card: card) {
                    deleteCard(card)
                    selectedCard = nil
                }
            }
            .sheet(isPresented: $showingAddCardView) {
                AddLoyaltyCardView { newCard in
                    addNewCard(newCard)
                    showingAddCardView = false
                }
            }
            //.tabItem {
            //   Label("Tab 1", systemImage: "wallet.bifold")
            //}
            
            
            //VStack {
            //    Image(systemName: "globe")
            //        .imageScale(.large)
            //        .foregroundStyle(.tint)
            //
            //    Text("Hello, worldss!")
            //}
            //.padding()
            //.tabItem {
            //    Label("Tab 2", systemImage: "gear")
            //}
        }
        .onAppear {
            loyaltyCards = loadLoyaltyCards()
        }
        .onChange(of: loyaltyCards) { newCards in
            saveLoyaltyCards(newCards)
        }
    }
}

#Preview {
    ContentView()
}
