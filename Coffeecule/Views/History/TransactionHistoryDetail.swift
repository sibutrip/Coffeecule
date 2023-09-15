//
//  MemberListDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/12/23.
//

import SwiftUI
import CloudKit

struct TransactionHistoryDetail: View {
    @ObservedObject var vm: ViewModel
    let transaction: Transaction
    var buyer: Person {
        vm.relationships
            .map { $0.person }
            .first { $0.name == transaction.buyerName }!
    }
    var receiver: Person {
        vm.relationships
            .map { $0.person }
            .first { $0.name == transaction.receiverName }!
    }
    var buyerName: String {
        buyer.name
    }
    var buyerIcon: MugIcon {
        buyer.mugIcon
    }
    var buyerColor: UserColor {
        buyer.userColor
    }
    var receiverName: String {
        receiver.name
    }
    var receiverIcon: MugIcon {
        receiver.mugIcon
    }
    var receiverColor: UserColor {
        receiver.userColor
    }
    
    @State private var textSize: CGSize = .zero
    var body: some View {
        HStack {
            ZStack {
                Image(receiverIcon.selectedImageBackground)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color("user.background"))
                Image(receiverIcon.selectedImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color(receiverColor.colorName))
                
            }
            ChildSizeReader(size: $textSize) {
                Text(receiverName)
                    .font(.title2)
//                    .padding(.vertical)
                    .foregroundStyle(Color(receiver.userColor.colorName))
            }
            Spacer()
            Label("Received coffee from", systemImage: "arrow.left")
                .labelStyle(.iconOnly)
            Spacer()
            ChildSizeReader(size: $textSize) {
                Text(buyerName)
                    .font(.title2)
//                    .padding(.vertical)
                    .foregroundStyle(Color(buyer.userColor.colorName))
            }
            ZStack {
                Image(buyerIcon.selectedImageBackground)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color("user.background"))
                Image(buyerIcon.selectedImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color(buyerColor.colorName))
//            }
//            .overlay {
                Image(buyerIcon.isBuyingBadgeImage)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
//                    .offset(x: -textSize.height / 2, y: -textSize.height / 2)
            }
        }
    }
}

#Preview {
    TransactionHistoryDetail(vm: ViewModel(), transaction: Transaction(record: CKRecord(recordType: "test"))!)
}
