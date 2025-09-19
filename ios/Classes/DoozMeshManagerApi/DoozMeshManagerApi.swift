//
//  DoozMeshManagerApi.swift
//  nordic_nrf_mesh
//
//  Created by Alexis Barat on 29/05/2020.
//

import Foundation
import nRFMeshProvision

/// Example Vendor Message

struct MyVendorMessage: StaticVendorMessage {
    // Vendor opcode (0xC0) + company ID (0x02E5, Nordic)
    static let opCode: UInt32 = (UInt32(0xC000) << 16) | UInt32(0xE502)
    static let companyIdentifier: UInt16 = 0xE502

    let parameters: Data?

    // Required by BaseMeshMessage
    var isSegmented: Bool { false }
    var ttl: UInt8? { nil }

    // For sending
    init(parameters: Data?) {
        self.parameters = parameters
    }

    // For receiving
    init?(parameters: Data) {
        self.parameters = parameters
    }
}


class DoozMeshManagerApi: NSObject{
    
    //MARK: Public properties
    var meshNetworkManager: MeshNetworkManager
    var delegate: DoozMeshManagerApiDelegate?
    var eventSink: FlutterEventSink?
    var mtuSize: Int = -1
    
    //MARK: Private properties
    private var doozMeshNetwork: DoozMeshNetwork?
    
    private let messenger: FlutterBinaryMessenger
    private var doozStorage: LocalStorage
    
    private var doozProvisioningManager: DoozProvisioningManager
    private var doozTransmitter: DoozTransmitter
    private var sarBuffer: Data?
    private var sarInProgressType: PduType?

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        self.doozTransmitter = DoozTransmitter()
        self.doozStorage = LocalStorage(fileName: DoozStorage.fileName)
        
        self.meshNetworkManager = MeshNetworkManager(using: doozStorage)
        self.meshNetworkManager.acknowledgmentTimerInterval = 0.150
        self.meshNetworkManager.transmissionTimerInterval = 0.600
        self.meshNetworkManager.incompleteMessageTimeout = 10.0
        self.meshNetworkManager.retransmissionLimit = 2
        self.meshNetworkManager.acknowledgmentMessageInterval = 4.2
        self.meshNetworkManager.acknowledgmentMessageTimeout = 40.0
        self.meshNetworkManager.transmitter = doozTransmitter
        
        self.doozProvisioningManager = DoozProvisioningManager(meshNetworkManager: meshNetworkManager, messenger: messenger)
        
        super.init()
        
        meshNetworkManager.logger = self
        meshNetworkManager.delegate = self
        doozTransmitter.doozDelegate = self
        doozProvisioningManager.delegate = self
        
        self.delegate = self
        
        _initChannels(messenger: messenger)
    }
    
}



private extension DoozMeshManagerApi {
    
    func _initChannels(messenger: FlutterBinaryMessenger){
        
        FlutterEventChannel(
            name: FlutterChannels.MeshManagerApi.getEventChannelName(),
            binaryMessenger: messenger
        )
        .setStreamHandler(self)
        
        FlutterMethodChannel(
            name: FlutterChannels.MeshManagerApi.getMethodChannelName(),
            binaryMessenger: messenger
        )
        .setMethodCallHandler({ (call, result) in
            self._handleMethodCall(call, result: result)
        })
        
    }
    
    func _handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🥂 [\(self.classForCoder)] Received flutter call : \(call.method)")

      //  try? meshNetworkManager.register(vendorMessageType: MyVendorMessage.self, withOpCode: 0xC002E5)

        
        let _method = DoozMeshManagerApiChannel(call: call)
        
