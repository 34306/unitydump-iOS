//
//  ContentView.swift
//  unitydump
//
//  Created by Huy Nguyen and しまりん on 15/06/2023.
//


import SwiftUI
import UIKit
import AuxiliaryExecute

struct ContentView: View {

    @State private var filePath1: String = ""
    @State private var filePath2: String = ""
    @State private var outputDirectory: String = "/var/mobile/Documents/Dump"
    
    @State private var processing = false
    @State private var showingAlert = false
    @State private var message: String = ""

    var body: some View {
        
        NavigationView {
    
                VStack {
                    VStack(alignment: .center) {
                        Text("Make sure the binary is decrypted.\nNot support encrypted\nglobal-metadata.dat")
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    NavigationLink(
                        destination: CreditsView(),
                        label: {
                            HStack {
                                Text("Credits")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.blue.opacity(0.7))
                            .font(.system(size: 20))
                        }
                    )
                    
                    TextField("Path to UnityFramework/BinaryExecute", text: $filePath1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .disabled(processing)
                    
                    TextField("Path to global-metadata.dat", text: $filePath2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .disabled(processing)
                    
                    TextField("Output Path", text: $outputDirectory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .disabled(processing)
                    
                    
                    
                    HStack {
                        Button(action: {
                            processing = true
                            DispatchQueue.global().async {
                                executeDumpingScript(file1: filePath1, file2: filePath2, outputDir: outputDirectory)
                                processing = false
                            }
                        }) {
                            Text("il2CppDumper!")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(processing)
                        
                        if processing {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Image("gradient")
                    //LinearGradient(gradient: Gradient(colors: [.blue, .green, .purple, .yellow]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .scaledToFill()
                    .blur(radius: 15)
                    .opacity(0.7)
                )
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(message))
            }
            .onAppear{
                initialize()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func initialize() {
        do {
            if !FileManager.default.fileExists(atPath: "/var/mobile/Documents/Dump") {
                try FileManager.default.createDirectory(atPath: "/var/mobile/Documents/Dump", withIntermediateDirectories: true)
            }
        } catch {
            message = "Could not create output folder."
            showingAlert = true
        }
    }

    private func executeDumpingScript(file1: String, file2: String, outputDir: String) {
        if let Il2CppDumper = Bundle.main.url(forResource: "iOS-Dump/Il2CppDumper", withExtension: nil) {
            var output = ""
            let command = Il2CppDumper.path
            let env = ["PATH": "\(Il2CppDumper.path.replacingOccurrences(of: "/Il2CppDumper", with: "")):$PATH"]
            let args = [file1, file2, outputDir]
            
            let receipt = AuxiliaryExecute.spawn(command: command, args: args, environment: env, output: { output += $0 })
            if receipt.exitCode != 0 {
                message = "Error when running the script! Please checking the file (decrypted or not) or path to the file is correct!"
                showingAlert = true
                return
            }
            message = "All done!\nEnjoy hacking your game 🥰"
            showingAlert = true
        }
    }
    
    private func openfilza() {
        if !FileManager.default.fileExists(atPath: "\(outputDirectory)/dump.cs") { return }
        if let url = URL(string: "filza://\(outputDirectory)/dump.cs") {
            UIApplication.shared.open(url)
        }
    }
}
