//
//  AddAddressView.swift
//  Fazaa
//
//  Created by Karim Amsha on 29.02.2024.
//

import SwiftUI
import MapKit
import Foundation

struct AddAddressView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var settings: UserSettings
    @StateObject private var viewModel = UserViewModel()

    @State private var title = ""
    @State private var streetName = ""
    @State private var buildingNo = ""
    @State private var floorNo = ""
    @State private var flatNo = ""
    @State private var address = ""
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var locations: [Mark] = []
    @State private var addressPlace: PlaceType = .home
    @State private var isShowingMap = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(LocalizedStringKey.addressDetails)
                            .customFont(weight: .bold, size: 16)
                            .foregroundColor(.black1F1F1F())

                        HStack {
                            createButton(image: "ic_house", title: LocalizedStringKey.house, place: .home)
                            createButton(image: "ic_work", title: LocalizedStringKey.work, place: .work)
                        }

                        inputField(titleKey: LocalizedStringKey.name, text: $title, placeholderKey: LocalizedStringKey.name)

                        mapView

                        inputField(titleKey: LocalizedStringKey.homeAddress, text: $streetName, placeholderKey: LocalizedStringKey.homeAddress)

                        HStack(spacing: 8) {
                            inputField(titleKey: LocalizedStringKey.buildingNo, text: $buildingNo, placeholderKey: LocalizedStringKey.buildingNo)
                            inputField(titleKey: LocalizedStringKey.floorNo, text: $floorNo, placeholderKey: LocalizedStringKey.floorNo)
                        }

                        inputField(titleKey: LocalizedStringKey.flatNo, text: $flatNo, placeholderKey: LocalizedStringKey.flatNo)

                        if viewModel.state.isLoading {
                            LoadingView()
                        }

                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }

                VStack {
                    Button {
                        withAnimation {
                            add()
                        }
                    } label: {
                        Text(LocalizedStringKey.send)
                    }
                    .buttonStyle(PrimaryButton(
                        fontSize: 16,
                        fontWeight: .bold,
                        background: .primary(),
                        foreground: .white,
                        height: 48,
                        radius: 8
                    ))
                    .disabled(viewModel.state.isLoading)
                }
                .padding(24)
                .background(Color.white)
                .background(RoundedRectangle(cornerRadius: 12)
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: -3))
            }
        }
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .bindLoadingState(viewModel.state, to: appRouter)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .frame(width: 20, height: 15)
                            .foregroundColor(.black)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 8)
                            .background(Color.white.cornerRadius(8))
                    }

                    Text(LocalizedStringKey.addAddress)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.black141F1F())
                }
            }
        }
        .onAppear {
            if let location = LocationManager.shared.userCoordinate {
                userLocation = location
            }
        }
    }

    private var mapView: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate, anchorPoint: CGPoint(x: 0.5, y: 0.7)) {
                    VStack {
                        if location.show {
                            Text(location.title)
                                .customFont(weight: .bold, size: 14)
                                .foregroundColor(.black131313())
                        }
                        Image(location.imageName)
                            .onTapGesture {
                                if let index = locations.firstIndex(where: { $0.id == location.id }) {
                                    locations[index].show.toggle()
                                }
                            }
                    }
                }
            }
            .disabled(true)
            .onChange(of: region) { newRegion in
                Utilities.getAddress(for: newRegion.center) { address in
                    self.address = address
                }
            }
            .onAppear {
                moveToUserLocation()
            }

            Image("ic_logo")
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "square.arrowtriangle.4.outward")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            isShowingMap = true
                        }
                }
            }
            .padding(10)
            .sheet(isPresented: $isShowingMap) {
                FullMapView(region: $region, isShowingMap: $isShowingMap, address: $address)
            }
        }
        .frame(height: 250)
        .cornerRadius(8)
    }

    private func inputField(titleKey: String, text: Binding<String>, placeholderKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .customFont(weight: .regular, size: 12)
                .foregroundColor(.black1F1F1F())
            CustomTextField(
                text: text,
                placeholder: placeholderKey,
                textColor: .black4E5556(),
                placeholderColor: .grayA4ACAD()
            )
            .disabled(viewModel.state.isLoading)
        }
    }

    private func createButton(image: String, title: String, place: PlaceType) -> some View {
        Button {
            addressPlace = place
        } label: {
            VStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(addressPlace == place ? .white : .black1F1F1F())
                Text(title)
                    .customFont(weight: addressPlace == place ? .bold : .regular, size: 14)
                    .foregroundColor(addressPlace == place ? .white : .black1F1F1F())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 38)
            .frame(maxWidth: .infinity)
            .background((addressPlace == place ? Color.primary() : .white).cornerRadius(8))
        }
    }

    private func add() {
        do {
            let request = try buildAddressRequest()

            viewModel.addAddress(body: request) { message in
                appRouter.show(.success, message: message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    appRouter.navigateBack()
                }
            }
        }
        catch let error as AddressValidationError {
            appRouter.show(.error, message: error.message)
        }
        catch {
            appRouter.show(.error, message: error.localizedDescription)
        }
    }

    private func moveToUserLocation() {
        if let userCoord = LocationManager.shared.userCoordinate {
            region.center = userCoord
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        }
    }
    
    private func buildAddressRequest() throws -> AddressRequest {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AddressValidationError.missingTitle
        }

        guard region.center.latitude != 0.0 && region.center.longitude != 0.0 else {
            throw AddressValidationError.invalidLatLng
        }

        guard !streetName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AddressValidationError.missingStreetName
        }

        guard !buildingNo.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AddressValidationError.missingBuildingNo
        }

        guard !flatNo.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AddressValidationError.missingFlatNo
        }

        return AddressRequest(
            title: title,
            lat: region.center.latitude,
            lng: region.center.longitude,
            description: address,
            type: addressPlace.rawValue,
            contact_name: nil,
            contact_phone: nil,
            floor: floorNo,
            apartment: flatNo,
            building: buildingNo,
            area: streetName,
            city: nil
        )
    }
}

#Preview {
    AddAddressView()
        .environmentObject(UserSettings())
        .environmentObject(AppRouter())
}

enum AddressValidationError: Error {
    case missingTitle
    case invalidLatLng
    case missingStreetName
    case missingBuildingNo
    case missingFlatNo

    var message: String {
        switch self {
        case .missingTitle:
            return "الرجاء إدخال اسم العنوان"
        case .invalidLatLng:
            return "الموقع غير صالح"
        case .missingStreetName:
            return "الرجاء إدخال اسم الشارع"
        case .missingBuildingNo:
            return "الرجاء إدخال رقم المبنى"
        case .missingFlatNo:
            return "الرجاء إدخال رقم الشقة"
        }
    }
}
