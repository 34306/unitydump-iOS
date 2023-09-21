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
    @AppStorage("outputDirectory") var outputDirectory: String = "/var/mobile/Documents/Dump"
    
    @State private var processing = false
    @State private var showingAlert = false
    @State private var message: String = ""
    
    @State private var update_available = false
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

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
                    .disabled(processing || filePath1 == "" || filePath2 == "" || outputDirectory == "")
                    .opacity(processing || filePath1 == "" || filePath2 == "" || outputDirectory == "" ? 0.5 : 1)
                    
                    if processing {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("gradient")
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
                fetchLatestRelease()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Text("unitydump-iOS v\(version)")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        if let url = URL(string: "https://github.com/34306/unitydump-iOS") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "sparkles")
                            if update_available {
                                Rectangle()
                                    .foregroundColor(.red)
                                    .frame(width: 9, height: 9)
                                    .cornerRadius(60)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        openfilza()
                    }) {
                        Image(systemName: "folder")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func executeDumpingScript(file1: String, file2: String, outputDir: String) {
        let basename = (filePath1 as NSString).lastPathComponent
        try? FileManager.default.createDirectory(atPath: "\(outputDirectory)/\(basename)", withIntermediateDirectories: true)
        if let Il2CppDumper = Bundle.main.url(forResource: "iOS-Dump/Il2CppDumper", withExtension: nil) {
            var output = ""
            let command = Il2CppDumper.path
            let env = ["PATH": "\(Il2CppDumper.path.replacingOccurrences(of: "/Il2CppDumper", with: "")):$PATH"]
            let args = ["\(outputDirectory)/\(basename)", file2, outputDir]
            
            let receipt = AuxiliaryExecute.spawn(command: command, args: args, environment: env, output: { output += $0 })
            if receipt.exitCode != 0 {
                showAlert("Error when running the script! Please checking the file (decrypted or not) or path to the file is correct!")
                return
            }
            let dumpExists = FileManager.default.fileExists(atPath: "\(outputDirectory)/\(basename)/dump.cs")
            showAlert(dumpExists ? "All done!\nEnjoy hacking your game 🥰" : "Unknown error")
        }
    }
    
    private func openfilza() {
        let basename = (filePath1 as NSString).lastPathComponent
        if !FileManager.default.fileExists(atPath: "\(outputDirectory)/\(basename)/dump.cs") {
            showAlert("dump.cs NotFound")
            return
        }
        if let url = URL(string: "filza://\(outputDirectory)/\(basename)/dump.cs") {
            if UIApplication.shared.canOpenURL(URL(string: "filza://")!) {
                UIApplication.shared.open(url)
             } else {
                 showAlert("Filza not installed")
            }
        }
    }
    
    func showAlert(_ m: String) {
        message = m
        showingAlert = true
    }
    
    func fetchLatestRelease() {
        let url = URL(string: "https://api.github.com/repos/34306/unitydump-iOS/releases/latest")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let o = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
                    guard let l = o["tag_name"] else { return }
                    if "unitydump-iOS-"+version != l as! String {
                        update_available = true
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
