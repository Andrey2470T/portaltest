-- GUN CONFIGURATION --

gsettings = {}
-- gravity acceleration (metres/second^2)
gsettings.SPLASH_STREAM_GRAVITY = 9.8

-- speed of stream splash (metres/second)
gsettings.SPLASH_STREAM_SPEED = 50

-- lifetime of splash drop (seconds)
gsettings.SPLASH_DROP_LIFETIME = 2

-- splash stream collision box
gsettings.SPLASH_STREAM_COLLISION_BOX = {-0.01, -0.01, -0.01, 0.01, 0.01, 0.01}

-- splash drop collision box
gsettings.SPLASH_DROP_COLLISION_BOX = {-0.005, -0.005, -0.005, 0.005, 0.005, 0.005}