        switch _method {
        
        case .error(let error):
            switch error {
            case FlutterCallError.notImplemented:
                result(FlutterMethodNotImplemented)
            case FlutterCallError.missingArguments:
                result(FlutterError(code: "missingArguments", message: "The provided arguments does not match required", details: nil))
            case FlutterCallError.errorDecoding:
                result(FlutterError(code: "errorDecoding", message: "An error occured attempting to decode arguments", details: nil))
            default:
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
        
            break
        case .loadMeshNetwork:
            do {
                let network = try _loadMeshNetwork()                
                // to parse the generic feedback from board, Set up local Elements on the phone.
                let element0 = Element(name: "Primary Element", location: .first, models: [
                    Model(sigModelId: SigModelIds.GenericOnOffServer, delegate: GenericOnOffServerDelegate()),
                    Model(sigModelId: SigModelIds.GenericLevelServer, delegate: GenericLevelServerDelegate()),
                    Model(sigModelId: SigModelIds.GenericOnOffClient, delegate: GenericOnOffClientDelegate()),
                    Model(sigModelId: SigModelIds.GenericLevelClient, delegate: GenericLevelClientDelegate()),
                ])
                meshNetworkManager.localElements = [element0]
                delegate?.onNetworkLoaded(network)
                delegate?.onNetworkUpdated(network)
                result(nil)
            }catch {
                delegate?.onNetworkLoadFailed(error)
            }

        case .importMeshNetworkJson(let data):
            do{
                let network = try _importMeshNetworkJson(data.json)
                // to parse the generic feedback from board, Set up local Elements on the phone.
                let element0 = Element(name: "Primary Element", location: .first, models: [
                    Model(sigModelId: SigModelIds.GenericOnOffServer, delegate: GenericOnOffServerDelegate()),
                    Model(sigModelId: SigModelIds.GenericLevelServer, delegate: GenericLevelServerDelegate()),
                    Model(sigModelId: SigModelIds.GenericOnOffClient, delegate: GenericOnOffClientDelegate()),
                    Model(sigModelId: SigModelIds.GenericLevelClient, delegate: GenericLevelClientDelegate()),
                ])
                 meshNetworkManager.localElements = [element0]

                delegate?.onNetworkImported(network)
                delegate?.onNetworkUpdated(network)
                result(nil)
            }catch{
                delegate?.onNetworkImportFailed(error)
            }
            
        case .deleteMeshNetworkFromDb(let data):
            do{
                try _deleteMeshNetworkFromDb(data.id)
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            
        case .exportMeshNetwork:
            let json = _exportMeshNetwork()
            result(json)
            break
        case .resetMeshNetwork:
            do {
                try _resetMeshNetwork()
                result(nil)
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
           
            break
        case .identifyNode(var data):
            do{
                try doozProvisioningManager.identifyNode(data.uuid)
                result(nil)
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .provisioning:
            do{
                print("🔵 Starting provisioning...")
                try doozProvisioningManager.provision()
                print("✅ Provisioning success")
                result(nil)
            }catch{
                let nsError = error as NSError
                print("❌ Provisioning failed: \(nsError.localizedDescription)")
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .handleNotifications(let data):
              print("📩 Handle Notifications: \(data.pdu.data as NSData)")
            _didDeliverData(data: data.pdu.data)
            result(nil)
            break
        case .handleWriteCallbacks(let data):
              print("✍️ Handle Write Callback: \(data.pdu as NSData)")
            _didDeliverData(data: data.pdu)
            result(nil)
            break
        case .setMtuSize(let data):
            print("📏 Setting MTU Size: \(data.mtuSize)")
            delegate?.mtuSize = data.mtuSize
            result(nil)
            break
        case .cleanProvisioningData:
            
            doozProvisioningManager.cleanProvisioningData()
            result(nil)
            break
        case .sendConfigCompositionDataGet(let data):
            
            doozProvisioningManager.sendConfigCompositionDataGet(data.dest)
            result(nil)
            break
        case .sendConfigAppKeyAdd(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys.first else{
                let error = MeshNetworkError.noApplicationKey
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            doozProvisioningManager.sendConfigAppKeyAdd(dest: data.dest, appKey: appKey)
            result(nil)
            break
        case .sendGenericLevelSet(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            let stepResolution = StepResolution(rawValue: UInt8(data.transitionResolution))!
            let transitionTime = TransitionTime(steps: UInt8(data.transitionStep), stepResolution: stepResolution)
            
            let message = GenericLevelSet(level: Int16(data.level), transitionTime: transitionTime, delay: UInt8(data.delay))
            do{
                
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                
                result(nil)
                
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
            
        case .sendGenericOnOffSet(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            let stepResolution = StepResolution(rawValue: UInt8(data.transitionResolution))!
            let transitionTime = TransitionTime(steps: UInt8(data.transitionStep), stepResolution: stepResolution)
            
            let message = GenericOnOffSet(data.value, transitionTime: transitionTime, delay: UInt8(data.delay))
            
            do{
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                result(nil)
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
            case .sendValueVendorModel(let data):
                print("📌 sendValueVendorModel called")
                print("➡️ nodeId: \(data.address)")
                print("➡️ modelId: \(data.modelId)")
                print("➡️ companyId: \(data.companyId)")
                print("➡️ opCode: \(data.opCode)")
                print("➡️ keyIndex: \(data.keyIndex)")
                print("➡️ parameters: \(data.parameters)")

                do {
                    // 1️⃣ Get the node
                    guard let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.address)!) else {
                        result(FlutterError(code: "2001", message: "Node not found", details: nil))
                        return
                    }

                    // 2️⃣ Get the element
                    guard let element = node.element(withAddress: Address(exactly: data.address)!) else {
                        result(FlutterError(code: "2002", message: "Element not found", details: nil))
                        return
                    }

                        let companyId = UInt32(data.companyId ?? 0x02E5)   // fallback to 0x02E5
                        let modelId = UInt32(data.modelId)                 // 0x0001
                        let combinedModelId = (companyId << 16) | modelId  // 0x02E50001
                        print("➡️ Combined ModelId (company + model): 0x\(String(combinedModelId, radix: 16))")

                        // Fetch the vendor model
                        guard let model = element.model(withModelId: combinedModelId) else {
                            result(FlutterError(code: "2003", message: "Vendor model not found", details: nil))
                            return
                        }
                    print("✅ Model found: \(model)")


                    // 4️⃣ Get the application key
                    guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else {
                        result(FlutterError(code: "2004", message: "AppKey not found", details: nil))
                        return
                    }

                    // 5️⃣ Convert parameters to Data
                    let parametersData = Data(data.parameters.map { UInt8($0) })
                    print("✅ Parameters Data: \(parametersData as NSData)")
                    
                    let message: MeshMessage = MyVendorMessage(parameters: parametersData)
                    // Registering the MyVendorMessage type.
                    
                    do {
                        try meshNetworkManager.send(
                            message,                 // VendorMessage → MeshMessage
                            to: MeshAddress(Address(exactly: data.address)!),
                            using:appKey
                        )
                        print("✅ Vendor message sent successfully")
                    } catch {
                        print("❌ Failed to send vendor message: \(error)")
                    }

                } catch {
                    let nsError = error as NSError
                    print("❌ Error sending vendor model message: \(nsError.localizedDescription)")
                    result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                }

                break


        case .sendConfigModelSubscriptionAdd(let data):
            if
                let group = meshNetworkManager.meshNetwork?.group(withAddress: MeshAddress(Address(exactly: data.subscriptionAddress)!)),

                    let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.elementAddress)!),
                let element = node.element(withAddress: Address(exactly: data.elementAddress)!),
                let model = element.model(withModelId: UInt32(data.modelIdentifier)){

                let message: ConfigMessage =
                    ConfigModelSubscriptionAdd(group: group, to: model) ??
                    ConfigModelSubscriptionVirtualAddressAdd(group: group, to: model)!

                do{
                    _ = try meshNetworkManager.send(message, to: node)
                    result(true)
                }catch{
                    let nsError = error as NSError
                    result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                }
            }
            break
        case .sendConfigModelSubscriptionDelete(let data):
            if
                let group = meshNetworkManager.meshNetwork?.group(withAddress: MeshAddress(Address(exactly: data.subscriptionAddress)!)),
                
                    let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.elementAddress)!),
                let element = node.element(withAddress: Address(exactly: data.elementAddress)!),
                let model = element.model(withModelId: UInt32(data.modelIdentifier)){
                
                let message: ConfigMessage =
                    ConfigModelSubscriptionDelete(group: group, from: model) ??
                    ConfigModelSubscriptionVirtualAddressDelete(group: group, from: model)!
                
                do{
                    _ = try meshNetworkManager.send(message, to: node)
                    result(true)
                }catch{
                    let nsError = error as NSError
                    result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                }
            }
            break
        case .sendConfigModelAppBind(let data):
            do{
                let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.nodeId)!)
                let element = node?.element(withAddress: Address(exactly: data.elementId)!)
                let model = element?.model(withModelId: UInt32(data.modelId))
                let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.appKeyIndex)]

                if let _appKey = appKey, let _model = model{

                    if let configModelAppBind = ConfigModelAppBind(applicationKey: _appKey, to: _model){
                        try _ =  meshNetworkManager.send(configModelAppBind, to: node!)
                        result(nil)
                    }
                }

            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .getSequenceNumberForAddress(let data):
            if
                let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(bitPattern: data.address)),
                _node.elements.count == 1,
                let element = _node.elements.first {
                
                let sequenceNumber = meshNetworkManager.getSequenceNumber(ofLocalElement: element)
                result(sequenceNumber)
                
            }else{
                let error = AccessError.invalidElement
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .setSequenceNumberForAddress(let data):
            if
                let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(bitPattern: data.address)),
                _node.elements.count == 1,
                let element = _node.elements.first {
                meshNetworkManager.setSequenceNumber(data.sequenceNumber, forLocalElement: element)
                result(nil)

            }else{
                let error = AccessError.invalidElement
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .sendGenericLevelGet(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            let message = GenericLevelGet()
            do{
                
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                
                result(nil)
                
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .setNetworkTransmitSettings(let data):
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            let message = ConfigNetworkTransmitSet(count: UInt8(data.transmitCount), steps: UInt8(data.transmitIntervalSteps))
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .getNetworkTransmitSettings(let data):
            let message = ConfigNetworkTransmitGet()
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .getDefaultTtl(let data):
            let message = ConfigDefaultTtlGet()
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .setDefaultTtl(let data):
            let message = ConfigDefaultTtlSet(ttl: UInt8(data.ttl))
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .getSNBeacon(let data):
            let message = ConfigBeaconGet()
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .setSNBeacon(let data):
            let message = ConfigBeaconSet(enable: Bool(data.enable))
            let _node = doozMeshNetwork?.meshNetwork.node(withAddress: Address(exactly: data.address)!)
            do {
                _ = try meshNetworkManager.send(message, to: _node!)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .sendConfigModelSubscriptionDeleteAll(let data):
            if
                
                let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.elementAddress)!),
                let element = node.element(withAddress: Address(exactly: data.elementAddress)!),
                let model = element.model(withModelId: UInt32(data.modelIdentifier)){
                
                let message: ConfigMessage = ConfigModelSubscriptionDeleteAll(from: model)!
                do {
                    _ = try meshNetworkManager.send(message, to: node)
                    result(nil)
                } catch {
                    let nsError = error as NSError
                    result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                }
            }
            break
        case .sendConfigModelPublicationSet(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.appKeyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            let retransmit = Publish.Retransmit.init(publishRetransmitCount: UInt8(data.retransmitCount), intervalSteps: UInt8(data.retransmitIntervalSteps))
            //let stepResolution = StepResolution.init(rawValue: .hundredsOfMilliseconds)
            let period = Publish.Period.init(steps: UInt8(data.retransmitIntervalSteps), resolution: .hundredsOfMilliseconds)
            let publish = Publish.init(to: MeshAddress(Address(exactly: data.publishAddress)!), using: appKey, usingFriendshipMaterial: data.credentialFlag, ttl: UInt8(data.publishTtl), period: period, retransmit: retransmit)

            if
                let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.elementAddress)!),
                let element = node.element(withAddress: Address(exactly: data.elementAddress)!),
                let model = element.model(withModelId: UInt32(data.modelIdentifier)){
                let message: ConfigModelPublicationSet = ConfigModelPublicationSet(publish, to: model)!
                    do{
                        _ = try meshNetworkManager.send(message, to: node)
                        result(nil)
                    }catch{
                        let nsError = error as NSError
                        result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                    }
                }
            break
        case .getPublicationSettings(let data):
            if
                let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.elementAddress)!),
                let element = node.element(withAddress: Address(exactly: data.elementAddress)!),
                let model = element.model(withModelId: UInt32(data.modelIdentifier)){
                let message: ConfigModelPublicationGet = ConfigModelPublicationGet(for: model)!
                    do{
                        _ = try meshNetworkManager.send(message, to: node)
                        result(nil)
                    }catch{
                        let nsError = error as NSError
                        result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                    }
                }
            break
        case .sendLightLightness(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            let message: LightLightnessSet = LightLightnessSet(lightness: UInt16(data.lightness))
            do {
                _ = try meshNetworkManager.send(message, to: MeshAddress(Address(bitPattern: data.address)), using: appKey)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .sendLightCtl(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            let message = LightCTLSet(lightness: UInt16(data.lightness), temperature: UInt16(data.temperature), deltaUV: data.lightDeltaUV)
            do {
                _ = try meshNetworkManager.send(message, to: MeshAddress(Address(bitPattern: data.address)), using: appKey)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .sendLightHsl(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            let message = LightHSLSet(lightness: UInt16(data.lightness), hue: UInt16(data.hue), saturation: UInt16(data.saturation))
            do {
                _ = try meshNetworkManager.send(message, to: MeshAddress(Address(bitPattern: data.address)), using: appKey)
                result(nil)
            } catch {
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .sendV2MagicLevel(let data):
            
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            let message = MagicLevelSet(io: UInt8(data.io), index: UInt16(data.index), value: UInt32(data.value), correlation: UInt32(data.correlation))
            do{
                
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                
                result(nil)
                
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
            
        case .getV2MagicLevel(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            
            let message = MagicLevelGet(io: UInt8(data.io), index: UInt16(data.index), correlation: UInt32(data.correlation))
            do{
                
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                
                result(nil)
                
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .doozScenarioEpochSet(let data):
            guard let appKey = meshNetworkManager.meshNetwork?.applicationKeys[KeyIndex(data.keyIndex)] else{
                let error = MeshNetworkError.keyIndexOutOfRange
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                return
            }
            let message = DoozEpochSet(packed: UInt16(data.packed), epoch: UInt32(data.epoch), correlation: UInt32(data.correlation), extra: UInt16?(data.extra ?? 0))
            do{
                _ = try meshNetworkManager.send(
                    message,
                    to: MeshAddress(Address(exactly: data.address)!),
                    using: appKey
                )
                result(nil)
            }catch{
                let nsError = error as NSError
                result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
            }
            break
        case .isAdvertisingWithNetworkIdentity(let data):
            result(isAdvertisingWithNetworkIdentity(data: data.serviceData.data))
        case .isAdvertisedWithNodeIdentity(let data):
            result(isAdvertisedWithNodeIdentity(data: data.serviceData.data))
        case .nodeIdentityMatches(let data):
            let hashAndRandom = nodeIdentityMatches(data: data.serviceData.data)
            guard hashAndRandom != nil else{
                result(false)
                return
            }
            result(meshNetworkManager.meshNetwork!.matches(hash: hashAndRandom!.hash, random: hashAndRandom!.random))
        case .networkIdMatches(let data):
            result(networkIdMatches(data: data.serviceData.data))
            
        case .cachedProvisionedMeshNodeUuid:
            let provisionedDevice = doozProvisioningManager.getCachedProvisionedDevice()
            if ("nil" == provisionedDevice){
                result(nil)
            }
            result(provisionedDevice)
            
        case .deprovision(let data):
            if
                let node = meshNetworkManager.meshNetwork?.node(withAddress: Address(exactly: data.unicastAddress)!){
                let message = ConfigNodeReset()
                do{
                    _ = try meshNetworkManager.send(
                        message,
                        to: node
                    )
                    result(true)
                }catch{
                    let nsError = error as NSError
                    result(FlutterError(code: String(nsError.code), message: nsError.localizedDescription, details: nil))
                }
            }
            break
        }
        
    }
    
}


private extension DoozMeshManagerApi{
    
    func isAdvertisingWithNetworkIdentity(data: Data) -> Bool{
        guard data.count == 9, data[0] == 0x00 else {
            return false
        }
        return true
    }
    
    func isAdvertisedWithNodeIdentity(data: Data) -> Bool{
        guard data.count == 17, data[0] == 0x01 else {
            return false
        }
        return true
    }
    
    func nodeIdentityMatches(data: Data) -> (hash: Data, random: Data)?{
        guard data.count == 17, data[0] == 0x01 else {
            return nil
        }
        return (hash: data.subdata(in: 1..<9), random: data.subdata(in: 9..<17))
    }
    
    func networkIdMatches(data: Data) -> Bool{
        let nId = data.subdata(in: 1..<9);
        return meshNetworkManager.meshNetwork!.matches(networkId: nId)
    }
    
    func _loadMeshNetwork() throws -> MeshNetwork {
        
        do{
            
            if try meshNetworkManager.load(){
                // Mesh Network loaded from database
            }else{
                // No mesh network in database, we have to create one
                let meshNetwork = _generateMeshNetwork()
                
                try _ = meshNetwork.add(networkKey: Data.random128BitKey(), name: "Network Key 1")
                
                try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 1")
                try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 2")
                try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 3")

                _ = meshNetworkManager.save()
            }
            
            guard let _network = meshNetworkManager.meshNetwork else{
                throw(DoozMeshManagerApiError.errorLoadingMeshNetwork)
            }
            
            return _network
            
        }catch{
            throw(error)
        }
        
    }
    
    
    func _importMeshNetworkJson(_ json: String) throws -> MeshNetwork {
        
        
        do{
            // It’s safe to force-unwrap the result of string-to-data transformation only when you use a Unicode encoding.
            let data = json.data(using: .utf8)!
            let _network = try meshNetworkManager.import(from: data)
            
            if (doozMeshNetwork == nil || doozMeshNetwork?.meshNetwork.uuid != _network.uuid) {
                doozMeshNetwork = DoozMeshNetwork(messenger: messenger, network: _network)
            } else {
                doozMeshNetwork?.meshNetwork = _network
            }
            
            return _network
            
        }catch{
            throw(error)
        }
    }
    
    func _deleteMeshNetworkFromDb(_ id: String) throws{
        
        do{
            try doozStorage.delete()
        }catch{
            throw error
        }
        
    }
    
    func _exportMeshNetwork() -> String{

        let data = meshNetworkManager.export()
        let str = String(decoding: data, as: UTF8.self)
        
        return str

    }
    
    func _generateMeshNetwork() -> MeshNetwork{
        
        let meshUUID = UUID().uuidString
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        
        let meshNetwork = meshNetworkManager.createNewMeshNetwork(withName: meshUUID, by: provisioner)
        
        return meshNetwork
    }
    
    /// Delete the existing network in local database and recreate a new / empty Mesh Network
    func _resetMeshNetwork() throws{
//        guard let _meshNetwork = meshNetworkManager.meshNetwork else{
//            return
//        }
        
        do{
//            try _deleteMeshNetworkFromDb(_meshNetwork.uuid.uuidString)
//            let _ = _generateMeshNetwork()
            let meshNetwork = _generateMeshNetwork()
                        
            try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 1")
            try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 2")
            try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "Application Key 3")

            _ = meshNetworkManager.save()
            
            // to parse the generic feedback from board, Set up local Elements on the phone.
            let element0 = Element(name: "Primary Element", location: .first, models: [
                Model(sigModelId: SigModelIds.GenericOnOffServer, delegate: GenericOnOffServerDelegate()),
                Model(sigModelId: SigModelIds.GenericLevelServer, delegate: GenericLevelServerDelegate()),
                Model(sigModelId: SigModelIds.GenericOnOffClient, delegate: GenericOnOffClientDelegate()),
                Model(sigModelId: SigModelIds.GenericLevelClient, delegate: GenericLevelClientDelegate()),
            ])
            meshNetworkManager.localElements = [element0]
            
            delegate?.onNetworkLoaded(meshNetwork)
        }catch{
            throw(error)
        }
        
    }

//    func _didDeliverData(data: Data){
//
//        let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
//        print("Received PDU: \(hexString)")
//        
//        let header = data[0]
//        let sar = header >> 6          // top 2 bits
//        let messageType = header & 0x3F // lower 6 bits
// 
//        print("SAR: \(sar), Message Type: \(messageType)")
//
//        guard let type = PduType(rawValue: messageType) else {
//            print("Received PDU with unknown type: \(header)")
//            return // unknown type
//        }
////        guard
////            let type = PduType(rawValue: UInt8(data[0])) else{
////            print("Received PDU with unknown type: \(data[0])")
////            return
////        }
//
//        let packet = data.subdata(in: 1 ..< data.count)
//        switch type {
//        case .provisioningPdu:
//            print("Received Provisioning PDU, Data: \(hexString)")
//            doozProvisioningManager.didDeliverData(data, ofType: type)
//
//        default:
//            
//            meshNetworkManager.bearerDidDeliverData(packet, ofType: type)
//        }
//
//    }
    // Add a global (or static) variable to track reassembly

    func _didDeliverData(data: Data) {

        let header = data[0]
        let sar = (header & 0xC0) >> 6   // bits 7-6
        let messageType = header & 0x3F  // lower 6 bits

        let payload = data.subdata(in: 1 ..< data.count)
        guard let type = PduType(rawValue: messageType) else {
            return
        }

        switch sar {
        case 0: // Complete message
            forwardPdu(type: type, payload: payload, fullData: data)

        case 1: // SAR Start
            sarBuffer = payload
            sarInProgressType = type

        case 2: // SAR Continue
            if sarInProgressType == type, var buffer = sarBuffer {
                buffer.append(payload)
                sarBuffer = buffer
            }

        case 3: // SAR End
            if sarInProgressType == type, var buffer = sarBuffer {
                buffer.append(payload)
                forwardPdu(type: type, payload: buffer, fullData: Data([header]) + buffer)
            }
            // Clear after complete
            sarBuffer = nil
            sarInProgressType = nil

        default:
            return
        }
    }

    // Helper function to forward PDUs
    private func forwardPdu(type: PduType, payload: Data, fullData: Data) {
        switch type {
        case .provisioningPdu:
            doozProvisioningManager.didDeliverData(fullData, ofType: type)
        default:
            meshNetworkManager.bearerDidDeliverData(payload, ofType: type)
        }
    }

}

extension DoozMeshManagerApi: FlutterStreamHandler{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
}

extension DoozMeshManagerApi: DoozMeshManagerApiDelegate{
    
    func onNetworkLoaded(_ network: MeshNetwork) {
        
        if (doozMeshNetwork == nil || doozMeshNetwork?.meshNetwork.uuid != network.uuid) {
            doozMeshNetwork = DoozMeshNetwork(messenger: messenger, network: network)
        } else {
            doozMeshNetwork?.meshNetwork = network
        }
        
        let message: FlutterMessage =
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkLoaded.rawValue,
                EventSinkKeys.id.rawValue : network.uuid.uuidString
            ]
        _sendFlutterMessage(message)
        
    }
    
    func onNetworkLoadFailed(_ error: Error) {
        
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkLoadFailed.rawValue,
            EventSinkKeys.error.rawValue : error
        ]
        
        _sendFlutterMessage(message)
        
    }
    
    func onNetworkUpdated(_ network: MeshNetwork) {
                
        doozMeshNetwork?.meshNetwork = network
        
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkUpdated.rawValue,
            EventSinkKeys.id.rawValue : network.uuid.uuidString
        ]
        
        _sendFlutterMessage(message)
    }
    
    func onNetworkImported(_ network: MeshNetwork) {
        
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkImported.rawValue,
            EventSinkKeys.id.rawValue : network.uuid.uuidString
        ]
        
        _sendFlutterMessage(message)
        
    }
    
    func onNetworkImportFailed(_ error: Error) {
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkImportFailed.rawValue,
            EventSinkKeys.error.rawValue : error
        ] 
        
        _sendFlutterMessage(message)
    }
    
}


extension DoozMeshManagerApi: DoozProvisioningManagerDelegate{
    func provisioningBearerSendMessage(data: Data, bearer: DoozPBGattBearer) {
        
        let message: FlutterMessage = [
            
            EventSinkKeys.eventName.rawValue: ProvisioningEvent.sendProvisioningPdu.rawValue,
            EventSinkKeys.pdu.rawValue: data,
            EventSinkKeys.meshNode.meshNode.rawValue:[
                EventSinkKeys.meshNode.uuid.rawValue: bearer.identifier.uuidString
            ]
        ]
        
        _sendFlutterMessage(message)
        
    }
    
    func provisioningStateDidChange(unprovisionedDevice: UnprovisionedDevice, state: ProvisioningState) {
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue : state.eventName(),
            EventSinkKeys.state.rawValue : state.flutterState(),
            EventSinkKeys.data.rawValue:[],
            EventSinkKeys.meshNode.meshNode.rawValue:[
                EventSinkKeys.meshNode.uuid.rawValue:unprovisionedDevice.uuid.uuidString
            ]
        ]
        
        _sendFlutterMessage(message)
    }
    
}



extension DoozMeshManagerApi: DoozPBGattBearerDelegate, DoozGattBearerDelegate, DoozTransmitterDelegate{
    func send(data: Data) {
        
        let message: FlutterMessage = [
            EventSinkKeys.eventName.rawValue: MessageEvent.onMeshPduCreated.rawValue,
            EventSinkKeys.pdu.rawValue: data
        ]
        
        _sendFlutterMessage(message)
        
    }
}

