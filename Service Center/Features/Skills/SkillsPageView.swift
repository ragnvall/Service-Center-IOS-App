import SwiftUI

struct SkillsPageView: View {
    let skills: [String]

    var body: some View {
        ZStack {
            // 🌑 Full black background
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 15) {
                // 🛠️ Icon + "All Skills" Title
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("All Skills")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding(.top, 10)

                // 🔹 Grid layout for skills (now in blue bubbles)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill)
                            .font(.system(size: 14, weight: .bold)) // Smaller bold text
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.blue)) // ✅ Blue bubble
                    }
                }
                .padding()

                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

