//
//  FloatingTabView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI

// MARK: - 1. Protokol untuk Tab
protocol FloatingTabProtocol {
    var symbolImage: String { get }
}

// MARK: - 2. ObservableObject Helper
// Mengelola status visibility, ekspansi, dan offset posisi vertikal FAB
class FLoatingTabViewHelper: ObservableObject {
    @Published var hideEntireTabBarComponent: Bool = false
    @Published var isCircularTabBarExpanded: Bool = false
    @Published var fabPositionOffset: CGSize = .zero // Hanya komponen .height yang akan diubah untuk drag
}

// MARK: - 3. Konfigurasi untuk FloatingTabBar
struct FloatingTabConfig {
    var activeTint: Color = .primary
    var activeBackgroundTint: Color = .purple
    var inactiveTint: Color = .gray
    var tabAnimation: Animation = .smooth(duration: 0.35, extraBounce: 0.1)
    var backgroundColor: Color = .gray.opacity(0.15) // Untuk latar belakang item saat diekspansi
    var insetAmount: CGFloat = 6
    var isTranslucent: Bool = true

    var mainButtonHPadding: CGFloat = 22 // Jarak horizontal tombol dari tepi kanan
    var mainButtonBPadding: CGFloat = 22 // Jarak vertikal tombol dari tepi bawah (posisi awal)
    var mainButtonSize: CGFloat = 58
    
    var collapsedButtonIcon: String = "line.3.horizontal.decrease.circle.fill"
    var expandedButtonIcon: String = "xmark.circle.fill"
    var itemSpacingWhenExpanded: CGFloat = 8
    var itemSizeRatio: CGFloat = 0.60
    var expansionItemsBackgroundColor: Color = .secondary.opacity(0.15)
    var expansionItemsIsTranslucent: Bool = true
    var expansionItemsPadding: CGFloat = 8
    var expansionAnimation: Animation = .interpolatingSpring(mass: 0.7, stiffness: 160, damping: 15, initialVelocity: 0.2)
    var dragEndAnimation: Animation = .interpolatingSpring(stiffness: 120, damping: 15)
}

// MARK: - 4. Modifier untuk Menyembunyikan Seluruh Komponen Tab Bar
fileprivate struct HideFloatingTabBarModifier: ViewModifier {
    @EnvironmentObject private var helper: FLoatingTabViewHelper
    var status: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: status) { oldStatus, newStatus in // iOS 17+ syntax, adjust if needed for older iOS
            // .onChange(of: status) { newStatus in // iOS 14-16 syntax
                // if oldStatus != newStatus { // Hanya untuk iOS 17+
                    if helper.hideEntireTabBarComponent != newStatus {
                        helper.hideEntireTabBarComponent = newStatus
                    }
                // }
            }
    }
}

extension View {
    func hideCircularExpandingTabBar(_ status: Bool) -> some View {
        self.modifier(HideFloatingTabBarModifier(status: status))
    }
}

