//
//  PeripheralViewController.swift
//  BeaconTest
//
//  Created by Henk van der Spek on 12/04/16.
//  Copyright © 2016 vanmezelf.nl. All rights reserved.
//

import UIKit
import CoreBluetooth
import PubNub

let pn_publish_key = "pub-c-47067a2e-1f51-4553-aa1c-fd6612899c0e"
let pn_subscribe_key = "sub-c-37a74c44-00e4-11e6-8b0b-0619f8945a4f"
let bt_service_uuid = CBUUID(string: "D0CBD57E-68FA-4F7A-9B45-F38F40FC08D8")
let bt_characteristic_uuid = CBUUID(string: "7D1D48B0-E2D3-4A45-B703-A80F811D1124")

class PeripheralViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    var client: PubNub?
    var uuid = NSUUID()
    let config = PNConfiguration(publishKey: pn_publish_key, subscribeKey: pn_subscribe_key)
    
    @IBAction func buttonClicked() {
        let string = uuid.UUIDString
        Bluetooth.Service.defaultUuid = bt_service_uuid
        Bluetooth.Characteristic.defaultUuid = bt_characteristic_uuid
        Bluetooth.Peripheral.advertise(string,
            success: {
                print("Advertising service")
            },
            failure: {
                print("Failed to advertise service")
            })
    }
}

//self.button.hidden = true
//self.client = PubNub.clientWithConfiguration(self.config)
//self.client!.addListener(self)
//self.client!.subscribeToChannels([string], withPresence: false)
//        }
//        if let manager = manager where !manager.isAdvertising {
//        } else if let manager = manager where manager.isAdvertising {
//            manager.stopAdvertising()
//            client!.unsubscribeFromAll()
//            button.setTitle("Start", forState: .Normal)
//            print("Stopped")
//        }
//    }
//}
//            client = PubNub.clientWithConfiguration(config)
//            client!.addListener(self)
//            client!.subscribeToChannels([uuid.UUIDString], withPresence: false)
//        } else {
//            print("Failed to start advertising")
//        }
//    }
//}

extension PeripheralViewController: PNObjectEventListener {
    func client(client: PubNub, didReceiveStatus status: PNStatus) {
        switch status.category {
        case .PNConnectedCategory:
            print("connected to channel")
            client.publish("Hello world!", toChannel: uuid.UUIDString, withCompletion: { status in
                if !status.error {
                    print("Message published")
                }
            })
        default:
            print("PubNub client received status(\(status.category))")
            print("Failed to prepare for connections")
        }
    }
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        print("PubNub client received message(\"\(message.data.message!)\")")
        print("Waiting for connections...")
    }
}
