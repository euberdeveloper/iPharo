"
I store the execution environment for a User, I implement playground variables, compile and evaluate the code. 

- I am a message factory, because all the answering messages need session information to build the wire message to the client. 

- I collaborate with IPComm and IPWidgets. 

 
Internal Representation and Key Implementation Points.

    Instance Variables
	bindings:		<Dictionary>, playground variables
	cachedObjects:	<Dictionary>, Bitmapped Objects are catched
	display:		<IPDisplay> is responsible of displaing complex object. 
	executionCounter:		<Integer>.
	id:		<Object> Session Id.
	startTime:		<Object> Session starting time.
	username:		<Object>
	widgetsFactory:		<IPWidgetFactory>


    Implementation Points
"
Class {
	#name : #IPSession,
	#superclass : #Object,
	#instVars : [
		'id',
		'username',
		'startTime',
		'executionCounter',
		'bindings',
		'cachedObjects',
		'display',
		'widgetsFactory',
		'currentMessage',
		'request',
		'sem',
		'pluggableEvaluationBlock',
		'debuggerServer',
		'dapServerPort',
		'clientSocket'
	],
	#classInstVars : [
		'sessions'
	],
	#category : #'IPharo-Core'
}

{ #category : #accessing }
IPSession class >> finalizeSession: sessionId [
	self sessions removeKey: sessionId

]

{ #category : #accessing }
IPSession class >> finalizeSessions [
	self sessions do:[:aSession | aSession dapServer ifNotNil:[
		  aSession dapServer isRunning ifTrue:[ aSession dapServer stop ] ] ]. 
	self sessions removeAll

]

{ #category : #accessing }
IPSession class >> getSessionForMessage: aMessage [

	| session |
	session := self sessions at: (aMessage header session) ifAbsentPut:[
						self new 
							username: aMessage header username;
							id: aMessage header session;
							startTime: aMessage header timestamp ].
	session currentMessage:	aMessage.
	^ session						
	
		
									
]

{ #category : #accessing }
IPSession class >> session: aSessionId [
	
	^ self sessions at: aSessionId 


									
]

{ #category : #accessing }
IPSession class >> sessions [
	^ sessions ifNil:[ sessions := Dictionary new ]
]

{ #category : #visiting }
IPSession >> acceptInputReplay: content [
	request := content.
	sem signal
]

{ #category : #'workspace-variables' }
IPSession >> bindingOf: aString [ 
	(bindings includesKey: aString)
		ifFalse: [ bindings add: (WorkspaceVariable key: aString asSymbol) ].
	^ bindings associationAt: aString
]

{ #category : #'workspace-variables' }
IPSession >> bindings [
	^ bindings
]

{ #category : #'message-comm' }
IPSession >> commCloseMessage [
	 | msg |
	msg := IPCommCloseMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-comm' }
IPSession >> commInfoReplyMessage [
	 | msg |
	msg := IPCommInfoReplyMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-comm' }
IPSession >> commMsgMessage [
	 | msg |
	msg := IPCommMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-comm' }
IPSession >> commOpenMessage [
	 | msg |
	msg := IPCommOpenMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-comm' }
IPSession >> commUpdateMessage [
	 | msg |
	msg := IPCommUpdateMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #evaluation }
IPSession >> compileAndEvaluate: aMessage [
	| result |
	self display reset.
	result := self evaluate: aMessage content code.
	result = self doNotSendDisplayOutputToken
	ifFalse:[
		self publishExecutionResult: result]
	
	
]

{ #category : #'message-comm' }
IPSession >> completeReplyMsg [
	 | msg |
	msg := IPCompleteReplyMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #accessing }
IPSession >> currentMessage [

	^ currentMessage
]

{ #category : #accessing }
IPSession >> currentMessage: anObject [

	currentMessage := anObject
]

{ #category : #dap }
IPSession >> dapClientSocket [

	| serverAddress |
	
	^ clientSocket 
		ifNil:[
			clientSocket := Socket newTCP.
			serverAddress := NetNameResolver addressForName: '127.0.0.1'.
			clientSocket connectTo: serverAddress port: dapServerPort;waitForConnectionFor: 10. 
			clientSocket ]
		ifNotNil:[
			clientSocket isConnected 
				ifTrue:[ clientSocket ]
				ifFalse:[ 
					clientSocket closeAndDestroy.
					clientSocket := nil.
					self dapClientSocket ] ]
	
]

{ #category : #dap }
IPSession >> dapServer [

	^ debuggerServer 
]

{ #category : #'message-control' }
IPSession >> debugEventMsg [
	 | msg |
	msg := IPDebugEventMsg  newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-control' }
IPSession >> debugReplyMsg [
	 | msg |
	msg := IPDebugReplyMsg  newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'message-control' }
IPSession >> debugRequestMsg [
	 | msg |
	msg := IPDebugRequestMsg  newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'public-api' }
IPSession >> defaultNumberOfRows [
	^ 100

	 
	
														
														
]

{ #category : #accessing }
IPSession >> display [
	^ display ifNil:[ display := IPDisplay onSession: self ]
]

{ #category : #'messages-iopub' }
IPSession >> displayDataMessage [
	 | msg |
	msg := IPDisplayDataMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.

	^ msg 
]

{ #category : #evaluation }
IPSession >> doNotSendDisplayOutputToken [
	^ '123456789qwertyui---------donotdisplay'
	
	
]

{ #category : #evaluation }
IPSession >> evaluate: sourceCode [

	| compiledMethod |

	^  	
		self dapServer isInitialized 
		ifTrue:[ 
			self dapServer launch:sourceCode seq: 1.
			self doNotSendDisplayOutputToken
		 ]
		ifFalse:[ 		
			compiledMethod := self pluggableCompilationBlock value: sourceCode.
			compiledMethod  valueWithReceiver: self arguments:{self} ]	 
]

{ #category : #'messages-iopub' }
IPSession >> executeErrorMessage [
	 | msg |
	msg := IPExecuteErrorMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'messages-iopub' }
IPSession >> executeInputMessage [
	 | msg |
	msg := IPExecuteInputMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg executionCount:  executionCounter
	
																						
]

{ #category : #'messages-iopub' }
IPSession >> executeResultMessage [
	 | msg |
	msg := IPExecuteResultMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg executionCount:  executionCounter
]

{ #category : #'messages-shell' }
IPSession >> executionAbortedMessage [
	 | msg |
	msg := IPExecutionAbortedMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg executionCount:  self executionCounter
]

{ #category : #accessing }
IPSession >> executionCounter [
	^ executionCounter 
]

{ #category : #'messages-shell' }
IPSession >> executionErrorMessage [
	 | msg |
	msg := IPExecutionErrorMsg newReplyingToWireMessage: self currentMessage wireMessage.  
	self initializeMessageHeader: msg.
	^ msg executionCount:  self executionCounter
]

{ #category : #'messages-shell' }
IPSession >> executionOkMessage [
	 | msg |
	msg := IPExecutionOkMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	msg metadata engine: self id.
	self initializeMessageHeader: msg.
	^ msg executionCount:  self executionCounter
]

{ #category : #dap }
IPSession >> extractDapRequest [
	| result interactionStream |
	result := OrderedCollection new.
	interactionStream := SocketStream on: self dapClientSocket. 
	[ interactionStream isDataAvailable ] whileTrue:[
		[interactionStream peek = ${] whileFalse:[	interactionStream next ].
		result add: (SCMaterializer materializeFrom: interactionStream) ].
	Processor yield.
	(Delay forDuration: 5 milliSecond ) wait.
	 ^ result .
]

{ #category : #'workspace-variables' }
IPSession >> guessTypeForName: aString [
	| binding |
	bindings
		ifNotNil: [ 
			binding := bindings at: aString ifAbsent: [ nil ].
			binding isNil
				ifFalse: [ ^ binding class ] ].
	^ nil
]

{ #category : #'workspace-variables' }
IPSession >> hasBindingOf: aString [ 
	^(self guessTypeForName: aString) notNil
]

{ #category : #'workspace-variables' }
IPSession >> hasBindingThatBeginsWith: aString [
	^ bindings keys anySatisfy: [:each | each beginsWith: aString]
]

{ #category : #accessing }
IPSession >> id [
	^ id
]

{ #category : #accessing }
IPSession >> id: anObject [
	id := anObject
]

{ #category : #accessing }
IPSession >> increaseExecutionCounter [
	executionCounter := executionCounter + 1
]

{ #category : #initialization }
IPSession >> initialize [

	super initialize.
	self initializeBindings.
	self initializeDapServer.
	executionCounter := 1.
	sem :=Semaphore new.

]

{ #category : #initialization }
IPSession >> initializeBindings [
	
	^ bindings := { #self -> self } asDictionary
]

{ #category : #initialization }
IPSession >> initializeDapServer [
	
	^ debuggerServer ifNil:[
		Smalltalk at: #DAPServer 
			ifPresent:[ :aDAPclass |
				debuggerServer := aDAPclass new.
				dapServerPort := debuggerServer start.
				self startDapResponder.
				debuggerServer ]
			ifAbsent:[ debuggerServer := NoDebugServerPresent new ] ]
]

{ #category : #initialization }
IPSession >> initializeMessageHeader: aMessage [
	"copy header from wire message, it could not be serialized from the IPMsg, jupyter client need to receive exactly the same bytes in parent header than the source wire message...so if you serialize, the order of the properties could not be the same so byte stream will not.
	All of the messages in a session are answering to an execute request message"
	aMessage header 
				session: self id;
				username: self username.

	^ aMessage 
]

{ #category : #'workspace-variables' }
IPSession >> interactive [ 
	^ false
]

{ #category : #'messages-shell' }
IPSession >> kernelInfoReplayMessage [
	 | msg |
	msg := IPKernelInfoReplyMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #'messages-iopub' }
IPSession >> kernelStatusBusyMessage [
	 | msg |
	msg := IPKernelStatusBusyMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
 
]

{ #category : #'messages-iopub' }
IPSession >> kernelStatusIdleMessage [
	 | msg |
	msg := IPKernelStatusIdleMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
 
]

{ #category : #'public-api' }
IPSession >> loadScript: aStringScript [
	"used to load javascript in client side"
	self display injectScript:aStringScript

	
	 
	
														
														
]

{ #category : #'workspace-variables' }
IPSession >> notify: aString at: anInteger in: aString3 [ 
	"we ignore"
]

{ #category : #evaluation }
IPSession >> pluggableCompilationBlock [

	^ pluggableEvaluationBlock ifNil:[
		pluggableEvaluationBlock :=  [ :source | 
			self class compiler
			source:  source;
			noPattern: true;
			context: thisContext;
			requestor: self;
			bindings: self bindings;
			compileDoit ] ]
]

{ #category : #accessing }
IPSession >> print: anObject [
	^ self display openInJupyter: anObject
]

{ #category : #evaluation }
IPSession >> publishExecutionResult: result [

	| executionResult dataModel |
	executionResult := self  executeResultMessage.
	dataModel := self display buildDisplayDataModel: result asString.
	executionResult content addAll: dataModel.	
	self display publish: executionResult
]

{ #category : #'public-api' }
IPSession >> request: requestString [
	| msg |
	(self currentMessage content at:'allow_stdin') ifFalse:[ IPStdInNotSupportedByClient signal].
	msg := IPInputRequestMsg newReplyingToWireMessage: self currentMessage wireMessage.
	msg prompt: requestString.
	self initializeMessageHeader: msg.
	IPharoKernel instance stdin sendMessage: msg.
	"request should be written by #acceptInputReply from IPharoKernel instance stdin processor"
	sem wait.
	^ request
	
	
]

{ #category : #private }
IPSession >> seed [ 
	^ 1972
]

{ #category : #accessing }
IPSession >> selectedClassOrMetaClass [
	^ nil
]

{ #category : #accessing }
IPSession >> sessionId [ 
	^ self currentMessage header session
]

{ #category : #'workspace-variables' }
IPSession >> setBindings: aDictionary [
	"Sets the Workspace to use the specified dictionary as its namespace"
	bindings := aDictionary.
]

{ #category : #dap }
IPSession >> startDapResponder [
	| event response collectionOfMessages |
	[
		[self dapServer isRunning] whileTrue:[
			collectionOfMessages := self extractDapRequest.
			collectionOfMessages do:[ :message |
				message type = #event 
				ifTrue:[ 
					event := self debugEventMsg.
					event content: message.
					IPharoKernel instance publisher publish: event ]
				ifFalse:[	
					response := self debugReplyMsg.
					response content: message.
					IPharoKernel instance control sendMessage: response ] ] ] ] 
	forkAt: Processor systemBackgroundPriority named:'ipharo-dapResponder'
]

{ #category : #accessing }
IPSession >> startTime [
	^ startTime
]

{ #category : #accessing }
IPSession >> startTime: anObject [
	startTime := anObject
]

{ #category : #'messages-iopub' }
IPSession >> updateDisplayMessage [
	 | msg |
	msg := IPUpdateDisplayDataMsg newReplyingToWireMessage: self currentMessage wireMessage. 
	self initializeMessageHeader: msg.
	^ msg 
]

{ #category : #accessing }
IPSession >> username [
	^ username
]

{ #category : #accessing }
IPSession >> username: anObject [
	username := anObject
]

{ #category : #'public-api' }
IPSession >> widgetsFactory [
	^ widgetsFactory ifNil:[widgetsFactory := IPWidgetFactory onSession: self]
]
