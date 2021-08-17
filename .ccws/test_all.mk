test:
	${MAKE} -f .ccws/test_cross.mk PROFILE=cross_raspberry_pi
	${MAKE} -f .ccws/test_cross.mk PROFILE=cross_jetson_xavier
	${MAKE} -f .ccws/test_cross.mk PROFILE=cross_jetson_nano
