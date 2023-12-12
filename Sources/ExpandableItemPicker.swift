import SwiftUI


struct PLItemPickerView<
    Data : RandomAccessCollection,
    Content : View,
    SectionContent: View,
    Modifier: ViewModifier
>: View where Data.Element : Hashable {
    
    let data: Data
    @Binding var selectedItem: Data.Element?
    
    private let arrow: Image
    
    @ViewBuilder var content: (Data.Element) -> Content
    @ViewBuilder var section: (Data.Element) -> SectionContent
    
    private var contentModifier: Modifier
    @State private var isExpanded = false
    
    init(data: Data,
         selectedItem: Binding<Data.Element?>,
         contentModifier: Modifier = PLItemPickerDefaultModifier(),
         arrow: Image = Image("chevron"),
         @ViewBuilder content: @escaping (Data.Element) -> Content,
         @ViewBuilder section: @escaping (Data.Element) -> SectionContent) {
        self.data = data
        self._selectedItem = selectedItem
        self.contentModifier = contentModifier
        self.content = content
        self.section = section
        self.arrow = arrow
    }
    
    init(data: Data,
         selectedItem: Binding<Data.Element?>,
         contentModifier: Modifier = PLItemPickerDefaultModifier(),
         arrow: Image = Image("chevron"),
         @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where SectionContent == EmptyView {
        self.init(
            data: data,
            selectedItem: selectedItem,
            contentModifier: contentModifier,
            arrow: arrow,
            content: content,
            section: { _ in EmptyView()})
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let element = selectedItem ?? data.first {
                    ItemView(arrow: arrow, hasArrow: true) {
                        content(element)
                    }
                    .infinitySize()
                } else {
                    Color.white
                }
            }
            .frame(alignment: .top)
            .modifier(contentModifier)
            .onTapGesture {
                guard data.count > 1 else {
                    return
                }
                withTransaction(.noAnimation) {
                    isExpanded = true
                }
            }
            .fullScreenCover(isPresented: $isExpanded) {
                ExpandedItemPickerView(
                    data: data,
                    frame: proxy.frame(in: .global),
                    arrow: arrow,
                    contentModifier: contentModifier,
                    content: content,
                    section: section,
                    isExpanded: $isExpanded,
                    selectedItem: $selectedItem)
                .clearModalBackground()
            }
        }
    }
    
    private struct ExpandedItemPickerView<Data, Content, Modifier: ViewModifier>: View where Data : RandomAccessCollection, Content : View, Data.Element : Hashable, SectionContent: View {
        
        let data: Data
        let frame: CGRect
        let arrow: Image
        let contentModifier: Modifier
        let content: (Data.Element) -> Content
        let section: ((Data.Element) -> SectionContent)?
        
        @Binding var isExpanded: Bool
        @Binding var selectedItem: Data.Element?
        
        @State private var blur: CGFloat = 0
        @State private var height: CGFloat = 0
        @State private var y: CGFloat = 0
        @State private var verticalPadding: CGFloat = 50
        @State private var contentOpacity: CGFloat = 0.1
        @State private var contentHeight: CGFloat = 0
        
        var body: some View {
            ZStack(alignment: .top) {
                Color.black.opacity(0.6)
                    .opacity(contentOpacity)
                    .blur(radius: blur)
                    .ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(data, id: \.self) { element in
                                section?(element)
                                ItemView(
                                    arrow: arrow,
                                    hasArrow: element == data.first,
                                    isExpanded: true) {
                                        content(element)
                                    }
                                    .id(element.hashValue)
                                    .onTapGesture {
                                        selectedItem = element
                                        shrinkView()
                                    }
                            }
                        }
                        .size {
                            contentHeight = $0.height
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(selectedItem?.hashValue, anchor: .top)
                    }
                }
                .opacity(contentOpacity)
                .modifier(contentModifier)
                .frame(width: frame.width, height: height == 0 && isExpanded ? frame.height : height)
                .padding(.top, y)
                .padding([.leading, .trailing], frame.origin.x)
            }
            .ignoresSafeArea()
            .onAppear(perform: expandView)
            .onTapGesture(perform: shrinkView)
            .onAnimationCompleted(for: height) {
                animationDidComplete()
            }
            .animation(nil, value: isExpanded)
        }
        
        private func shrinkView() {
            withAnimation() {
                y = frame.origin.y
                height = 0
                blur = 0
                contentOpacity = 0
            }
        }
        
        private func expandView() {
            y = frame.origin.y
            withAnimation() {
                let deviceSafeAreaInsets = UIApplication.shared.mainWindow?.safeAreaInsets ?? .zero
                let maxHeight = UIScreen.main.bounds.height - (verticalPadding * 2 + deviceSafeAreaInsets.top + deviceSafeAreaInsets.bottom)
                let maxY = UIScreen.main.bounds.height - (verticalPadding + deviceSafeAreaInsets.bottom)
                height = contentHeight < maxHeight ? contentHeight : maxHeight
                y = maxY - frame.origin.y < height  ? maxY - height : y
                blur = 5
                contentOpacity = 1
            }
        }
        
        private func animationDidComplete() {
            if height == 0 {
                withTransaction(.noAnimation) {
                    isExpanded = false
                }
            }
        }
    }
    
    private struct ItemView<Content>: View where Content: View {
        
        let arrow: Image
        let hasArrow: Bool
        var isExpanded: Bool = false
        
        @ViewBuilder let content: () -> Content
        
        var body: some View {
            if hasArrow {
                ZStack {
                    VStack {
                        content()
                    }
                    HStack {
                        Spacer()
                        arrow
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                            .padding(.trailing, 16)
                    }
                }
            } else {
                content()
            }
        }
    }
}