// MARK: - 5. ExpandingCircularTabBar (Implementasi Tombol Bulat yang Bisa Ekspansi)
fileprivate struct ExpandingCircularTabBar<Value: CaseIterable & Hashable & FloatingTabProtocol>: View where Value.AllCases: RandomAccessCollection {
    
    @EnvironmentObject private var helper: FLoatingTabViewHelper
    @Binding var activeTab: Value
    var config: FloatingTabConfig
    
    init(activeTab: Binding<Value>, config: FloatingTabConfig) {
        self._activeTab = activeTab
        self.config = config
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if helper.isCircularTabBarExpanded {
                ForEach(Value.allCases.reversed(), id: \.hashValue) { tab in
                    Button {
                        activeTab = tab
                        withAnimation(config.expansionAnimation.speed(1.2)) {
                            helper.isCircularTabBarExpanded = false
                        }
                    } label: {
                        Image(systemName: tab.symbolImage)
                            .font(.system(size: config.mainButtonSize * config.itemSizeRatio * 0.55))
                            .foregroundColor(activeTab == tab ? config.activeTint : config.inactiveTint)
                            .frame(width: config.mainButtonSize * config.itemSizeRatio,
                                   height: config.mainButtonSize * config.itemSizeRatio)
                            .background(Circle().fill(activeTab == tab ? config.activeBackgroundTint.opacity(0.5) : Color.clear))
                    }
                    .padding(.horizontal, config.itemSpacingWhenExpanded / 2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3, anchor: .trailing).combined(with: .opacity).animation(config.expansionAnimation.delay(0.05)),
                        removal: .scale(scale: 0.3, anchor: .trailing).combined(with: .opacity).animation(config.expansionAnimation.speed(1.5)))
                    )
                }
            }
            Button {
                withAnimation(config.expansionAnimation) {
                    helper.isCircularTabBarExpanded.toggle()
                }
            } label: {
                Image(systemName: helper.isCircularTabBarExpanded ? config.expandedButtonIcon : config.collapsedButtonIcon)
                    .font(.system(size: config.mainButtonSize * 0.45, weight: .medium))
                    .foregroundColor(config.activeTint)
                    .frame(width: config.mainButtonSize, height: config.mainButtonSize)
                    .background(config.activeBackgroundTint)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: helper.isCircularTabBarExpanded ? 5 : 3, x: 0, y: 2)
            }
            .padding(.leading, helper.isCircularTabBarExpanded ? config.itemSpacingWhenExpanded / 2 : 0)
        }
        .padding(helper.isCircularTabBarExpanded ? config.expansionItemsPadding : 0)
        .background(
            Group {
                if helper.isCircularTabBarExpanded {
                    Capsule()
                        .fill(config.expansionItemsIsTranslucent ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(config.expansionItemsBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                }
            }
        )
        .animation(config.expansionAnimation, value: helper.isCircularTabBarExpanded)
    }
    
    // Di dalam ExpandingCircularTabBar
    var calculatedExpandedWidth: CGFloat {
        // Jika tidak ada item, lebarnya hanya tombol utama + padding luar
        guard !Value.allCases.isEmpty else {
            return config.mainButtonSize + (config.expansionItemsPadding * 2)
        }

        // Lebar semua item (termasuk padding horizontal internalnya)
        // Setiap item (Button > Image) memiliki frame(width: itemFrameSize) dan .padding(.horizontal, itemSpacing/2)
        // Jadi, lebar visual satu item = itemFrameSize + itemSpacing
        let itemFrameSize = config.mainButtonSize * config.itemSizeRatio
        let singleItemVisualWidth = itemFrameSize + config.itemSpacingWhenExpanded // karena padding .horizontal X/2 di kedua sisi
        let totalItemsVisualWidth = CGFloat(Value.allCases.count) * singleItemVisualWidth

        // Lebar tombol utama (termasuk padding kirinya)
        let mainButtonVisualWidth = config.mainButtonSize + (config.itemSpacingWhenExpanded / 2) // karena .padding(.leading, X/2)

        // Total lebar konten di dalam HStack (sebelum padding luar dari .padding(config.expansionItemsPadding))
        // Tidak ada HStack spacing eksplisit karena padding sudah menangani jarak.
        let totalInternalWidth = totalItemsVisualWidth + mainButtonVisualWidth
        
        // Lebar total termasuk padding luar dari .padding(config.expansionItemsPadding) pada HStack
        return totalInternalWidth + (config.expansionItemsPadding * 2)
    }
}

// MARK: - 6. FloatingTabView (Kontainer Utama dengan Logika Geser Vertikal)
struct FloatingTabView<Content: View, Value: CaseIterable & Hashable & FloatingTabProtocol>: View where Value.AllCases: RandomAccessCollection {
    
    @Binding var selection: Value
    var content: (Value, CGFloat) -> Content
    var config: FloatingTabConfig
    
    init(config: FloatingTabConfig = .init(), selection: Binding<Value>, @ViewBuilder content: @escaping (Value, CGFloat) -> Content) {
        self._selection = selection
        self.content = content
        self.config = config
    }
    
    @StateObject private var helper: FLoatingTabViewHelper = .init()
    @State private var liveDragAmountVertical: CGFloat = .zero // Hanya untuk pergeseran vertikal live

