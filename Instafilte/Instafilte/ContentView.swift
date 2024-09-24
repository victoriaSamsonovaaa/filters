//
//  ContentView.swift
//  Instafilte
//
//  Created by Victoria Samsonova on 28.08.24.
//

import SwiftUI
import PhotosUI
import CoreImage
import StoreKit
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var hideSlider = true
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false

    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview

    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    }
                    else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Import a photo to get started"))
                        
                    }
                }
                .onChange(of: selectedItem) {
                    loadImage()
                    hideSlider = false
                }
                .onChange(of: selectedItem, loadImage)
               // .buttonStyle(.plain) убирает цвет от кнопки( то есть сама по себе она интереактивная)
                Spacer()
                
                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .disabled(hideSlider)
                        .onChange(of: filterIntensity, applyProcessing)
                }
                .padding(.vertical)
                
                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(hideSlider)
                    Spacer()
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }

    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        //currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        filterCount += 1
        
        if filterCount >= 20 {
            requestReview()
        }
    }
    
}

#Preview {
    ContentView()
}

// onChange() modifier, which tells SwiftUI to run a function of our choosing when a particular value changes. SwiftUI will automatically pass in both the old and new value to whatever function you attach

//ContentUnavailableView {
//    Label("No snippets", systemImage: "swift")
//} description: {
//    Text("You don't have any saved snippets yet.")
//} actions: {
//    Button("Create Snippet") {
//    }
//    .buttonStyle(.borderedProminent)
//}



//VStack {
//    ScrollView {
//ForEach(0..<selectedImages.count, id: \.self) { i in
//selectedImages[i]
// .resizable()
// .scaledToFit()
//}
//}
//  PhotosPicker("Select images", selection: $pickerItems, maxSelectionCount: 5, matching: .images)
//Button("Leave a review") {
//requestReview()
//}
//
//PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .images) {
//Label("Select a picture", systemImage: "photo")
//}
//
//ShareLink(item: URL(string: "https://www.hackingwithswift.com")!) {
//Label("Spread the word about Swift", systemImage: "swift")
//}
//ShareLink(item: example, preview: SharePreview("Singapore Airport", image: example)) {
//Label("Click to share", systemImage: "airplane")
//}
//
//}
//.onChange(of: pickerItems) {
//    Task {
//        selectedImages.removeAll()
//        for item in pickerItems {
//            if let loadedImage = try await item.loadTransferable(type: Image.self) {
//                selectedImages.append(loadedImage)
//            }
//        }
//    }
//}
//.onAppear(perform: loadImage)

/*     func loadImage() {
 let inputImage = UIImage(resource: .image)
 let beginImage = CIImage(image: inputImage)
 let context = CIContext()
 
 let currentFilter = CIFilter.crystallize()
 currentFilter.inputImage = beginImage
 currentFilter.radius = 10
 
 guard let outputImage = currentFilter.outputImage else {return}
 guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {return}
 let uiImage = UIImage(cgImage: cgImage)
 image = Image(uiImage: uiImage)
}*/


