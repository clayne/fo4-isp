Scriptname ISP_Script extends ObjectReference

Activator Property DummyMarker Auto Const

SnapPoint[] Property SnapPoints Auto

CustomEvent OnSnapped
CustomEvent OnUnsnapped

Struct SnapPoint
	String Name
	String Target
	String Type
	String RemoteName Hidden
	ObjectReference Marker Hidden
	ObjectReference Object Hidden
EndStruct

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	PlaceMarkers()
	Update()
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	Update()
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	RemoveMarkers()
EndEvent

Function PlaceMarkers()
	SnapPoint SP
	
	int i
	While(i < SnapPoints.Length)
		SP = SnapPoints[i]
		
		SP.Marker = PlaceAtNode(SP.Name, DummyMarker as Form, 1, False, False, False, True) as ISP_MarkerScript
		SP.Marker.SetLinkedRef(Self, None)
		SP.Marker.SetPropertyValue("Name", SP.Name)
		SP.Marker.SetPropertyValue("Type", SP.Type)
		
		If(SP.Target == "")
			SP.Target = SP.Name
		EndIf
		
		i += 1
	EndWhile
EndFunction

Function RemoveMarkers()
	SnapPoint SP
	
	int i
	While(i < SnapPoints.Length)
		SP = SnapPoints[i]
		
		SP.Marker.Delete()
		SP.Marker = None
		If(SP.Object != None)
			Unsnap(SP)
		EndIf

		i += 1
	EndWhile
EndFunction

Function Update()
	ObjectReference[] FoundMarkers
	ISP_MarkerScript Marker
	SnapPoint SP
	
	int i
	While(i < SnapPoints.Length)
		SP = SnapPoints[i]
		FoundMarkers = SP.Marker.FindAllReferencesOfType(DummyMarker as Form, 5)
		
		If(FoundMarkers.Length > 1)
			int j
			While(j < FoundMarkers.Length)
				Marker = FoundMarkers[j] as ISP_MarkerScript
			
				If(IsValidMarker(SP, Marker))
					; We unsnap from one thing and then snap back to another
					If(SP.Object != None)
						Unsnap(SP)
					EndIf
					
					SP.RemoteName = Marker.Name
					SP.Object = Marker.GetLinkedRef(None)
					SendOnSnappedEvent(Self, SP.Object, SP.Name, Marker.Name)
					(SP.Object as ISP_Script).HandleSnap(SP.Object, Self, Marker.Name, SP.Target)
			
					j = FoundMarkers.Length
				EndIf
			
				j += 1
			EndWhile
		Else
			; something was just unsnapped
			If(SP.Object != None)
				Unsnap(SP)
			EndIf
			
			SP.RemoteName = ""
			SP.Object = None
		EndIf
		
		i += 1
	EndWhile
EndFunction

bool Function IsValidMarker(SnapPoint SP, ISP_MarkerScript Marker)
	If(Marker.GetLinkedRef(None) == Self)
		Return False
	ElseIf(Marker.GetLinkedRef(None).IsEnabled() == False)
		Return False
	ElseIf(SP.Type != "" && SP.Type == Marker.Type)
		Return True
	ElseIF(Marker.Name == SP.Target)
		Return True
	Else
		Return False
	EndIf
EndFunction

Function Unsnap(SnapPoint SP)
	SendOnUnsnappedEvent(Self, SP.Object, SP.Name, SP.RemoteName)
	(SP.Object as ISP_Script).HandleUnsnap(SP.Object, Self, SP.RemoteName, SP.Target)
	SP.Object = None
	SP.RemoteName = ""
EndFunction

ObjectReference Function GetObject(string Name)
	int index = SnapPoints.FindStruct("Name", Name)
	If(index == -1)
		Return None
	Else
		Return SnapPoints[index].Object
	EndIf
EndFunction

String Function GetRemoteName(String Name)
	int index = SnapPoints.FindStruct("Name", Name)
	If(index == -1)
		Return ""
	Else
		Return SnapPoints[index].RemoteName
	EndIf
EndFunction

Function Register(ObjectReference ref)
	ref.RegisterForCustomEvent(Self, "OnSnapped")
	ref.RegisterForCustomEvent(Self, "OnUnsnapped")
EndFunction

Function Unregister(ObjectReference ref)
	ref.UnregisterForCustomEvent(Self, "OnSnapped")
	ref.UnregisterForCustomEvent(Self, "OnUnsnapped")
EndFunction

Function SendOnSnappedEvent(ObjectReference objA, ObjectReference objB, String NodeName, String RemoteName)
	Var[] kargs = new Var[4]
	kargs[0] = objA
	kargs[1] = objB
	kargs[2] = NodeName
	kargs[3] = RemoteName
	SendCustomEvent("OnSnapped", kargs)

	Debug.Trace(objA + " was just snapped to " + objB + " at a node named: " + NodeName)
EndFunction

Function SendOnUnsnappedEvent(ObjectReference objA, ObjectReference objB, String NodeName, String RemoteName)
	Var[] kargs = new Var[4]
	kargs[0] = objA
	kargs[1] = objB
	kargs[2] = NodeName
	kargs[3] = RemoteName
	SendCustomEvent("OnUnsnapped", kargs)

	Debug.Trace(objA + " was just unsnapped from " + objB + " at a node named: " + NodeName)
EndFunction

Function HandleSnap(ObjectReference objA, ObjectReference objB, String NodeName, String RemoteName)
	SnapPoint SP = SnapPoints[SnapPoints.FindStruct("Name", NodeName)]
	SP.Object = objB
	SP.RemoteName = RemoteName
	
	SendOnSnappedEvent(objA, objB, NodeName, RemoteName)
EndFunction

Function HandleUnsnap(ObjectReference objA, ObjectReference objB, String NodeName, String RemoteName)
	SnapPoint SP = SnapPoints[SnapPoints.FindStruct("Name", NodeName)]
	SP.Object = None
	SP.RemoteName = ""

	SendOnUnsnappedEvent(objA, objB, NodeName, RemoteName)
EndFunction