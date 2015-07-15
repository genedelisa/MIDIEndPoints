//
//  MIDIEndpointViewController.swift
//  MIDIEndPoints
//
//  Created by Gene De Lisa on 7/14/15.
//  Copyright © 2015 Gene De Lisa. All rights reserved.
//

import Cocoa
import AudioToolbox

// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/OutlineView/OutlineView.html

class MIDISourceList: NSObject {
    let name:String
    var sources: [MIDISource] = []
    let icon:NSImage?
    
    init (name:String, icon:NSImage?){
        self.name = name
        self.icon = icon
    }
}
class MIDIDestinationList: NSObject {
    let name:String
    var destinations: [MIDIDestination] = []
    let icon:NSImage?
    
    init (name:String, icon:NSImage?){
        self.name = name
        self.icon = icon
    }
}

class MIDISource: NSObject {
    let name:String
    var endpoint: MIDIEndpointRef
    let icon:NSImage?
    
    init (name:String, endpoint:MIDIEndpointRef, icon:NSImage?){
        self.name = name
        self.endpoint = endpoint
        self.icon = icon
    }
}
class MIDIDestination: NSObject {
    let name:String
    var endpoint: MIDIEndpointRef
    let icon:NSImage?
    
    init (name:String, endpoint:MIDIEndpointRef, icon:NSImage?){
        self.name = name
        self.endpoint = endpoint
        self.icon = icon
    }
}


var midiSourceList = MIDISourceList(name: "Sources", icon: nil)
var midiDestinationList = MIDIDestinationList(name: "Destinations", icon: nil)


class MIDIEndpointViewController: NSViewController {

    @IBOutlet var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scanMIDISources()
        scanMIDIDestinations()
        
        outlineView.expandItem(nil, expandChildren: true)

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func scanMIDISources() {
        
        midiSourceList.sources = []
        
        let numSrcs = MIDIGetNumberOfSources()
        print("number of MIDI sources: \(numSrcs)")
        for srcIndex in 0 ..< numSrcs {
            let midiEndPoint = MIDIGetSource(srcIndex)
            if let displayName = getDisplayName(midiEndPoint) {
                let ms = MIDISource(name: displayName, endpoint: midiEndPoint, icon: NSImage(named: "MIDI-icon"))
                midiSourceList.sources.append(ms)
            }
        }
    }
    
    func scanMIDIDestinations() {
        
        midiDestinationList.destinations = []
        
        let numDests = MIDIGetNumberOfDestinations()
        print("number of MIDI dests: \(numDests)")
        for destIndex in 0 ..< numDests {
            let midiEndPoint = MIDIGetDestination(destIndex)
            if let displayName = getDisplayName(midiEndPoint) {
                let ms = MIDIDestination(name: displayName, endpoint: midiEndPoint, icon: NSImage(named: "MIDI-icon"))
                midiDestinationList.destinations.append(ms)
            }
        }
    }

    
    func getDisplayName(midiEndPoint:MIDIEndpointRef) -> String? {
        var property : Unmanaged<CFString>?
        let err = MIDIObjectGetStringProperty(midiEndPoint, kMIDIPropertyDisplayName, &property)
        if err == noErr {
            let displayName = property!.takeRetainedValue() as String
            return displayName
        }
        return nil
    }


}


extension MIDIEndpointViewController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, viewForTableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        print("viewForTableColumn \(item)")

        switch item {
        case let ms as MIDISource:
            print("viewForTableColumn endpoint \(ms)")
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = ms.name
            }
            if let image = ms.icon {
                view.imageView!.image = image
            }

            return view
            
        case let ms as MIDIDestination:
            print("viewForTableColumn endpoint \(ms)")
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = ms.name
            }
            if let image = ms.icon {
                view.imageView!.image = image
            }
            
            return view
            

        case let srclist as MIDISourceList:
            print("viewForTableColumn MIDISourceList  \(srclist)")
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = srclist.name
            }

            return view
            
        case let dests as MIDIDestinationList:
            print("viewForTableColumn MIDIDestinationList  \(dests)")
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = dests.name
            }
            
            return view
        
        default:
            print("whazzat? \(item)")
            return nil
        }
        
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification){
        
        if let index = notification.object?.selectedRow {
            if let object = notification.object?.itemAtRow(index) {
                if let s = object as? MIDISource {
                    print("selected Object is a MIDISource \(s.name)")
                }
                if let s = object as? MIDISourceList {
                    print("selected Object is a MIDISourceList \(s.name)")
                }
                if let s = object as? MIDIDestination {
                    print("selected Object is a MIDIDestination \(s.name)")
                }
                if let s = object as? MIDIDestinationList {
                    print("selected Object is a MIDIDestinationList \(s.name)")
                }
            }
        }
    }


}


extension MIDIEndpointViewController: NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        print("child:ofItem index \(index) item \(item)")
        
        if let item: AnyObject = item {
            switch item {
            case let s as MIDISourceList:
                print("child source list")
                return s.sources[index]
                
            case let s as MIDIDestinationList:
                print("child dest list")
                return s.destinations[index]


            default:
                print("child self")
                return self
            }
        } else {
            print("child use index")
            switch index {
            case 0:
                return midiSourceList
           
            default:
                return midiDestinationList
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        print("isItemExpandable \(item)")
        switch item {
        case let srclist as MIDISourceList:
            print( (srclist.sources.count > 0) ? true : false)
            return (srclist.sources.count > 0) ? true : false
        case let destlist as MIDIDestinationList:
            print( (destlist.destinations.count > 0) ? true : false)
            return (destlist.destinations.count > 0) ? true : false
        default:
            return false
        }

    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        print("numberOfChildrenOfItem \(midiSourceList.sources.count) item \(item)")
        if let item: AnyObject = item {
            switch item {
            case let srclist as MIDISourceList:
                print("numberOfChildrenOfItem srclist")
                return srclist.sources.count
                
            case let destlist as MIDIDestinationList:
                print("numberOfChildrenOfItem MIDIDestinationList")
                return destlist.destinations.count

            default:
                print("numberOfChildrenOfItem 0")
                return 0
            }
        } else {
            print("numberOfChildrenOfItem 1")
            return 2 // src and dest
        }

    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        if item is MIDISourceList {
            return true
        }
        if item is MIDIDestinationList {
            return true
        }
        return false
    }
    
}