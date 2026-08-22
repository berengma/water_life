#!/usr/bin/env bash
# Convert all .ogg files in the current directory to mono using ffmpeg
shopt -s nullglob

for f in *.ogg; do
	[ -e "$f" ] || continue
	
	# Do nothing if already mono
	if (ffprobe -v error \
		-select_streams a:0 \
		-show_entries stream=channels \
		-of default=nokey=1:noprint_wrappers=1 \
		"$f" | awk '{exit ($1<=1 ? 0 : 1)}'
	); then
		printf 'Skipping %s because it is already mono.\n' "$f"
		continue
	fi

	# Convert it
	out="${f%.*}.mono.ogg"
	if (!(ffmpeg -i "$f" -ac 1 "$out" -y)); then
		printf 'Error!\n'
	fi
	mv -f "$out" "$f"
done

