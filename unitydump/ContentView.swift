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
    @AppStorage("executableBinary") 
    private var executableBinary: String = ""
    @AppStorage("globalMetadata") 
    private var globalMetadata: String = ""
    @AppStorage("outputDirectory") 
    private var outputDirectory: String = "/var/mobile/Documents/unitydump"
    
    @State private var processing: Bool = false
    @State private var showingAlert: Bool = false
    @State private var message: String = ""
    
    @State private var updateAvailable = false
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

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
                
                TextField("Path to UnityFramework/BinaryExecute", text: self.$executableBinary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .disabled(self.processing)
                
                TextField("Path to global-metadata.dat", text: self.$globalMetadata)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .disabled(self.processing)
                
                TextField("Output Directory Path", text: self.$outputDirectory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .disabled(self.processing)
                
                
                HStack {
                    Button(action: {
                        self.processing = true
                        DispatchQueue.global().async {
                            self.Il2CppDumper(
                                executableBinary: self.executableBinary,
                                globalMetadata: self.globalMetadata,
                                outputDirectory: self.outputDirectory
                            )
                            self.processing = false
                        }
                    }) {
                        Text("il2CppDumper!")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(self.processing || self.executableBinary == "" || self.globalMetadata == "" || self.outputDirectory == "")
                    .opacity(self.processing || self.executableBinary == "" || self.globalMetadata == "" || self.outputDirectory == "" ? 0.5 : 1)
                    
                    if self.processing {
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
            .alert(isPresented: self.$showingAlert) {
                Alert(title: Text(self.message))
            }
            .onAppear{
                self.fetchLatestRelease()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Text("unitydump-iOS v\(self.version)")
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
                            if self.updateAvailable {
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
                        self.openFilza()
                    }) {
                        Image(systemName: "folder")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func Il2CppDumper(executableBinary: String, globalMetadata: String, outputDirectory: String) {
        let appName = (executableBinary as NSString).lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        
        try? FileManager.default.createDirectory(atPath: "\(outputDirectory)/\(appName)/\(timestamp)", withIntermediateDirectories: true)
        let Il2CppDumper = Bundle.main.url(forResource: "iOS-Dump/Il2CppDumper", withExtension: nil)!
        
        let command = Il2CppDumper.path
        let args = [executableBinary, globalMetadata, "\(outputDirectory)/\(appName)/\(timestamp)"]
        let env = ["PATH": "\(Il2CppDumper.path.replacingOccurrences(of: "/Il2CppDumper", with: "")):$PATH"]
        
        var output = ""
        let receipt = AuxiliaryExecute.spawn(command: command, args: args, environment: env, output: { output += $0 })
        if receipt.exitCode != 0 {
            self.showAlert("Error when running the script! Please checking the file (decrypted or not) or path to the file is correct!")
            return
        }
        
        let dumpExists = FileManager.default.fileExists(atPath: "\(outputDirectory)/\(appName)/\(timestamp)/dump.cs")
        self.showAlert(dumpExists ? "All done!\nEnjoy hacking your game 🥰" : "Unknown error\n\(receipt.stderr)")
    }
    
    private func openFilza() {
        let appName = (self.executableBinary as NSString).lastPathComponent
        if !FileManager.default.fileExists(atPath: "\(self.outputDirectory)/\(appName)") {
            self.showAlert("dump.cs NotFound")
            return
        }
        if let url = URL(string: "filza://\(self.outputDirectory)/\(appName)") {
            if UIApplication.shared.canOpenURL(URL(string: "filza://")!) {
                UIApplication.shared.open(url)
             } else {
                 self.showAlert("Filza not installed")
            }
        }
    }
    
    private func showAlert(_ message: String) {
        self.message = message
        self.showingAlert = true
    }
    
    private func fetchLatestRelease() {
        let url = URL(string: "https://api.github.com/repos/34306/unitydump-iOS/releases/latest")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let o = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
                    guard let l = o["tag_name"] else { return }
                    if "unitydump-iOS-"+self.version != l as! String {
                        self.updateAvailable = true
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
