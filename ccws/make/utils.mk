ccws_rebase:
	-git remote add ccws https://github.com/asherikov/ccws.git --no-tags
	git fetch --all
	git rebase remotes/ccws/master

grab_video:
	test "${NAME}" != ""
	ffmpeg -f x11grab -s 1920:1080 -i :1.0 -r 25 -vcodec libx264 ${CCWS_ARTIFACTS_DIR}/`date +%Y_%m_%d__`${NAME}.mkv
