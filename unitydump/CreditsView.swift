//
//  Credits.swift
//  unitydump
//
//  Created by Huy Nguyen on 16/06/2023.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Image("background")
                    .resizable()
                    .blur(radius: 4)
                    .opacity(0.5)
                    .ignoresSafeArea()

                VStack {
                    ScrollView {
                        VStack {
                            creditView(imageURL: URL(string: "https://avatars.githubusercontent.com/34306"), githubname: "34306", name: "Huy Nguyen (34306)", description: "Idea and initial commit 😭")
                            creditView(imageURL: URL(string: "https://avatars.githubusercontent.com/straight-tamago"), githubname: "straight-tamago", name: "しまりん (straight-tamago)", description: "Fixed most of things in this app 🤣🥰")
                        }
                        .padding()
                    }
                    .listStyle(.insetGrouped)
                }
                .padding()
            }
        }
        .preferredColorScheme(colorScheme)
    }


    private func creditView(imageURL: URL?, githubname: String, name: String, description: String) -> some View {
        HStack {
            if #available(iOS 15.0, *) {
                AsyncImage(url: imageURL, content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 35, maxHeight: 35)
                        .cornerRadius(20)
                }, placeholder: {
                    ProgressView()
                        .frame(maxWidth: 35, maxHeight: 35)
                })
            } else {
                // Fallback on earlier versions
                if let imageURL = imageURL,
                   let data = try? Data(contentsOf: imageURL),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 35, maxHeight: 35)
                        .cornerRadius(20)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 35, maxHeight: 35)
                        .cornerRadius(20)
                }
            }

            VStack(alignment: .leading) {
                Button(name) {
                    if let url = URL(string: "https://github.com/\(githubname)") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(fontColor)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(fontColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundColor(.white)
    }

    private var fontColor: Color {
        return colorScheme == .dark ? Color(red: 0.4, green: 0.7, blue: 0.9) : Color(red: 0.88, green: 0.08, blue: 0.52)
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
