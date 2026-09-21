
all:
	xcodebuild -workspace chasm.xcodeproj/project.xcworkspace -scheme chasm SYMROOT=${PWD}/build | xcbeautify
	
test:
	xcodebuild -workspace chasm.xcodeproj/project.xcworkspace -scheme chasmTest test SYMROOT=${PWD}/build | xcbeautify
	