    var body: some View {
        GeometryReader { screenGeometry in
            ZStack(alignment: .bottomTrailing) { // Posisi awal FAB di kanan bawah
                
                let bottomClearanceForButton = config.mainButtonSize + config.mainButtonBPadding + (screenGeometry.safeAreaInsets.bottom)
                
                // Konten TabView
                if #available(iOS 18, *) {
                     TabView(selection: $selection) {
                        ForEach(Value.allCases, id: \.hashValue) { tab in
                            Tab(value: tab) {
                                content(tab, bottomClearanceForButton)
                                    .toolbarVisibility(.hidden, for: .tabBar)
                            }
                        }
                    }
                } else {
                    TabView(selection: $selection) {
                        ForEach(Value.allCases, id: \.hashValue) { tab in
                            content(tab, bottomClearanceForButton)
                                .tag(tab)
                                .toolbar(.hidden, for: .tabBar)
                        }
                    }
                }

                // Offset X akan selalu 0 dari posisi awalnya (kanan + padding horizontal) karena helper.fabPositionOffset.width dijaga 0.
                // Offset Y akan berdasarkan fabPositionOffset.height + liveDragAmountVertical.
                let currentAppliedOffsetY = helper.fabPositionOffset.height + liveDragAmountVertical
                
                let hideOffsetY = helper.hideEntireTabBarComponent ? (config.mainButtonSize + config.mainButtonBPadding + screenGeometry.safeAreaInsets.bottom + 50) : 0
                
                ExpandingCircularTabBar(activeTab: $selection, config: config)
                    .padding(.trailing, config.mainButtonHPadding) // Padding horizontal awal (tetap)
                    .padding(.bottom, config.mainButtonBPadding)   // Padding bawah awal (dasar untuk offset Y)
                    .offset(x: helper.fabPositionOffset.width, y: currentAppliedOffsetY) // fabPositionOffset.width akan 0
                    .offset(y: hideOffsetY) // Offset tambahan untuk menyembunyikan (hanya vertikal)
                    .gesture(
                        DragGesture(minimumDistance: 1.0)
                            .onChanged { value in
                                if helper.isCircularTabBarExpanded {
                                    withAnimation(config.expansionAnimation.speed(1.5)) {
                                        helper.isCircularTabBarExpanded = false
                                    }
                                }
                                // Hanya perbarui komponen height dari liveDragAmount
                                self.liveDragAmountVertical = value.translation.height
                            }
                            .onEnded { value in
                                // Perbarui hanya komponen height dari fabPositionOffset
                                var targetOffsetY = helper.fabPositionOffset.height + value.translation.height
                                // Pastikan komponen width dari fabPositionOffset selalu 0
                                let targetOffsetX: CGFloat = 0


                                // --- Logika Pembatasan Vertikal (Clamping Y) ---
                                let screenHeight = screenGeometry.size.height
                                let fabActualSize = config.mainButtonSize
                                
                                // Posisi awal (anchor) tombol FAB secara vertikal adalah di (ZStack height - mainButtonBPadding - fabSize)
                                // Offset (fabPositionOffset.height) adalah dari posisi anchor vertikal tersebut.
                                let initialFabTopY = screenHeight - config.mainButtonBPadding - fabActualSize
                                
                                // Hitung posisi atas FAB yang diusulkan dalam koordinat layar
                                let proposedFabTopY = initialFabTopY + targetOffsetY

                                // Batasi posisi atas FAB agar tidak melewati safe area atas,
                                // dan posisi bawah FAB tidak melewati safe area bawah.
                                let clampedFabTopY = max(
                                    screenGeometry.safeAreaInsets.top, // Batas atas
                                    min(proposedFabTopY, screenHeight - fabActualSize - screenGeometry.safeAreaInsets.bottom) // Batas bawah
                                )

                                // Konversi kembali posisi atas yang sudah dibatasi ke offset relatif dari posisi awal
                                targetOffsetY = clampedFabTopY - initialFabTopY
                                // --- Akhir Logika Pembatasan Vertikal ---

                                withAnimation(config.dragEndAnimation) {
                                    helper.fabPositionOffset = CGSize(width: targetOffsetX, height: targetOffsetY)
                                }
                                // Reset live drag amount
                                self.liveDragAmountVertical = .zero
                            }
                    )
                    .animation(config.tabAnimation, value: helper.hideEntireTabBarComponent)
            }
            .environmentObject(helper)
        }
    }
}

// MARK: - 7. Ekstensi Utilitas
extension UIApplication {
    var getKeyWindow: UIWindow? {
        // ... (implementasi sama seperti sebelumnya)
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
    }
}

#Preview {
    MainView()
}
