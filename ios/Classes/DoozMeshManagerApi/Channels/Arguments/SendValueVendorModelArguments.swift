//
//  SendGenericOnOffSetArguments.swift
//  nordic_nrf_mesh
//
//  Created by Alexis Barat on 13/10/2020.
//

struct SendValueVendorModelArguments: BaseFlutterArguments {
    let modelName: String?
    let modelId: Int
    let companyId: Int
    let opCode: Int
    let keyIndex: Int
    let parameters: [Int]
    let address: Int
}
