Class {
	#name : #IPComm,
	#superclass : #Object,
	#instVars : [
		'uuid',
		'targetName',
		'commMsgListener',
		'session'
	],
	#category : #'IPharo-Comm'
}

{ #category : #'instance creation' }
IPComm class >> new [
	|instance|
	instance := super new.
	IPharoKernel instance commManager registerComm: instance.
	^ instance 
	
]

{ #category : #'instance creation' }
IPComm class >> new: anUUID [
	|instance|
	instance := super new.
	instance uuid: anUUID.
	IPharoKernel instance commManager registerComm: instance.
	^ instance 
	
]

{ #category : #'instance creation' }
IPComm class >> new: anUUID onSession: anIPSession [
	|instance|
	instance := self new: anUUID.
	^ instance session: anIPSession
	
]

{ #category : #'instance creation' }
IPComm class >> onSession: anIPSession [
	|instance|
	instance := self new.
	^ instance session: anIPSession
	
]

{ #category : #versions }
IPComm class >> version [
	^ '2.0.0'
]

{ #category : #'comm handlers' }
IPComm >> addCommListener: aCommListener [
	self commListeners add:aCommListener
]

{ #category : #'instance creation' }
IPComm >> close [
	self close:nil
]

{ #category : #'instance creation' }
IPComm >> close:data [
	self publish: ( self session commCloseMessage  new 
																	data: data;
																	commID: self uuid;
																	targetName: self targetName;
																	yourself )
]

{ #category : #accessing }
IPComm >> commListeners [
	^ commMsgListener ifNil:[ commMsgListener:= OrderedCollection new]
]

{ #category : #'instance creation' }
IPComm >> open [

	"AKI HAY QUE envíar en open el contenido del modelo del widget"
	self open: nil
]

{ #category : #'instance creation' }
IPComm >> open: data [

	self publish: (self session commOpenMessage 
															data: data;
															commID: self uuid;
															targetName: self targetName;
															yourself)
]

{ #category : #'comm handlers' }
IPComm >> publish: aResult [
	IPharoKernel instance publisher publish: aResult
]

{ #category : #'comm handlers' }
IPComm >> removeCommMsgListeners [ 
	self commListeners removeAll
]

{ #category : #'comm handlers' }
IPComm >> send: data [
	self publish: (self session commMsgMessage 
														commID: self uuid;
														data:data;
														targetName: self targetName;
														yourself)
]

{ #category : #accessing }
IPComm >> session [

	^ session
]

{ #category : #accessing }
IPComm >> session: anObject [

	session := anObject
]

{ #category : #accessing }
IPComm >> targetName [
	^ targetName 
]

{ #category : #accessing }
IPComm >> targetName: aString [
	targetName := aString
]

{ #category : #'instance creation' }
IPComm >> update: state [

	self publish: (self session commUpdateMessage 
															state: state;
															commID: self uuid;
															yourself)
]

{ #category : #accessing }
IPComm >> uuid [
	^ uuid ifNil:[ uuid:= UUID new hex asString asUppercase].
]

{ #category : #accessing }
IPComm >> uuid: anObject [
	uuid := anObject
]
